use Test::More;
plan tests => 4;

use ExtUtils::testlib;
use Crypt::GCrypt;

my $c = Crypt::GCrypt->new(
                           type => 'cipher',
                           algorithm => 'aes',  # blklen == 16
                           mode => 'cbc',
                           padding => 'standard'
);
$c->setkey('b' x 32);

{
    my $text = 'a' x 999;

    $c->start('encrypting');
    my $t1 = substr($text, 0, 512);
    my $t2 = substr($text, 512);
    printf "length of original text is %d\n", length($text);

    my $e = $c->encrypt($t1);
    $e .= $c->encrypt($t2);
    $e .= $c->finish;
    printf "length of encrypted text is %d\n", length($e);

    $c->start('decrypting');
    my $e1 = substr($e, 0, 512);
    my $e2 = substr($e, 512);
    my $d = $c->decrypt($e1);
    $d .= $c->decrypt($e2);
    $d .= $c->finish;
    printf "length of decrypted text is %d\n", length($d);
    ok($d eq $text);
    ok(length $d == length $text);
}


# compatibility with <= 1.17 for applications which don't call ->finish()
{
    my $text = <<'EOF';
Lorem ipsum dolor sit amet, con
EOF
    printf "length of original text is %d\n", length($text);

    $c->start('encrypting');
    my $e = $c->encrypt($text) . $c->finish;
    printf "length of encrypted text is %d\n", length($e);

    $c->start('decrypting');
    my $d = $c->decrypt($e);
    my $d2 = $c->finish;  # discarding finish() output
    printf "length of decrypted text is %d\n", length($d);

    ok($d eq $text);
    ok(length $d == length $text);
}


__END__
