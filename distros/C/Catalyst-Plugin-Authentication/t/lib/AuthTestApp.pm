package AuthTestApp;
use strict;
use warnings;
use base qw/Catalyst/;
use Catalyst qw/
    Authentication
    Authentication::Store::Minimal
    Authentication::Credential::Password
/;

use Digest::MD5 qw/md5/;
use Digest::SHA qw/sha1_base64/;

our $users = {
    foo => {
        password => "s3cr3t",
    },
    bar => {
        crypted_password => crypt("s3cr3t", "x8"),
    },
    gorch => {
        hashed_password => md5("s3cr3t"),
        hash_algorithm => "MD5",
    },
    shabaz => {
        hashed_password => sha1_base64("s3cr3t"),
        hash_algorithm => "SHA-1"
    },
    sadeek => {
        hashed_password => sha1_base64("s3cr3t").'=',
        hash_algorithm => "SHA-1"
    },
    baz => {},
};

__PACKAGE__->config('Plugin::Authentication' =>{users => $users});

__PACKAGE__->setup;

1;

