package Alien::WhiteDB;
# ABSTRACT: Discover or download and install WhiteDB
use strict;
use warnings;

use base 'Alien::Base';

1;

__END__

=head1 NAME

Alien::WhiteDB

=head1 SYNOPSIS

    my $alien = Alien::WhiteDB->new;
    my $cflags = $alien->cflags;
    my $libs = $alien->libs;

The above methods are inherited from L<Alien::Base>.

If C<whitedb libwgdb-dev> packages installed on your system, L<Alien::Base> will attempt to use the system version.
Otherwise it will download a latest from L<WhiteDB site|http://whitedb.org/download.html>.

=head1 DESCRIPTION

Discover or download and install L<WhiteDB|http://whitedb.org/>

=head1 AUTHOR

Yegor Korablev <egor@cpan.org>

=head1 LICENSE

The default licence of WhiteDB is GPLv3.

=head1 SEE ALSO

L<Official WhiteDB site|http://whitedb.org/> L<Alien::Base>

=cut
