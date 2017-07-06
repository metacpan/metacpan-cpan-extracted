package CPAN::Reporter::Smoker::OpenBSD;
use warnings;
use strict;
use Exporter 'import';
our @EXPORT_OK = qw(is_distro_ok);
our $VERSION = '0.007'; # VERSION

sub is_distro_ok {
    my $distro = shift;

    unless (defined($distro)) {
       warn "--distro is a required parameter!\n\n";
       return 0;
    }

    unless ($distro =~ /^\w+\/[\w-]+$/) {
        warn "invalid string '$distro' in --distro!\n\n";
        return 0;
    } else {
        return 1;
    }
}

=pod

=head1 NAME

CPAN::Reporter::Smoker::OpenBSD - set of scripts to manage a CPAN::Reporter::Smoker on OpenBSD

=head1 DESCRIPTION

This module is mainly Pod: you want to take a look at the following programs documentation:

=over

=item *

C<perldoc send_reports>

=item *

C<perldoc dblock>

=item *

C<perldoc mirror_cleanup>

=back

=head1 EXPORTS

Only the C<sub> C<is_distro_ok> is exported, if explicit requested.

=head2 is_distro_ok

Expects as parameter a string in the format <AUTHOR>/<DISTRIBUTION>.

It executes some very basic testing against the string.

Returns true or false depending if the string passes the tests. It will also C<warn> if things are not going OK.

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 of Alceu Rodrigues de Freitas Junior, arfreitas@cpan.org

This file is part of CPAN OpenBSD Smoker.

CPAN OpenBSD Smoker is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

CPAN OpenBSD Smoker is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with CPAN OpenBSD Smoker.  If not, see <http://www.gnu.org/licenses/>.

=cut

1;
