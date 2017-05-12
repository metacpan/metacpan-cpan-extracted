package Couchbase::Test::Settings;
use strict;
use warnings;
use base qw(Couchbase::Test::Common);
use Test::More;
use Couchbase::Constants;
use Couchbase::Bucket;
use Data::Dumper;
use Storable;

use Class::XSAccessor {
    accessors => [qw(cbo)]
};

sub setup_client :Test(startup)
{
    my $self = shift;
    $self->mock_init();
}

#We make a new client for each test
sub _pretest :Test(setup) {
    my $self = shift;
    my $o = Couchbase::Bucket->new($self->common_options);
    $self->cbo( $o );
}

sub T20_settings_connect :Test(no_plan)
{
    my $self = shift;
    my $client = Couchbase::Bucket->new({
        connstr => "couchbases://badhost/badbucket",
        no_init_connect => 1
    });

    ok(!$client->connected);
    # Set the timeout value..
    $client->settings->{config_total_timeout} = 0.5;
    eval { $client->connect(); };
    ok($@, "Got connection error");

    # Try to perform an operation
    my $doc = Couchbase::Document->new('foo', 'bar');
    $client->upsert($doc);
    ok(!$doc->is_ok);
    is($doc->errnum, COUCHBASE_CLIENT_ETMPFAIL);
}

sub T23_serialize_settings :Test(no_plan)
{
    my $self = shift;
    my $cbo = $self->cbo;
    my $serialize_called = 0;
    my $doc = Couchbase::Document->new('serkey', \"Hello World", { format => COUCHBASE_FMT_STORABLE });

    {
        local $cbo->settings->{storable_encoder} = sub {
            $serialize_called = 1;
            Storable::freeze(shift);
        };
        $cbo->upsert($doc);
        ok($serialize_called);
    }

    $serialize_called = 0;
    {
        local $cbo->settings->{storable_decoder} = sub {
            $serialize_called = 1;
            Storable::thaw(shift);
        };
        $cbo->get($doc);
        ok($serialize_called);
    }

    # See what happens when we get an error
    {
        local $cbo->settings->{storable_encoder} = sub { die("Argh!!") };
        eval { $cbo->upsert($doc); };
        ok($@, "Got exception during encoding");
    }

    {
        $cbo->upsert($doc); # This should be ok
        ok($doc->is_ok);
        $doc->value(undef);


        my $did_warn = 0;
        local $SIG{__WARN__} = sub { $did_warn = 1 };
        local $cbo->settings->{storable_decoder} = sub { die("ARGH") };
        $cbo->get($doc);
        ok($did_warn, "Got warning during decoding");
    }
}

sub T24_timeout_settings :Test(no_plan)
{
    my $self = shift;
    #here we can just get/set the timeout value, the real timeout tests happen
    #in a different test module:
    my $cbo = $self->cbo();
    my $orig_timeo = $cbo->settings->{kv_timeout};
    is($orig_timeo, 2.5);
    $cbo->settings->{kv_timeout} = 0.1;
    is(0.1, $cbo->settings->{kv_timeout});
}

sub T26_server_nodes :Test(no_plan) {
    my $self = shift;
    my $o = $self->cbo;
    ok($o->connected);

    my $nodes = $o->cluster_nodes;
    isa_ok($nodes, 'ARRAY');

    ok($#{$nodes} >= 0); # Not empty
    ok($o->settings->{bucket});
}

sub T27_lcb_version :Test(no_plan) {
    my $self = shift;
    my $version = Couchbase::lcb_version();
    isa_ok($version, 'HASH');
}
1;
