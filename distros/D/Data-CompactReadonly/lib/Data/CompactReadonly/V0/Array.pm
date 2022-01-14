package Data::CompactReadonly::V0::Array;
our $VERSION = '0.1.0';

use warnings;
use strict;
use base qw(Data::CompactReadonly::V0::Collection Data::CompactReadonly::Array);

use Data::CompactReadonly::V0::TiedArray;

sub _init {
    my($class, %args) = @_;
    my($root, $offset) = @args{qw(root offset)};

    my $object = bless({
        root => $root,
        offset => $offset
    }, $class);

    if($root->_tied()) {
        tie my @array, 'Data::CompactReadonly::V0::TiedArray', $object;
        return \@array;
    } else {
        return $object;
    }
}

# write an Array to the file at the current offset
sub _create {
    my($class, %args) = @_;
    my $fh = $args{fh};
    $class->_stash_already_seen(%args);
    (my $scalar_type = $class) =~ s/Array/Scalar/;

    # node header
    print $fh $class->_type_byte_from_class().
              $scalar_type->_get_bytes_from_word(1 + $#{$args{data}});

    # empty pointer table
    my $table_start_ptr = tell($fh);
    print $fh "\x00" x $args{ptr_size} x (1 + $#{$args{data}});
    $class->_set_next_free_ptr(%args);

    # write a pointer to each item in turn, and if necessary also write
    # item, which can be of any type
    foreach my $index (0 .. $#{$args{data}}) {
        my $this_data = $args{data}->[$index];
        $class->_seek(%args, pointer => $table_start_ptr + $index * $args{ptr_size});
        if(my $ptr = $class->_get_already_seen(%args, data => $this_data)) {
            print $fh $class->_encode_ptr(%args, pointer => $ptr);
        } else {
            print $fh $class->_encode_ptr(%args, pointer => $class->_get_next_free_ptr(%args));
            $class->_seek(%args, pointer => $class->_get_next_free_ptr(%args));
            Data::CompactReadonly::V0::Node->_create(%args, data => $this_data);
        }
    }
}

sub exists {
    my($self, $element) = @_;
    eval { $self->element($element) };
    if($@ =~ /out of range/) {
        return 0;
    } elsif($@) {
        die($@);
    } else {
        return 1;
    }
}

sub element {
    my($self, $element) = @_;
    no warnings 'numeric';
    die("$self: Invalid element: $element: negative\n")
        if($element < 0);
    die("$self: Invalid element: $element: non-integer\n")
        if($element =~ /[^0-9]/);
    die("$self: Invalid element: $element: out of range\n")
        if($element > $self->count() - 1);

    $self->_seek($self->_offset() + $self->_scalar_type_bytes() + $element * $self->_ptr_size());
    my $ptr = $self->_decode_ptr(
        $self->_bytes_at_current_offset($self->_ptr_size())
    );
    $self->_seek($ptr);
    return $self->_node_at_current_offset();
}

sub indices {
    my $self = shift;
    
    return [] if($self->count() == 0);
    return [(0 .. $self->count() - 1)];
}

1;
