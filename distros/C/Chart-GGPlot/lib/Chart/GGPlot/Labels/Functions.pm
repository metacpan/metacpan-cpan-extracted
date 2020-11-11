package Chart::GGPlot::Labels::Functions;

# ABSTRACT: Function interface for Chart::GGPlot::Labels

use Chart::GGPlot::Setup;

our $VERSION = '0.0011'; # VERSION

use Chart::GGPlot::Labels;

use parent qw(Exporter::Tiny);

our @EXPORT_OK = qw(
  labs xlab ylab ggtitle
);
our %EXPORT_TAGS = (
    all    => \@EXPORT_OK,
    ggplot => [qw(labs xlab ylab ggtitle)]
);


sub labs {
    return Chart::GGPlot::Labels->new(@_);
}


fun xlab($label) {
    return Chart::GGPlot::Labels->new( x => $label );
}

fun ylab($label) {
    return Chart::GGPlot::Labels->new( y => $label );
}


fun ggtitle( $title, $subtitle = undef ) {
    return Chart::GGPlot::Labels->new(
        title          => $title,
        maybe subtitle => $subtitle,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Labels::Functions - Function interface for Chart::GGPlot::Labels

=head1 VERSION

version 0.0011

=head1 FUNCTIONS

=head2 labs

This is same as C<Chart::GGPlot::Labels-E<gt>new>.

=head2 xlab($label)

This is a shortcut of C<labs(x =E<gt> $label)>.

=head2 ylab($label)

This is a shortcut of C<labs(y =E<gt> $label)>.

=head2 ggtitle($title, $subtitle=undef)

This is a shortcut of
C<labs(title =E<gt> $title, subtitle =E<gt> $subtitle)>.

=head1 SEE ALSO

L<Chart::GGPlot::Labels>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2020 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
