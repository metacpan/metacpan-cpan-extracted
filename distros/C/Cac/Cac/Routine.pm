package Cac::Routine;

use 5.006;
use strict;
use warnings;
use bytes;
  
use XSLoader;
XSLoader::load Cac unless $Cac::xs_loaded++; # this is in cacperl.xs :)

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( &Do &Call );
our @EXPORT = @EXPORT_OK;
our $VERSION = 1.83;

=head1 NAME

Cac::Routine - Call COS routines or functions 

=head1 SYNOPSIS

  use Cac::Routine;

  Do "tag", "routine", @args
  my $rc = Call "tag", "routine", @args

=head1 DESCRIPTION
 
This module gives you a high-performance call-gate
into Cache.

=head1 FUNCTIONS

The following functions (which are all exported) exist:

=over 4

=item Do $tag, $routine, [ @args ]

  Performs a DO and returns nothing.

=item Call $tag, $routine, [ @args ]

  Calls a Cache Function and returns it's result.

=back

=head1 EXPORTS

 none.

=head1 SEE ALSO

L<Cac>, L<Cac::Global>, L<Cac::Bind>, L<Cac::ObjectScript>, L<Cac::ObjectScript>.

=head1 AUTHOR

 Stefan Traby <stefan@hello-penguin.com>
 http://hello-penguin.com

=cut

1;
__END__

