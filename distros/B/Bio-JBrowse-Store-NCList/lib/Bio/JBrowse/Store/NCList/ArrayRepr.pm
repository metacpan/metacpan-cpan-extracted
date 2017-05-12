package Bio::JBrowse::Store::NCList::ArrayRepr;
BEGIN {
  $Bio::JBrowse::Store::NCList::ArrayRepr::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::JBrowse::Store::NCList::ArrayRepr::VERSION = '0.1';
}
#ABSTRACT: compact array-based serialization of hashrefs

use strict;
use warnings;
use Carp;


sub new {
    my ($class, $classes) = @_;
    $classes ||= [];

    # fields is an array of (map from attribute name to attribute index)
    my @fields;
    for my $attributes ( map $_->{attributes}, @$classes ) {
        my $field_index = 1;
        push @fields, { map { $_ => $field_index++ } @$attributes };
    }

    my $self = {
        fields  => \@fields,
        classes => $classes,
        classes_by_fingerprint => {
            map { join( '-', @{$_->{attributes}} ) => $_ } @$classes
        }
    };

    bless $self, $class;
    return $self;
}

# convert a feature hashref into array representation
sub convert_hashref {
    my ( $self, $hashref ) = @_;
    delete $hashref->{seq_id};
    my $class = $self->getClass( $hashref );
    my $a = [ $class->{index}, map { $hashref->{$_} } @{$class->{attributes}} ];
    if( defined( my $sub_idx = $class->{attr_idx}{subfeatures} ) ) {
        $a->[$sub_idx] = [ map { $self->convert_hashref( $_ ) } @{$a->[$sub_idx]} ];
    }
    return $a;
}

# convert a stream of hashrefs into a stream of arrays
sub convert_hashref_stream {
    my ( $self, $in_stream ) = @_;
    return sub {
        my $f = $in_stream->();
        return unless $f;
        return $self->convert_hashref( $f );
    };
}

my %skip_field = map { $_ => 1 } qw( start end );
sub getClass {
    my ( $self, $feature ) = @_;

    my @attrs = keys %$feature;
    my $attr_fingerprint = join '-', @attrs;

    return $self->{classes_by_fingerprint}{$attr_fingerprint} ||= do {
        my @attributes = ( 'start', 'end', ( grep !$skip_field{$_}, @attrs ) );
        my $i = 0;
        my $class = {
            attributes => \@attributes,
            attr_idx => { map { $_ => ++$i } @attributes },
            # assumes that if a field is an array for one feature, it will be for all of them
            isArrayAttr => { map { $_ => 1 } grep ref($feature->{$_}) eq 'ARRAY', @attrs }
        };
        push @{ $self->{fields} }, $class->{attr_idx};
        push @{ $self->{classes} }, $class;
        $class->{index} = $#{ $self->{classes} };
        $class;
    };
}


sub get {
    my ($self, $obj, $attr) = @_;
    my $fields = $self->{'fields'}->[$obj->[0]];
    if (defined($fields) && defined($fields->{$attr})) {
        return $obj->[$fields->{$attr}];
    } else {
        my $cls = $self->{'classes'}->[$obj->[0]];
        return unless defined($cls);
        my $adhocIndex = $#{$cls->{'attributes'}} + 2;
        if (($adhocIndex > $#{$obj})
            or (not defined($obj->[$adhocIndex]->{$attr})) ) {
            if (defined($cls->{'proto'})
                and (defined($cls->{'proto'}->{$attr})) ) {
                return $cls->{'proto'}->{$attr};
            }
            return undef;
        }
        return $obj->[$adhocIndex]->{$attr};
    }
}

sub fastGet {
    # this method can be used if the attribute is guaranteed to be in
    # the attributes array for the object's class
    my ($self, $obj, $attr) = @_;
    return $obj->[ $self->{fields}->[$obj->[0]]->{$attr} ];
}

sub set {
    my ($self, $obj, $attr, $val) = @_;
    my $fields = $self->{'fields'}->[$obj->[0]];
    if (defined($fields) && defined($fields->{$attr})) {
        $obj->[$fields->{$attr}] = $val;
    } else {
        my $cls = $self->{'classes'}->[$obj->[0]];
        return unless defined($cls);
        my $adhocIndex = $#{$cls->{'attributes'}} + 2;
        if ($adhocIndex > $#{$obj}) {
            $obj->[$adhocIndex] = {}
        }
        $obj->[$adhocIndex]->{$attr} = $val;
    }
}

sub descriptor {
    [ map { { attributes => $_->{attributes}, isArrayAttr => $_->{isArrayAttr} } } @{shift->{classes}} ]
}

sub fastSet {
    # this method can be used if the attribute is guaranteed to be in
    # the attributes array for the object's class
    my ($self, $obj, $attr, $val) = @_;
    $obj->[$self->{'fields'}->[$obj->[0]]->{$attr}] = $val;
}

sub makeSetter {
    my ($self, $attr) = @_;
    return sub {
        my ($obj, $val) = @_;
        $self->set($obj, $attr, $val);
    };
}

sub makeGetter {
    my ($self, $attr) = @_;
    return sub {
        my ($obj) = @_;
        return $self->get($obj, $attr);
    };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Bio::JBrowse::Store::NCList::ArrayRepr - compact array-based serialization of hashrefs

=head1 DESCRIPTION

    The ArrayRepr class is for operating on indexed representations of objects.

    For example, if we have a lot of objects with similar attributes, e.g.:

        [
            {start: 1, end: 2, strand: -1},
            {start: 5, end: 6, strand: 1},
            ...
        ]

    we can represent them more compactly (e.g., in JSON) something like this:

        class = ["start", "end", "strand"]

        [
            [1, 2, -1],
            [5, 6, 1],
            ...
        ]

    If we want to represent a few different kinds of objects in our big list,
    we can have multiple "class" arrays, and tag each object to identify
    which "class" array describes it.

    For example, if we have a lot of instances of a few types of objects,
    like this:

        [
            {start: 1, end: 2, strand: 1, id: 1},
            {start: 5, end: 6, strand: 1, id: 2},
            ...
            {start: 10, end: 20, chunk: 1},
            {start: 30, end: 40, chunk: 2},
            ...
        ]

    We could use the first array position to indicate the "class" for the
    object, like this:

        classes = [["start", "end", "strand", "id"], ["start", "end", "chunk"]]

        [
            [0, 1, 2, 1, 1],
            [0, 5, 6, 1, 2],
            ...
            [1, 10, 20, 1],
            [1, 30, 40, 1]
        ]

    Also, if we occasionally want to add an ad-hoc attribute, we could just
    stick an optional dictionary onto the end:

        classes = [["start", "end", "strand", "id"], ["start", "end", "chunk"]]

        [
            [0, 1, 2, 1, 1],
            [0, 5, 6, 1, 2, {foo: 1}]
        ]

    Given that individual objects are being represented by arrays, generic
    code needs some way to differentiate arrays that are meant to be objects
    from arrays that are actually meant to be arrays.
    So for each class, we include a dict with <attribute name>: true mappings
    for each attribute that is meant to be an array.

    Also, in cases where some attribute values are the same for all objects
    in a particular set, it may be convenient to define a prototype ("proto")
    with default values for all objects in the set

    In the end, we get something like this:

        classes = [
            { "attributes"  : [ "start", "end", "subfeatures" ],
              "proto"       : { "Chrom"       : "chr1"   },
              "isArrayAttr" : { "Subfeatures" : true     }
            }
        ]

    That's what this class facilitates.

=head1 AUTHOR

Robert Buels <rbuels@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Robert Buels.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
