package Acme::MetaSyntactic::viclones;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.000';
__PACKAGE__->init();

our %Remote = (
    source  => 'http://www.guckes.net/vi/clones.php3',
    extract => sub {
        return
            map { y!- /!__!d; /clone/ ? () : $_ }
            $_[0] =~ /^<dt>\s*([^[\n\(]+?)(?:\s*\([^)]+\))?\s*\[/gm;
    },
);

1;

=head1 NAME

Acme::MetaSyntactic::viclones - The C<vi> clones theme

=head1 DESCRIPTION

A list of vi clones, as maintained by Sven Guckes on
L<http://www.guckes.net/vi/clones.php3>.

=head1 CONTRIBUTOR

Philippe "BooK" Bruhat.

=head1 CHANGES

=over 4

=item *

2012-05-07 - v1.000

Received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2005-11-21

Added a remote list in Acme-MetaSyntactic version 0.49.

=item *

2005-02-21

Introduced in Acme-MetaSyntactic version 0.10.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
BBStevie bedit Bvi calvin e3 Elvis exvi elwin javi jVi Lemmy levee nvi
Oak_Hill_vi PVIC trived tvi vigor vile vim Watcom_VI WinVi viper virus
xvi
