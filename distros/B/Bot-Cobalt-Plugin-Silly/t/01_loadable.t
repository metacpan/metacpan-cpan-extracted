use Test::More;

my @modules = qw/
  AutoOpAll
  BoneEasy
  DailyFail
  LOLCAT
  MakeMoneyAtHome
  OutputLOLCAT
  Reverse
  Rot13
/;

my $prefix = "Bot::Cobalt::Plugin::Silly::";

for my $mod (@modules) {
  my $module = $prefix.$mod;
  use_ok( $module );
  new_ok( $module );
  can_ok( $module, 'Cobalt_register', 'Cobalt_unregister' );
}

done_testing;
