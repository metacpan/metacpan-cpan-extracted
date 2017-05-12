#!perl -T
use strict; use warnings; no indirect 'fatal'; use namespace::autoclean;

use Readonly;
use Test::More;
use Test::Exception;

use CloudFlare::Client::Exception::Upstream;

plan tests => 7;
Readonly my $MSG => 'Doesn\'t Matter';

# Test for superclass
Readonly my $CLASS => 'CloudFlare::Client::Exception::Upstream';
isa_ok( $CLASS, 'Throwable::Error', 'Class superclass correct');
# Test for errorCode accessor
can_ok( $CLASS, 'errorCode');

# Construction
# Valid error code
lives_and { new_ok( $CLASS => [ message => $MSG, errorCode => 'E_MAXAPI'])}
          "construction with valid EC works";
# No error code
lives_and { new_ok( $CLASS => [ message => $MSG])}
          "construction with no EC works";
# Invalid error code
throws_ok { $CLASS->new( message => $MSG, errorCode => 'E_NOTSPECD')}
          qr/Attribute \(errorCode\) does not pass the type constraint/,
          'construction with invalid EC fails';
# Missing message attr
throws_ok { $CLASS->new } qr/Attribute \(message\) is required/,
          'Construction with missing message attr dies';
# Extra attr
throws_ok { $CLASS->new(message => $MSG, extra => 'arg')}
          qr/^Found unknown attribute\(s\)/,
         'construction with extra attr throws exception';
