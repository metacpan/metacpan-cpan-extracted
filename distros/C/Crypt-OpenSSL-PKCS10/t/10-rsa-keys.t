use strict;
use warnings;

use Test::More tests => 27;
use Test::Lib;
use Test::Crypt::OpenSSL::PKCS10;

BEGIN { use_ok('Crypt::OpenSSL::PKCS10') };

my @hash = qw/SHA256/;
my @keysize = qw/512 1024 2048 3172 4096/;

#diag("Only hash passed should default to 1024"); 
foreach my $hash (@hash) {
    my $keysize = 1024;
    my $req = Crypt::OpenSSL::PKCS10->new({type => 'rsa', hash => $hash});
    my $output = get_openssl_output($req->get_pem_req());
    my $hash_re = lc($hash) . "WithRSAEncryption";
    like($output, qr/$hash_re/, "Digest $hash matches");
    my $keysize_re = "$keysize bit";
    like($output, qr/$keysize_re/m, "Public Keysize $keysize_re matches");
}

#diag("keysize and hash passed"); 
foreach my $hash (@hash) {
    foreach my $keysize (@keysize) {
        my $req = Crypt::OpenSSL::PKCS10->new($keysize, {type => 'rsa', hash => $hash});
        my $output = get_openssl_output($req->get_pem_req());
        my $hash_re = lc($hash) . "WithRSAEncryption";
        like($output, qr/$hash_re/, "Digest $hash matches");
        my $keysize_re = "$keysize bit";
        like($output, qr/$keysize_re/m, "Public Keysize $keysize_re matches");
    }
}

#diag("keysize only passed"); 
foreach my $keysize (@keysize) {
    my $hash = 'SHA256';
    my $req = Crypt::OpenSSL::PKCS10->new($keysize);
    my $output = get_openssl_output($req->get_pem_req());
    my $hash_re = lc($hash) . "WithRSAEncryption";
    like($output, qr/$hash_re/, "Digest $hash matches");
    my $keysize_re = "$keysize bit";
    like($output, qr/$keysize_re/m, "Public Keysize $keysize_re matches");
}

#diag("No arguements passed"); 
{
    my $hash = 'SHA256';
    my $keysize = 1024;
    my $req = Crypt::OpenSSL::PKCS10->new();
    my $output = get_openssl_output($req->get_pem_req());
    my $hash_re = lc($hash) . "WithRSAEncryption";
    like($output, qr/$hash_re/, "Digest $hash matches");
    my $keysize_re = "$keysize bit";
    like($output, qr/$keysize_re/m, "Public Keysize $keysize_re matches");
}

#diag("Too many arguements passed"); 
{
    eval {
        my $req = Crypt::OpenSSL::PKCS10->new(1024, {type => 'rsa', hash => 'SHA256'}, 'Too Many');
    };
    like ($@, qr/Maximum 2 optional arguements/, "Correctly errors on too many arguements");
}

#diag("keysize and hash passed in wrong order"); 
{
    eval {
        my $req = Crypt::OpenSSL::PKCS10->new({type => 'rsa', hash => 'SHA256'}, 1024);
    };
    like ($@, qr/Wrong order for arguements/, "Correctly errors on wrong order for arguements");
}

done_testing;
