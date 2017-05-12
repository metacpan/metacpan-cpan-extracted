package Couchbase::Test::Common;
use strict;
use warnings;
use base qw(Test::Class);
use Test::More;
use Couchbase::MockServer;
use Data::Dumper;
use Class::XSAccessor {
    accessors => [qw(mock res_buckets)]
};

my $have_confua = eval {
    require Couchbase::Config::UA; 1;
};

our $Mock;
our $RealServer = $ENV{PLCB_TEST_REAL_SERVER};
our $MemdPort = $ENV{PLCB_TEST_MEMD_PORT};

sub SKIP_CLASS {
    my ($cls,$msg) = @_;
    if(defined $msg) {
        my $cstr = ref $cls ? ref $cls : $cls;
        my $header = ("#" x 10) . " $cstr SKIP " . ("#" x 10);
        
        diag $header;
        diag "";
        diag $msg;
        diag "";
    }
    goto &Test::Class::SKIP_CLASS;
}

sub mock_init
{
    my $self = shift;
    if(!$Mock) {
        die("Mock object not found. Initialize mock object with Initialize()");
    }
    $self->{mock} = $Mock;
}

sub fetch_config {
    my $self = shift;
    if(!$have_confua) {
        return;
    }
    my $confua = Couchbase::Config::UA->new(
        $self->common_options->{server},
        username => $self->common_options->{username},
        password => $self->common_options->{password}
    );
    my $defpool = $confua->list_pools();
    $confua->pool_info($defpool);
    my $buckets = $confua->list_buckets($defpool);
    $self->res_buckets($buckets);
}

use constant {
    BUCKET_MEMCACHED => 1,
    BUCKET_COUCHBASE => 2,
    BUCKET_DEFAULT => 3
};

sub common_options {
    my ($self,$bucket_type) = @_;
    
    if($RealServer) {
        return { %$RealServer };
    }
    my $mock = $self->mock;
    my $opthash = {};
    
    if(!$bucket_type) {
        $bucket_type = BUCKET_DEFAULT;
    } elsif ($bucket_type =~ /mem/) {
        $bucket_type = BUCKET_MEMCACHED;
    } elsif ($bucket_type =~ /couch/) {
        $bucket_type = BUCKET_COUCHBASE;
    } else {
        warn("No such bucket type $bucket_type");
        $bucket_type = BUCKET_DEFAULT;
    }
    
    my $bucket = $self->mock->buckets->[0] or die "No buckets!";
    if($bucket_type == BUCKET_MEMCACHED) {
        $bucket = (grep $_->{type} eq 'memcache',
                        @{$mock->buckets})[0];
    } elsif ($bucket == BUCKET_COUCHBASE) {
        $bucket = (grep { (!$_->{type}) || $_->{type} eq 'couchbase' }
                        @{$mock->buckets})[0];
    }
    if(!$bucket) {
        die("Can't find common options for bucket (@_)");
    }
    
    if($bucket->{password}) {
        $opthash->{username} = "some_user";
        $opthash->{password} = $bucket->{password};
    }
    $opthash->{server} = "127.0.0.1:" . $self->mock->port;
    $opthash->{bucket} = $bucket->{name};
    return $opthash;
}

sub memd_options {
    if(!$MemdPort) {
        die("Cannot find Memcached port");
    }
    my ($hostname) = split(/:/, $RealServer->{server});
    $hostname .= ":$MemdPort";
    return {
        servers => [ $hostname ]
    };
}

sub k2v {
    my ($self,$k) = @_;
    reverse($k);
}

sub v2k {
    my ($self,$v) = @_;
    reverse($v);
}

my $init_pid = $$;
sub Initialize {
    my ($cls,%opts) = @_;
    if($RealServer && (!ref $RealServer) ) {
        my @kvpairs = split(/,/, $RealServer);
        $RealServer = {};
        foreach my $pair (@kvpairs) {
            my ($k,$v) = split(/=/, $pair);
            $RealServer->{$k} = $v if $k =~
                /server|bucket|username|password|memd_port/;
        }
        $RealServer->{server} ||= "localhost:8091";
        $RealServer->{bucket} ||= "default";
        $MemdPort ||= delete $RealServer->{memd_port};
        $Mock = 1;
    } else {
        eval {
            $Mock = Couchbase::MockServer->new(%opts);
        }; if( ($@ || (!$Mock)) && $$ == $init_pid) {
            $cls->SKIP_ALL("Cannot run tests without mock server ($@)");
        }
        return $Mock;
    }
}
1;