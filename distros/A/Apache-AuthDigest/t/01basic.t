use strict;
use warnings FATAL => 'all';

use Apache::Test;

plan tests => 6;

ok require 5.005;
ok require mod_perl;
ok $mod_perl::VERSION >= 1.26;
ok require Digest::MD5;

ok require Apache::AuthDigest::API;
ok require Apache::AuthDigest::API::Full;
# these won't work due to mod_perl .so magic
#ok require Apache::AuthDigest;
#ok require Apache::AuthDigest::API::Session;
