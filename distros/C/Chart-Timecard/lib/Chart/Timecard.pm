package Chart::Timecard;

use strict;
use warnings;
use Object::Tiny qw(times size);

our $VERSION = '0.02';

sub url {
    my $self = shift;

    my @times = @{ $self->times };

    my $xy = {};
    my (@x, @y, @z);

    for my $dt (@times) {
        $xy->{ $dt->hour }{ $dt->wday - 1 }++;
    }

    for my $day (0..6) {
        for my $hour (0..23) {
            my $size = $xy->{$hour}{$day} || 0;
            push @x, $hour;
            push @y, $day;
            push @z, $size;
        }
    }

    local $" = ",";
    my $chart_size = $self->size || "900x300";
    return "http://chart.apis.google.com/chart?cht=s&chs=${chart_size}&chxt=x,y&chxl=0:||0|1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20|21|22|23||1:||Sun|Mon|Tue|Wed|Thu|Fri|Sat|&chm=o,333333,1,1.0,25,0&chds=-1,24,-1,7,0,20&chd=t:@x|@y|@z";
}

1;

__END__

=head1 NAME

Chart::Timecard - Generate a Timecard chart from a time series

=head1 SYNOPSIS

    use Chart::Timecard;

    # $times is an array of DateTime objects
    my $chart = Chart::Timecard->new( times => $times );

    # Get the url of it.
    $chart->url;

=head1 DESCRIPTION

C<Chart::Timecard> is a easy helper to generate timecard chart. See
L<http://dustin.github.com/2009/01/11/timecard.html> and
L<http://github.com/blog/159-one-more-thing> to get the idea of what'a
timecard.

=head1 ATTRIBUTES

These attributes can be passed to the C<new> constructor

=over 4

=item times

An array of L<DateTime> objects.

=item size "WxH"

An string looks like "500x300". Specified the width and height for the
chart. The defalut chart size is 900x300, which is about the largest
possible size google charts.

=back

=head1 METHODS

=over 4

=item new( attr1 => value1, ... )

The object constructor. Optionally takes a list of key-value pairs as the initial values of attributes.
Usually you should just say:

    my $chart = Chart::Timecard->new( times => [...], size => "300x150" );

This should be enough.

=item url()

Return the URL of the chart. Under the hood, it's a Googel Chart
URL. Therefore it is limited by what's offered in the Google Chart
API. See L<http://code.google.com/apis/chart/basics.html> for more
information about Google Chart API.

=back

=head1 SEE ALSO

To understand Google Chart API,
L<http://code.google.com/apis/chart/basics.html>.  The originator of
this kind of chart: L<http://github.com/blog/159-one-more-thing>, and
the tool to generate rate this kind of chart from you git commits,
L<http://dustin.github.com/2009/01/11/timecard.html>.

=head1 AUTHOR

Kang-min Liu E<lt>gugod@gugod.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, 2010, 2011, Kang-min Liu C<< <gugod@gugod.org> >>.

This is free software, licensed under:

    The MIT (X11) License

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
