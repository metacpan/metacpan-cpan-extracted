requires 'perl' => '5.008001';
requires 'Crypt::PRNG';
if  ((eval {require Encode::Base2N;1;} || 0) ne 1) {
    requires 'MIME::Base32';
}
else {
    requires 'Encode::Base2N';
}

if  ((eval {require Digest::SHA;1;} || 0) ne 1) {
    requires 'Digest::SHA::PurePerl';
}
else {
    #this is quite pointless but anyhow
    requires 'Digest::SHA';
}

on 'test' => sub {
    requires 'Test::More', '0.98';
};
