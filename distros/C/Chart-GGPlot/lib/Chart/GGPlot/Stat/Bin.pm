package Chart::GGPlot::Stat::Bin;

# ABSTRACT: Statistic method that gets histogram of data

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean -except => 'stat';
use MooseX::Singleton;

our $VERSION = '0.0001'; # VERSION

use PDL::Primitive qw(which);
use POSIX qw(floor);

use Chart::GGPlot::Aes::Functions qw(aes);
use Chart::GGPlot::Bins;
use Chart::GGPlot::Util qw(call_if_coderef seq_n stat);

with qw(
  Chart::GGPlot::Stat
);

has '+default_aes' => (
    default => sub {
        aes(
            y      => q{stat($count)},
            weight => 1,
        );
    }
);

classmethod required_aes () { ['x'] }

classmethod _parameters () {
    [
        qw(
          na_rm
          bins binwidth boundary breaks center pad
          )
    ]
}

method setup_params ($data, $params) {
    if ( $data->exists('y') ) {
        die "stat_count() must not be used with a y aesthetic.";
    }
    if (    !$params->at('breaks')
        and !$params->at('binwidth')
        and !$params->at('bins') )
    {
        $params->set( bins => 30 );
        warn
          "'stat_bin()' using 'bins = 30'. Pick better value with 'binwidth'.";
    }
    return $params;
}

method compute_group ($data, $scales, $params) {
    my ( $binwidth, $bins, $center, $boundary, $breaks, $pad ) =
      map { $params->at($_) }
      qw(
      binwidth bins center boundary breaks pad
    );

    if ( defined $breaks ) {
        my $scale_x = $scales->at('x');
        if ( $scale_x->$_DOES('Chart::GGPlot::Scales::Discrete') ) {
            $breaks = $scale_x->transform->($breaks);
        }
        $bins = Chart::GGPlot::Bins->bin_breaks($breaks);
    }
    elsif ( defined $binwidth ) {
        $binwidth = call_if_coderef( $binwidth, $data->at('x') );
        $bins     = Chart::GGPlot::Bins->bin_breaks_width(
            $scales->at('x')->dimension(),
            $binwidth,
            center   => $center,
            boundary => $boundary
        );
    }
    else {
        $bins = Chart::GGPlot::Bins->bin_breaks_bins(
            $scales->at('x')->dimension(),
            $bins,
            center   => $center,
            boundary => $boundary
        );
    }

    return $bins->bin_vector(
        $data->at('x'),
        ( $data->exists('weight') ? ( weight => $data->at('weight') ) : () ),
        maybe pad => $pad
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Stat::Bin - Statistic method that gets histogram of data

=head1 VERSION

version 0.0001

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
