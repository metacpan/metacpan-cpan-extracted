package Boolean::Converter;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Carp qw/croak/;
use List::Util qw/reduce/;
use overload ();

our %DEFAULT_EVALUATE_METHODS = ();
our %DEFAULT_CONVERT_METHODS = (
    'JSON::PP'           => sub { $_[0] ? JSON::PP::true()          : JSON::PP::false()          },
    'JSON::XS'           => sub { $_[0] ? JSON::XS::true()          : JSON::XS::false()          },
    'Types::Serialiser'  => sub { $_[0] ? Types::Serialiser::true() : Types::Serialiser::false() },
    'Data::MessagePack'  => sub { $_[0] ? Data::MessagePack::true() : Data::MessagePack::false() },
    'boolean'            => sub { $_[0] ? boolean::true()           : boolean::false()           },
);

sub new {
    my ($class, %args) = @_;
    return bless {
        evaluator => {
            %DEFAULT_EVALUATE_METHODS,
            %{ $args{evaluator} || +{} },
        },
        converter => {
            %DEFAULT_CONVERT_METHODS,
            %{ $args{converter} || +{} },
        },
    } => $class;
}

sub can_evaluate {
    my ($self, $value) = @_;
    return !!1 unless ref $value;
    return exists $self->{evaluator}->{ref $value}
        || reduce { $a || $b } map {
               overload::Method($value, $_)
           } qw/0+ bool int !/;
}

sub evaluate {
    my ($self, $value) = @_;
    my $converter = $self->{evaluator}->{ref $value};
    return $converter->($value) if $converter;
    return !!$value;
}

sub can_convert_to {
    my ($self, $klass) = @_;
    return exists $self->{converter}->{$klass};
}

sub convert_to {
    my ($self, $value, $klass) = @_;
    my $boolean = $self->evaluate($value);
    my $converter = $self->{converter}->{$klass}
        or croak "Unsupported class: $klass";
    return $converter->($boolean);
}

1;
__END__

=encoding utf-8

=head1 NAME

Boolean::Converter - boolean object converter

=head1 SYNOPSIS

    use Boolean::Converter;

    my $converter = Boolean::Converter->new();

    my $booelan = $converter->convert_to(JSON::PP::true, 'Data::MessagePack');
    # => Data::MessagePack::true

=head1 DESCRIPTION

Boolean::Converter is the super great boolean converter for you.

=head1 METHODS

=head2 Boolean::Converter->new(%args)

Create a new Boolean::Converter object.

=head3 ARGUMENTS

=over 4

=item evaluator

Evaluates methods map for boolean objects.
In default, this module evaluates the object in boolean context.

=item converter

Converts methods map to boolean object from a scalar value.

=back

=head2 my $can_evaluate = $evaluate->can_evaluate($boolean_object)

Checks to evaluate the C<$boolean_object> as a boolean object.

=head2 my $boolean = $evaluate->evaluate($boolean_object)

Evaluates the C<$boolean_object> as a boolean object.

=head2 my $can_convert_to = $convert->can_convert($to_boolean_class)

Checks to convert to the C<$to_boolean_object> from a boolean.

=head2 my $boolean_object = $convert->convert_to($from_boolean_object, $to_boolean_class)

Converts to the C<$to_boolean_object> from C<$from_boolean_object>.

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

