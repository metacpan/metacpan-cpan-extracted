requires 'perl' => '5.008001';

if  ((eval {require MIME::Base32::XS;1;} || 0) ne 1) {
    requires 'MIME::Base32';
}
else {
    requires 'MIME::Base32::XS';
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
