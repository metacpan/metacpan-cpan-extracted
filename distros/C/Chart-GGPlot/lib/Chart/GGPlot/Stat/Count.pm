package Chart::GGPlot::Stat::Count;

# ABSTRACT: Statistic method that counts number of data in bin

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean -except => 'stat';
use MooseX::Singleton;

our $VERSION = '0.0001'; # VERSION

use Data::Frame;

use Chart::GGPlot::Aes::Functions qw(aes);
use Chart::GGPlot::Util qw(resolution stat);

with qw(
  Chart::GGPlot::Stat
);

has '+default_aes'  => (
    default => sub {
        aes(
            y      => q{stat($count)},
            weight => 1,
        );
    }
);

classmethod required_aes() { ['x'] }

method setup_params ($data, $params) {
    if ( $data->exists('y') ) {
        die "stat_count() must not be used with a y aesthetic.";
    }
    return $params;
}

method compute_group ($data, $scales, $params) {
    my $width  = $params->at('width');

    my $x      = $data->at('x');
    my $weight =
        $data->exists('weight')
      ? $data->at('weight')
      : PDL::Core::ones($x->length);
    $width  = $width // pdl(resolution($x) * 0.9);

    # TODO: R does tapply() here. It's somewhat like groupby and then
    #  summarise on #  each group. We can change this once we have
    #  groupby + summarize in our data frame implementations.

    my $uniq = $x->uniq->qsort;
    my $count = pdl(
        $uniq->unpdl->map( sub { $weight->where($x == $_)->sum; } )
    );
    $count->setbadtoval(0);

    return Data::Frame->new(
        columns => [
            count => $count,
            prop  => $count / $count->abs->sum,
            x     => $uniq,
            width => $width,
        ]
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Stat::Count - Statistic method that counts number of data in bin

=head1 VERSION

version 0.0001

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
