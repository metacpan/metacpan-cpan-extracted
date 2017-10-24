#!/usr/bin/perl -w

use Test::More qw(no_plan);

## grab info from the ENV
my $login = $ENV{'BOP_USERNAME'} ? $ENV{'BOP_USERNAME'} : 'TESTMERCHANT';
my $password = $ENV{'BOP_PASSWORD'} ? $ENV{'BOP_PASSWORD'} : 'TESTPASS';
my $merchantid = $ENV{'BOP_MERCHANTID'} ? $ENV{'BOP_MERCHANTID'} : 'TESTMERCHANTID';
my $ftp_user = $ENV{'BOP_FTP_USERNAME'} ? $ENV{'BOP_FTP_USERNAME'} : 'TESTFTPUSERNAME';
my $ftp_pass = $ENV{'BOP_FTP_PASS'} ? $ENV{'BOP_FTP_PASS'} : 'TESTFTPPASS';
my $env = $ENV{'BOP_TEST_ENV'} ? $ENV{'BOP_TEST_ENV'} : 'prelive'; # prelive for certification testing
my @opts = ('default_Origin' => 'RECURRING' );

## grab test info from the storable^H^H yeah actually just DATA now

my $str = do { local $/ = undef; <DATA> };
my $data;
eval($str);

#print Dumper( keys %{$data} );
  
my $authed = 
    $ENV{BOP_USERNAME}
    && $ENV{BOP_PASSWORD}
    && $ENV{BOP_MERCHANTID};

use_ok 'Business::OnlinePayment';

SKIP: {
    skip "No Auth Supplied", 3 if ! $authed;
    ok( $login, 'Supplied a Login' );
    ok( $password, 'Supplied a Password' );
    like( $merchantid, qr/^\d+/, 'Supplied a MerchantID');
}

SKIP: {
    skip "No Test Account Setup",0 if ! $authed;
    my $tx = Business::OnlinePayment->new("Litle", @opts);
    $tx->test_transaction($env);
    foreach my $account ( @{ $data->{'updater'} } ) {
        my %content = (
            action => 'Account Update',
            expiration => $account->{'exp_date'},
            customer_id => $account->{'order_id'},
            invoice_number => $account->{'order_id'},
            type => $account->{'type'},
            card_number => $account->{'number'},
        );

        $tx->add_item(\%content);
    }
    is($tx->create_batch(
        method => 'sftp',
        login           => $login,
        password        => $password,
        merchantid      => $merchantid,
        batch_id        => 'BOP-test-suite-' . time,
        ftp_username    => $ftp_user,
        ftp_password    => $ftp_pass,
#        #sftp_hosts_file => '/var/card_server/conf/known_hosts',  #how do we handle this in the test?
    ), 0, "Uploaded Batch");

}

__DATA__
$data= {
  updater => [
    {
      order_id => 1,
      type     => 'MC',
      number   => '5194560012341234',
      exp_date => '1250',
      ack      => {
        response => '000',
        message  => 'Approved',
      },
      response => {
        response => '500',
        message  => 'The account number was changed.',
        updatedCard => {
            type => 'VI',
            number => '4457010000000009',
            expDate => '0150',
        },
        originalCard => {
              type     => 'MC',
              number   => '5194560012341234',
              exp_date => '1250',
        },
      },
    },

    {
      order_id => 2,
      type     => 'MC',
      number   => '5435101234510196',
      exp_date => '0750',
      ack      => {
        response => '000',
        message  => 'Approved',
      },
      response => {
        response => '501',
        message  => 'The account was closed.',
        updatedCard => {
            type => undef,
            number => undef,
            expDate => undef,
        },
        originalCard => {
            type => MC,
            number => '5435101234510196',
            expDate => '0750',
        },
      },
    },
    {
      order_id => 3,
      type     => 'MC',
      number   => '5112010000000003',
      exp_date => '0250',
      ack      => {
        response => '000',
        message  => 'Approved',
      },
      response => {
        response => '502',
        message  => 'The expiration date was changed.',
        updatedCard => {
            type => 'MC',
            number => '5112010000000003',
            expDate => '0150',
        },
        originalCard => {
              type     => 'MC',
              number   => '5112010000000003',
              exp_date => '0250',
        },
      },
    },

    {
      order_id => 4,
      type     => 'MC',
      number   => '5112002200000008',
      exp_date => '1150',
      ack      => {
        response => '000',
        message  => 'Approved',
      },
      response => {
        response => '506',
        message  => 'No changes found',
        updatedCard => {
            type => undef,
            number => undef,
            expDate => undef,
        },
        originalCard => {
              type     => 'MC',
              number   => '5112010000000003',
              exp_date => '0250',
        },
      },
    },
    
    ],
};
