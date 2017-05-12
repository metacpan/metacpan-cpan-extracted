# -*-perl-*-
# run with perl -d:DProf $0

use CGI::Ex::Validate;

my $form = {
  username  => "++foobar++",
  password  => "123",
  password2 => "1234",
};

my $val_hash_ce = {
    'group no_alert'   => 1,
    'group no_confirm' => 1,
    username => {
        required => 1,
        match2    => 'm/^\w+$/',
        match2_error => '$name may only contain letters and numbers',
#        untaint  => 1,
    },
    password => {
        required => 1,
        min_len  => 6,
        max_len  => 30,
        match    => 'm/^[ -~]+$/',
#        untaint  => 1,
    },
    password2 => {
        validate_if => 'password',
        equals      => 'password',
    },
    email => {
        required => 1,
        match    => 'm/^[\w\.\-]+\@[\w\.\-]+$/',
#        untaint  => 1,
    },
};


for (1 .. 10_000) {
    my $err_obj = CGI::Ex::Validate->validate($form, $val_hash_ce);
#    my $err_obj = CGI::Ex::Validate->validate($form, $val_hash_ce)->as_hash;
}
