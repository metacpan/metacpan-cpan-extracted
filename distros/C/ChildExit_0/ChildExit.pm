package Apache::ChildExit;

use 5.006;
use strict;
use warnings;
use Carp ;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Apache::ChildExit ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( postpone ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.1';

bootstrap Apache::ChildExit $VERSION;

# Preloaded methods go here.

our @postponed ;

BEGIN {
	@postponed = () ;
	}


sub handler {
	ChildExit() ;
	}


sub nullCode {
	my $t ;
	my $str = '$t = sub {}' ;

	eval $str ;
	return $t ;
	}


sub Postpone {
	my $cv ;
	my @caller = caller ;

	if ( $caller[0] =~ /^Apache::ROOT/i ) {
		push @postponed, $cv while ( $cv = ShiftEND( nullCode() ) ) ;
		}
	elsif ( $caller[0] eq 'main' ) {}
	else {
		carp "Unrecognized caller package $caller[0]" ;
		}
	}


sub PostponedCount {
	return scalar @postponed ;
	}


sub ChildExit {
	foreach ( @postponed ) {
		&$_ ;
		}
	}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Apache::ChildExit - Modify ModPerl Apache::Registry's treatment of B<END> 
blocks

=head1 SYNOPSIS

Each script executed by Apache::Registry should contain the following 
statements:

  use Apache::ChildExit ;
  Apache::ChildExit::Postpone() ;

or

  use Apache::ChildExit qw( Postpone ) ;
  Postpone() ;

The Postpone() function should be called in the last line of your script.


=head1 DESCRIPTION

## Example

  use Apache::ChildExit qw( Postpone ) ;

  ## ...user code...
  printf "%d\n", Apache::ChildExit::ENDBlockCount() ;	# 4
  printf "%d\n", Apache::ChildExit::PostponedCount() ;	# 0

  Postpone() ;
  printf "%d\n", Apache::ChildExit::ENDBlockCount() ;	# 0
  printf "%d\n", Apache::ChildExit::PostponedCount() ;	# 4

  ## ...user code...
  printf "%d\n", Apache::ChildExit::ENDBlockCount() ;	# 3
  printf "%d\n", Apache::ChildExit::PostponedCount() ;	# 4

  Postpone() ;
  printf "%d\n", Apache::ChildExit::ENDBlockCount() ;	# 0
  printf "%d\n", Apache::ChildExit::PostponedCount() ;	# 7

  ## Child process terminates
  Apache::ChildExit::ChildExit() ;

As part of Apache::Registry's design, the B<BEGIN> blocks' code executes only 
once when a module is compiled.  But the B<END> blocks are executed every time 
the enclosing script runs.  Consequently, Apache::Registry is incompatible 
with the standard Perl specification, which balances the execution of 
the B<BEGIN> and B<END> blocks.  Modules that use these blocks to allocate and 
deallocate resources will behave quite badly when run under 
Apache::Registry, possibly damaging other system resources.

In Perl, each B<END> block is represented by a code reference.  
Apache::ChildExit moves these references into a private array.  
Subsequently, the code blocks are not executed until the B<ChildExit>
phase of Apache's operation.

In the above example, 4 B<END> blocks are encountered while compiling the first 
block of user code.  3 additional B<END> blocks are encountered while compiling
the second block of user code.  After each block of user code, the Postpone()
command moves the B<END> block code references.

Apache::Registry compiles each script upon request by the web server.  After
running the script, Apache::Registry will execute each of the encountered B<END>
blocks.  In order to prevent execution of the B<END> blocks, the Postpone()
function should be the last line of code in each script.

The Postpone() function should not be successfully called without an
eventual call to the ChildExit() function, or indirectly, the handler()
function.  As a safeguard, the Postpone() function ensures the 
Apache::Registry environment by checking the caller package.  If the 
caller package is B<main>, the Postpone() function call has no effect.
Postpone() will complain B<Unrecognized caller package> if called outside
of the above guidelines.

In order to comply with the Perl specification, the B<END> blocks are
executed by the handler function during the B<ChildExit> phase of an Apache 
process.  The following line needs to be added to httpd.conf:

	PerlChildExitHandler Apache::ChildExit

=head2 EXPORT

None by default.


=head1 AUTHOR

Jim Schueler, E<lt>jschueler@tqis.comE<gt>

=head1 SEE ALSO

L<perl>.

=cut
