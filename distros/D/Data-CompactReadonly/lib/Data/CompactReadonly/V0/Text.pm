package Data::CompactReadonly::V0::Text;
our $VERSION = '0.0.6';

use warnings;
use strict;
use base 'Data::CompactReadonly::V0::Collection';

use Encode qw(encode decode);

sub _init {
    my($class, %args) = @_;
    my($root, $offset) = @args{qw(root offset)};

    my $length = $class->_numeric_type_for_length()->_init(root => $root, offset => $offset);
    my $value  = $class->_bytes_to_text($root->_bytes_at_current_offset($length));

    return $value;
}

sub _create {
    my($class, %args) = @_;
    my $fh = $args{fh};
    $class->_stash_already_seen(%args);
    (my $scalar_type = $class) =~ s/Text/Scalar/;
    my $text = $class->_text_to_bytes($args{data});

    print $fh $class->_type_byte_from_class().
              $scalar_type->_get_bytes_from_word(length($text)).
              $text;
    $class->_set_next_free_ptr(%args);
}

sub _bytes_to_text {
    my($invocant, $bytes) = @_;
    return decode('utf-8', $bytes);
}

sub _text_to_bytes {
    my($invocant,$text) = @_;
    return encode('utf-8', $text);
}

1;
