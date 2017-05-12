package Data::Focus::Lens::HashArray::Index;
use strict;
use warnings;
use parent qw(Data::Focus::Lens);
use Data::Focus::LensMaker ();
use Scalar::Util qw(reftype);
use Carp;

our @CARP_NOT = qw(Data::Focus::Lens Data::Focus);

sub new {
    my ($class, %args) = @_;
    my $indices = [];
    if(exists($args{index})) {
        if(ref($args{index}) eq "ARRAY") {
            $indices = $args{index};
        }else {
            $indices = [$args{index}];
        }
    }
    croak "index must be mandatory" if !@$indices;
    croak "index must be defined" if grep { !defined($_) } @$indices;
    my $self = bless {
        indices => $indices,
        immutable => $args{immutable},
        allow_blessed => $args{allow_blessed},
    }, $class;
    return $self;
}

sub _type_of {
    my ($self, $target) = @_;
    if($self->{allow_blessed}) {
        my $ref = reftype($target);
        return defined($ref) ? $ref : "";
    }else {
        return ref($target);
    }
}

sub _getter {
    my ($self, $whole) = @_;
    my $type = $self->_type_of($whole);
    if(!defined($whole)) {
        ## slots for autovivification
        return map { undef } @{$self->{indices}};
    }elsif($type eq "ARRAY") {
        my @indices = map { int($_) } @{$self->{indices}};
        return @{$whole}[@indices];
    }elsif($type eq "HASH") {
        return @{$whole}{@{$self->{indices}}};
    }else {
        ## no slot. cannot set.
        return ();
    }
}
    
sub _setter {
    my ($self, $whole, @parts) = @_;
    return $whole if !@parts;
    if(!defined($whole)) {
        ## autovivifying
        if(grep { $_ !~ /^\d+$/ } @{$self->{indices}}) {
            return +{ map { $self->{indices}[$_] => $parts[$_] } 0 .. $#{$self->{indices}} };
        }else {
            my $ret = [];
            $ret->[$self->{indices}[$_]] = $parts[$_] foreach 0 .. $#{$self->{indices}};
            return $ret;
        }
    }
    my $type = $self->_type_of($whole);
    if($type eq "ARRAY") {
        my @indices = map { int($_) } @{$self->{indices}};
        my $ret = $self->{immutable} ? [@$whole] : $whole;
        foreach my $i (0 .. $#indices) {
            my $index = $indices[$i];
            croak "$index: negative out-of-range index" if $index < -(@$ret);
            $ret->[$index] = $parts[$i];
        }
        return $ret;
    }elsif($type eq "HASH") {
        my $ret = $self->{immutable} ? {%$whole} : $whole;
        $ret->{$self->{indices}[$_]} = $parts[$_] foreach 0 .. $#{$self->{indices}};
        return $ret;
    }else {
        confess "This should not be executed because the getter should return an empty list.";
    }
}

Data::Focus::LensMaker::make_lens_from_accessors(\&_getter, \&_setter);

1;

__END__

=pod

=head1 NAME

Data::Focus::Lens::HashArray::Index - a lens to focus on element(s) of hash/array

=head1 SYNOPSIS

    use Data::Focus qw(focus);
    use Data::Focus::Lens::HashArray::Index;
    
    sub lens { Data::Focus::Lens::HashArray::Index->new(index => $_[0]) }
    
    my $target = {
        foo => "bar",
        hoge => [ "a", "b", "c" ]
    };
    
    focus($target)->get(lens("foo"));                ## => "bar"
    focus($target)->get(lens("hoge"));               ## => ["a", "b", "c"]
    focus($target)->get(lens("hoge"), lens(1));      ## => "b"
    
    focus($target)->list(lens("hoge"), lens([0, 2])) ## => ("a", "c")

=head1 DESCRIPTION

This is an implementation of L<Data::Focus::Lens>,
which focuses on one or more elements in a hash or array.

Conceptually, this lens does the same as hash/array subscripts and slices.

    $hash->{index}
    @{$hash}{"index1", "index2", "index3"}
    $array->[4]
    @{$array}[3,4,5]

This lens never autovivifies when reading, while it DOES autovivify when writing.

Detailed behaviors of this lens are described below for each target type.

=head2 HASH target

If the target is a hash-ref, this lens behaves as its subscript or slice.

Duplicate keys in a slice are allowed.
If different values are set to those keys, only the last one takes effect.

It returns C<undef> for non-existent keys. You can set values to them.

=head2 ARRAY target

If the target is an array-ref, this lens behaves as its subscript and slice.
The indices are cast to integers.

Positive out-of-range indices are allowed.
C<get()> and C<list()> return C<undef> for those indices.
When set, it extends the array.

Negative indices are allowed.
They create focal points from the end of the array,
e.g., index of C<-1> means the last element in the array.

Negative out-of-range indices are read-only.
They always return C<undef>.
If you try to set values, it croaks.

Duplicate indices in a slice are allowed.
If different values are set to those indices, only the last one takes effect.

=head2 undef target

When reading, it always returns C<undef>.

When writing, it autovivifies an array-ref if and only if the indices are all non-negative integers.
Otherwise, it autovivifies a hash-ref.

=head2 blessed target

By default, the lens creates no focal point for a blessed target.
This means C<get()> returns C<undef> and C<set()> does nothing.

If C<allow_blessed> option is set to true and the target is made of a hash-ref or array-ref,
the lens creates focal points as if the target were a regular hash-ref or array-ref.

=head2 other targets

For other types of targets such as scalar-refs,
the lens creates no focal point.
This means C<get()> returns C<undef> and C<set()> does nothing.

=head1 CLASS METHODS

=head2 $lens = Data::Focus::Lens::HashArray::Index->new(%args)

The constructor. Fields in C<%args> are:

=over

=item C<index> => STR or ARRAYREF_OF_THEM (mandatory)

Index to focus. When you specify an array-ref, the C<$lens> behaves like slice.

=item C<immutable> => BOOL (optional, default: false)

If set to true, the target hash/array is treated as immutable.
This means every updating operation using the C<$lens> creates a new hash/array in a copy-on-write fashion.

=item C<allow_blessed> => BOOL (optional, default: false)

If set to true, the lens makes focal points for blessed targets if they are made of hash-refs or array-refs.

You should not set this option together with C<immutable> option,
bacause in this case you get a plain (unblessed) hash-ref/array-ref from C<set()> method.
This is confusing.

=back

=head1 OBJECT METHODS

=head2 apply_lens

See L<Data::Focus::Lens>.

=head1 AUTHOR
 
Toshio Ito, C<< <toshioito at cpan.org> >>

=cut
