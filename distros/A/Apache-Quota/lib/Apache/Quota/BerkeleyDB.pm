package Apache::Quota::BerkeleyDB;

use strict;

use BerkeleyDB qw( DB_CREATE DB_RDONLY DB_INIT_LOCK DB_INIT_MPOOL );
use File::Basename ();

sub _open_db
{
    my $class = shift;
    my %p = @_;

    my $env = BerkeleyDB::Env->new( -Home  => File::Basename::dirname( $p{file} ),
                                    -Flags => DB_INIT_LOCK|DB_INIT_MPOOL,
                                  );

    # BerkeleyDB doesn't allow you to open a db with both DB_CREATE
    # and DB_RDONLY specified, so if it doesn't exist we need to
    # create it now.
    unless ( -f $p{file} )
    {
        BerkeleyDB::Hash->new( -Filename => $p{file},
                               -Flags    => DB_CREATE,
                               -Mode     => 0644,
                               -Env      => $env,
                             );
    }

    my $flags;
    $flags = DB_RDONLY if $p{mode} eq 'read';

    my %db;
    tie %db, 'BerkeleyDB::Hash', ( -Filename => $p{file},
                                   -Flags    => $flags,
                                   -Mode     => 0644,
                                   -Env      => $env,
                                 );

    die "Cannot tie to $p{file} with BerkeleyDB: $BerkeleyDB::Error"
        unless tied %db;

    return \%db;
}


1;

__END__

=head1 NAME

Apache::Quota::BerkeleyDB - Uses BerkeleyDB to lock the quota db file

=head1 SYNOPSIS

  PerlSetVar  QuotaLocker  BerkeleyDB

=head1 DESCRIPTION

This module implements locking for the quota db file using BerkeleyDB.

=head1 SUPPORT

Please submit bugs to the CPAN RT system at
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache%3A%3AQuota
or via email at bug-apache-quota@rt.cpan.org.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT

Copyright (c) 2003-2004 David Rolsky.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut
