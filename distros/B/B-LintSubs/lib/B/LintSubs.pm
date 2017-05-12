#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2006,2007,2009 -- leonerd@leonerd.org.uk

package B::LintSubs;

use strict;
use warnings;
use B qw(walkoptree_slow main_root main_cv walksymtable);

our $VERSION = '0.06';

my $file = "unknown";		# shadows current filename
my $line = 0;			# shadows current line number
my $curstash = "main";		# shadows current stash
my $curcv;			# shadows current CV for current stash

my %done_cv;		# used to mark which subs have already been linted

my $exitcode = 0;

=head1 NAME

B::LintSubs - Perl compiler backend to check sub linkage

=head1 SYNOPSIS

B<perl> B<-MO=LintSubs> [I<FILE>] [B<-e PROGRAM>]

=head1 DESCRIPTION

When using C<use strict>, subroutine names are not checked at the callsite;
this makes the following a perfectly valid program at compiletime, that only
blows up at runtime

 use strict;
 foobar();

When using the C<B::LintSubs> checker instead, this is detected:

 $ perl -MO=LintSubs -e 'use strict;
                         foobar();'
 Undefined subroutine foobar called at -e line 2

Imported functions from other modules are of course detected:

 $ perl -MO=LintSubs -e 'use strict; 
                         use List::Util qw( max );
			 $_ = max( 1, 2, 3 )'
 -e syntax OK

In order to handle situations where external code is conditionally referenced
at runtime, any fully-qualified references to other functions are printed with
a warning, but not considered fatal. The programmer is assumed to Know What He
Is Doing in this case:

 $ perl -MO=LintSubs -e 'if( 1 ) { require Data::Dumper; 
                                   Data::Dumper::Dump( "Hello" ) }'
 Unable to check call to Data::Dumper::Dump in foreign package at -e line 1
 -e syntax OK

=cut

sub warning {
    my $format = (@_ < 2) ? "%s" : shift;
    warn sprintf("$format at %s line %d\n", @_, $file, $line);
}

sub lint_gv
{
    my $gv = shift;

    my $package = $gv->STASH->NAME;
    my $subname = $package . "::" . $gv->NAME;
    
    no strict 'refs';

    return if defined( &$subname );
    
    # AUTOLOADed functions will have failed here, but can() will get them
    my $coderef = UNIVERSAL::can( $package, $gv->NAME );
    return if defined( $coderef );

    # If we're still failing here, it maybe means a fully-qualified function
    # is being called at runtime in another package, that is 'require'd rather
    # than 'use'd, so we haven't loaded it yet. We can't check this.

    if( $curstash ne $package ) {
        # Throw a warning and hope the programmer knows what they are doing
        warning('Unable to check call to %s in foreign package', $subname);
        return;
    }

    $subname =~ s/^main:://;
    warning('Undefined subroutine %s called', $subname);
    $exitcode = 1;
}

sub B::OP::lint { }

sub B::COP::lint {
    my $op = shift;
    if ($op->name eq "nextstate") {
	$file = $op->file;
	$line = $op->line;
	$curstash = $op->stash->NAME;
    }
}

sub B::SVOP::lint {
    my $op = shift;
    if ($op->name eq "gv"
	&& $op->next->name eq "entersub")
    {
	lint_gv( $op->gv );
    }
}

sub B::PADOP::lint {
    my $op = shift;
    if ($op->name eq "gv"
	&& $op->next->name eq "entersub")
    {
	my $idx = $op->padix;
	my $gv = (($curcv->PADLIST->ARRAY)[1]->ARRAY)[$idx];
	lint_gv( $gv );
    }
}

sub B::GV::lintcv {
    my $gv = shift;
    my $cv = $gv->CV;
    return if !$$cv || $done_cv{$$cv}++;
    if( $cv->FILE eq $0 ) {
        my $root = $cv->ROOT;
        $curcv = $cv;
        walkoptree_slow($root, "lint") if $$root;
    }
}

sub do_lint {
    my %search_pack;

    $curcv = main_cv;
    walkoptree_slow(main_root, "lint") if ${main_root()};

    no strict qw( refs );
    walksymtable(\%{"main::"}, "lintcv", sub { 1 } );

    exit( $exitcode ) if $exitcode;
}

sub compile {
    my @options = @_;

    return \&do_lint;
}

# B.pm has a bug, in walkoptree_slow() tries to recurse into things that
# aren't actually B::OP trees. We'll have to work around it
my $walkoptree_old = \&B::walkoptree_slow;

{
   no warnings 'redefine';
   *B::walkoptree_slow = sub {
      my ( $op, $method, $level ) = @_;
      return unless $op->isa( "B::OP" );
      return $walkoptree_old->( $op, $method, $level );
   };
}

# Keep perl happy; keep Britain tidy
1;

__END__

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

Based on the C<B::Lint> module by Malcolm Beattie, <mbeattie@sable.ox.ac.uk>.

=cut
