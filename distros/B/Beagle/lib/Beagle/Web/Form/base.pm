package Beagle::Web::Form::base;

use Any::Moose;
use Beagle::Util;

has 'name' => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

has 'label' => (
    isa     => 'Str',
    is      => 'rw',
    default => sub {
        join ' ',
          map { exists $Beagle::Util::ABBREV{ lc $_ } ? uc : ucfirst }
          split /_+/, $_[0]->name;
    },
);

has 'default' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

sub render {
    my $self = shift;
    my $name = $self->name;
    return $self->render_label . $self->render_input;
}

sub render_label {
    my $self  = shift;
    my $label =
        decode_utf8(Beagle::Web->i18n_handle()->maketext($self->label));
    return <<EOF;
<label class="label">$label:</label>
EOF
}

sub render_input {
    my $self    = shift;
    my $name    = $self->name;
    my $default = defined $self->default ? $self->default : '';
    $default = encode_entities( $default );

    return <<EOF;
<input name="$name" value="$default" type="text" />
EOF
}

1;

__END__

=head1 AUTHOR

sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

Copyright 2011 sunnavy@gmail.com

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


