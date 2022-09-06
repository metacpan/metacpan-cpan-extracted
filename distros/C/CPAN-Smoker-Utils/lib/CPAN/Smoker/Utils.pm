package CPAN::Smoker::Utils;

use warnings;
use strict;
use Exporter 'import';
use CPAN;
use CPAN::HandleConfig;

our @EXPORT_OK = qw(is_distro_ok block_distro);

our $VERSION = 'v1.0.1'; # VERSION

=pod

=head1 NAME

CPAN::Smoker::Utils - Set of CLI's to manage a Perl CPAN smoker machine

=head1 DESCRIPTION

This module exports some functions used to manage a smoker testing machine
based on L<CPAN::Reporter::Smoker>.

=head2 Command Line Interfaces programs

The following programs are available under this distribution:

=over

=item *

C<dblock>: blocks a distribution to be tested in the smoker.

=item *

C<mirror_cleanup>: further removes spurious files from a local CPAN mirror.

=item *

C<send_reports>: send local stored tests results to a running
L<metabase::relayd>.

=back

You can check each program online documentation by using C<perldoc dblock>,
C<perldoc mirror_cleanup> and C<perldoc send_reports> after installing the
distribution.

=head1 EXPORTS

Only the C<sub> C<is_distro_ok> is exported, if explicit requested.

=head2 is_distro_ok

Expects as parameter a string in the format C<AUTHOR/DISTRIBUTION>.

It executes some very basic testing against the string.

Returns true or false depending if the string passes the tests. It will also
C<warn> if things are not OK.

=cut

sub is_distro_ok {
    my $distro = shift;

    unless ( defined($distro) ) {
        warn "--distro is a required parameter!\n\n";
        return 0;
    }

    unless ( $distro =~ /^\w+\/[\w-]+$/ ) {
        warn "invalid string '$distro' in --distro!\n\n";
        return 0;
    }
    else {
        return 1;
    }
}

=head2 block_distro

Blocks a distribution to be tested under the smoker by using a distroprefs file.

Expects as parameters:

=over

=item 1.

a distribution name (for example, "JOHNDOE/Some-Distro-Name").

=item 2.

The perl interpreter (which is in execution) configuration.

=item 3.

An comment to include in the distroprefs file.

=back

It returns a hash reference containing keys/values that could be directly
serialized to YAML (or other format) but the C<full_path> key, that contains
a suggest complete path to the distroprefs file (based on the L<CPAN>
C<prefs_dir> configuration client.

If there is an already file created as defined in C<full_path> key, it will
C<warn> and return C<undef>.

=cut

sub block_distro {
    my ( $distro, $perl_info, $comment ) = @_;
    my $distribution = '^' . $distro;
    my $filename     = "$distro.yml";
    $filename =~ s/\//./;

    my %data = (
        comment => $comment || 'Tests hang smoker',
        match   => {
            distribution => $distribution,
            perlconfig   => $perl_info
        },
        disabled => 1
    );

    CPAN::HandleConfig->load;
    my $prefs_dir = $CPAN::Config->{prefs_dir};
    die "$prefs_dir does not exist or it is not readable\n"
        unless ( -d $prefs_dir );
    my $full_path = File::Spec->catfile( $prefs_dir, $filename );

    if ( -f $full_path ) {
        warn "$full_path already exists, will not overwrite it.";
        return;
    }
    else {
        $data{full_path} = $full_path;
        return \%data;
    }
}

=head1 SEE ALSO

For more details about those programs interact with the smoker and
L<CPAN::Reporter>, be sure to read the documentation about L<CPAN> client,
specially the part about DistroPrefs.

You will also want to take a look at the following programs documentation:

=over

=item *

C<perldoc send_reports>

=item *

C<perldoc dblock>

=item *

C<perldoc mirror_cleanup>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 of Alceu Rodrigues de Freitas Junior,
arfreitas@cpan.org

This file is part of CPAN Smoker Utils.

CPAN Smoker Utils is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

CPAN Smoker Utils is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with CPAN Smoker Utils.  If not, see L<http://www.gnu.org/licenses/>.

=cut

1;
