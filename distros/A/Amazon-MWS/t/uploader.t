#!perl

use utf8;
use strict;
use warnings;
use Amazon::MWS::Uploader;
use Data::Dumper;
use Test::More;
use DateTime;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

my $feed_dir = 't/feeds';

if (-d 'schemas') {
    plan tests => 26;
}
else {
    plan skip_all => q{Missing "schemas" directory with the xsd from Amazon, skipping feeds tests};
}



unless (-d $feed_dir) {
    mkdir $feed_dir or die "Cannot create $feed_dir $!";
}

my %constructor = (
                   merchant_id => '__MERCHANT_ID__',
                   access_key_id => '12341234',
                   secret_key => '123412341234',
                   marketplace_id => '123412341234',
                   endpoint => 'https://mws-eu.amazonservices.com',
                   feed_dir => $feed_dir,
                   schema_dir => 'schemas',
                  );

my $uploader = Amazon::MWS::Uploader->new(%constructor);

ok($uploader);
ok($uploader->client->can('agent'), "Client can call agent");
ok($uploader->client->agent->isa('LWP::UserAgent'));
ok($uploader->schema, "schema built");
ok($uploader->xml_reader, "Reader ok");
ok($uploader->xml_writer, "Writer ok");
ok($uploader->generic_feeder->xml_writer);

is($uploader->_unique_shop_id, $constructor{merchant_id});
$uploader = Amazon::MWS::Uploader->new(%constructor,
                                       shop_id => 'shoppe');

is($uploader->_unique_shop_id, 'shoppe');

eval {
    $uploader = Amazon::MWS::Uploader->new(%constructor,
                                           reset_errors => '! 2341 , 1234 , 1234 ,'
                                           );
};
ok (!$@, "No exception");

is_deeply($uploader->_reset_error_structure,
          {
           negate => 1,
           codes => {
                     2341 => 1,
                     1234 => 1,
                    }
          }, "reset error structure ok")
  or diag Dumper($uploader->_reset_error_structure);

eval {
    $uploader = Amazon::MWS::Uploader->new(%constructor,
                                           reset_errors => '2341 , 1234 , 1234 ,'
                                           );
};
ok (!$@, "No exception");


is_deeply($uploader->_reset_error_structure,
          {
           negate => 0,
           codes => {
                     2341 => 1,
                     1234 => 1,
                    }
          }, "reset error structure ok (no negate)")
  or diag Dumper($uploader->_reset_error_structure);



eval {
    $uploader = Amazon::MWS::Uploader->new(%constructor,
                                           reset_errors => 'balklasdfl'
                                          );
};
ok ($@, "Found exception") and diag $@;

eval {
    $uploader = Amazon::MWS::Uploader->new(%constructor,
                                           db_options => undef);
};

ok (!$@, "undef as db_options is fine") and diag $@;


$uploader = Amazon::MWS::Uploader->new(%constructor,
                                       skus_warnings_modes => {
                                                               8002 => 'warn',
                                                               8003 => 'print',
                                                               8001 => 'invalid',
                                                              });

{
    my @warned;
    local $SIG{__WARN__} = sub {
        my ($warn) = @_;
        like $warn, qr/\(800\d\)/;
        push @warned, $warn;
    };
    foreach my $code (qw/8001 8002 8003 8008/) {
        $uploader->_error_logger(warning => $code => "$code ć warn");
    }
    is (scalar(@warned), 2) or diag Dumper(\@warned);
    is_deeply(\@warned, [
                         "Invalid mode invalid for warning: 8001 ć warn (8001)\n",
                         "warning: 8002 ć warn (8002)\n",
                        ]);
}

my $now = DateTime->now;

my $old = $now->clone->subtract(hours => 2);

ok (!$uploader->job_timed_out({
                               task => 'order_ack',
                               job_started_epoch => $old->epoch,
                              }),
    "order_ack doesn't timeout in 2 hours since " . $old->ymd);

ok (!$uploader->job_timed_out({
                               task => 'upload',
                               job_started_epoch => $old->epoch,
                              }),
    "upload doesn't timeout in 2 hours since " . $old->ymd);

$old = $now->clone->subtract(days => 4);

ok (!$uploader->job_timed_out({
                               task => 'order_ack',
                               job_started_epoch => $old->epoch,
                              }),
    "order_ack doesn't timeout in 4 days since " . $old->ymd);

ok ($uploader->job_timed_out({
                              task => 'upload',
                              job_started_epoch => $old->epoch,
                             }),
    "upload timeouts in 4 days since " . $old->ymd);


$old = $now->clone->subtract(days => 31);

ok ($uploader->job_timed_out({
                              task => 'order_ack',
                              job_started_epoch => $old->epoch,
                             }),
    "order_ack doesn't timeout in 31 days since " . $old->ymd);

my @warns = $uploader->_print_or_warn_error("test me\n");
is $warns[0], 'warn';

$uploader = Amazon::MWS::Uploader->new(%constructor, quiet => 1);
@warns = $uploader->_print_or_warn_error("test me\n");
is $warns[0], 'print';

