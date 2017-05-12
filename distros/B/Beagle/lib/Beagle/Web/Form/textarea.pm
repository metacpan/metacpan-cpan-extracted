package Beagle::Web::Form::textarea;

use Any::Moose;
use Beagle::Util;
extends 'Beagle::Web::Form::base';

sub render_input {
    my $self    = shift;
    my $options = $self->options;
    my $name    = $self->name;
    my $default = defined $self->default ? $self->default : '';
    $default = encode_entities( $default );
    return qq{<textarea>$default</textarea>};
}

1;

__END__

=head1 AUTHOR

sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright 2011 sunnavy@gmail.com

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


