package Chart::GGPlot;

# ABSTRACT: ggplot2 port in Perl

use Chart::GGPlot::Setup qw(:base :pdl);

our $VERSION = '0.0001'; # VERSION

use Data::Munge qw(elem);
use Data::Frame::Types qw(DataFrame);
use Data::Frame::Util qw(guess_and_convert_to_pdl);
use Module::Load;
use Types::PDL qw(Piddle1D);
use Types::Standard qw(Maybe Str);

use Chart::GGPlot::Plot;
use Chart::GGPlot::Aes;
use Chart::GGPlot::Util qw(factor);

use parent qw(Exporter::Tiny);

our @EXPORT_OK = qw(ggplot qplot);

# PodWeaver would move the HTML/markdown block to after FUNCTION.
# So we have to move our DESCRIPTION part to the top and explicitly have
# a "=head1 FUNCTIONS" header, and not use =func directive.


for my $package (
    qw(
    Chart::GGPlot::Aes::Functions
    Chart::GGPlot::Position::Functions
    )
  )
{
    load $package, ':ggplot';
    no strict 'refs';
    push @EXPORT_OK, @{ ${"${package}::EXPORT_TAGS"}{ggplot} };
}
push @EXPORT_OK, qw(factor);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );


sub ggplot {
    return Chart::GGPlot::Plot->new(@_);
}


fun qplot (
    Piddle1D :$x, Piddle1D :$y, 
    :$facets = undef,
    Str :$geom = "auto",
    :$xlim = undef, :$ylim = undef,
    :$title = undef, :$xlab = 'x', :$ylab = 'y',
#    : $asp     = undef,
    %rest
  ) {
    my $log_mode = $rest{log} // '';

    my $all_aesthetics = Chart::GGPlot::Aes->all_aesthetics;

    $x = guess_and_convert_to_pdl($x);
    $y = guess_and_convert_to_pdl($y);

    unless ( $x->length == $y->length ) {
        die "x and y must have same length";
    }

    my $mapping = aes( x => 'x', y => 'y' );
    for my $aes ( grep { elem( $_, $all_aesthetics ) } keys %rest ) {
        $mapping->set( $aes, $aes );
    }

    $log->debug('qplot() $mapping = ' . Dumper($mapping));

    my $data = Data::Frame->new(
        columns => [
            x => guess_and_convert_to_pdl($x),
            y => guess_and_convert_to_pdl($y),

            $mapping->keys->grep( sub { $_ ne 'x' and $_ ne 'y' } )->map(
                sub {
                    my $d = guess_and_convert_to_pdl( $rest{$_} );
                    $_ => $d->repeat_to_length( $x->length );
                }
            )->flatten
        ]
    );

    my $p = ggplot( data => $data, mapping => $mapping );

    if ( not defined $facets ) {
        $p->facet_null();
    }
    else {
        die "'facets' is not yet supported.";
    }

    my $geom_func = $geom eq 'auto' ? 'geom_point' : "geom_${geom}";
    $p->$geom_func();

    if ( $log_mode =~ /x/ ) { $p->scale_x_log10(); }
    if ( $log_mode =~ /y/ ) { $p->scale_y_log10(); }

    $p->ggtitle($title) if ( defined $title );
    $p->xlab($xlab)     if ( defined $xlab );
    $p->ylab($ylab)     if ( defined $ylab );
    $p->xlim($xlim)     if ( defined $xlim );
    $p->ylim($ylim)     if ( defined $ylim );

    return $p;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot - ggplot2 port in Perl

=head1 VERSION

version 0.0001

=head1 STATUS

At this moment this library is experimental and still under active
development (at my after-work time). It's still quite incomplete compared
to R's ggplot2 library, but the core features are working.

Besides, it heavily depends on my L<Alt::Data::Frame::ButMore> library,
which is also experimental.

=head1 SYNOPSIS

    use Chart::GGPlot qw(:all);
    use Data::Frame::Examples qw(mtcars);

    my $plot = ggplot(
        data => mtcars(),
        mapping => aes( x => 'wt', y => 'mpg' )
    )->geom_point();

    # show in browser
    $plot->show;

    # export to image file
    $plot->save('mtcars.png');

    # see "examples" dir of this library's distribution for more examples.

=head1 DESCRIPTION

This Chart-GGPlot library is an implementation of
L<ggplot2|https://en.wikipedia.org/wiki/Ggplot2> in Perl. It's designed to
be possible to support multiple plotting backends. And it ships a default
backend which uses L<Chart::Plotly>.

This Chart::GGPlot module is the function interface of the Perl Chart-GGPlot
library.

Example exported image files:

=for html <p float="left">
<img src="https://raw.githubusercontent.com/stphnlyd/perl5-Chart-GGPlot/master/examples/position_stack_02_02.png" alt="proportional stacked bar" width="45%">
<img src="https://raw.githubusercontent.com/stphnlyd/perl5-Chart-GGPlot/master/examples/geom_line_02_01.png" alt="line chart" width="45%">
<img src="https://raw.githubusercontent.com/stphnlyd/perl5-Chart-GGPlot/master/examples/scale_viridis_02_01.png" alt="viridis color scale" width="45%">
<img src="https://raw.githubusercontent.com/stphnlyd/perl5-Chart-GGPlot/master/examples/theme_01_06.png" alt="theme 'minimal'" width="45%">
</p>

See the C<examples> dir in the library's distribution for more examples.

=head1 FUNCTIONS

=head2 ggplot

    ggplot(:$data, :$mapping, %rest)

This is same as C<Chart::GGPlot::Plot-E<gt>new(...)>.
See L<Chart::GGPlot::Plot> for details.

=head2 qplot

    qplot(Piddle1D :$x, Piddle1D :$y, Str :$geom='auto',
        :$xlim=undef, :$ylim=undef,
        :$log='', :$title=undef, :$xlab='x', :$ylab='y',
        %rest)

=head1 ENVIRONMENT VARIABLES

=head2 CHART_GGPLOT_TRACE

A positive integer would enable debug messages.

=head1 SEE ALSO

L<ggplot2|https://en.wikipedia.org/wiki/Ggplot2>

L<Chart::GGPlot::Plot>

L<Alt::Data::Frame::ButMore>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
