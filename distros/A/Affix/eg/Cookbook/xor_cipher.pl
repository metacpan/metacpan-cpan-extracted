use YAML();
use Affix;
affix './xor_cipher.so', 'string_crypt_free', [ Pointer [Void] ], Void;

sub string_crypt {
    CORE::state $string_crypt //= wrap './xor_cipher.so', 'string_crypt', [ Str, Int, Str ],
        Pointer [Char];
    my ( $input, $key ) = @_;
    my $ptr = $string_crypt->( $input, length($input), $key );
    my $out = $ptr->raw( length $input );
    string_crypt_free($ptr);
    $out;
}
#
my $orig = "hello world";
my $key  = "foobar";
print YAML::Dump($orig);
my $encrypted = string_crypt( $orig, $key );
print YAML::Dump($encrypted);
my $decrypted = string_crypt( $encrypted, $key );
print YAML::Dump($decrypted);
