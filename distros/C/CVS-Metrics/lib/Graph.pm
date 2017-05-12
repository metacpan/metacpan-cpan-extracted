package CVS::Metrics;

use strict;
use warnings;

our $VERSION = '0.18';

use GD;
use CVS::Metrics::TaggedChart;

sub EnergyGD {
    my $cvs_log = shift;
    my ($tags, $path, $title, $width, $height, $tag_from, $tag_to) = @_;

    my $data = $cvs_log->_Energy($tags, $path);
    my $img = CVS::Metrics::TaggedChart->new($width, $height);
    if (defined $tag_from and defined $tag_to) {
        my @tags2 = @{$tags};
        my @data_pre;
        my @tags_pre;
        while ($tags2[0] ne $tag_from) {
            push @tags_pre, shift @tags2;
            push @data_pre, shift @{$data};
            push @data_pre, shift @{$data};
        }
        if (scalar @tags_pre) {
            push @tags_pre, $tags2[0];
            push @data_pre, ${$data}[0], ${$data}[1];
            $img->setData(\@data_pre, 'blue up');
            $img->setTag(\@tags_pre);
        }
        unless ($tag_to eq 'HEAD') {
            my @data_post;
            my @tags_post;
            if ($tags2[-1] eq 'HEAD') {
                unshift @tags_post, pop @tags2;
                unshift @data_post, pop @{$data};
                unshift @data_post, pop @{$data};
            }
            while ($tags2[-1] ne $tag_to) {
                unshift @tags_post, pop @tags2;
                unshift @data_post, pop @{$data};
                unshift @data_post, pop @{$data};
            }
            if (scalar @tags_post) {
                unshift @tags_post, $tags2[-1];
                unshift @data_post, ${$data}[-2], ${$data}[-1];
                $img->setData(\@data_post, 'blue up');
                $img->setTag(\@tags_post);
            }
        }
        $img->setData($data, 'red up');
        $img->setTag(\@tags2);
    }
    else {
        $img->setData($data, 'blue up');
        $img->setTag($tags);
    }
    $img->setGraphOptions(
            title           => $title,
            horAxisLabel    => 'delta (added or modified files)',
            vertAxisLabel   => 'size (nb files)',
    );
    $img->draw();
    my $gd = $img->getGDobject();
    $gd->transparent(-1);
    return $gd;
}

sub EnergyCv {
    my $cvs_log = shift;
    my ($tags, $path, $title, $width, $height, $toplevel) = @_;

    my $data = $cvs_log->_Energy($tags, $path);
    my $img = CVS::Metrics::TaggedChart->new($width, $height);
    $img->setData($data, 'blue up');
    $img->setTag($tags);
    $img->setGraphOptions(
            title           => $title,
            horAxisLabel    => 'delta (added or modified files)',
            vertAxisLabel   => 'size (nb files)',
    );
    return $img->canvas($toplevel);
}

sub ActivityGD {
    my $cvs_log = shift;
    my ($path, $title, $start_date, $width, $height, $date_from, $date_to) = @_;

    use GD::Graph::bars;
    use GD::Graph::mixed;

    my ($days, $data) = $cvs_log->_Activity($path, $start_date);

    my $sum = 0;
    my $nb = 0;
    foreach (@{$data}) {
        next unless ($_);
        $sum += $_;
        $nb ++;
    }
    my $average = 1;
    $average = $sum / $nb if ($sum and $nb);

    my $range_day = 30;
    while ((scalar(@{$days}) % $range_day) != 1) {
        unshift @{$days}, ${$days}[0] - 1;
        unshift @{$data}, 0;
    }

    my @days2;
    foreach (@{$days}) {
        push @days2, $_ - ${$days}[-1];
    }

    $width = 200 - ${$days}[0] if ($width < 200 - ${$days}[0]);

    if (defined $date_from and defined $date_to) {
        my $now = int(time() / 86400);
        my $day_from = _get_day($date_from) || 0;
        my $day_to = _get_day($date_to) || 0;
        my @data1;
        my @data2;
        my $i = 0;
        foreach (reverse @{$data}) {
            if (        $i <= ($now - $day_from)
                    and $i >= ($now - $day_to) ) {
                unshift @data1, $_;
                unshift @data2, undef;
            }
            else {
                unshift @data1, undef;
                unshift @data2, $_;
            }
            $i ++;
        }
        my $graph = GD::Graph::mixed->new($width, $height);
        $graph->set(
                '3d'            => 0,
                x_label         => 'days',
                y_label         => 'nb commits',
                x_label_skip    => $range_day,
                title           => $title,
                y_max_value     => 5 ** int(1 + 1.2 * log($average) / log(5)),
                dclrs           => [qw(lred lblue)],
                types           => [ 'bars', 'bars' ],
        );
        return $graph->plot( [\@days2, \@data1, \@data2] );
    }
    else {
        my $graph = GD::Graph::bars->new($width, $height);
        $graph->set(
                '3d'            => 0,
                x_label         => 'days',
                y_label         => 'nb commits',
                x_label_skip    => $range_day,
                title           => $title,
                y_max_value     => 5 ** int(1 + 1.2 * log($average) / log(5)),
        );
        return $graph->plot( [\@days2, $data] );
    }
}

1;

