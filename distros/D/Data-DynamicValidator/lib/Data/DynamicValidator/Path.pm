package Data::DynamicValidator::Path;
{
  $Data::DynamicValidator::Path::VERSION = '0.03';
}
# ABSTRACT: Class represents "splitted" to labelled componets path.

use strict;
use warnings;

use Carp;
use Scalar::Util qw/looks_like_number/;

use overload fallback => 1, q/""/ => sub { $_[0]->to_string };

use constant DEBUG => $ENV{DATA_DYNAMICVALIDATOR_DEBUG} || 0;

sub new {
    my ($class, $path) = @_;
    my $self = { };
    bless $self => $class;
    $self->_build_components($path);
    return $self;
}

sub _build_components {
    my ($self, $path) = @_;

    # handle escaped path components
    $_ = $path;
    # substitute all '/'-symbols to "`" and strip
    # surrounding(wraping) ` 
    s[`(.+?)`][my $x=$1;$x=~ tr{/}{`};$x]ge;
    my @elements = split '/';
    for(@elements) {
        tr {`}{/}; # roll back slashes again
    }
    for my $i (0..@elements-1) {
        my @parts = split(':', $elements[$i]);
        if (@parts > 1) {
            $elements[$i] = $parts[1];
            $self->{_labels}->{ $parts[0] } = $i;
        }
    }
    # special name _ for the last route component
    $self->{_labels}->{'_'} = @elements-1;
    $self->{_components} = \@elements;
}

sub components { shift->{_components} }

sub to_string {
    join('/',
         map { /\// ? "`$_`" : $_ }
         @{ shift->{_components} })
}

sub labels {
    my $self = shift;
    my $labels = $self->{_labels};
    sort { $labels->{$a} <=> $labels->{$b} } grep { $_ ne '_' } keys %$labels;
}

sub named_route {
    my ($self, $label) = @_;
    croak("No label '$label' in path '$self'")
        unless exists $self->{_labels}->{$label};
    return $self->_clone_to($self->{_labels}->{$label});
}

sub named_component {
    my ($self, $label) = @_;
    croak("No label '$label' in path '$self'")
        unless exists $self->{_labels}->{$label};
    my $idx = $self->{_labels}->{$label};
    return $self->{_components}->[$idx];
}

sub _clone_to {
    my ($self, $index) = @_;
    my @components;
    for my $i (0 .. $index) {
        push @components, $self->{_components}->[$i]
    }
    while ( my ($name, $idx) = each(%{ $self->{_labels} })) {
        $components[$idx] = join(':', $name, $components[$idx])
            if( $idx <= $index && $name ne '_');
    }
    my $path = join('/', @components);
    return Data::DynamicValidator::Path->new($path);
}


sub value {
    my ($self, $data, $label) = @_;
    $label //= '_';
    croak("No label '$label' in path '$self'")
        if(!exists $self->{_labels}->{$label});
    my $idx = $self->{_labels}->{$label};
    my $value = $data;
    for my $i (1 .. $idx) {
        my $element = $self->{_components}->[$i];
        if (ref($value) && ref($value) eq 'HASH' && exists $value->{$element}) {
            $value = $value->{$element};
            next;
        }
        elsif (ref($value) && ref($value) eq 'ARRAY'
            && looks_like_number($element) && $element < @$value) {
            $value = $value->[$element];
            next;
        }
        croak "I don't know how to get element#$i ($element) at $self";
    }
    if (DEBUG) {
        warn "-- value for $self is "
            . (defined($value)? $value : 'undefined') . "\n"
    }
    return $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::DynamicValidator::Path - Class represents "splitted" to labelled componets path.

=head1 VERSION

version 0.03

=head1 METHODS

=head2 value

Returns data value under named label or (if undefined)
the value under path itself

=head1 AUTHOR

Ivan Baidakou <dmol@gmx.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Ivan Baidakou.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
