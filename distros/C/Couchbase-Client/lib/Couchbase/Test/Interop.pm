package Couchbase::Test::Interop;
use strict;
use warnings;
use base qw(Couchbase::Test::Common);
use Test::More;
use Couchbase::Client::Errors;
use Data::Dumper;
Log::Fu::set_log_level('Couchbase::Config', 'info');
use Class::XSAccessor {
    accessors => [qw(cbo memd)]
};

my $MEMD_CLASS;
my $have_memcached = 
eval {
    require Cache::Memcached::libmemcached;
    $MEMD_CLASS = "Cache::Memcached::libmemcached";
}; if ($@) {
    diag "Memcached interop tests will not be available: $@";
    __PACKAGE__->SKIP_CLASS("Need Cache::Memcached::libmemcached");
}

if($] < 5.010) {
    __PACKAGE__->SKIP_CLASS("Cache::Memcached::libmemcached ".
                    "segfaults on perls < 5.10");
}

eval {
    require Couchbase::Config::UA; 1;
} or __PACKAGE__->SKIP_CLASS(
            "Need Couchbase::Config for interop tests\n$@");


sub _setup_client :Test(startup) {
    my $self = shift;
    $self->mock_init();
    
    my $server = $self->common_options->{server};
    my $username = $self->common_options->{username};
    my $password = $self->common_options->{password};
    my $bucket_name = $self->common_options->{bucket};
    
    my $cbo = Couchbase::Client->new({
        %{$self->common_options}
    });
    
    $self->cbo($cbo);
    unless($self->fetch_config()) {
        diag "Skipping Cache::Memcached interop tests";
        $self->SKIP_CLASS("Couldn't fetch buckets");
    }
    
    my $buckets = $self->res_buckets();
    my $bucket = (grep {
        $_->name eq $bucket_name &&
        $_->port_proxy || $_->type eq 'memcached'
    } @$buckets)[0];
    
    if(!$bucket) {
        my $msg =
        "Couldn't find appropriate bucket. Bucket must have an auth-less proxy ".
        "port, and/or be of memcached type";
        die $msg;
    }
    #print Dumper($bucket);
    
    my $node = $bucket->nodes->[0];
    my $memd_host = sprintf("%s:%d",
                        $node->base_addr,
                        $bucket->port_proxy ||
                        $node->port_proxy ||
                        $node->port_direct);
    
    
    note "Have $memd_host";
    my $memd = $MEMD_CLASS->new({servers => [ $memd_host] ,
                                 compress_threshold => 100,
                                 });
    $self->memd($memd);
    if($memd->can('set_binary_protocol')) {
        $memd->set_binary_protocol(1);
    }
}

sub T30_interop_init :Test(no_plan)
{
    my $self = shift;
    my $memd = $self->memd();
    foreach my $key (qw(foo bar baz)) {
        my $value = scalar reverse($key);
        ok($memd->set($key, $value), "Set value OK");
        is($memd->get($key), $value, "Got back our value");
        
        my $ret = $self->cbo->get($key);
        ok($ret->is_ok, "Found value for memcached key");
        is($ret->value, $value, "Got back same value");
        
        ok($self->cbo->set($key,$value)->is_ok, "set via cbc");
        is($memd->get($key), $value, "get via memd");
    }
}

sub T31_interop_serialization :Test(no_plan) {
    my $self = shift;
    my $key = "Serialized";
    my $value = [ qw(foo bar baz), { "this is" => "a hash" } ];
    my $memd = $self->memd();
    
    ok($memd->set($key, $value), "Set serialized structure");
    my $ret;
    $ret = $self->cbo->get($key);
    ok($ret->is_ok, "Got ok result");
    is_deeply($ret->value, $value, "Compared identical perl structures");
    is_deeply($memd->get($key), $ret->value,"even deeper comparison");
}

sub T32_interop_compression :Test(no_plan) {
    my $self = shift;
    my $key = "Compressed";
    my $value = "foobarbaz" x 1000;
    #return;
    
    $self->memd->set_compress_threshold(100);
    $self->memd->set_compress_enable(1);
    
    diag "Hacking into unexposed Cache::Memcached::libmemcached methods";
    $self->memd->{compress_savingsS} = 500;
    
    ok($self->memd->get_compress_enable, "Compression is enabled via memd");
    ok($self->memd->get_compress_threshold < length($value),
       "compression threshold is set to <length(value)");
    
    
    ok($self->memd->set($key, $value), "Set compressed value via memd");
    
    ok($self->cbo->deconversion_settings, "Deconversion enabled");
    $self->cbo->deconversion_settings(0);
    ok(!$self->cbo->deconversion_settings, "Deconversion now disabled");
    $self->cbo->enable_compress(0);
    
    
    my $ret = $self->cbo->get($key);
    ok($ret->is_ok, "Got value via cbo");
    #diag $ret->value;
    
    ok(length($ret->value) != length($value),
       "got compressed value (comp_len < real_len)");
    
    $self->cbo->deconversion_settings(1);
    $self->cbo->enable_compress(1);
    
    $ret = $self->cbo->get($key);
    ok($ret->is_ok, "Re-got value via cbo");
    if(!$ret->is_ok) {
        diag("ERR ", $ret->errstr);
        return;
    }
    is($ret->value, $value, "Decompressed to same value");
}

1;