package Chart::GGPlot::Range::Functions;

# ABSTRACT: Function interface for range

use Chart::GGPlot::Setup;

our $VERSION = '0.0003'; # VERSION

use Chart::GGPlot::Range::Continuous;
use Chart::GGPlot::Range::Discrete;

use parent qw(Exporter::Tiny);

our @EXPORT_OK = qw(
  continuous_range discrete_range
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );


fun continuous_range () {
    return Chart::GGPlot::Range::Continuous->new();
}


fun discrete_range () {
    return Chart::GGPlot::Range::Discrete->new();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Range::Functions - Function interface for range

=head1 VERSION

version 0.0003

=head1 FUNCTIONS

=head2 continuous_range

=head2 discrete_range

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
