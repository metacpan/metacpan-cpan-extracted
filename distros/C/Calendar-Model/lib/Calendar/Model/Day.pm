package Calendar::Model::Day;
use strict;

=head1 NAME

Calendar::Model::Day - Simple class modelling Calendar day

=cut

use Data::Dumper;

use DateTime;

use Moose;

=head1 SYNOPSIS

my $cal = Calendar::Model->new(selected_date=>DateTime->new(day=>3, month=>1, year=>2013));

my $day2 = $cal->weeks->[0][2];

$day2->dow_name; # 'Tuesday'

$day2->day_of_week; # 3

$day2->dd; # '01'

$day2->yyyy; # '2013'

$day->to_DateTime; # DateTime object

=head1 ATTRIBUTES

=over 4

=item dmy - date in DD-MM-YYYY format

=item day_of_week - day of week (1 (Monday) to 7)

=item dow_name - day of week name (Monday, etc)

=item dd - day of month

=item mm - Month number ( 0-12 )

=item yyyy - Year (4 digits)

=back

=cut

has 'dmy' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
);


has 'dd' => (
    is  => 'ro',
    isa => 'Int',
    init_arg => undef,
);

has 'mm' => (
    is  => 'ro',
    isa => 'Int',
    init_arg => undef,
);

has 'yyyy' => (
    is  => 'ro',
    isa => 'Int',
    init_arg => undef,
);


has 'day_of_week' => (
    is  => 'ro',
    isa => 'Int',
    required => 1,
);

has 'dow_name' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
);

has 'is_selected_month' => (
    is => 'ro',
    isa => 'Bool',
);

=head1 METHODS

=head2 new

Class constructor method, returns a Calendar::Model::Day object based on the arguments :

=over 4

=item dmy - required a date in DD-MM-YYYY format

=item day_of_week - required day of week (1 to 7)

=back

=head2 BUILD

Std Moose initialisation hook called by constructor method

=cut

sub BUILD {
    my $self = shift;
    my $args = shift;

    # split dmy into dd mm yyyy,
    @{$self}{qw/dd mm yyyy/} = split(/\-/,$self->dmy);

    # check if provided selected month and set flag appropriately

    # do working day check

    # work out ordinal value/format
}

=head2 to_DateTime

Object method, returns a DateTime object built from the days attributes

=cut

sub to_DateTime {
    my $self = shift;
    return DateTime->new(year => $self->yyyy, month => $self->mm, day => $self->dd);
}

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Aaron Trevena.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
