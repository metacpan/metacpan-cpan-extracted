package Couchbase::Test::Settings;
use strict;
use warnings;
use base qw(Couchbase::Test::Common);
use Test::More;
use Couchbase::Client::Errors;
use Data::Dumper;

use Class::XSAccessor {
    accessors => [qw(cbo)]
};

my $have_zlib = eval {
    require Compress::Zlib;
};

my $SERIALIZATION_CALLED = 0;
my $DESERIALIZATION_CALLED = 0;
my $COMPRESSION_CALLED = 0;
my $DECOMPRESSION_CALLED = 0;

my $COMPRESS_METHOD;
my $DECOMPRESS_METHOD;
if($have_zlib) {
    $COMPRESS_METHOD = sub {
        $COMPRESSION_CALLED = 1;
        ${$_[1]} = Compress::Zlib::memGzip(${$_[0]});
    };
    $DECOMPRESS_METHOD = sub {
        $DECOMPRESSION_CALLED = 1;
        ${$_[1]} = Compress::Zlib::memGunzip(${$_[0]});
    };
} else {
    $COMPRESS_METHOD = sub {
        $COMPRESSION_CALLED = 1;
        ${$_[1]} = scalar reverse ${$_[0]};
    };
    $DECOMPRESS_METHOD = sub {
        $DECOMPRESSION_CALLED = 1;
        ${$_[1]} = scalar reverse ${$_[0]};
    };
}

sub setup_client :Test(startup)
{
    my $self = shift;
    $self->mock_init();    
}

sub reset_vars {
    $COMPRESSION_CALLED = 0;
    $DECOMPRESSION_CALLED = 0;
    $SERIALIZATION_CALLED = 0;
    $DESERIALIZATION_CALLED = 0;
}
#We make a new client for each test
sub _pretest :Test(setup) {
    my $self = shift;
    reset_vars();
    my %options = (
        %{$self->common_options},
        compress_threshold => 100,
        compress_methods => [$COMPRESS_METHOD, $DECOMPRESS_METHOD]
    );
    
    my $o = Couchbase::Client->new(\%options);
    
    $self->cbo( $o );

}

sub T20_settings_connect :Test(no_plan)
{
    my $self = shift;
    
    my $client = Couchbase::Client->new({
        username => "bad",
        password => "12345",
        bucket => "nonexistent",
        no_init_connect => 1,
        server => '127.0.0.1:0'
    });
    is(scalar @{$client->get_errors()}, 0,
       "No error on initial connect with no_init_connect => 1");
    
    my $ret = $client->set("Foo", "Bar");
    is($ret->errnum, COUCHBASE_ETMPFAIL, "Got ETMPFAIL on non-connected server");
    
    ok(!$client->connect, "Failure to connect to nonexistent host");
    my $errors = $client->get_errors;
    ok(scalar @$errors, "Have error");
    is($errors->[0]->[0], COUCHBASE_CONNECT_ERROR, "Got CONNECT_ERROR");
    
    $client = Couchbase::Client->new({
        %{$self->common_options},
        bucket => 'nonexist',
    });
    $errors = $client->get_errors();
    ok(scalar @$errors, "Have error for nonexistent bucket");
    is($errors->[0]->[0], COUCHBASE_BUCKET_ENOENT,
       "Got BUCKET_ENOENT for nonexistent bucket");
    
    my $warnmsg;
    {
        local $SIG{__WARN__} = sub { $warnmsg = shift };
        ok($self->cbo->connect, "connect on connected instance returns OK");
        like($warnmsg, qr/already connected/i,
             "warning on already connected instance");
    }
}

sub T21_default_settings :Test(no_plan)
{
    my $self = shift;
    my $cbo = Couchbase::Client->new({
        no_init_connect => 1,
        server => "localhost:0",
    });
    
    ok(!$cbo->dereference_scalar_ref_settings,
       "SCALAR ref deref disabled by default");
    ok($cbo->deconversion_settings, "deconversion enabled by default");
    ok(!$cbo->enable_compress, "compression disabled by default");
    ok($cbo->serialization_settings, "Serialization enabled by default");
}

sub T22_compress_settings :Test(no_plan)
{
    my $self = shift;
    my $v;
    
    my $key = "compressed";
    my $value = "foo" x 100;
    
    my $cbo = $self->cbo;
        
    my $ret = $cbo->set($key, $value);
    ok($ret->is_ok, "No problem setting key");
    is($COMPRESSION_CALLED, 1, "compression method called");
    
    $ret = $cbo->get($key);
    ok($ret->is_ok, "Got back our data");
    is($ret->value, $value, "same value");
    ok($DECOMPRESSION_CALLED, "Decompression method called");
    
    $v = $cbo->enable_compress(0);
    is($cbo->enable_compress, 0, "Compression disabled via setter");
    reset_vars();
    
    $ret = $cbo->get($key);
    ok($ret->is_ok, "status OK");
    ok($DECOMPRESSION_CALLED,
       "decompression still called with compressiond disabled");
    is($ret->value, $value, "Got same value");
    
    reset_vars();
    $ret = $cbo->set($key, $value);
    ok($ret->is_ok, "storage operation ok");
    is($COMPRESSION_CALLED, 0, "compression not called");
    
    $ret = $cbo->get($key);
    ok($ret->is_ok, "uncompressed retrieval ok");
    is($DECOMPRESSION_CALLED, 0,
       "decompression not called for non-compressed value");
    is($ret->value, $value, "got same value");
    
    reset_vars();
    $cbo->enable_compress(1);
    ok($cbo->enable_compress, "compression re-enabled");
    
    
    
    $cbo->set($key, $value);
    ok($COMPRESSION_CALLED,
       "compression method called when compression re-enabled");
    
    $cbo->enable_compress(0);
    is($cbo->enable_compress, 0, "compression disabled");
    
    ok($cbo->deconversion_settings, "deconversion still enabled");
    $cbo->deconversion_settings(0);
    is($cbo->deconversion_settings, 0, "deconversion now disabled");
    
    reset_vars();    
    $ret = $cbo->get($key);
    ok($ret->is_ok, "got compressed value ok");
    is($DECOMPRESSION_CALLED, 0, "decompression not called");
    ok($ret->value ne $value, "compressed data does not match original");
    
    reset_vars();
    $cbo->deconversion_settings(1);
    $ret = $cbo->get($key);
    is($ret->value, $value, "deconversion enabled, deompression enabled");
}

sub T23_serialize_settings :Test(no_plan)
{
    my $self = shift;
    my $cbo = $self->cbo;
    
    $cbo->serialization_settings(0);
    $cbo->dereference_scalar_ref_settings(1);
    
        #try to store a reference:
    
    eval {
        $cbo->set("serialized", [qw(foo bar baz)]);
    };
    ok($@, "got error for serializing data - ($@)");
    is($SERIALIZATION_CALLED, 0, "serialization method not called on pre-check");
    
    my $key = "compressed_key";
    my $value = \"Hello world";
    
    my $ret = $cbo->set($key, $value);
    ok($ret->is_ok, "set value ok");
    is($SERIALIZATION_CALLED, 0, "serialization not performed");
    
    $ret = $cbo->get($key);
    ok($ret->is_ok, "Got value ok");
    is($ret->value, $$value, "dereference scalar ref");
}

sub T24_timeout_settings :Test(no_plan)
{
    my $self = shift;
    #here we can just get/set the timeout value, the real timeout tests happen
    #in a different test module:
    my $cbo = $self->cbo();
    my $orig_timeo = $cbo->timeout;
    is($orig_timeo, 2.5);
    
    
    my $warnmsg;
    {
        local $SIG{__WARN__} = sub { $warnmsg = shift };
        ok(!$cbo->timeout(-1), "Return nothing on bad argument");
    };
    like($warnmsg, qr/cannot disable timeouts/i, "cannot disable timeouts");
    is($cbo->timeout, $orig_timeo, "still have the same timeout");
    
    ok($cbo->timeout(0.1), "set timeout to value under 1");
}

sub T25_multi_server_list :Test(no_plan)
{
    my $self = shift;
    # We can't use null for a port here because it might fail on GAI for
    # SOCK_STREAM
    
    my $server_list = ['localhost:1'];
    my %options = %{$self->common_options};
    my $bucket = $options{bucket};
    my ($username,$password) = @options{qw(username password)};
    push @$server_list, delete $options{server};
    $options{servers} = $server_list;
    
    my $errors;
    my $cbo;
    my $ret;
    
    $cbo = Couchbase::Client->new({%options});
    note "Connecting with bucket $bucket";
    isa_ok($cbo, 'Couchbase::Client');
    ok(scalar @{$cbo->get_errors}, "have error(s)");
    is($cbo->get_errors->[0]->[0], COUCHBASE_CONNECT_ERROR,
       "Got network error for nonexistent host");
    
    # If we have more than a single error, print them out (via dumper);
    if(@{$cbo->get_errors()} > 1) {
        diag "We really expected a single error. Extra info:";
        diag Dumper($cbo->get_errors());
    }
    
    $ret = $cbo->set("foo", "fooval");
    ok($ret->is_ok, "connected and can set value (retry ok)");
    if(!$ret->is_ok){
        print Dumper($ret);
    }
    $cbo = Couchbase::Client->new({
        %options,
        servers => [$self->common_options->{server}, 'localhost:0'],
        bucket => 'nonexistent'
    });
    is(scalar @{$cbo->get_errors}, 1, "Got one non-retriable error");
    is($cbo->get_errors->[0]->[0], COUCHBASE_BUCKET_ENOENT,
       "BUCKET_ENOENT as expected");
}
1;