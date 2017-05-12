package Consul::Simple;
$Consul::Simple::VERSION = '1.142430';
use strict;use warnings;
use LWP::UserAgent;
use HTTP::Response;
use HTTP::Request::Common;
use MIME::Base64;
use JSON;
use Data::Dumper;

sub new {
    my $class = shift;
    my $self = {};
    bless ($self,$class);
    my %args;
    {   my @args = @_;
        die 'Consul::Simple::new: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }
    $self->{consul_server} = $args{consul_server} || 'localhost';
    $args{kv_prefix} = $args{kvPrefix} if $args{kvPrefix};
    $self->{kv_prefix} = $args{kv_prefix} || '/';
    $self->{kv_prefix} =~ s/\/\//\//g;
    $self->{kv_prefix} =~ s/\/\//\//g;
    $self->{kv_prefix} =~ s/\/\//\//g;
    if($self->{kv_prefix} !~ /^\//) {
        $self->{kv_prefix} = '/' . $self->{kv_prefix};
    }
    if($self->{kv_prefix} !~ /\/$/) {
        $self->{kv_prefix} = $self->{kv_prefix} . '/';
    }
    {   my %ua_args = ();
        $ua_args{ssl_opts} = $args{ssl_opts} if $args{ssl_opts};
        $self->{ua} = LWP::UserAgent->new(%ua_args);
    }

    $self->{proto} = $args{proto} || 'http';
    $self->{consul_port} = $args{port} || 8500;
    $self->{constructor_args} = \%args;
    $self->{warning_handler} = $args{warning_handler} || sub {
        my $warnstr = shift;
        my %args = @_;
        print STDERR "[WARN]: $warnstr\n";
    };
    return $self;
}

sub _warn {
    my $self = shift;
    $self->{warning_handler}->(@_);
}

sub _do_request {
    my $self = shift;
    my $req = shift;
    my %req_args = @_;
    my $ret;
    my $tries = $self->{constructor_args}->{retries} || 5;
    my $timeout = $self->{constructor_args}->{timeout} || 2;
    while($tries--) {
        eval {
            local $SIG{ALRM} = sub { die "timed out\n"; };
            alarm $timeout;
            $ret = $self->{ua}->request($req, %req_args);
        };
        alarm 0;
        last if $ret->status_line =~ /^404 /;
        last if $ret and $ret->is_success;
        my $err;
        if($@) {
            $err = $@;
        } else {
            $err = 'http request failed with ' . $ret->status_line;
        }
        $self->_warn("request failed: $err", response => $ret);
        sleep 1;
    }
    return $ret;
}

sub KVGet {
    my $self = shift;
    my $key = shift;
    die 'Consul::Simple::KVGet: key required as first argument' unless defined $key;
    my %args;
    {   my @args = @_;
        die 'Consul::Simple::KVGet: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }
    my @entries = ();
    eval {
        my $url = $self->_mk_kv_url($key);
        $url .= '?recurse' if $args{recurse};
        my $res = $self->_do_request(GET $url);
        my $content = $res->content;
        my $values = JSON::decode_json($content);
        @entries = @$values;
    };
    my @ret = ();
    foreach my $entry (@entries) {
        #The returned entry Value is always base64 encoded
        $entry->{Value} = MIME::Base64::decode_base64($entry->{Value});

        #the idea below is to try to JSON decode it.  If that works,
        #return the JSON decoded value.  Otherwise, return it un-decoded
        my $value;
        eval {
            $value = JSON::decode_json($entry->{Value});
        };
        $value = $entry->{Value} unless $value;
        $entry->{Value} = $value;
        push @ret, $entry;
    }

    return @ret;
}


sub KVPut {
    my $self = shift;
    my $key = shift;
    die 'Consul::Simple::KVPut: key required as first argument' unless defined $key;
    my $value = shift or die 'Consul::Simple::KVPut: value required as second argument';
    if(ref $value) {
        $value = JSON::encode_json($value);
    }
    my %args;
    {   my @args = @_;
        die 'Consul::Simple::KVPut: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }
    my $res = $self->_do_request(PUT $self->_mk_kv_url($key), Content => $value);
    return $res;
}

sub _mk_kv_url {
    my $self = shift;
    my $key = shift;
    return $self->{proto} . '://' . $self->{consul_server} . ':' . $self->{consul_port} . '/v1/kv' . $self->{kv_prefix} . $key;
}

sub KVDelete {
    my $self = shift;
    my $key = shift;
    die 'Consul::Simple::KVDelete: key required as first argument' unless defined $key;
    my %args;
    {   my @args = @_;
        die 'Consul::Simple::KVPut: even number of arguments required'
            if scalar @args % 2;
        %args = @args;
    }
    my $url = $self->_mk_kv_url($key);
    $url .= '?recurse' if $args{recurse};
    my $res = $self->_do_request(
        HTTP::Request::Common::_simple_req(
            'DELETE',
            $url
        )
    );
    return $res;
}
1;

__END__

=head1 NAME

Consul::Simple - Easy access to Consul (http://www.consul.io/)

=head1 SYNOPSIS

    my $c = Consul::Simple->new();
    $c->KVPut('foo/bar', 'something');
    my @recs = $c->KVGet('foo/bar');
    #@recs = [
    #      {
    #        'Value' => 'one',
    #        'LockIndex' => 0,
    #        'CreateIndex' => 4,
    #        'Flags' => 0,
    #        'ModifyIndex' => 4,
    #        'Key' => 'foo/bar'
    #      }
    #    ];

    $c->KVPut('foo/fuz', { something => 'rich' });
    my @recs = $c->KVGet('foo/bar', recurse => 1);
    #@recs = [
    #      {
    #        'Value' => 'one',
    #        'LockIndex' => 0,
    #        'CreateIndex' => 4,
    #        'Flags' => 0,
    #        'ModifyIndex' => 4,
    #        'Key' => 'foo/bar'
    #      },
    #      {
    #        'Value' => {
    #                     'something' => 'rich'
    #                   },
    #        'LockIndex' => 0,
    #        'CreateIndex' => 5,
    #        'Flags' => 0,
    #        'ModifyIndex' => 5,
    #        'Key' => 'foo/fuz'
    #      }
    #    ];
    $c->KVDelete('foo/bar');

=head1 DESCRIPTION

Simple interface to Consul (http://www.consul.io/)

=head1 METHODS/CONSTRUCTOR

=head2 new(%options)

Your basic constructor.  It does not take any external action, so it can not
fail.

=over 4

=item kv_prefix (optional)

Adds this prefix to all key/value operations, essentially giving you a
'namespace' inside of Consul, for the life of this object.  Defaults to
'/'.

=item proto (optional)

Defaults to 'http'.

=item consul_server (optional)

Defaults to 'localhost'.

=item ssl_opts (optional)

Defaults to nothing.  Passed into LWP::UserAgent.  For instance, if you
need to do https operations against a bogus cert:
 ssl_opts => { SSL_verify_mode => 'SSL_VERIFY_NONE' }

=item retries (optional)

Defaults to 5.  The number of times to retry a given operation before
giving up.

=item timeout (optional)

Defaults to 2 seconds.  How long to wait for a given operation to timeout.

=item consul_port (optional)

Defaults to 8500.  Where the consul http API is listening.

=back

=head2 KVPut($key, $value, %options)

This calls the Consul HTTP PUT method to set a value in the key/value store.

=over 4

=item key (required)

This is the key, optionally prefixed by kv_prefix in the constructor.  No
encoding is done; this is passed to Consul as is.

=item value (required)

This is the value to be PUT with the associated key.  If it is a simple
scalar, it is passed to Consul as is.  If it is a reference of any kind,
it is JSON encoded before being sent to Consul.

=back

=head2 KVGet($key, %options)

This calls the Consul HTTP GET method to read a set of records from the
key/value store.  It returns an array of records returned by the API, if any.
The data that was previous PUT is found in the Value field of each record.

=over 4

=item key (required)

This is the key, optionally prefixed by kv_prefix in the constructor.  No
encoding is done; this is passed to Consul as is.

=item recurse (optional)

Causes the ?recurse flag to be sent along, which will cause Consul to return
all of the records 'below' the passed key.

=back

=head2 KVDelete($key, %options)

This calls the Consul HTTP DELETE method to delete a value or set of values
from the key/value store.

=over 4

=item key (required)

This is the key, optionally prefixed by kv_prefix in the constructor.  No
encoding is done; this is passed to Consul as is.

=item recurse (optional)

Causes the ?recurse flag to be sent along, which will cause Consul to delete
all of the records 'below' the passed key.

=back

=head1 TODO

Tons.

Actually and correctly test the DELETE functionality.

Implement recurse DELETE.

Add the tons of other Consul features for the KV API.

Add the rest of the non-KV Consul features.

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2014 Dana M. Diederich. All Rights Reserved.

=head1 AUTHOR

Dana M. Diederich <dana@realms.org>

=cut

