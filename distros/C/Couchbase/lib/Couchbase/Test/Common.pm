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

our $Mock;
our $RealServer = $ENV{PLCB_TEST_SERVER};
our $RealPasswd = $ENV{PLCB_TEST_PASSWORD} || "";

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
    if ( (!$Mock) && (!$RealServer) ) {
        die("Mock object not found. Initialize mock object with Initialize()");
    }
    $self->{mock} = $Mock;
}

sub fetch_config { }

sub common_options {
    my ($self) = @_;

    if($RealServer) {
        return { %$RealServer };
    }
    my $mock = $self->mock;
    my $opthash = {};
    my $bucket = $self->mock->buckets->[0] or die "No buckets!";
    if(!$bucket) {
        die("Can't find common options for bucket (@_)");
    }

    if($bucket->{password}) {
        $opthash->{password} = $bucket->{password};
    }
    $opthash->{connstr} = sprintf("http://localhost:%s/%s",
                                  $self->mock->port, $bucket->{name});
    return $opthash;
}

sub make_cbo {
    my $self = shift;
    return Couchbase::Bucket->new({%{$self->common_options}});
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
        my $connstr = $RealServer;
        $RealServer = {
            connstr => $connstr,
            password => $RealPasswd
        };
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
