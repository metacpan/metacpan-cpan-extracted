package Data::CompactReadonly::V0::Dictionary;
our $VERSION = '0.0.6';

use warnings;
use strict;
use base qw(Data::CompactReadonly::V0::Collection Data::CompactReadonly::Dictionary);

use Data::CompactReadonly::V0::TiedDictionary;
use Scalar::Util qw(blessed);
use Devel::StackTrace;

sub _init {
    my($class, %args) = @_;
    my($root, $offset) = @args{qw(root offset)};

    my $object = bless({
        root   => $root,
        offset => $offset,
        cache  => ($root->_fast_collections() ? {} : undef),
    }, $class);

    if($root->_tied()) {
        tie my %dict, 'Data::CompactReadonly::V0::TiedDictionary', $object;
        return \%dict;
    } else {
        return $object;
    }
}

# write a Dictionary to the file at the current offset
sub _create {
    my($class, %args) = @_;
    my $fh = $args{fh};
    $class->_stash_already_seen(%args);
    (my $scalar_type = $class) =~ s/Dictionary/Scalar/;

    # node header
    print $fh $class->_type_byte_from_class().
              $scalar_type->_get_bytes_from_word(scalar(keys %{$args{data}}));

    # empty pointer table
    my $table_start_ptr = tell($fh);
    print $fh "\x00" x $args{ptr_size} x 2 x scalar(keys %{$args{data}}); 
    $class->_set_next_free_ptr(%args);

    my @sorted_keys = sort keys %{$args{data}};
    foreach my $index (0 .. $#sorted_keys) {
        my $this_key = $sorted_keys[$index];
        my $this_value = $args{data}->{$this_key};

        # write the pointer to the key, and the key if needed. Then write the
        # pointer to the value, and the value if needed. The value can be any
        # type. Keys are coerced Text to avoid floating point problems.
        foreach my $item (
            { data => $this_key,   ptr_offset => 0, coerce_to_text => 1 },
            { data => $this_value, ptr_offset => $args{ptr_size} }
        ) {
            $class->_seek(%args, pointer => $item->{ptr_offset} + $table_start_ptr + 2 * $index * $args{ptr_size});
            if(my $ptr = $class->_get_already_seen(%args, data => $item->{data})) {
                print $fh $class->_encode_ptr(%args, pointer => $ptr);
            } else {
                print $fh $class->_encode_ptr(%args, pointer => $class->_get_next_free_ptr(%args));
                $class->_seek(%args, pointer => $class->_get_next_free_ptr(%args));

                my $node_class = 'Data::CompactReadonly::V0::Node';
                if($item->{coerce_to_text}) {
                    $node_class = 'Data::CompactReadonly::V0::'.$class->_text_type_for_data($item->{data});
                    unless($node_class->VERSION()) {
                        eval "use $node_class";
                        die($@) if($@);
                    }
                }
                $node_class->_create(%args, data => $item->{data});
            }
        }
    }
}

# Efficient binary search. Relies on elements' being ASCIIbetically sorted by key.
# 1 <= iterations to find key (or find that there is no key) <= ceil(log2(N))
# so no more than 4 iterations for a ten element list, no more than 20 for
# a million element list. Each iteration takes two seeks and two reads there
# are then two more seeks and reads to get the value
sub element {
    my($self, $element) = @_;

    die(
        "$self: Invalid element: ".
        (!defined($element) ? '[undef]' : $element).
        " isn't Text or numeric\n"
    ) unless(defined($element) && !ref($element));

    # first we need to find that key
    my $max_candidate = $self->count() - 1;
    my $min_candidate = 0;
    my $cur_candidate = int($max_candidate / 2);
    my $prev_candidate = -1;

    while(1) {
        my $key = $self->_nth_key($cur_candidate);
        $prev_candidate = $cur_candidate;
        if($key eq $element) {
            return $self->_nth_value($cur_candidate);
        } elsif($key lt $element) { # our target is futher down the list
            ($min_candidate, $cur_candidate, $max_candidate) = (
                $cur_candidate + 1,
                int(($cur_candidate + $max_candidate + 1) / 2),
                $max_candidate
            );
        } else { # our target is further up the list
            ($min_candidate, $cur_candidate, $max_candidate) = (
                $min_candidate,
                int(($min_candidate + $cur_candidate) / 2),
                $cur_candidate - 1
            );
        }
        last if($prev_candidate == $cur_candidate);
    }
    die("$self: Invalid element: $element: doesn't exist\n");
}

sub exists {
    my($self, $element) = @_;
    return 0 if($self->count() == 0);
    eval { $self->element($element) };
    if($@ =~ /doesn't exist/) {
        return 0;
    } elsif($@) {
        die($@);
    } else {
        return 1;
    }
}

sub _nth_key {
    my($self, $n) = @_;
    if($self->{cache} && exists($self->{cache}->{keys}->{$n})) {
        return $self->{cache}->{keys}->{$n}
    }
    
    $self->_seek($self->_nth_key_ptr_location($n));
    $self->_seek($self->_ptr_at_current_offset());

    # for performance, cache the filehandle in this object
    $self->{_fh} ||= $self->_fh();
    my $offset = tell($self->{_fh});
    my $key = $self->_node_at_current_offset();
    if(!defined($key) || ref($key)) {
        die("$self: Invalid type: ".
            (!defined($key) ? 'Null' : $key).
            ": Dictionary keys must be Text at ".
            sprintf("0x%08x", $offset).
            "\n".
            Devel::StackTrace->new()->as_string()
        );
    }
    if($self->{cache}) {
        return $self->{cache}->{keys}->{$n} = $key;
    }
    return $key;
}

sub _nth_value {
    my($self, $n) = @_;
    if($self->{cache} && exists($self->{cache}->{values}->{$n})) {
        return $self->{cache}->{values}->{$n}
    }

    $self->_seek($self->_nth_key_ptr_location($n) + $self->_ptr_size());
    $self->_seek($self->_ptr_at_current_offset());

    my $val = $self->_node_at_current_offset();

    if($self->{cache}) {
        return $self->{cache}->{values}->{$n} = $val;
    }
    return $val;
}

sub _nth_key_ptr_location {
    my($self, $n) = @_;
    return $self->_offset() + $self->_scalar_type_bytes() +
           2 * $n * $self->_ptr_size();
}

sub _ptr_at_current_offset {
    my $self = shift;
    return $self->_decode_ptr(
        $self->_bytes_at_current_offset($self->_ptr_size())
    );
}

sub indices {
    my $self = shift;
    return [] if($self->count() == 0);
    return [ map { $self->_nth_key($_) } (0 .. $self->count() - 1) ];
}

1;
