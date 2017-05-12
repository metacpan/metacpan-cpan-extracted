use strict;

# vim: ft=perl ts=3 sts=3 sw=3 et ai :

use Test::More;
use Data::Dumper;
use Test::Exception;

use Data::Tubes qw< summon >;

summon('Parser::parse_ghashy');
ok __PACKAGE__->can('parse_ghashy'), "summoned parse_ghashy";

my $raw = q< what = ever you= 'like whatever' this\ goes\ default >;
{
   my $parser = parse_ghashy(default_key => 'mu');
   my $record = $parser->({raw => $raw});
   is ref($record), 'HASH', 'record is a hash';
   is_deeply $record,
     {
      structured => {
         what => 'ever',
         you  => 'like whatever',
         mu   => 'this goes default',
      },
      raw => $raw
     },
     'hash was parsed';
}

{
   my $parser =
     parse_ghashy(input => 'karb', output => 'what', default_key => 'mu');
   my $record = $parser->({karb => $raw});
   is ref($record), 'HASH', 'record is a hash';
   is_deeply $record,
     {
      what => {
         what => 'ever',
         you  => 'like whatever',
         mu   => 'this goes default',
      },
      karb => $raw
     },
     'hash was parsed';
}

$raw     = 'what=ever you=like whatever';
{
   my $parser  = parse_ghashy(default_key => 'mu');
   my $record;
   lives_ok { $record = $parser->({raw => $raw}) }
      'call to ghashy lives with new input'
         or diag Dumper($@);
   is ref($record), 'HASH', 'record is a hash';
   is_deeply $record,
     {structured => {qw< what ever you like mu whatever >}, raw => $raw},
     'hash was parsed';
}

done_testing();
