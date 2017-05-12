package Calendar::Model;
use strict;

=head1 NAME

Calendar::Model - Simple class modelling Calendars

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    use Calendar::Model;

    my $cal = Calendar::Model->new();

    my $columns = $cal->columns;

    my $rows = $cal->rows;

    my $dates = $cal->as_list;

    my $start_date = $cal->start_date;

    my $selected_date = $cal->selected_date

    my $month = $cal->month; # 3

    my $year  = $cal->year; # 1992

    my $next_month = $cal->next_month; # 4

    my $prev_month = $cal->previous_month; # 2

    my $month_name = $cal->month_name; # March

    my $next_month_name = $cal->month_name('next'); # April

    my $day = $cal->get_day($dt);

    my $events = $schema->resultset('events')->search( date => { between => [$cal->start_date->dmy,$cal->last_entry_day->dmy] });


=head1 DESCRIPTION

A simple Model layer providing Classes representing A Calendar containing rows and days

=cut

use POSIX qw(locale_h);
use I18N::Langinfo qw(langinfo DAY_1 DAY_2 DAY_3 DAY_4 DAY_5 DAY_6 DAY_7
                      MON_1 MON_2 MON_3 MON_4 MON_5 MON_6
                      MON_7 MON_8 MON_9 MON_10 MON_11 MON_12);
use DateTime;
use DateTime::Duration;
use Calendar::List;

use Calendar::Model::Day;

use Data::Dumper;

use Moose;
with 'MooseX::Role::Pluggable';
use namespace::autoclean;


=head1 ATTRIBUTES

=over 4

=item columns

=item rows

=item month

=item LANG

=item next_month

=item previous_month

=item year

=item next_year

=item previous_year

=item seleted_date

=item days_of_week

=item months_of_year

=back

=cut

has 'columns' => (
    is  => 'ro',
    isa => 'ArrayRef',
    init_arg => undef,
    writer => '_columns'
);

has 'rows'  => (
    is  => 'ro',
    isa => 'ArrayRef',
    init_arg => undef,
    writer => '_rows',
);

has 'month' => (
    is  => 'ro',
    isa => 'Int',
    writer => '_month',
);

has 'LANG' => (
    is => 'ro',
    isa => 'Str',
    default => 'EN-GB',
);

has 'next_month' => (
    is  => 'ro',
    isa => 'Str',
    init_arg => undef,
    writer => '_next_month',
);

has 'previous_month' => (
    is  => 'ro',
    isa => 'Str',
    init_arg => undef,
    writer => '_previous_month',
);

has 'year' => (
    is  => 'ro',
    isa => 'Int',
    writer => '_year',
);

has 'next_year' => (
    is  => 'ro',
    isa => 'Str',
    init_arg => undef,
    writer => '_next_year',
);

has 'previous_year' => (
    is  => 'ro',
    isa => 'Str',
    init_arg => undef,
    writer => '_previous_year',
);

# has 'start_date' => (
#     is  => 'ro',
#     isa => 'DateTime'
# );

has 'selected_date' => (
    is  => 'ro',
    isa => 'DateTime',
    writer => '_selected_date',
);

has 'first_entry_day' => (
    is  => 'ro',
    isa => 'DateTime',
    init_arg => undef,
    writer => '_first_entry_day',
);

has '_last_entry_day' => (
    is  => 'ro',
    isa => 'DateTime',
    init_arg => undef,
    writer => '_set_last_entry_day',
);


has 'days_of_week'  => (
    is  => 'ro',
    isa => 'ArrayRef',
    init_arg => undef,
    writer => '_days_of_week',
);

has 'months_of_year'  => (
    is  => 'ro',
    isa => 'ArrayRef',
    init_arg => undef,
    writer => '_months_of_year',
);


=head1 METHODS

=head2 new

Class constructor method, returns a Calendar::Model object based on the arguments :

=over 4

=item selected_date - optional, defaults to current local/system date, otherwise provide a DateTime object

=item window - optional, defaults to current month + next/previous days to complete calendar rows,
 otherwise provide number of days before selected date to show at start.

=back

=head2 BUILD

Std Moose initialisation hook called by constructor method

=cut

sub BUILD {
    my $self = shift;
    my $args = shift;

    # get selected date, month, year
    my $selected_date = $self->selected_date;
    my $dd;
    if ($self->month && $self->year) {
        $selected_date ||= DateTime->new(year => $self->year, month => $self->month, day => 1);
        $dd = 1 unless ($selected_date->month == $self->month and $selected_date->year == $self->year );
    } else {
        $selected_date ||= DateTime->now();
        $self->_month($selected_date->month);
        $self->_year($selected_date->year);
        $dd = $selected_date->day;
    }
    $self->_selected_date($selected_date) unless ($self->selected_date);

    # get first entry
    my $first_month_day = $selected_date->clone;
    unless ($dd == 1) {
        $first_month_day = DateTime->new(year => $self->year, month => $self->month, day => 1);
    }
    my $first_entry_day = $first_month_day->clone;
    unless ($first_month_day->wday == 7) {
        $first_entry_day->subtract(days => $first_month_day->wday);
    }
    $self->_first_entry_day($first_entry_day);

    # get next/prev month and year
    $self->{previous_month} = ($self->month == 1) ? 12 : $self->month - 1;
    $self->{next_month} = ($self->month == 12) ? 1 : $self->month + 1;
    $self->{previous_year} = ($self->previous_month == 12) ? $self->year - 1 : $self->year;
    $self->{next_year} = ($self->next_month == 1)? $self->year + 1 : $self->year;

    $self->_translate_days_months;

#     my $day_plugins = [];
#     foreach my $plugin ( @{ $self->plugin_list } ) {
#         $plugin->init() if ( $plugin->can( 'init' ));
#     }

    return;
}

=head2 weeks

Object method (lazily) builds and returns rows of Calendar::Model::Day objects, 1 for each week.

=cut

sub weeks {
    my $self = shift;

    unless ($self->rows) {
        # build rows of days
        my $day_plugins = [];
#         foreach my $plugin ( @{ $self->plugin_list } ) {
#             push if ( $plugin->can( 'init' ));
#         }

        my $dow = 1;
        $self->{rows} = [[
            map { Calendar::Model::Day->new({ dmy => $_, dow_name => $self->days_of_week->[$dow], day_of_week => $dow++, }) }
            calendar_list('DD-MM-YYYY',{start => $self->first_entry_day->dmy, "options" => 7})
        ]];
        foreach (1..4) {
            $dow = 1;
            my $last_day = $self->{rows}->[-1][-1];
            my (undef,@days) = calendar_list('DD-MM-YYYY',{start => $last_day->dmy, "options" => 8} );
            push (
                @{$self->{rows}},
                [ map { Calendar::Model::Day->new({ dmy => $_, dow_name => $self->days_of_week->[$dow],
                                                    day_of_week => $dow++, }) } @days ]
            );
        }
    }
    # natatime is iterator accessor for ArrayRef accessor in moose - built in, would be nice to wrap it
    return $self->rows;
}

=head2 as_list

Object method returns all Calendar::Model::Day objects for calendar

=cut

sub as_list {
    my $self = shift;
    return [ map { @$_ } @{$self->weeks} ];
}

=head2 month_name

Object method, returns name of current/selected month or takes a string indicating whether to show 'next' or 'previous' month.

    my $month_name = $cal->month_name; # March

    my $next_month_name = $cal->month_name('next'); # April


=cut

sub month_name {
    my ($self, $delta) = @_;
    my $monthname;
    if ($delta) {
        if ($delta eq 'next') {
            $monthname = $self->months_of_year()->[$self->next_month];
        } elsif ($delta eq 'previous') {
            $monthname = $self->months_of_year()->[$self->previous_month];
        } else {
            die 'unrecognised month delta - needs to be undef, next or previous';
        }
    } else {
        $monthname = $self->months_of_year()->[$self->month];
    }
    return $monthname;
}

=head2 last_entry_day

Get last day in calendar as a DateTime object

=cut

sub last_entry_day {
    my $self = shift;

    my $last_day = $self->weeks->[-1][-1];

    $self->_set_last_entry_day($last_day->to_DateTime);

    return $self->_last_entry_day;
}

=head2 get_day

Get given day from Calendar, takes a DateTime object, returns a Calendar::Modal::Day object

=cut

sub get_day {
    my ($self, $match) = @_;

    # get delta to start date in days
    my $delta = $self->first_entry_day->delta_days( $match );
    my ($w, $d) = $delta->in_units( 'weeks', 'days' );
    # get delta-nth day from appropriate list

    my $last_day = $self->weeks->[$w][$d];
}

###

sub _translate_days_months {
    my $self = shift;

    # query and save the old locale
    my $old_locale = POSIX::setlocale( &POSIX::LC_ALL);

    # set local from obj language
    POSIX::setlocale( &POSIX::LC_ALL,$self->{LANG});
    $self->_days_of_week([ undef, map { langinfo($_) } (DAY_1, DAY_2, DAY_3, DAY_4, DAY_5, DAY_6, DAY_7) ]);
    $self->_months_of_year([ undef, map { langinfo($_) } (MON_1, MON_2, MON_3, MON_4, MON_5, MON_6,
                                                          MON_7, MON_8, MON_9, MON_10, MON_11, MON_12) ]);

    $self->_columns([@{$self->days_of_week}[1,2,3,4,5,6,7]]);

    # restore the old locale
    setlocale(LC_CTYPE, $old_locale);
    return;
}


no Moose;
__PACKAGE__->meta->make_immutable;

=head1 AUTHOR

Aaron Trevena, C<< <teejay at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-calendar-model at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Calendar-Model>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Calendar::Model


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Calendar-Model>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Calendar-Model>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Calendar-Model>

=item * Search CPAN

L<http://search.cpan.org/dist/Calendar-Model/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Aaron Trevena.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
