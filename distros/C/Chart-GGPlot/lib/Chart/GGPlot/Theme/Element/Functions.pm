package Chart::GGPlot::Theme::Element::Functions;

# ABSTRACT: 

use Chart::GGPlot::Setup;

our $VERSION = '0.002001'; # VERSION

use Chart::GGPlot::Theme::Element;
use Chart::GGPlot::Theme::Rel;

use parent qw(Exporter::Tiny);

our @EXPORT_OK = qw(
  element_blank element_rect element_line element_text
  rel
);
our %EXPORT_TAGS = (
    all    => \@EXPORT_OK,
    ggplot => [qw(
        element_blank element_rect element_line element_text
        rel)]
);


for my $x (qw(blank rect line text)) {
    my $class = 'Chart::GGPlot::Theme::Element::' . ucfirst($x);

    no strict 'refs';
    *{"element_${x}"} = sub { $class->new(@_); }
}


fun rel($x) {
    return Chart::GGPlot::Theme::Rel->new($x);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Theme::Element::Functions -  

=head1 VERSION

version 0.002001

=head1 FUNCTIONS

=head2 element_blank()

=head2 element_rect(:$fill=undef, :$color=undef, :$size=undef,
:$linetype=undef, :$inherit_blank=false) 

=head2 element_line(:$color=undef, :$linetype=undef, :$lineend=undef,
:$arrow=undef, :$inherit_blank=false)

=head2 element_text(:$family=undef, :$face=undef, :$color=undef,
:$size=undef, :$hjust=undef, :$vjust=undef, :$angle=undef,
:$lineheight=undef, :$margin=undef, :$debug=undef, :$inherit_blank=false)

=head2 rel($x)

Used to specify sizes relative to the parent.

=head1 SEE ALSO

L<Chart::GGPlot::Theme::Element>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2022 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
