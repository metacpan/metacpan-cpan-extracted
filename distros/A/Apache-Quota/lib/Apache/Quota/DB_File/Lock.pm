package Apache::Quota::DB_File::Lock;

use strict;

use DB_File::Lock;
use Fcntl qw(O_CREAT O_RDWR O_RDONLY);

sub _open_db
{
    my $class = shift;
    my %p = @_;

    my $rdwr;
    if ( $p{mode} eq 'read' )
    {
        $rdwr = O_CREAT|O_RDONLY;
    }
    else
    {
        $rdwr = O_CREAT|O_RDWR;
    }

    my $locking = { mode        => $p{mode},
                    nonblocking => 1,
                  };

    my %db;
    for ( 1..3 )
    {
        last if tie %db, 'DB_File::Lock', $p{file}, $rdwr, 0644, $DB_HASH, $locking;

        sleep 1;
    }

    die "Cannot tie to $p{file} with DB_File::Lock: $!" unless tied %db;

    return \%db;
}


1;

__END__

=head1 NAME

Apache::Quota::DB_File::Lock - Uses DB_File::Lock to lock the quota db file

=head1 SYNOPSIS

  PerlSetVar  QuotaLocker  DB_File::Lock

=head1 DESCRIPTION

This module implements locking for the quota db file using
DB_File::Lock.

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
