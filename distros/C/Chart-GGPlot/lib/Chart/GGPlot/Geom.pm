package Chart::GGPlot::Geom;

# ABSTRACT: The geom role

use Chart::GGPlot::Role qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.0016'; # VERSION

use Data::Frame::Util qw(guess_and_convert_to_pdl);
use Types::Standard qw(ArrayRef CodeRef);

use Chart::GGPlot::Aes;
use Chart::GGPlot::Util qw(:all);

with qw(
  Chart::GGPlot::HasRequiredAes
  Chart::GGPlot::HasDefaultAes
  Chart::GGPlot::HasNonMissingAes
  Chart::GGPlot::HasParams
  Chart::GGPlot::HasCollectibleFunctions
);

classmethod optional_aes() { [] }

method setup_data ($data, $params) { $data }

# Renders a single legend key.
sub draw_key { return draw_key_point(@_) }

method handle_na ( $data, $params ) {
    return remove_missing(
        $data,
        na_rm => $params->at('na_rm'),
        vars  => [ @{ $self->required_aes }, @{ $self->non_missing_aes } ],
        name  => $self->name
    );
}

# Combine data with defaults and set aesthetics from parameters
method use_defaults ( $data, $params = {} ) {
    if ( $data->isempty ) {

        # create $data from $self->default_aes
        #$data = $self->default_aes->get();
    }
    else {
        # Fill in missing aesthetics with their defaults
        my $missing_aes = $self->default_aes->names->setdiff( $data->names );

        for my $name ( sort @$missing_aes ) {
            my $default = $self->default_aes->at($name);
            next unless defined $default;
            $data->set( $name, $default );
        }
    }

    # Override mappings with params
    my $aes_names = $self->aesthetics->intersect( $params->keys );
    my $aes_params = $params->hslice($aes_names);
    for my $aes (@$aes_names) {
        my $val = $aes_params->at($aes);
        unless ($val->$_DOES('PDL')) {
            $val = guess_and_convert_to_pdl($val); 
            $aes_params->set($aes, $val);
        }
    }
    Chart::GGPlot::Aes->check_aesthetics( $aes_params, $data->nrow );
    for my $aes (@$aes_names) {
        $data->set($aes, $aes_params->at($aes));
    }
    return $data;
}

method aesthetics () {
    return [
        (
            $self->required_aes->union( $self->default_aes->keys )->flatten,
            $self->optional_aes->flatten, "group"
        )
    ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Geom - The geom role

=head1 VERSION

version 0.0016

=head1 DESCRIPTION

This module is a Moose role for "geom".

For users of Chart::GGPlot you would mostly want to look at
L<Chart::GGPlot::Geom::Functions> instead.

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
