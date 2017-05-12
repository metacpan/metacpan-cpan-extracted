#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 13;

{    # fake test driver 1 (no _info hash)

    package Business::OnlinePayment::MOCK1;
    use strict;
    use warnings;
    use base qw(Business::OnlinePayment);
}

{    # fake test driver 2 (with _info hash)

    package Business::OnlinePayment::MOCK2;
    use base qw(Business::OnlinePayment::MOCK1);
    sub _info {
      {
        'info_compat'           => '0.01', # always 0.01 for now,
                                           # 0.02 will have requirements
        'gateway_name'          => 'Example Gateway',
        'gateway_url'           => 'http://www.example.com/',
        'module_version'        => '0.01', #$VERSION,
        'supported_types'       => [ qw( CC ECHECK ) ],
        'token_support'         => 0, #card storage/tokenization support
        'test_transaction'      => 0, #set true if ->test_transaction(1) works
        'supported_actions'     => [
                                     'Normal Authorization',
                                     'Authorization Only',
                                     'Post Authorization',
                                     'Void',
                                     'Credit',
                                   ],
        'CC_void_requires_card' => 1,
      };
    }
}

{    # fake test driver 3 (with _info hash)

    package Business::OnlinePayment::MOCK3;
    use base qw(Business::OnlinePayment::MOCK1);
    sub _info {
      {
        'info_compat'           => '0.01', # always 0.01 for now,
                                           # 0.02 will have requirements
        'gateway_name'          => 'Example Gateway',
        'gateway_url'           => 'http://www.example.com/',
        'module_version'        => '0.01', #$VERSION,
        'supported_types'       => [ qw( CC ECHECK ) ],
        'token_support'         => 1,
        'test_transaction'      => 1,
        'supported_actions'     => { 'CC' => [
                                       'Normal Authorization',
                                       'Authorization Only',
                                       'Post Authorization',
                                       'Void',
                                       'Credit',
                                       'Recurring Authorization',
                                       'Modify Recurring Authorization',
                                       'Cancel Recurring Authorization',
                                     ],
                                     'ECHECK' => [
                                       'Normal Authorization',
                                       'Void',
                                       'Credit',
                                     ],
                                   },
      };
    }
}

my $package = "Business::OnlinePayment";
my @drivers = qw(MOCK1 MOCK2 MOCK3);
my $driver  = $drivers[0];

# trick to make use() happy (called in Business::OnlinePayment->new)
foreach my $drv (@drivers) {
    $INC{"Business/OnlinePayment/${drv}.pm"} = "testing";
}


my $obj = $package->new($driver);
isa_ok( $obj, $package );
isa_ok( $obj, $package . "::" . $driver );

my %throwaway_actions = eval { $obj->info('supported_actions') };
ok( !$@, "->info('supported_actions') works w/o gateway module introspection");


$driver = 'MOCK2';
$obj = $package->new($driver);
isa_ok( $obj, $package );
isa_ok( $obj, $package . "::" . $driver );

my %actions = eval { $obj->info('supported_actions') };
ok( grep { $_ eq 'Void' } @{ $actions{$_} },
    "->info('supported_actions') works w/gateway module introspection ($_)"
  ) foreach qw( CC ECHECK );

ok($obj->info('CC_void_requires_card'),
   'CC_void_requires_card introspection');
ok(!$obj->info('ECHECK_void_requires_account'),
   'ECHECK_void_requires_account introspection');


$driver = 'MOCK3';
$obj = $package->new($driver);
isa_ok( $obj, $package );
isa_ok( $obj, $package . "::" . $driver );

%actions = eval { $obj->info('supported_actions') };
ok( grep { $_ eq 'Authorization Only' } @{ $actions{CC} },
    "->info('supported_actions') w/hashref supported_actions");
ok( ! grep { $_ eq 'Authorization Only' } @{ $actions{ECHECK} },
    "->info('supported_actions') w/hashref supported_actions");

