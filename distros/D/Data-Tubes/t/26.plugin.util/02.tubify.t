use strict;

# vim: ts=3 sts=3 sw=3 et ai :

use Test::More;
use Test::Exception;
use Path::Tiny;
use Data::Dumper;
use Scalar::Util qw< refaddr >;
use Encode qw< encode decode >;

use Data::Tubes qw< summon >;

summon('Util::tubify');
ok __PACKAGE__->can('tubify'), "summoned tubify";

my $sub = sub { return };
{
   my ($tube) = tubify($sub);
   isa_ok $tube, 'CODE';
   is refaddr($tube), refaddr($sub), 'a sub is already a tube';
}

{
   my ($tube) = tubify(['Util::tubify', $sub]);
   isa_ok $tube, 'CODE';
   is refaddr($tube), refaddr($sub), 'the same old sub, eventually';
}

{
   my ($tube) = tubify('Parser::hashy');
   isa_ok $tube, 'CODE';
   my $record = {raw => 'what=ever'};
   my $benchmark = {%$record, structured => {what => 'ever'}};
   my $orecord = $tube->($record);
   is refaddr($orecord), refaddr($record), 'the tube we were expecting';
   is_deeply $orecord, $benchmark, 'parser tube worked as expected';
}

{
   my $flag = 0;
   my @tubes =
     tubify('Parser::hashy', $sub, $flag && 'Parser::ghashy', $sub);
   is scalar(@tubes), 3, 'one element ignored';
   isa_ok $_, 'CODE' for @tubes;
}

done_testing();
