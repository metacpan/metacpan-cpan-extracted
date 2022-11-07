# NAME

Compass::Bearing - Convert angle to text bearing (aka heading)

# SYNOPSIS

    use Compass::Bearing;
    my $cb    = Compass::Bearing->new(3);
    my $angle = 12;
    printf "Bearing: %s deg => %s\n", $angle, $cb->bearing($angle); #prints NNE

# DESCRIPTION

Convert angle to text bearing (aka heading)

# CONSTRUCTOR

## new

The new() constructor may be called with any parameter that is appropriate to the set method.

    my $obj = Compass::Bearing->new();

# METHODS

## bearing

Method returns a text string based on bearing

    my $bearing=$obj->bearing($degrees_from_north);

## bearing\_rad

Method returns a text string based on bearing

    my $bearing=$obj->bearing_rad($radians_from_north);

## set

Method sets and returns key for the bearing text data structure.

    my $key = $self->set;
    my $key = $self->set(1);
    my $key = $self->set(2);
    my $key = $self->set(3); #default value

## data

Method returns an array of text values.

    my $data=$self->data;

# BUGS

Please log on GitHub

# AUTHOR

Michael R. Davis

# LICENSE

MIT License

Copyright (c) 2022 Michael R. Davis

# SEE ALSO

[Ham::Resources::Utils](https://metacpan.org/pod/Ham::Resources::Utils) compass method
