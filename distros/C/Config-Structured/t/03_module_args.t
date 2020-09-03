use strict;
use warnings qw(all);
use 5.022;

use Test::More tests => 3;
use Test::Exception;
use Test::Warn;

use Config::Structured;

throws_ok {
  my $conf = Config::Structured->new(config => {});
}
qr/Attribute \(_structure_v\), passed as \(structure\), is required/, "Unspecified structure";

throws_ok {
  my $conf = Config::Structured->new(structure => {});
}
qr/Attribute \(_config_v\), passed as \(config\), is required/, "Unspecified config";

warnings_are {
  my $conf = Config::Structured->new(
    structure => {
      element => {
        isa => 'Str'
      }
    },
    config => {
      element => 'hello world',
    },
    hooks => undef,
  );
  $conf->element;
}
undef, "Undefined hooks";
