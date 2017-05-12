package App::Math::Tutor::Role::Roman;

use warnings;
use strict;

=head1 NAME

App::Math::Tutor::Role::Roman - role for roman style natural numbers

=cut

use Moo::Role;
use App::Math::Tutor::Numbers;

with "App::Math::Tutor::Role::Natural";

our $VERSION = '0.005';

around _guess_natural_number => sub {
    my $next    = shift;
    my $max_val = $_[0]->format;
    my $value   = int( rand( $max_val - 1 ) ) + 1;
    RomanNum->new( value => $value );
};

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
