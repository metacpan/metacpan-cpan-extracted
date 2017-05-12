package Acme::BlahBlahBlah;

use 5.008003;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	blah_blah_blah
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    blah_blah_blah	    
);

our $VERSION = '0.01';

sub blah_blah_blah {
    croak "blah blah blah";
} 


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Acme::BlahBlahBlah - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Acme::BlahBlahBlah;
  sub bla { blah_blah_blah }

=head1 DESCRIPTION

Perl 6 will have a C<...> operator that dies if it is ever evaluated.  This is an implementation
of it, called C<blah_blah_blah>.

Blah blah blah.

=head2 EXPORT

C<blah_blah_blah>, which dies if it's ever evaluated.


=head1 SEE ALSO

L<Yada::Yada::Yada>, which does the same thing for a different reason.


=head1 AUTHOR

David Glasser, E<lt>glasser@bestpractical.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by David Glasser

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
