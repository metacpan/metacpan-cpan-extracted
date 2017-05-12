package Alien::LMDB;

our $VERSION = '0.103';

use parent 'Alien::Base';

use strict;

1;


__END__


=head1 NAME

Alien::LMDB - Build and install the LMDB embedded database

=head1 SYNOPSIS

    my $lmdb = Alien::LMDB->new;

    my $cflags = $lmdb->cflags;
    ## "-I/usr/local/share/perl/5.20.2/auto/share/dist/Alien-LMDB/include"

    my $libs = $lmdb->libs;
    ## "-L/usr/local/share/perl/5.20.2/auto/share/dist/Alien-LMDB/lib -llmdb"

    my $mdb_stat_binary = $lmdb->bin_dir . '/mdb_stat';
    system("$mdb_stat_binary /path/to/db");

The above methods are inherited from L<Alien::Base>.

If C<pkg-config --modversion lmdb> works on your system, L<Alien::Base> will attempt to use the system-installed lmdb. Otherwise it will use a bundled lmdb tarball.


=head1 DESCRIPTION

This module is primarily for use with L<LMDB_File>.

=head1 SEE ALSO

L<Alien-LMDB github repo|https://github.com/hoytech/Alien-LMDB>

L<LMDB_File>

L<Official LMDB site|http://symas.com/mdb/>

L<github mirror of LMDB repo|https://github.com/LMDB/lmdb>

L<Alien::Base>

=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2016 Doug Hoyte.

This module includes LMDB (formerly known as MDB) which is copyright 2011-2016 Howard Chu, Symas Corp.

LMDB is licensed under the OpenLDAP license.

=cut
