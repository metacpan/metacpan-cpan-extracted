package Chart::GGPlot::Global;

# ABSTRACT: Various global variables and settings

use Chart::GGPlot::Class;
use namespace::autoclean;
use MooseX::Singleton;

our $VERSION = '0.002002'; # VERSION

use Module::Load;
use Types::Standard qw(ConsumerOf InstanceOf);


has theme_current => (
    is      => 'rw',
    isa     => ConsumerOf ['Chart::GGPlot::Theme'],
    lazy    => 1,
    builder => '_build_theme_current'
);

method _build_theme_current () {
    load Chart::GGPlot::Theme::Defaults, qw(theme_grey);
    return theme_grey();
}


has element_tree => (
    is      => 'rw',
    isa     => ConsumerOf ['Chart::GGPlot::Theme::ElementTree'],
    lazy    => 1,
    builder => '_build_element_tree',
);

method _build_element_tree () {
    load Chart::GGPlot::Theme::ElementTree;
    return Chart::GGPlot::Theme::ElementTree->default_element_tree();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Global - Various global variables and settings

=head1 VERSION

version 0.002002

=head1 SYNOPSIS

    use Chart::GGPlot::Global;

    my $theme = Chart::GGPlot::Global->theme_current;
    my $ggplot_global = Chart::GGPlot::Global->instance;

=head1 DESCRIPTION

This is a singleton class that holds various global variables and settings
for the Chart::GGPlot system.

=head1 ATTRIBUTES

=head2 theme_current

RW. The current theme.
L<Chart::GGPlot::Theme> object.

=head2 element_tree

RW. Element tree for the theme elements.
L<Chart::GGPlot::Theme::ElementTree> object.

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
