#!perl -T

# Aims to test basic usage of CloudFlare::Client
use strict; use warnings; no indirect 'fatal'; use namespace::autoclean;

use Readonly;
use Try::Tiny;

use Test::More; use Test::Moose; use Test::Exception;
use CloudFlare::Client;

plan tests => 9;
Readonly my $USER => 'blah';
Readonly my $KEY  => 'blah';

# Moose tests
Readonly my $CLASS => 'CloudFlare::Client';
meta_ok($CLASS);
for my $attr (qw/ _user _key _ua/) {
    has_attribute_ok( $CLASS, $attr)}
lives_and { meta_ok( $CLASS->new( user => $USER, apikey => $KEY))}
          "Instance has meta";

# Construction
lives_and { new_ok($CLASS, [ user => $USER, apikey  => $KEY])}
          "construction with valid credentials works";
# Work around Moose versions
if($Moose::VERSION >= 2.1101) {
    # Missing user
    Readonly my $MISS_ARG_E => 'Moose::Exception::AttributeIsRequired';
    throws_ok { $CLASS->new( apikey => $KEY) } $MISS_ARG_E,
              "construction with missing user attribute throws exception";
    # Missing apikey
    throws_ok { $CLASS->new( user => $USER) } $MISS_ARG_E,
              "construction with missing apikey attribute throws exception";
    # Extra attr
    throws_ok { $CLASS->new( user => $USER, apikey => $KEY, extra => 'arg')}
              'Moose::Exception::Legacy',
              "construction with extra attribute throws exception"}
# Old Mooses throw strings
else { # Missing message attr
       throws_ok { $CLASS->new( apikey => $KEY) }
                 qr/^Attribute \(_user\) is required/,
                 'Construction with missing user attr dies';
       # Missing apikey attr
       throws_ok { $CLASS->new( user => $USER) }
                 qr/^Attribute \(_key\) is required/,
                 'Construction with missing apikey attr dies';
       # Extra attr
       throws_ok { $CLASS->new( user => $USER, apikey => $KEY, extra => 'arg')}
                 qr/^Found unknown attribute\(s\)/,
                 'construction with extra attr throws exception';}
