package Chart::GGPlot::Guides;

# ABSTRACT: The container of guides

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.0009'; # VERSION

use List::AllUtils qw(uniq);
use Module::Load;

has _guides => (is => 'ro', default => sub { {} });


my $defined_or = sub {
    my ( $obj, $attr, $or ) = @_;

    # Have to make $or a coderef. Too bad Perl 5 does not support macros.
    unless ( defined $obj->{$attr} ) {
        $obj->{$attr} = $or->();
    }
};

# Train each scale in scales and generate the definition of guide.
method build ($scales, :$layers, :$labels, :$default_mapping=undef, %rest) {
    my @gdefs;
    for my $scale ($scales->scales->flatten) {
        for my $output ( $scale->aesthetics->flatten ) {
            my $guide = $self->get_guide($output) // $scale->guide;

            next unless (defined $guide and $guide ne 'none');

            # Check the validity of guide.
            # If guide is a string, then find the guide object.
            $guide = $self->_validate_guide($guide);

            # Check the consistency of the guide and scale.
            my $guide_available_aes = $guide->available_aes;
            if ( defined $guide_available_aes
                and $guide_available_aes->intersect( $scale->aesthetics )
                ->length == 0 )
            {
                die sprintf( "Guide %s cannot be used for %s.",
                    $guide, join( ', ', @{ $scale->aesthetics } ) );
            }

            unless (defined $guide->title) {
                $guide->set( 'title',
                    $scale->make_title( $scale->name // $labels->at($output) )
                );
            }

            $guide = $guide->train($scale, $output);
            next unless defined $guide;

            if (
                List::AllUtils::none {
                    my $matched =
                      $self->_matched_aes( $_, $guide, $default_mapping );
                    my $show_legend = $_->show_legend;
                    ( $matched->length > 0
                          and ( not defined $show_legend or $show_legend ) )
                }
                @$layers
              )
            {
                next;
            }

            if (defined $guide) { 
                push @gdefs, $guide;
            }
        }
    }
    return \@gdefs;
}

method set($key, $guide) { $self->_guides->{$key} = $guide; }
method get_guide($key) { $self->_guides->{$key}; }

method guides() {
    my $guides = $self->_guides;
    return [ map { $guides->{$_} } sort keys %$guides ];
}

classmethod _validate_guide ($guide) {
    if ($guide->$_DOES('Chart::GGPlot::Guide')) {
        return $guide;
    } else {
        my $class_guide = 'Chart::GGPlot::Guide::' . ucfirst($guide);
        load $class_guide;
        return $class_guide->new;
    }
}

classmethod _matched_aes ($layer, $guide, $defaults) {
    my $all = [
        uniq(
            @{ $layer->mapping->names },
            @{
                ( $layer->inherit_aes ? $defaults : $layer->stat->default_aes )
                  ->names
            }
        )
    ];
    my $geom_aes = [ @{ $layer->geom->required_aes },
        @{ $layer->geom->default_aes->names } ];
    my $matched = $all->intersect($geom_aes)->intersect( $guide->key->names );
    return $matched->setdiff(
        [ @{ $layer->geom_params->names }, @{ $layer->aes_params->names } ] );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Guides - The container of guides

=head1 VERSION

version 0.0009

=head1 METHODS

=head2 build

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
