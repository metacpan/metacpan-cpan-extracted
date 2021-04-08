package Data::CompactReadonly::V0::Node;
our $VERSION = '0.0.5';

use warnings;
use strict;

use Fcntl qw(:seek);

use Devel::StackTrace;
use Data::CompactReadonly::V0::Text;
use Data::Dumper;

# return the root node. assumes the $fh is pointing at the start of the node header
sub _init {
    my($class, %args) = @_;
    my $self = bless(\%args, $class);
    $self->{root} = $self;
    return $self->_node_at_current_offset();
}

# write the root node to the file and, recursively, its children
sub _create {
    my($class, %args) = @_;
    die("fell through to Data::CompactReadonly::V0::Node::_create when creating a $class\n")
        if($class ne __PACKAGE__);

    $class->_type_class(
        from_data => $args{data}
    )->_create(%args);
}

# stash (in memory) of everything that we've seen while writing the database,
# with a pointer to their location in the file so that it can be re-used. We
# even stash stringified Dicts/Arrays, which can eat a TON of memory. Yes, we
# seem to need to local()ise the config vars in each sub.
sub _stash_already_seen {
    my($class, %args) = @_;
    local $Data::Dumper::Indent   = 0;
    local $Data::Dumper::Sortkeys = 1;
    if(defined($args{data})) {
        $args{globals}->{already_seen}->{d}->{
            ref($args{data}) ? Dumper($args{data}) : $args{data}
        } = tell($args{fh});
    } else {
        $args{globals}->{already_seen}->{u} = tell($args{fh});
    }
}

# look in the stash for data that we've seen before and get a pointer to it
sub _get_already_seen {
    my($class, %args) = @_;
    local $Data::Dumper::Indent   = 0;
    local $Data::Dumper::Sortkeys = 1;
    return defined($args{data})
        ? $args{globals}->{already_seen}->{d}->{
              ref($args{data}) ? Dumper($args{data}) : $args{data}
          }
        : $args{globals}->{already_seen}->{u};
}

sub _get_next_free_ptr {
    my($class, %args) = @_;
    return $args{globals}->{next_free_ptr};
}

sub _set_next_free_ptr {
    my($class, %args) = @_;
    $args{globals}->{next_free_ptr} = tell($args{fh});
}

# in case the database isn't at the beginning of a file, eg in __DATA__
sub _db_base {
    my $self = shift;
    return $self->_root()->{db_base};
}

sub _fast_collections {
    my $self = shift;
    return $self->_root()->{'fast_collections'};
}

sub _tied {
    my $self = shift;
    return $self->_root()->{'tie'};
}

# figure out what type the node is from the node specifier byte, then call
# the class's _init to get it to read itself from the db
sub _node_at_current_offset {
    my $self = shift;

    # for performance, cache the filehandle in this object
    $self->{_fh} ||= $self->_fh();
    my $type_class = $self->_type_class(from_byte => $self->_bytes_at_current_offset(1));
    return $type_class->_init(root => $self->_root(), offset => tell($self->{_fh}) - $self->_db_base());
}

# what's the minimum number of bytes required to store this int?
sub _bytes_required_for_int {
    no warnings 'portable'; # perl worries about 32 bit machines. I don't.
    my($class, $int) = @_;
    return
        $int <= 0xff               ? 1 : # Byte
        $int <= 0xffff             ? 2 : # Short
        $int <= 0xffffff           ? 3 : # Medium
        $int <= 0xffffffff         ? 4 : # Long
        $int <= 0xffffffffffffffff ? 8 : # Huge
                                     9;  # 9 or greater signals too big for 64 bits
}

# given the number of elements in a Collection, figure out what the appropriate
# class is to represent it. NB that only Byte/Short/Medium/Long are allowed, we
# don't allow Huge numbers of elements in a Collection
sub _sub_type_for_collection_of_length {
    my($class, $length) = @_;
    my $bytes = $class->_bytes_required_for_int($length);
    return $bytes == 1 ? 'Byte' :
           $bytes == 2 ? 'Short' :
           $bytes == 3 ? 'Medium' :
           $bytes == 4 ? 'Long' :
                         undef;
}

# given a blob of text, figure out its type
sub _text_type_for_data {
    my($class, $data) = @_;
    return 'Text::'.do {
        $class->_sub_type_for_collection_of_length(
            length(Data::CompactReadonly::V0::Text->_text_to_bytes($data))
        ) || die("$class: Invalid: Text too long");
    };
}

# work out what node type is required to represent a piece of data. At least in
# the case of numbers it might be better to look at the SV, as this won't distinguish
# between 2 (the number) and "2" (the string).
sub _type_map_from_data {
    my($class, $data) = @_;
    return !defined($data)
             ? 'Scalar::Null' :
           ref($data) eq 'ARRAY'
             ? 'Array::'.do { $class->_sub_type_for_collection_of_length(1 + $#{$data}) ||
                              die("$class: Invalid: Array too long");
                         } :
           ref($data) eq 'HASH'
             ? 'Dictionary::'.do { $class->_sub_type_for_collection_of_length(scalar(keys %{$data})) ||
                                   die("$class: Invalid: Dictionary too long");
                         } :
           $data =~ /
               ^-?                       # don't want to numify 00.7 (but 0.07 is fine)
               ( 0 | [1-9][0-9]* )       # 0, or 1-9 followed by any number of digits
               \.                        # decimal point
               [0-9]*[1-9]               # digits, must not end in zero
               ([eE][+-]?[0-9]+)?$       # exponent
           /x
             ? 'Scalar::Float' :
           $data =~ /
               ^(-?)                     # don't want to numify 007
               ( 0 | [1-9][0-9]* )$      # 0, or 1-9 followed by any number of digits
           /x
             ? do {
                 my $bytes = $class->_bytes_required_for_int($2);
                 $bytes == 1 ? 'Scalar::'.($1 ? 'Negative' : '').'Byte' :
                 $bytes == 2 ? 'Scalar::'.($1 ? 'Negative' : '').'Short' :
                 $bytes == 3 ? 'Scalar::'.($1 ? 'Negative' : '').'Medium' :
                 $bytes == 4 ? 'Scalar::'.($1 ? 'Negative' : '').'Long' :
                 $bytes <  9 ? 'Scalar::'.($1 ? 'Negative' : '').'Huge' :
                               'Scalar::Float'
             } :
           !ref($data)
             ? $class->_text_type_for_data($data)
             : die("Can't yet create from '$data'\n");
}

my $type_by_bits = {
    0b00 => 'Text',
    0b01 => 'Array',
    0b10 => 'Dictionary',
    0b11 => 'Scalar'
};
my $subtype_by_bits = { 
    0b0000 => 'Byte',      0b0001 => 'NegativeByte',
    0b0010 => 'Short',     0b0011 => 'NegativeShort',
    0b0100 => 'Medium',    0b0101 => 'NegativeMedium',
    0b0110 => 'Long',      0b0111 => 'NegativeLong',
    0b1000 => 'Huge',      0b1001 => 'NegativeHuge',
    0b1010 => 'Null',
    0b1011 => 'Float',
    (map { $_ => 'Reserved' } (0b1100 .. 0b1111))
};
my $bits_by_type    = { reverse %{$type_by_bits} };
my $bits_by_subtype = { reverse %{$subtype_by_bits} };

# used by classes when serialising themselves to figure out what their
# type specifier byte should be
sub _type_byte_from_class {
    my $class = shift;
    $class =~ /.*::([^:]+)::([^:]+)/;
    my($type, $subtype) = ($1, $2);
    return chr(
        ($bits_by_type->{$type}       << 6) +
        ($bits_by_subtype->{$subtype} << 2)
    );
}

# work out what node type is represented by a given node specifier byte
sub _type_map_from_byte {
    my $class   = shift;
    my $in_type = ord(shift());

    my $type        = $type_by_bits->{$in_type >> 6};
    my $scalar_type = $subtype_by_bits->{($in_type & 0b111100) >> 2};

    die(sprintf("$class: Invalid type: 0b%08b: Reserved\n", $in_type))
        if($scalar_type eq 'Reserved');
    die(sprintf("$class: Invalid type: 0b%08b: length $scalar_type\n", $in_type))
        if($type ne 'Scalar' && $scalar_type =~ /^(Null|Float|Negative|Huge)/);
    return join('::', $type, $scalar_type);
}

# get a class name (having loaded the relevant class) either from_data
# (when writing a file) or from_byte (when reading a file)
sub _type_class {
    my($class, $from, $in_type) = @_;
    my $map_method = "_type_map_$from";
    my $type_name = "Data::CompactReadonly::V0::".$class->$map_method($in_type);
    unless($type_name->VERSION()) {
        eval "use $type_name";
        die($@) if($@);
    }
    return $type_name;
}

# read N bytes from the current offset
sub _bytes_at_current_offset {
    my($self, $bytes) = @_;
    # for performance, cache the filehandle in this object
    $self->{_fh} ||= $self->_fh();
    my $tell = tell($self->{_fh});
    my $chars_read = read($self->{_fh}, my $data, $bytes);

    if(!defined($chars_read)) {
        die(
            "$self: read() failed to read $bytes bytes at offset $tell: $!\n".
            Devel::StackTrace->new()->as_string()
        );
    } elsif($chars_read != $bytes) {
        die(
            "$self: read() tried to read $bytes bytes at offset $tell, got $chars_read: $!\n".
            Devel::StackTrace->new()->as_string()
        );
    }
    return $data;
}

# this is a monstrous evil - TODO instantiate classes when writing!
# seek to a particular point in the *database* (not in the file). If the
# pointer has gone too far for the current pointer size, die. This will be
# caught in Data::CompactReadonly::V0->create(), the pointer size incremented, and it will
# try again from the start
sub _seek {
    my $self = shift;
    if($#_ == 0) { # for when reading
        my $to = shift;
        # for performance, cache the filehandle in this object
        $self->{_fh} ||= $self->_fh();
        seek($self->{_fh}, $self->_db_base() + $to, SEEK_SET);
    } else { # for when writing
        my %args = @_;
        die($self->_ptr_blown())
            if($args{pointer} >= 256 ** $args{ptr_size});
        seek($args{fh}, $args{pointer}, SEEK_SET);
    }
}

sub _ptr_blown { "pointer out of range" }

# the offset of the current node
sub _offset {
    my $self = shift;
    return $self->{offset};
}

sub _root {
    my $self = shift;
    return $self->{root};
}

# the filehandle, currently only used when reading, see the TODO above
# for _seek
sub _fh {
    my $self = shift;
    return $self->_root()->{fh};
}

sub _ptr_size {
    my $self = shift;
    return $self->_root()->{ptr_size};
}

1;
