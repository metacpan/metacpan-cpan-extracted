package DBIx::Schema::Changelog::Commands;

=head1 NAME

DBIx::Schema::Changelog::Command - Command Line module for DBIx::Schema::Changelog

=head1 VERSION

Version 0.9.0


=cut

our $VERSION = '0.9.0';

use utf8;
use strict;
use warnings;
use DBI;
use Pod::Usage;
use Getopt::Long;
use DBIx::Schema::Changelog::Command::Driver;
use DBIx::Schema::Changelog::Command::File;
use DBIx::Schema::Changelog::Command::Changeset;
use DBIx::Schema::Changelog::Command::Read;
use DBIx::Schema::Changelog::Command::Write;

# -----------------------------------------------
# Preloaded methods go here.
# -----------------------------------------------
# Encapsulated class data.
{

    sub _process_command_line {
        my ( $self, %config ) = @_;
        $config{'argv'} = [@ARGV];
        GetOptions(

            # command
            'cd|createdriver'    => \$config{createdriver},
            'cf|createfile'      => \$config{createfile},
            'cc|createchangeset' => \$config{createchangeset},
            'h|help|?'           => \$config{help},
            'v|version'          => \$config{version},
            'w|write'            => \$config{write},
            'r|read'             => \$config{read},

            # options
            'dr|driver=s'   => \$config{driver},
            't|type=s'      => \$config{file_type},
            'db|database=s' => \$config{db},
            'd|dir=s'       => \$config{dir},
            'u|user=s'      => \$config{user},
            'p|pass=s'      => \$config{pass},
            'a|author=s'    => \$config{author},
            'e|email|@=s'   => \$config{email},
        );
        return %config;
    }
}    ############# End of encapsulated class data.      ########################

=head2 run

    Is called from the changelog-run in bin directory

=cut

sub run {
    my $self   = shift;
    my %config = ();
    %config = $self->_process_command_line(%config);
    if ( $config{createdriver} ) {
        DBIx::Schema::Changelog::Command::Driver->new()->make( \%config );
    }
    elsif ( $config{createfile} ) {
        DBIx::Schema::Changelog::Command::File->new()->make( \%config );
    }
    elsif ( $config{createchangeset} ) {
        DBIx::Schema::Changelog::Command::Changeset->new( \%config )->make();
    }
    elsif ( $config{read} ) {
        DBIx::Schema::Changelog::Command::Read->run( \%config );
    }
    elsif ( $config{write} ) {
        DBIx::Schema::Changelog::Command::Write->run( \%config );
    }
    elsif ( $config{version} ) { print __PACKAGE__, ' Verion: ', $VERSION, $/; }
    elsif ( $config{help} ) { pod2usage( { -verbose => 1 } ); }
    else                    { pod2usage( { -verbose => 1 } ); }
}

no Moose;

1;

__END__

=head1 SYNOPSIS

=over 4

    changelog-run  [commands] [options]
    ...
    # start reading
    changelog-run -r -db=db.sqlite -d=/path/to/changelog
    ...
    # make new driver module
    changelog-run -cd --author='Mario Zieschang' -email='mziescha [at] cpan.org' -driver=MySQL -dir=/path/to/directory
    ...
    # make new file read module
    changelog-run -cf -a='Mario Zieschang' -@='mziescha [at] cpan.org' -t=XML -dir=/path/to/directory
    ...
    # create a new changeset project
    changelog-run -cc -dir=/path/to/directory

=back

=head1 OPTIONS

=over 4

    Commands:
    -cd --createdriver      : Will create a module for a new driver
    -cf --createfile        : Will create a module for a new file parser
    -cc, --createchangeset  : Will create a new changeset project
    -w, --Write             : Write changeset files from existing database
    -r, --read              : Read changelog files
    -v, --version           : Print the current version of this module
    -h, --help, -?          : print what you are currently reading
    (If no command is set print what you are currently reading.)

    Options:
    -a, --author            : Author of new file or driver
    -d, --dir               : Directory of new file or driver
    -dr, --driver           : Driver to use by running changelog (default SQLite)
    -t, --type              : File type for reading changesets (default Yaml)
    -db, --database         : Database to use by running changelog (default SQLite)
    -u, --user              : User to connect with remote db
    -p, --pass              : Pass for user to connect with remote db
    -e, --email, -@         : Email of author of new file or driver

=back

=head1 SEE ALSO

=over 4

=item L<module::Starter>   The package from which the idea originated.

=back

=head1 AUTHOR

=over 4

Mario Zieschang, C<< <mziescha at cpan.org> >>

=back

=head1 LICENSE AND COPYRIGHT

=over 1

Copyright 2015 Mario Zieschang.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, trade name, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANT ABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=back

=cut
