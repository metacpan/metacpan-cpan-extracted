package App::LedgerSMB::Admin;

use 5.006;
use strict;
use warnings FATAL => 'all';

=head1 NAME

App::LedgerSMB::Admin - Easily Manage LedgerSMB Installations

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';


=head1 SYNOPSIS

This module provides the basic routines for managing multiple major versions of
LedgerSMB through a consistent toolkit.

It contains basically two components:

=over

=item command line scripts

=item libraries for writing management programs

=back

=head1 BUNDLED CLI PROGRAMS

=head2 lsmb_reload

Due to improper errors, this currently does not work properly with LedgerSMB
1.3.  It is expected that it will following the LedgerSMB 1.3.45 release
(forthcoming).

The lsmb_reload application provides a command line tool for upgrading or
rebuilding stored procedures and permissions of a LedgerSMB 1.3 or 1.4 database.

Due to shortcomings in error handling it does not work for LedgerSMB 1.3.44 and
below.

The program supports UNIX sockets as well as TCP/IP for connecting to the
LedgerSMB database, and all aspects of the database connection may be controlled
through the same environment variables as any other libpq program.

The following options are supported:

   --all                    Reload All Databases
   --help                   Print this message and exit
   --host hostname          Database Host
   --path13 /example/path   Path to LedgerSMB 1.3 installation
   --path14 /example/path2  Path to LedgerSMB 1.4 installation
   --port 5432              Database Poart
   --dbname database        Reload the specified db, overridden by --all
   --username postgres      Database Superuser to Log In As
   --prompt-password        Prompt for Password (can use PGPASSWORD instead)


=head2 lsmb_createdb

Due to improper errors, this currently does not work properly with LedgerSMB
1.3.  It is expected that it will following the LedgerSMB 1.3.45 release
(forthcoming).

The lsmb_reload application provides a command line tool for upgrading or
rebuilding stored procedures and permissions of a LedgerSMB 1.3 or 1.4 database.

   --help                   Print this message and exit
   --host hostname          Database Host
   --path /example/path     Path to LedgerSMB installation (required)
   --chart us/chart/General Chart of Accounts path (relative to sql)
   --gifi  ca/gifi/General  Path to GIFI
   --port 5432              Database Poart
   --dbname database        Create db with the following name (required)
   --username postgres      Database Superuser to Log In As
   --prompt-password        Prompt for Password (can use PGPASSWORD instead)

=head1 Bundled Libraries

=head2 App::LedgerSMB::Admin

Provides base version tracking and management routines

=head2 App::LedgerSMB::Admin::Database

Routines to reload, create, update, backup, and restore databases

=head2 App::LedgerSMB::Admin::Database::Setting

Look up settings in a LedgerSMB database

=head2 App::LedgerSMB::Admin::User

Undeveloped, but will include basic user management routines.

=head1 SUBROUTINES/METHODS of This Library

=head2 add_paths(%versionhash)

=cut

my %version_paths;

sub add_paths{
    shift if $_[0] eq __PACKAGE__;
    my %version_hash = @_;
    %version_paths = (%version_paths, %version_hash);
    return %version_paths;
}

=head2 path_for($major_version)

=cut

sub path_for{
    shift if $_[0] eq __PACKAGE__;
    return $version_paths{$_[0]};
}

=head1 AUTHOR

Chris Travers, C<< <chris at efficito.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-ledgersmb-admin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-LedgerSMB-Admin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::LedgerSMB::Admin


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-LedgerSMB-Admin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-LedgerSMB-Admin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-LedgerSMB-Admin>

=item * Search CPAN

L<http://search.cpan.org/dist/App-LedgerSMB-Admin/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Chris Travers.

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

* Neither the name of Chris Travers's Organization
nor the names of its contributors may be used to endorse or promote
products derived from this software without specific prior written
permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of App::LedgerSMB::Admin
