package App::SpamcupNG::Warning::Factory;
use strict;
use warnings;
use Exporter 'import';

use App::SpamcupNG::Warning;
use App::SpamcupNG::Warning::Yum;

our $VERSION = '0.016'; # VERSION

=head1 NAME

App::SpamcupNG::Warning::Factory - a factory design pattern to create warnings.

=head1 SYNOPSIS

    use App::SpamcupNG::Warning::Factory qw(create_warning);


=head1 DESCRIPTION

This is a factory to create warnings.

It should be used instead of creating new instances manually.

=cut

our @EXPORT_OK = qw(create_warning);

my $yum_regex = qr/^Yum/;

=head1 EXPORTS

Only C<create_warning> is exported by request.

=head1 FUNCTIONS

=head2 create_warning

Creates a new instance of App::SpamcupNG::Warning or one of it's subclasses.

Expects as parameters an array reference with the warning message lines.

Returns the instance.

=cut

sub create_warning {
    my $message_ref = shift;

    die 'message must be an array reference'
        unless ( ( ref($message_ref) eq 'ARRAY' )
        and ( scalar( @{$message_ref} ) > 0 ) );

    return App::SpamcupNG::Warning::Yum->new($message_ref)
        if ( $message_ref->[0] =~ $yum_regex );
    return App::SpamcupNG::Warning->new($message_ref);
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
