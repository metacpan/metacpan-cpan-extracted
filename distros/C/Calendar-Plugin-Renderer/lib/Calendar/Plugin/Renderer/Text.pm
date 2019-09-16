package Calendar::Plugin::Renderer::Text;

$Calendar::Plugin::Renderer::Text::VERSION   = '0.16';
$Calendar::Plugin::Renderer::Text::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Calendar::Plugin::Renderer::Text - Interface to render calendar in text format.

=head1 VERSION

Version 0.16

=cut

use 5.006;
use Data::Dumper;

use Moo;
use namespace::autoclean;

has 'start_index' => (is => 'ro', required => 1);
has 'month_name'  => (is => 'ro', required => 1);
has 'days'        => (is => 'ro', required => 1);
has 'year'        => (is => 'ro', required => 1);
has 'day_names'   => (is => 'ro', required => 1);

has 'max_days_name' => (is => 'rw');
has 'line_size'     => (is => 'rw');
has 'f'             => (is => 'rw');
has 's'             => (is => 'rw');
has 'month_head'    => (is => 'rw');

=head1 DESCRIPTION

Interface to render calendar in text format.

=head1 CONSTRUCTOR

It expects one parameter as a hash ref with keys mentioned in the below table.

    +-------------+-------------------------------------------------------------+
    | Key         | Description                                                 |
    +-------------+-------------------------------------------------------------+
    | start_index | Index (0-6) for the first day of the month, 0 for Sunday.   |
    | month_name  | Name of the given month.                                    |
    | days        | Total days count for the given month.                       |
    | year        | Given year.                                                 |
    | day_names   | Ref to a list of day name starting with Sunday.             |
    +-------------+-------------------------------------------------------------+

=cut

sub BUILD {
    my ($self) = @_;

    my $day_names  = $self->day_names;
    my $month_name = $self->month_name;
    my $year       = $self->year;

    my $max_days_name = 0;
    foreach my $day_name (@$day_names) {
        if ($max_days_name < length($day_name)) {
            $max_days_name = length($day_name);
        }
    }

    my $line_size  = (7 * ($max_days_name + 2)) + 8;
    my $month_head = sprintf("%s [%d BE]", $month_name, $year);
    my $h = int($line_size/2);
    my $m = int(length($month_head)/2);
    my $f = $h - $m;
    my $s = $line_size - ($f + length($month_head));

    $self->max_days_name($max_days_name);
    $self->line_size($line_size);
    $self->month_head($month_head);
    $self->f($f);
    $self->s($s);
}

=head1 METHODS

=head2 get_day_header()

=cut

sub get_day_header   {
    my ($self) = @_;

    my $max_length_day_name = $self->max_days_name;
    my $day_names = $self->day_names;
    my $line = '<blue><bold>|</bold></blue>';
    my $i = 1;
    foreach (@$day_names) {
        my $x = length($_);
        my $y = $max_length_day_name - $x;
        my $z = $y + 1;
        if ($i == 1) {
            $line .= ((' ')x$z). "<yellow><bold>$_</bold></yellow>";
            $i++;
        }
        else {
            $line .= " <blue><bold>|</bold></blue>".((' ')x$z)."<yellow><bold>$_</bold></yellow>";
        }

    }
    $line .= " <blue><bold>|</bold></blue>";

    return $line;
}

=head2 get_month_header()

=cut

sub get_month_header {
    my ($self) = @_;

    my $f = $self->f;
    my $s = $self->s;
    my $h = $self->month_head;

    return '<blue><bold>|</bold></blue>'.
           (' ')x($f-1).
           '<yellow><bold>'.
           $h.
           '</bold></yellow>'.
           (' ')x($s-1).
           '<blue><bold>|</bold></blue>';
}

=head2 get_dashed_line()

=cut

sub get_dashed_line  {
    my ($self) = @_;

    my $line_size = $self->line_size;
    return '<blue><bold>+'.('-')x($line_size-2).'+</bold></blue>';
}

=head2 get_blocked_line()

=cut

sub get_blocked_line {
    my ($self) = @_;

    my $max_length_day_name = $self->max_days_name;
    my $line = '<blue><bold>+';
    foreach (1..7) {
        $line .= ('-')x($max_length_day_name+2).'+';
    }

    $line .= '</bold></blue>';

    return $line;
}

=head2 get_empty_space()

=cut

sub get_empty_space {
    my ($self) = @_;

    my $max_length_day_name = $self->max_days_name;
    my $start_index = $self->start_index;
    my $line = '';
    if ($start_index % 7 != 0) {
        $line .= '<blue><bold>|</bold></blue>'.(' ')x($max_length_day_name+2);
        map { $line .= ' 'x($max_length_day_name+3) } (2..($start_index %= 7));
    }

    return $line;
}

=head2 get_dates()

=cut

sub get_dates {
    my ($self) = @_;

    my $max_length_day_name = $self->max_days_name;
    my $start_index = $self->start_index;
    my $days        = $self->days;
    my $line = '';
    my $blocked_line = $self->get_blocked_line;
    foreach (1 .. $days) {
        $line .= sprintf("<blue><bold>|</bold></blue><cyan><bold>%".($max_length_day_name+1)."s </bold></cyan>", $_);
        if ($_ != $days) {
            $line .= "<blue><bold>|</bold></blue>\n".$blocked_line."\n" unless (($start_index + $_) % 7);
        }
        elsif ($_ == $days) {
            my $x = 7 - (($start_index + $_) % 7);
            if (($x >= 2) && ($x != 7)) {
                $line .= '<blue><bold>|</bold></blue>'. (' 'x($max_length_day_name+2));
                map { $line .= ' 'x($max_length_day_name+3) } (1..$x-1);
            }
            elsif ($x != 7) {
                $line .= '<blue><bold>|</bold></blue>'.' 'x($max_length_day_name+2);
            }
        }
    }

    return sprintf("%s<blue><bold>|</bold></blue>\n%s\n", $line, $blocked_line);
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

    perldoc Calendar::Plugin::Renderer::Text

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

1; # End of Calendar::Plugin::Renderer::Text
