package Calendar::Plugin::Renderer;

$Calendar::Plugin::Renderer::VERSION   = '0.16';
$Calendar::Plugin::Renderer::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Calendar::Plugin::Renderer - Role to render calendar.

=head1 VERSION

Version 0.16

=cut

use 5.006;
use Data::Dumper;
use Term::ANSIColor::Markup;

use Calendar::Plugin::Renderer::Text;
use Calendar::Plugin::Renderer::SVG;

use Moo::Role;
use namespace::autoclean;

=head1 DESCRIPTION

Moo Role to render Calendar, currently in  SVG and Text format only. This role is
taken by the following calendars:

=over 4

=item * L<Calendar::Bahai>

=item * L<Calendar::Gregorian>

=item * L<Calendar::Hijri>

=item * L<Calendar::Persian>

=item * L<Calendar::Saka>

=back

=head1 SYNOPSIS

    package Cal;

    use Moo;
    use namespace::autoclean;
    with 'Calendar::Plugin::Renderer';

    package main;

    use strict; use warnings;
    use Cal;

    my $cal = Cal->new;
    print $cal->svg_calendar({
        start_index => 5,
        month_name  => 'January',
        days        => 31,
        year        => 2016 });

    print $cal->text_calendar({
        start_index => 5,
        month_name  => 'January',
        days        => 31,
        year        => 2016 });

=head1 METHODS

=head2 text_calendar(\%params)

Returns the color coded calendar as a scalar string.

Expected paramaeters are as below:

    +-------------+-------------------------------------------------------------+
    | Key         | Description                                                 |
    +-------------+-------------------------------------------------------------+
    | start_index | Index of first day of the month. (0-Sun,1-Mon etc)          |
    | month_name  | Calendar month.                                             |
    | days        | Days count in the month.                                    |
    | year        | Calendar year.                                              |
    | day_names   | Ref to a list of day name starting with Sunday. (Optional)  |
    +-------------+-------------------------------------------------------------+

=cut

sub text_calendar {
    my ($self, $params) = @_;

    unless (exists $params->{day_names}) {
        $params->{day_names} = [qw(Sun Mon Tue Wed Thu Fri Sat)];
    }

    my $text = Calendar::Plugin::Renderer::Text->new($params);

    my $line1 = $text->get_dashed_line;
    my $line2 = $text->get_month_header;
    my $line3 = $text->get_blocked_line;
    my $line4 = $text->get_day_header;
    my $empty = $text->get_empty_space;
    my $dates = $text->get_dates;

    my $calendar = join("\n", $line1, $line2, $line3, $line4, $line3, $empty.$dates)."\n";

    return Term::ANSIColor::Markup->colorize($calendar);
}

=head2 svg_calendar(\%params)

Returns the requested calendar month in SVG format.

Expected paramaeters are as below:

    +---------------+-----------------------------------------------------------+
    | Key           | Description                                               |
    +---------------+-----------------------------------------------------------+
    | start_index   | Index of first day of the month. (0-Sun,1-Mon etc)        |
    | month_name    | Calendar month.                                           |
    | days          | Days count in the month.                                  |
    | year          | Calendar year.                                            |
    | adjust_height | Adjust height of the rows in Calendar. (Optional)         |
    +---------------+-----------------------------------------------------------+

=cut

sub svg_calendar {
    my ($self, $params) = @_;

    my $svg = Calendar::Plugin::Renderer::SVG->new($params);
    $svg->process;

    return $svg->as_string;
}

=head2 validate_params($month, $year)

Validate given  C<$month>  and C<$year> as per the Calendar guidelines. C<$month>
can be "name" or "integer". If C<$month> is passed as "name"  then it converts it
it into its "integer" equivalent. Both parameters are optional. In  case they are
missing, it returns the current month and year of the selected calendar.

=cut

sub validate_params {
    my ($self, $month, $year) = @_;

    if (defined $month && defined $year) {
        $self->date->validate_month($month);
        $self->date->validate_year($year);

        if ($month !~ /^\d+$/) {
            $month = $self->date->get_month_number($month);
        }
    }
    else {
        $month = $self->month;
        $year  = $self->year;
    }

    return ($month, $year);
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Calendar-Plugin-Renderer>

=head1 SEE ALSO

L<SVG::Calendar>

=head1 ACKNOWLEDGEMENT

Inspired by the package L<SVG::Calendar> so that it can be used as a plugin.

=head1 BUGS

Please report any bugs / feature requests to C<bug-calendar-plugin-renderer at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Calendar-Plugin-Renderer>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Calendar::Plugin::Renderer

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Calendar-Plugin-Renderer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Calendar-Plugin-Renderer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Calendar-Plugin-Renderer>

=item * Search CPAN

L<http://search.cpan.org/dist/Calendar-Plugin-Renderer/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 - 2016 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain a  copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Calendar::Plugin::Renderer
