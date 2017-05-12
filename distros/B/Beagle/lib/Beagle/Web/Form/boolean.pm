package Beagle::Web::Form::boolean;

use Any::Moose;
extends 'Beagle::Web::Form::base';

sub render_input {
    my $self    = shift;
    my $name    = $self->name;
    my $out     = qq{<input type="hidden" value="0" name="$name" />};
    if ( $self->default ) {
        $out .=
          qq{<input type="checkbox" value="1" name="$name" checked="checked" />};
    }
    else {
        $out .= qq{<input type="checkbox" value="1" name="$name" />};
    }
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


