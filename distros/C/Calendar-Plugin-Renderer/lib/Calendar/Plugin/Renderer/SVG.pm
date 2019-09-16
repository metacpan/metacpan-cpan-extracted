package Calendar::Plugin::Renderer::SVG;

$Calendar::Plugin::Renderer::SVG::VERSION   = '0.16';
$Calendar::Plugin::Renderer::SVG::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Calendar::Plugin::Renderer::SVG - Interface to render calendar in SVG format.

=head1 VERSION

Version 0.16

=cut

use 5.006;
use Data::Dumper;

use Calendar::Plugin::Renderer::Util qw(round_number get_max_week_rows);
use Calendar::Plugin::Renderer::SVG::Box;
use Calendar::Plugin::Renderer::SVG::Page;
use Calendar::Plugin::Renderer::SVG::Text;
use Calendar::Plugin::Renderer::SVG::Label;

use SVG;
use Moo;
use namespace::autoclean;

has 'days'          => (is => 'ro', required => 1);
has 'month_name'    => (is => 'ro', required => 1);
has 'year'          => (is => 'ro', required => 1);
has 'start_index'   => (is => 'ro', required => 1);

has 'days_box'      => (is => 'rw');
has 'month_label'   => (is => 'rw');
has 'year_label'    => (is => 'rw');
has 'wdays'         => (is => 'rw');
has 'page'          => (is => 'rw');
has 'boundary_box'  => (is => 'rw');
has 'adjust_height' => (is => 'rw', default => sub { 0 });
has '_row'          => (is => 'rw');

my $HEIGHT                   = 0.5;
my $MARGIN_RATIO             = 0.04;
my $DAY_COLS                 = 8;
my $ROUNDING_FACTOR          = 0.5;
my $TEXT_OFFSET_Y            = 0.1;
my $TEXT_OFFSET_X            = 0.15;
my $TEXT_WIDTH_RATIO         = 0.1;
my $TEXT_HEIGHT_RATIO        = 0.145;
my $HEADING_WIDTH_SCALE      = 0.8;
my $HEADING_HEIGHT_SCALE     = 0.45;
my $HEADING_DOW_WIDTH_SCALE  = 2;
my $HEADING_DOW_HEIGHT_SCALE = 0.4;
my $HEADING_WOY_WIDTH_SCALE  = 4;
my $HEADING_WOY_HEIGHT_SCALE = 0.9;
my $MAX_WEEK_ROW             = 5;

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY>

=cut

sub BUILD {
    my ($self, $params) = @_;

    my $adjust_height = $params->{adjust_height} || 0;
    my $start_index   = $params->{start_index};
    my $year          = $params->{year};
    my $month_name    = $params->{month_name};
    my $days          = $params->{days};

    my ($width,  $width_unit)  = (round_number(210 * 1.0), 'mm');
    my ($height, $height_unit) = (round_number(297 * 1.0), 'mm');

    my $page = Calendar::Plugin::Renderer::SVG::Page->new(
        {
            width       => $width,
            width_unit  => $width_unit,
            height      => $height,
            height_unit => $height_unit,
            x_margin    => round_number($width  * $MARGIN_RATIO),
            y_margin    => round_number($height * $MARGIN_RATIO),
        });

    my $rows = get_max_week_rows($start_index, $days, $MAX_WEEK_ROW) + 1;
    my $t    = round_number(($rows + $ROUNDING_FACTOR) * (0.5 + $HEIGHT));
    my $boundary_box = Calendar::Plugin::Renderer::SVG::Box->new(
        {
            'x'      => $page->x_margin,
            'y'      => round_number(($page->height * (1 - $HEIGHT)) + $page->y_margin),
            'height' => round_number((($page->height * $HEIGHT) - ($page->y_margin * 2)) - $t),
            'width'  => round_number($page->width - ($page->x_margin * 2))
        });

    my $row_height        = round_number($boundary_box->height / ($rows + $ROUNDING_FACTOR) * (0.5 + $HEIGHT));
    my $row_margin_height = round_number($row_height / ($rows * 2));

    my $cols              = $DAY_COLS;
    my $col_width         = round_number($boundary_box->width / ($cols + $ROUNDING_FACTOR));
    my $col_margin_width  = round_number($col_width / ($cols * 2));

    my $month_label = Calendar::Plugin::Renderer::SVG::Label->new(
        {
            'x'     => round_number($boundary_box->x + ($col_margin_width * 2) + 11),
            'y'     => round_number($boundary_box->y - $page->y_margin/2),
            'style' => 'font-size: ' . ($row_height),
        });

    my $year_label = Calendar::Plugin::Renderer::SVG::Label->new(
       {
           'x'     => round_number($boundary_box->x + $boundary_box->width),
           'y'     => round_number($boundary_box->y - $page->y_margin/2),
           'style' => 'text-align: end; text-anchor: end; font-size: ' . $row_height,
       });

    my $count = 1;
    my $wdays = [];
    for my $day (qw/Sun Mon Tue Wed Thu Fri Sat/) {
        my $x = round_number($boundary_box->x + $col_margin_width * (2 * $count + 1) + $col_width * ($count - 1) + $col_width / 2);
        my $y = round_number($boundary_box->y + $row_margin_height);

        my $wday_text = Calendar::Plugin::Renderer::SVG::Text->new(
            {
                'value'     => $day,
                'x'         => round_number($x + $col_width  / $HEADING_DOW_WIDTH_SCALE),
                'y'         => round_number($y + $row_height * $HEADING_DOW_HEIGHT_SCALE),
                'length'    => round_number($col_width * $HEADING_WIDTH_SCALE),
                'adjust'    => 'spacing',
                'font_size' => round_number(($row_height * $HEADING_HEIGHT_SCALE))
            });

        push @$wdays, Calendar::Plugin::Renderer::SVG::Box->new(
            {
                'x'      => $x,
                'y'      => $y,
                'height' => round_number($row_height * $HEIGHT),
                'width'  => $col_width,
                'text'   => $wday_text
            });

        $count++;
    }

    my $days_box = [];
    foreach my $i (2 .. $rows) {
        my $row_y = round_number($boundary_box->y + $row_margin_height * (2 * $i - 1) + $row_height * ($i - 1));
        foreach my $j (2 .. $cols) {
            my $x = round_number(($boundary_box->x + $col_margin_width * (2 * $j - 1) + $col_width * ($j - 1)) - $col_width / 2);
            my $y = round_number($row_y - $row_height / 2);

            my $day_text = Calendar::Plugin::Renderer::SVG::Text->new(
                {
                    'x'         => round_number($x + $col_margin_width * $TEXT_OFFSET_X),
                    'y'         => round_number($y + $row_height * $TEXT_OFFSET_X),
                    'length'    => round_number($col_width * $TEXT_WIDTH_RATIO),
                    'font_size' => round_number((($row_height * $TEXT_HEIGHT_RATIO) + 5)),
                });

            $days_box->[$i - 1][$j - 2] = Calendar::Plugin::Renderer::SVG::Box->new(
                {
                    'x'      => $x,
                    'y'      => $y,
                    'height' => $row_height,
                    'width'  => $col_width,
                    'text'   => $day_text
                });
        }
    }

    $year_label->text($year);
    $month_label->text($month_name);

    $self->{days_box}      = $days_box;
    $self->{month_label}   = $month_label;
    $self->{year_label}    = $year_label;
    $self->{wdays}         = $wdays;
    $self->{page}          = $page;
    $self->{boundary_box}  = $boundary_box;
    $self->{adjust_height} = $adjust_height;
};

sub process {
    my ($self) = @_;

    my $start_index    = $self->start_index;
    my $max_month_days = $self->days;
    my $days_box       = $self->days_box;

    my $row = 1;
    my $i   = 0;
    while ($i < $start_index) {
        $days_box->[$row][$i]->text->value(' ');
        $i++;
    }

    my $d = 1;
    while ($i <= 6) {
        $days_box->[$row][$i]->text->value($d);
        $i++;
        $d++;
    }

    $row++;
    my $k = 0;
    while ($d <= $max_month_days) {
        $days_box->[$row][$k]->text->value($d);
        if ($k == 6) {
            $row++;
            $k = 0;
        }
        else {
            $k++;
        }
        $d++;
    }

    $self->_row($row);
}

sub as_string {
    my ($self) = @_;

    my $p_height = sprintf("%d%s", $self->page->height, $self->page->height_unit);
    my $p_width  = sprintf("%d%s", $self->page->width,  $self->page->width_unit);
    my $view_box = sprintf("0 0 %d %d", $self->page->width, $self->page->height);

    my $svg = SVG->new(
        height   => $p_height,
        width    => $p_width,
        viewBox  => $view_box,
        -svg_version => '1.1',
        -pubid       => '-//W3C//DTD SVG 1.1//EN',
        -sysid       => 'http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd');
    my $calendar = $svg->group(id => 'calendar', label => "Calendar");

    my $month_label = $self->month_label;
    $calendar->text('id'    => "month",
                    'fill'  => 'blue',
                    'x'     => $month_label->x,
                    'y'     => $month_label->y,
                    'style' => $month_label->style)->cdata($month_label->text);

    my $year_label = $self->year_label;
    $calendar->text('id'    => "year",
                    'fill'  => 'blue',
                    'x'     => $year_label->x,
                    'y'     => $year_label->y,
                    'style' => $year_label->style)->cdata($year_label->text);

    my $boundary_box = $self->boundary_box;
    $calendar->rect('id'     => 'bounding_box',
                    'height' => $boundary_box->height - $self->adjust_height,
                    'width'  => $boundary_box->width - 14,
                    'x'      => $boundary_box->x + 7 + 7,
                    'y'      => $boundary_box->y,
                    'style'  => 'fill:none; stroke: blue; stroke-width: 0.5;');

    my $wdays = $self->wdays;
    foreach (0..6) {
        my $day = $calendar->tag('g',
                                 'id'           => "row0_col$_",
                                 'text-anchor'  => 'middle',
                                 'fill'         => 'none',
                                 'stroke'       => 'blue',
                                 'stroke-width' => '0.5');
        next unless defined $wdays->[$_];

        $day->rect('id'     => "box_row0_col$_",
                   'x'      => $wdays->[$_]->x,
                   'y'      => $wdays->[$_]->y,
                   'height' => $wdays->[$_]->height,
                   'width'  => $wdays->[$_]->width);
        $day->text('id'          => "text_row0_col$_",
                   'x'           => $wdays->[$_]->text->x,
                   'y'           => $wdays->[$_]->text->y,
                   'length'      => $wdays->[$_]->text->length,
                   'adjust'      => $wdays->[$_]->text->adjust,
                   'font-size'   => $wdays->[$_]->text->font_size,
                   'text-anchor' => 'middle',
                   'stroke'      => 'red')
            ->cdata($wdays->[$_]->text->value);
    }

    my $row      = $self->_row;
    my $days_box = $self->days_box;
    foreach my $r (1..$row) {
        foreach my $c (0..6) {
            my $g_id = sprintf("row%d_col%d"     , $r, $c);
            my $r_id = sprintf("box_row%d_col%d" , $r, $c);
            my $t_id = sprintf("text_row%d_col%d", $r, $c);
            next unless defined $days_box->[$r]->[$c];

            my $d = $calendar->tag('g',
                                   'id'           => "$g_id",
                                   'fill'         => 'none',
                                   'stroke'       => 'blue',
                                   'stroke-width' => '0.5');
            $d->rect('id'     => "$r_id",
                     'x'      => $days_box->[$r]->[$c]->x,
                     'y'      => $days_box->[$r]->[$c]->y,
                     'height' => $days_box->[$r]->[$c]->height,
                     'width'  => $days_box->[$r]->[$c]->width,
                     'fill'         => 'none',
                     'stroke'       => 'blue',
                     'stroke-width' => '0.5');

            my $text = ' ';
            if (defined $days_box->[$r]->[$c]->text
                && defined $days_box->[$r]->[$c]->text->value) {
                $text = $days_box->[$r]->[$c]->text->value;
            }

            $d->text('id'     => "$t_id",
                     'x'      => $days_box->[$r]->[$c]->text->x + 1,
                     'y'      => $days_box->[$r]->[$c]->text->y + 5,
                     'length' => $days_box->[$r]->[$c]->text->length,
                     'adjust' => 'spacing',
                     'font-size'    => $days_box->[$r]->[$c]->text->font_size,
                     'stroke'       => 'green',
                     'text-anchor'  => 'right',
                     'fill'         => 'silver',
                     'fill-opacity' => '50%')
                ->cdata($text);
        }
    }

    return $svg->to_xml;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Calendar-Plugin-Renderer>

=head1 BUGS

Please report any bugs / feature requests to C<bug-calendar-plugin-renderer at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Calendar-Plugin-Renderer>.
I will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Calendar::Plugin::Renderer::SVG

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

1; # End of Calendar::Plugin::Renderer::SVG
