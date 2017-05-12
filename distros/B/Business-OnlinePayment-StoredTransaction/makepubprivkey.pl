use Crypt::OpenSSL::RSA;
#This will print out a public and private RSA key suitable for use by
#Business::OnlinePayment::StoredTransaction

$rsa = Crypt::OpenSSL::RSA->generate_key(1024); # or

print "private key is:\n", $rsa->get_private_key_string();
print "public key (in PKCS1 format) is:\n",
        $rsa->get_public_key_string();


