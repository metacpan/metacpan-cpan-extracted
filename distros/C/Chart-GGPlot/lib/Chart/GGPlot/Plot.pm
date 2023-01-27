package Chart::GGPlot::Plot;

# ABSTRACT: ggplot class

use Chart::GGPlot::Class;
use namespace::autoclean;

our $VERSION = '0.002002'; # VERSION

use Autoload::AUTOCAN;
use Data::Frame::Types qw(DataFrame);
use List::AllUtils qw(pairgrep pairmap firstres);
use Module::Load;
use Package::Stash;
use Scalar::Util qw(looks_like_number);
use String::Util qw(trim);
use Types::Standard qw(ArrayRef ConsumerOf HashRef InstanceOf);

use Chart::GGPlot::Aes;
use Chart::GGPlot::Coord::Functions ();
use Chart::GGPlot::Guides;
use Chart::GGPlot::Layout;
use Chart::GGPlot::Params;
use Chart::GGPlot::ScalesList;
use Chart::GGPlot::Types qw(:all);

my @function_namespaces = qw(
  Chart::GGPlot::Geom::Functions
  Chart::GGPlot::Scale::Functions
  Chart::GGPlot::Labels::Functions
  Chart::GGPlot::Limits
  Chart::GGPlot::Coord::Functions
  Chart::GGPlot::Facet::Functions
  Chart::GGPlot::Guide::Functions
  Chart::GGPlot::Theme::Defaults
);

for (@function_namespaces) {
    load $_;
}

method AUTOCAN ($method) {
    state $known_methods;   # mapping method name to coderef
    unless ($known_methods) {
        $known_methods = {
            map {
                my $ns = $_;
                no strict 'refs';
                my @funcs = @{ ${"${ns}::EXPORT_TAGS"}{ggplot} };
                map { $_ => \&{"${ns}::$_"}; } @funcs;
            } @function_namespaces
        };
    }
    my $f = $known_methods->{$method};

    unless ( defined $f ) {

        # For several kinds of methods, fallback to look for them in the
        # caller pacakge.
        if ( $method =~ /^(?:geom|scale)_/ ) {
            my $p = Package::Stash->new( ( caller() )[0] );
            $f = $p->get_symbol("&$method");
        }
    }
    return undef unless ($f);

    state $type_to_method = [
        [ ( ConsumerOf ['Chart::GGPlot::Facet'] ),  'facet' ],
        [ ( ConsumerOf ['Chart::GGPlot::Layer'] ),  'add_layer' ],
        [ ( ConsumerOf ['Chart::GGPlot::Labels'] ), 'add_labels' ],
        [ ( ConsumerOf ['Chart::GGPlot::Coord'] ),  'add_coord' ],
        [ ( ConsumerOf ['Chart::GGPlot::Guide'] ),  'add_guide' ],
        [ ( ConsumerOf ['Chart::GGPlot::Scale'] ),  'add_scale' ],
        [ ( ConsumerOf ['Chart::GGPlot::Theme'] ),  '_set__theme' ],
    ];

    return method(@rest) {
        my $x = $f->(@rest);

        for my $item (@$type_to_method) {
            my ( $type, $add_method ) = @$item;
            if ( $type->check($x) ) {
                $self->$add_method($x);
                return $self;
            }
        }
        die "Unsupported data type: $x got from method $method";
    };
}


my $DEFAULT_BACKEND = 'Plotly';

has backend => (
    is      => 'ro',
    isa     => ConsumerOf ['Chart::GGPlot::Backend'],
    builder => sub {
        my $backend_class = "Chart::GGPlot::Backend::$DEFAULT_BACKEND";
        load $backend_class;
        return $backend_class->new();
    },
);


has data   => (
    is => 'ro', 
    isa => DataFrame,
);


has mapping => (
    is      => 'ro',
    isa     => AesMapping,
    builder => sub { Chart::GGPlot::Aes->new() }
);

has layers => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub { [] },
    traits  => ['Array'],
);
has scales => (
    is      => 'ro',
    default => sub { Chart::GGPlot::ScalesList->new() }
);
has _theme   => ( is => 'rwp', isa => InstanceOf['Chart::GGPlot::Theme'] );
has coordinates => (
    is      => 'rwp',
    isa     => Coord,
    default => sub {
        Chart::GGPlot::Coord::Functions::coord_cartesian( default => true );
    },
);
has facet => (
    is      => 'rw',
    isa     => Facet,
    default => sub { Chart::GGPlot::Facet::Functions::facet_null() },
);

has _labels => (
    is      => 'rw',
    default => sub { Chart::GGPlot::Params->new(); },
);

has guides => ( is => 'ro', default => sub { Chart::GGPlot::Guides->new() } );

with qw(MooseX::Clone);

method labels () {
    return $self->make_labels( $self->mapping )
      ->merge( $self->_labels->as_hashref );
}


method show (HashRef $opts={}) {
    $self->backend->show( $self, $opts );
}

method save ($filename, HashRef $opts={}) {
    $self->backend->save( $self, $filename, $opts );
}

method iplot (HashRef $opts={}) {
    $self->backend->iplot( $self, $opts );
}


method summary () {
    my $s     = '';
    my $label = fun($l) { sprintf( "%-9s", $l ); };

    #TODO: use Text::Wrap for better format
    if ( $self->data ) {
        $s .=
            &$label("data:")
          . join(", ", @{$self->data->names})
          . sprintf( " [%sx%s] ", $self->data->nrow, $self->data->ncol ) . "\n";
    }
    if ( $self->mapping->length > 0 ) {
        $s .= &$label("mapping:") . $self->mapping->string . "\n";
    }
    if ( $self->scales->length() > 0 ) {
        $s .=
          &$label("scales:") . join( ", ", @{ $self->scales->input } ) . "\n";
    }
    $s .= &$label("faceting: ") . $self->facet . "\n";
    $s .= "-----------------------------------";
    return $s;
}


method theme() {
    use Chart::GGPlot::Global;

    my $default = Chart::GGPlot::Global->theme_current();
    if (my $theme = $self->_theme) {
        if ($theme->is_complete) {
            return $theme;
        }
        else {
            return $theme->defaults($default);
        }
    } else {
        return $default;
    }
}



method add_layer ($layer) {
    push @{ $self->layers }, $layer;

    # Add any new labels
    my $mapping = $self->make_labels($layer->mapping);
    my $defaults = $self->make_labels($layer->stat->default_aes);
    map { $mapping->{$_} //= $defaults->{$_} } keys %$defaults;
    $self->add_labels($mapping);

    return $self;
}


method add_labels ($labels) {
    $self->_labels( $self->_labels->merge($labels) );
    return $self;
}


method add_scale ($scale) {
    $self->scales->add($scale);
    return $self;
}


method add_coord($coord) {
    $self->_set_coordinates($coord);
    return $self;
}

classmethod make_labels($mapping) {
    state $strip = sub {    # strip_dots() in R ggplot2
        my ($aesthetic, $expr) = @_; 
        unless ($expr->$_DOES('Eval::Quosure')) {
            return $expr;
        }   

        $expr = $expr->expr;

        # TODO: Need PPR here.
        if (looks_like_number($expr)) {
            return $aesthetic;
        }
        elsif ($expr =~ /^\s*stat\s*\((.*)\)/) {
            return trim($1);
        }
        return $expr;
    };  

    my %labels = pairmap { $a => $strip->($a, $b) } $mapping->flatten;
    return \%labels;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Plot - ggplot class

=head1 VERSION

version 0.002002

=head1 DESCRIPTION

This class represents the ggplot plot class.
Instead of this class you would usually want to directly use L<Chart::GGPlot>,
which is a function interface of this library and is closer to R ggplot2's
API.

=head1 ATTRIBUTES

=head2 backend

Consumer of L<Chart::GGPlot::Backend>.
Default is a L<Chart::GGPlot::Backend::Plotly> object.

=head2 data

L<Data::Frame> object.

=head2 mapping

Aesthetics mapping.
Default is an empty L<Chart::GGPlot::Aes> object.

=head1 METHODS

=head2 show

    show(HashRef $opts={})

Show the plot (like in web browser).
Implementation depends on the plotting backend.

=head2 save

    save($filename, HashRef $opts={})

Export the plot to a static image file.
Implementation depends on the plotting backend.

=head2 iplot

    iplot(HashRef $opts={})

Generate plot for L<IPerl> in Jupyter notebook.
Implementation depends on the plotting backend.

=head2 summary

    summary()

Get a useful description of a ggplot object.

=head2 theme

    theme()

Returns theme of the plot.

=head2 add_layer

    add_layer($layer)

Adds a L<Chart::GGPlot::Layer> object to the plot.

You normally don't have to explicitly call this method.

=head2 add_labels

    add_labels($labels)

Adds a L<Chart::GGPlot::Label> object to the plot.

You normally don't have to explicitly call this method.

=head2 add_scale

    add_scale($scale)

You normally don't have to explicitly call this method.

=head2 add_coord

    add_coord($coord)

You normally don't have to explicitly call this method.

=head1 MORE METHODS

This class uses Perl's autoloading feature, to allow this class to get
into its member methods exported functions of C<:ggplot> tag from several
other namespaces:

=over 4

=item *

L<Chart::GGPlot::Geom::Functions>

=item *

L<Chart::GGPlot::Scale::Functions>

=item *

L<Chart::GGPlot::Labels::Functions>

=item *

L<Chart::GGPlot::Limits>

=item *

L<Chart::GGPlot::Coord::Functions>

=item *

L<Chart::GGPlot::Facet::Functions>

=item *

L<Chart::GGPlot::Guide::Functions>

=item *

L<Chart::GGPlot::Theme::Defaults>

=back

For example, when you do

   $plot->geom_point(...)

It internally does something like,

   my $layer = Chart::GGPlot::Geom::Functions::geom_point(...);
   $plot->add_layer($layer);

Depend on the return type of the function it would call one of the class's
add/set methods. In this case of C<geom_point()> we get a layer object so
C<add_layer()> is called.

=head1 SEE ALSO

L<Chart::GGPlot>

L<Chart::GGPlot::Backend>, L<Chart::GGPlot::Backend::Plotly>

L<Devel::IPerl>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
