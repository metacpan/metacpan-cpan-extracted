package Chart::GGPlot::Stat::Smooth;

# ABSTRACT: Statistic method that does smoothing

use Chart::GGPlot::Class;
use namespace::autoclean;
use MooseX::Singleton;

our $VERSION = '0.0001'; # VERSION

with qw(
  Chart::GGPlot::Stat
);

method setup_params($data, $params) {
    if ($params->{method} eq 'auto') {
        my $max_group = 

        if ($max_group < 1000) {
            $params->{method} = 'loess';
        } else {
            $params->{method} = 'gam';
        }

    } elsif ($params->{method} eq 'gam') {
        die "Not implemented";
    }
    return $params;
}

method compute_group($data, $scales, $params) {

}


method compute_layer( $data, $params, $layout ) {
    return $data;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Stat::Smooth - Statistic method that does smoothing

=head1 VERSION

version 0.0001

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
