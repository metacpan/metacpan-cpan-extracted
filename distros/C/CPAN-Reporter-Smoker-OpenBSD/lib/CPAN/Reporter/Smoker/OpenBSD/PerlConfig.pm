package CPAN::Reporter::Smoker::OpenBSD::PerlConfig;

use strict;
use warnings;
use Config;
use Hash::Util qw(lock_hash);

our $VERSION = '0.019'; # VERSION

=pod

=head1 NAME

CPAN::Reporter::Smoker::OpenBSD::PerlConfig - class representing perl configuration

=head1 SYNOPSIS

    use CPAN::Reporter::Smoker::OpenBSD::PerlConfig;

    my $cfg = CPAN::Reporter::Smoker::OpenBSD::PerlConfig->new;

=head1 DESCRIPTION

This class represents a C<perl> configuration in a way that can be used by the
C<dblock> CLI.

It was created to handle the details of a distroprefs implementation, specially
regarding dealing with C<undef> values.

=head1 METHODS

=head2 new

Creates a new instance of this class.

Expects nothing, returns a new instance.

=cut

sub new {
    my $class = shift;
    my $self  = {
        osname   => $Config{osname},
        archname => $Config{archname}
    };
    my $attrib_name = 'useithreads';

    if ( defined( $Config{$attrib_name} ) ) {
        $self->{$attrib_name} = 1;
    }
    else {
        $self->{$attrib_name} = 0;
    }

    bless $self, $class;
    lock_hash( %{$self} );
    return $self;
}

=head2 dump

This methods returns a instance attributes as a hash reference.

This is particulary useful to use with YAML modules C<DumpFile> function.

=cut

sub dump {
    my $self        = shift;
    my %attribs     = %{$self};
    my $attrib_name = 'useithreads';

    if ( $self->{$attrib_name} ) {
        $attribs{$attrib_name} = 'define';
    }
    else {
        delete( $attribs{$attrib_name} );
        $attribs{"no_$attrib_name"} = 'define';
    }

    return \%attribs;
}

=head1 SEE ALSO

=over

=item *

L<Config>

=back

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
