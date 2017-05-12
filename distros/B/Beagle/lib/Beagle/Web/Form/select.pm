package Beagle::Web::Form::select;

use Any::Moose;
use Beagle::Util;
extends 'Beagle::Web::Form::base';

has 'options' => (
    isa     => 'ArrayRef',
    is      => 'ro',
    default => sub { [] },
);

sub render_input {
    my $self    = shift;
    my $options = $self->options;
    my $name    = $self->name;
    my $out     = qq{<select name="$name">};
    my $default = encode_entities( $self->default );
    for my $option (@$options) {
        my $label = encode_entities( $option->{label} );
        my $value = encode_entities( $option->{value} );
        if ( $value && $default && $value eq $default ) {
            $out .=
              qq{<option selected="selected" value="$value">$label</option>};
        }
        else {
            $out .= qq{<option value="$value">$label</option>};
        }
    }
    $out .= '</select>';
    return $out;
}

1;

__END__

=head1 AUTHOR

sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright 2011 sunnavy@gmail.com

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


