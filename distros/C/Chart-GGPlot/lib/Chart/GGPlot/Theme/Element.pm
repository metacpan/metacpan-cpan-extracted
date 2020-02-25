package Chart::GGPlot::Theme::Element;

# ABSTRACT: Basic types for theme elements

use strict;
use warnings;

our $VERSION = '0.0009'; # VERSION

package Chart::GGPlot::Theme::Element {
    use Chart::GGPlot::Setup;
    use Function::Parameters qw(classmethod);
    use namespace::autoclean;

    use parent qw(Chart::GGPlot::Params);

    sub transform_key {
        my ( $class, $key ) = @_;
        return 'color' if $key eq 'colour';
        return $key;
    }

    sub parameters { [] } 

    sub is_blank { false }

    method string () {
        return Dumper($self);
    }

}

package Chart::GGPlot::Theme::Element::Blank {
    use Chart::GGPlot::Setup;
    use Function::Parameters qw(classmethod);
    use namespace::autoclean;

    use parent qw(Chart::GGPlot::Theme::Element);

    classmethod parameters () { [] }

    sub is_blank { true }
}

package Chart::GGPlot::Theme::Element::Line {
    use Chart::GGPlot::Setup;
    use Function::Parameters qw(classmethod);
    use Class::Method::Modifiers;
    use namespace::autoclean;

    use parent qw(Chart::GGPlot::Theme::Element);

    use Types::Standard;

    around parameters => sub {
        my $orig  = shift;
        my $class = shift;
        return [
            qw(color size linetype lineend inherit_blank),
            @{ $class->$orig() }
        ];
    };
}

package Chart::GGPlot::Theme::Element::Rect {
    use Chart::GGPlot::Setup;
    use Function::Parameters qw(classmethod);
    use Class::Method::Modifiers;
    use namespace::autoclean;

    use parent qw(Chart::GGPlot::Theme::Element);

    use Types::Standard;

    use Chart::GGPlot::Util qw(pt);

    around parameters => sub {
        my $orig  = shift;
        my $class = shift;
        return [ qw(fill color size linetype inherit_blank),
            @{ $class->$orig() } ];
    }
}

package Chart::GGPlot::Theme::Element::Text {

    use Chart::GGPlot::Setup;
    use Function::Parameters qw(classmethod);
    use Class::Method::Modifiers;
    use namespace::autoclean;

    our $VERSION = '0.0009'; # VERSION

    use parent qw(Chart::GGPlot::Theme::Element);

    around parameters => sub {
        my $orig  = shift;
        my $class = shift;
        return [
            qw(
              family face color size hjust vjust
              angle lineheight inherit_blank
              ),
            @{ $class->$orig() }
        ];
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Theme::Element - Basic types for theme elements

=head1 VERSION

version 0.0009

=head1 SEE ALSO

L<Chart::GGPlot::Theme::Element>

1;

__END__

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
