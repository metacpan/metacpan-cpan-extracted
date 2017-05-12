use Test::Most 0.22;
require Test::NoWarnings;

use Crypt::NamedKeys;
use Data::Dumper;

Crypt::NamedKeys->keyfile('t/config/aes_keys.yml');

my $test_data = {
    aaa => 'bbb',
    ccc => 'ddd',
    eee => {
        fff => 'ggg',
    },
    hhh => [qw(iii jjj kkk)],
};

subtest "encrypt data" => sub {
    my $crypt = Crypt::NamedKeys->new(keyname => 'test');
    my $res = $crypt->encrypt_data(data => $test_data);
    is ref $res, 'HASH', "encrypted_json returned hash reference";
    eq_or_diff [sort keys %$res], [sort qw(data mac)], "  ... with data and mac values";

    my $decrypt = Crypt::NamedKeys->new(keyname => 'test');
    my $data = $decrypt->decrypt_data(%$res);
    eq_or_diff $data, $test_data, "successfully restored data with correct password";
    $data = Crypt::NamedKeys->new(keyname => 'fail_test')->decrypt_data(%$res);
    ok !$data, "couldn't decrypt with the wrong password";

    my $subst = substr($res->{mac}, 2, 1) eq 'a' ? 'b' : 'a';
    my $modified_mac = $res->{mac};
    substr $modified_mac, 2, 1, $subst;
    $data = $decrypt->decrypt_data(
        data => $res->{data},
        mac  => $modified_mac,
    );
    ok !$data, "couldn't decrypt with tampered mac";

    my $modified_data = $res->{data};
    $subst = substr($res->{data}, 2, 1) eq 'a' ? 'b' : 'a';
    substr $modified_data, 2, 1, $subst;
    $data = $decrypt->decrypt_data(
        data => $modified_data,
        mac  => $res->{mac},
    );
    ok !$data, "couldn't decrypt with tampered data";

    throws_ok { $crypt->encrypt_data(data => 'a string') } qr/must be a reference/, 'We dont support encrypting strings';
    throws_ok { $crypt->encrypt_data(data => \9) } qr/cannot encode reference to scalar/, 'We dont support references to scalars';
    throws_ok { $crypt->encrypt_data() } qr/data argument is required and must be a reference/, 'data argument is required';

    throws_ok { $crypt->decrypt_data() } qr/requires data and mac/, 'We dont support encrypting strings';
    throws_ok { $crypt->decrypt_data(data => 123) } qr/requires data and mac/, 'We dont support encrypting strings';
    throws_ok { $crypt->decrypt_data(mac  => 123) } qr/requires data and mac/, 'We dont support encrypting strings';
};

subtest 'sanity check our encryption doesnt change over time' => sub {
    # uses 'none' encryption keynum
    my $sample = {
        'data' => 'U2FsdGVkX1800ySUzgwY62FLhiG+mtKMJ4xI07P6iAK6CF4kQvEFsqj/6NO8e7WpXlPHi3sEAss+lY+wxLSXT4wDN+sT4MLUvJ5qNsb5D4i3gF3hNrwtsO0In0HCPYzy',
        'mac'  => 'tlfRE0erpuaSoYEyqMTF3fMqz/6FxGYeyRq0YX4RRa8'
    };
    my $decrypt = Crypt::NamedKeys->new(keyname => 'test');
    my $data = $decrypt->decrypt_data(%$sample);

    eq_or_diff $data, $test_data, 'Decrypted sample data correctly';

};

subtest "encrypt payload" => sub {
    my $crypt = Crypt::NamedKeys->new(keyname => 'test');
    my $cookie = $crypt->encrypt_payload(data => $test_data);
    ok $cookie, "got something in encrypted cookie";
    like $cookie, qr/^\w+\*[A-Za-z0-9+\/]+\.[A-Za-z0-9+\/]+$/, "looks like what we expect";
    my $data = $crypt->decrypt_payload(value => $cookie);
    eq_or_diff $data, $test_data, "Successfully decrypted cookie";
    $data = Crypt::NamedKeys->new(keyname => 'fail_test')->decrypt_payload(value => $cookie);
    ok !$data, "couldn't decrypt with the wrong password";
    $data = $crypt->decrypt_payload(value => "some random stuff");
    ok !$data, "couldn't decrypt the data in the wrong format";
    my $subst = substr($cookie, 12, 1) eq 'a' ? 'b' : 'a';
    substr $cookie, 12, 1, $subst;
    $data = $crypt->decrypt_payload(value => $cookie);
    ok !$data, "couldn't decrypt the mangled data";
    my $teststring = 'Hello World';
    my $cypherstring = $crypt->encrypt_payload(data => $teststring);
    ok $cypherstring, 'Have a valid cypherstring';
    is $crypt->decrypt_payload(value => $cypherstring), $teststring, 'decrypted string';
};

Test::NoWarnings::had_no_warnings();
done_testing;
