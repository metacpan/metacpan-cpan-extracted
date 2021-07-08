package Chart::GGPlot::Guide::Functions;

# ABSTRACT: Function interface for guides

use Chart::GGPlot::Setup;

our $VERSION = '0.0016'; # VERSION

use Chart::GGPlot::Guide::Legend;

use parent qw(Exporter::Tiny);

our @EXPORT_OK = qw(
  guide_legend 
);
our %EXPORT_TAGS = (
    'all'    => \@EXPORT_OK,
    'ggplot' => [qw(guide_legend)],
);


sub guide_legend {
    return Chart::GGPlot::Guide::Legend->new(@_);   
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Guide::Functions - Function interface for guides

=head1 VERSION

version 0.0016

=head1 FUNCTIONS

=head2 guide_legend

    guide_legend(:$title=undef, %rest)

=head1 SEE ALSO

L<Chart::GGPlot::Guide>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
