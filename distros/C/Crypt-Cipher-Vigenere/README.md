# SYNOPSIS

```perl
use Crypt::Cipher::Vigenere;

my $vigenere = Crypt::Cipher::Vigenere->new( $key );

# encode plaintext
my $cipher_text = $vigenere->encode( $plain_text );

# decode ciphertext
my $plain_text = $vigenere->decode( $cipher_rtext );

# reset internal position in the key
$vigenere->reset;
```

# DESCRIPTION

Perl implementation of the Vigenere cipher. Cipher key is specified as argument
to the constructor and it should only contain letters A to Z (case is ignored).
Using anything but ASCII letters will result in undefined behaviour.

Plaintext can be any sequence of characters, but anything but letters A to Z
is passed through unenciphered. Letters preserve their case through the
enciphering/deciphering.

The instance keeps track of the last position in the key, so subsequent call
properly continue in the enciphering process. If need to reset the position,
use the 'reset' method. Please note, that this key position is shared for both
enciphering and deciphering, so when you want to use the same instance for
deciphering text you just enciphered, you must reset it.

# METHODS

## `new`

Returns new instance with key specified as the only argument. The key is
a character string where only \[A-Za-z\] characters are allowed. Case has no
bearing on the enciphering/deciphering process.

## `encode`

Takes plaintext as argument and returns ciphertext. Subsequent calls to this
method do not reset the position in the key, but continue where the last call
left off.

## `decode`

Takes ciphertext as argument and returns plaintext. Subsequent calls to this
method do not reset the position in the key, but continue where the last call
left off.

## `reset`

Reset the internal position to the start of the key.

# AUTHOR

Borek Lupomesky <borek@lupomesky.cz>
