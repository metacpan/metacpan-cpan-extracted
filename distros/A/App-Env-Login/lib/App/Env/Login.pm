# --8<--8<--8<--8<--
#
# Copyright (C) 2016 Smithsonian Astrophysical Observatory
#
# This file is part of App::Env::Login
#
# App::Env::Login is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package App::Env::Login;

use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

use File::Spec::Functions qw[ splitpath ];
use Shell::GetEnv '0.08_03';

sub envs
{
    my ( $opt ) = @_;

    my %opt = ( Shell => $ENV{SHELL}, %$opt );

    my $shell = ( splitpath( $opt{Shell} ) )[-1];

    local %ENV = map { $_ => $ENV{$_} } grep { exists $ENV{$_} }qw[ HOME LOGNAME ];

    return Shell::GetEnv->new( $shell, { Login => 1 } )->envs;
}


__END__

=head1 NAME

App::Env::Login - An App::Env application module which returns the login environment


=head1 SYNOPSIS

    use App::Env 'Login';


=head1 DESCRIPTION

The is an B<App::Env> application module which returns the
user's login environment by starting the user's login shell in login mode.

B<App::Env::Login> should not be used directly.  It must be used via B<App::Env>.


=head1 INTERFACE

The following options may be passed via B<App::Env>'s C<AppOpts> facility:

=over

=item C<Shell>

The user's login shell.  If not specified, this is derived from the
B<SHELL> environment variable.  Any shell supported by the
B<Shell::GetEnv> module is accepted.

=back

=head1 DEPENDENCIES

L<Shell::GetEnv>

=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-app-env-login@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=App-Env-Login>.

=head1 SEE ALSO

L<App::Env>


=head1 VERSION

Version 0.01

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016 The Smithsonian Astrophysical Observatory

App::Env::Login is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 AUTHOR

Diab Jerius  E<lt>djerius@cpan.orgE<gt>


