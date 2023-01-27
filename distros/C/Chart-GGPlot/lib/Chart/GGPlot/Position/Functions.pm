package Chart::GGPlot::Position::Functions;

# ABSTRACT: Functions for Chart::GGPlot::Position

use Chart::GGPlot::Setup qw(:base :pdl);

our $VERSION = '0.002002'; # VERSION

use Module::Load;

use Chart::GGPlot::Aes::Functions qw(:all);

use parent qw(Exporter::Tiny);

my @position_types = qw(identity dodge dodge2 stack fill);

our @EXPORT_OK = (map { "position_${_}" } @position_types);

my @export_ggplot = @EXPORT_OK;
our %EXPORT_TAGS = ( all => \@EXPORT_OK, ggplot => \@export_ggplot );

for my $type (@position_types) {
    my $class = 'Chart::GGPlot::Position::' . ucfirst($type);
    load $class;

    no strict 'refs';
    *{"position_${type}"} = sub { $class->new(@_); };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Position::Functions - Functions for Chart::GGPlot::Position

=head1 VERSION

version 0.002002

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
