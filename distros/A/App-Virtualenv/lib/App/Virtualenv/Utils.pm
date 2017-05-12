package App::Virtualenv::Utils;
=head1 NAME

App::Virtualenv::Utils - Utilities for Perl virtual environment (deprecated)

=head1 VERSION

version 2.03

=head1 ABSTRACT

Utilities for Perl virtual environment (deprecated)

=cut
use strict;
use warnings;


BEGIN
{
	require Exporter;
	our $VERSION     = '2.03';
	our @ISA         = qw(Exporter);
	our @EXPORT      = qw();
	our @EXPORT_OK   = qw();
}


warn __PACKAGE__." is deprecated\n";

1;
__END__
=head1 REPOSITORY

B<GitHub> L<https://github.com/orkunkaraduman/perl5-virtualenv>

B<CPAN> L<https://metacpan.org/release/App-Virtualenv>

=head1 AUTHOR

Orkun Karaduman <orkunkaraduman@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017  Orkun Karaduman <orkunkaraduman@gmail.com>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
