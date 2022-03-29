package App::SpamcupNG::Warning::Yum;
use strict;
use warnings;
use parent 'App::SpamcupNG::Warning';

our $VERSION = '0.015'; # VERSION

=head1 NAME

App::SpamcupNG::Warning::Yum - representation of a warning about the SPAM
report being fresh.

=head1 SYNOPSIS

See L<App::SpamcupNG::Warning::Factory> instead.

=head1 DESCRIPTION

Everytime Spamcop receives a SPAM report that it considers as fresh, this
warning is available on the website HTML.

=head1 METHODS

=head2 new

Overrided from parent class.

=cut

sub new {
    my ( $class, $messages_ref ) = @_;
    my $self = $class->SUPER::new( [ $messages_ref->[0] ] );
    return $self;
}

=head2 message

Overrided from parent class.

=cut

sub message {
    my $self = shift;
    return $self->{message}->[0];
}

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 of Alceu Rodrigues de Freitas Junior,
E<lt>arfreitas@cpan.orgE<gt>

This file is part of App-SpamcupNG distribution.

App-SpamcupNG is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

App-SpamcupNG is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
App-SpamcupNG. If not, see <http://www.gnu.org/licenses/>.

=cut

1;
