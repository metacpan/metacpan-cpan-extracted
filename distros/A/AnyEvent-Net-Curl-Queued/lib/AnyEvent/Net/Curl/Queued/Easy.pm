package AnyEvent::Net::Curl::Queued::Easy;
# ABSTRACT: Net::Curl::Easy wrapped by Moo


use feature qw(switch);
use strict;
use utf8;
use warnings qw(all);

use Carp qw(carp confess);
use Digest::SHA;
use Encode;
use HTTP::Response;
use JSON;
use Moo;
use MooX::Types::MooseLike::Base qw(
    AnyOf
    Bool
    CodeRef
    HashRef
    InstanceOf
    Int
    Object
    ScalarRef
    Str
);
use Scalar::Util qw(set_prototype);
use URI;

# kill Net::Curl::Easy prototypes as they wreck around/before/after method modifiers
set_prototype \&Net::Curl::Easy::new        => undef;
set_prototype \&Net::Curl::Easy::getinfo    => undef;
set_prototype \&Net::Curl::Easy::setopt     => undef;

extends 'Net::Curl::Easy';

use AnyEvent::Net::Curl::Const;
use AnyEvent::Net::Curl::Queued::Stats;

no if ($] >= 5.017010), warnings => q(experimental);

our $VERSION = '0.047'; # VERSION

has json        => (
    is          => 'ro',
    isa         => InstanceOf['JSON'],
    default     => sub { JSON->new->utf8->allow_blessed->convert_blessed },
    lazy        => 1,
);


has curl_result => (is => 'ro', isa => Object, writer => 'set_curl_result');


has data        => (is => 'ro', isa => ScalarRef, writer => 'set_data');


has force       => (is => 'ro', isa => Bool, default => sub { 0 });


has header      => (is => 'ro', isa => ScalarRef, writer => 'set_header');


has _autodecoded => (is => 'rw', isa => Bool, default => sub { 0 });
has http_response => (is => 'ro', isa => Bool, default => sub { 0 }, writer => 'set_http_response');


has post_content => (is => 'ro', isa => Str, default => sub { '' }, writer => 'set_post_content');


sub _URI_type {
    my $uri = shift;
    return $uri->isa('URI')
        ? $uri
        : URI->new(q...$uri)
}

has initial_url => (is => 'ro', isa => InstanceOf['URI'], coerce => \&_URI_type, required => 1);


has final_url   => (is => 'ro', isa => InstanceOf['URI'], coerce => \&_URI_type, writer => 'set_final_url');


has opts        => (is => 'ro', isa => HashRef, default => sub { {} });


has queue       => (
    is          => 'rw',
    isa         => AnyOf[
        InstanceOf['AnyEvent::Net::Curl::Queued'],
        InstanceOf['YADA'],
    ],
    weak_ref    => 1,
);


has sha         => (is => 'ro', isa => InstanceOf['Digest::SHA'], default => sub { Digest::SHA->new(256) }, lazy => 1);


has response    => (is => 'ro', isa => InstanceOf['HTTP::Response'], writer => 'set_response');
sub res { my ($self, @args) = @_; return $self->response(@args) }


has retry       => (is => 'ro', isa => Int, default => sub { 10 });


has stats       => (is => 'ro', isa => InstanceOf['AnyEvent::Net::Curl::Queued::Stats'], default => sub { AnyEvent::Net::Curl::Queued::Stats->new }, lazy => 1);
has use_stats   => (is => 'ro', isa => Bool, default => sub { 0 });


has [qw(on_init on_finish)] => (is => 'ro', isa => CodeRef);


## no critic (RequireArgUnpacking)

sub BUILDARGS {
    return ($_[0] eq ref $_[-1])
        ? $_[-1]
        : FOREIGNBUILDARGS(@_);
}


sub FOREIGNBUILDARGS {
    my $class = shift;
    if (@_ == 1 and q(HASH) eq ref $_[0]) {
        return shift;
    } elsif (@_ == 1) {
        return { initial_url => shift };
    } elsif (@_ % 2 == 0) {
        return { @_ };
    } else {
        confess 'Should be initialized as ' . $class . '->new(Hash|HashRef|URL)';
    }
}


sub unique {
    my ($self) = @_;

    # make URL-friendly Base64
    my $digest = $self->sha->clone->b64digest;
    $digest =~ tr{+/}{-_};

    # return the signature
    return $digest;
}


sub sign {
    my ($self, $str) = @_;

    # add entropy to the signature
    ## no critic (ProtectPrivateSubs)
    Encode::_utf8_off($str);
    return $self->sha->add($str);
}


sub init {
    my ($self) = @_;

    # buffers
    my $data = '';
    $self->set_data(\$data);
    my $header = '';
    $self->set_header(\$header);

    # fragment mangling
    my $url = $self->initial_url->clone;
    $url->fragment(undef);
    $self->setopt(
        Net::Curl::Easy::CURLOPT_URL,           $url->as_string,
        Net::Curl::Easy::CURLOPT_WRITEDATA,     \$data,
        Net::Curl::Easy::CURLOPT_WRITEHEADER,   \$header,
    );

    # common parameters
    if (defined($self->queue)) {
        $self->setopt(
            Net::Curl::Easy::CURLOPT_SHARE,     $self->queue->share,
            Net::Curl::Easy::CURLOPT_TIMEOUT,   $self->queue->timeout,
        );
        $self->setopt($self->queue->common_opts);
        $self->set_http_response($self->queue->http_response)
            if $self->queue->http_response;
    }

    # salt
    $self->sign(ref($self));
    # URL; GET parameters included
    $self->sign($url->as_string);

    # set default options
    $self->setopt($self->opts);

    # call the optional callback
    $self->on_init->(@_) if ref($self->on_init) eq 'CODE';

    return;
}


sub has_error {
    # very bad error
    return 0 + $_[0]->curl_result != Net::Curl::Easy::CURLE_OK;
}


## no critic (ProhibitUnusedPrivateSubroutines)
sub _finish {
    my ($self, $result) = @_;

    # populate results
    $self->set_curl_result($result);
    $self->set_final_url($self->getinfo(Net::Curl::Easy::CURLINFO_EFFECTIVE_URL));

    # optionally encapsulate with HTTP::Response
    if ($self->http_response and $self->final_url->scheme =~ m{^https?$}ix) {
        # libcurl concatenates headers of redirections!
        my $header = ${$self->header};
        $header =~ s/^.*(?:\015\012?|\012\015){2}(?!$)//sx;
        $self->set_response(
            HTTP::Response->parse(
                $header
                . ${$self->data}
            )
        );

        $self->response->headers->header(content_encoding => 'identity')
            if $self->_autodecoded;

        my $msg = $self->response->message // '';
        $msg =~ s/^\s+|\s+$//gsx;
        $self->response->message($msg);
    }

    # wrap around the extendible interface
    $self->finish($result);

    # re-enqueue the request
    if ($self->has_error and $self->retry > 1) {
        $self->queue->queue_push($self->clone);
    }

    # update stats
    if ($self->use_stats) {
        $self->stats->sum($self);
        $self->queue->stats->sum($self);
    }

    # request completed (even if returned error!)
    $self->queue->inc_completed;

    # move queue
    $self->queue->start;

    return;
}

sub finish {
    my ($self, $result) = @_;

    # call the optional callback
    $self->on_finish->($self, $result) if ref($self->on_finish) eq 'CODE';

    return;
}


sub clone {
    my ($self, $param) = @_;

    # silently ignore unsupported parameters
    $param = {} unless 'HASH' eq ref $param;

    my $class = ref($self);
    $param->{$_} = $self->$_()
        for qw(
            http_response
            initial_url
            retry
            use_stats
        );
    --$param->{retry};
    $param->{force} = 1;

    $param->{on_init}   = $self->on_init if ref($self->on_init) eq 'CODE';
    $param->{on_finish} = $self->on_finish if ref($self->on_finish) eq 'CODE';

    my $post_content = $self->post_content;
    return ($post_content eq '')
        ? sub { $class->new($param) }
        : sub {
            my $new = $class->new($param);
            $new->setopt(Net::Curl::Easy::CURLOPT_POSTFIELDS, $post_content);
            return $new;
        };
}


around setopt => sub {
    my $orig = shift;
    my $self = shift;

    if (@_) {
        my %param;
        if (scalar @_ % 2 == 0) {
            %param = @_;
        } elsif (ref($_[0]) eq 'HASH') {
            my $param = shift;
            %param = %{$param};
        } else {
            carp "setopt() expects OPTION/VALUE pair, OPTION/VALUE hash or hashref!";
        }

        while (my ($key, $val) = each %param) {
            $key = AnyEvent::Net::Curl::Const::opt($key);
            if ($key == Net::Curl::Easy::CURLOPT_POSTFIELDS) {
                my $is_json = 0;
                ($val, $is_json) = $self->_setopt_postfields($val);

                $orig->($self =>
                    Net::Curl::Easy::CURLOPT_HTTPHEADER,
                    [ 'Content-Type: application/json; charset=utf-8' ],
                ) if $is_json;
            } elsif ($key == Net::Curl::Easy::CURLOPT_ENCODING) {
                $self->_autodecoded(1);
                $val = $self->_setopt_encoding($val);
            }
            $orig->($self => $key, $val);
        }
    } else {
        carp "Specify at least one OPTION/VALUE pair!";
    }
};

sub _setopt_postfields {
    my ($self, $val) = @_;

    my $is_json = 0;
    if ('HASH' eq ref $val) {
        ++$is_json;
        $val = $self->json->encode($val);
    } else {
        # some DWIMmery here!
        # application/x-www-form-urlencoded is supposed to have a 7-bit encoding
        $val = encode_utf8($val)
            if utf8::is_utf8($val);

        my $obj;
        ++$is_json if 'HASH' eq ref($obj = eval { $self->json->decode($val) });
    }

    return ($self->set_post_content($val), $is_json);
}

sub _setopt_encoding {
    my ($self, $val) = @_;

    # stolen from LWP::Protocol::Net::Curl
    my @encoding =
        map { /^(?:x-)?(deflate|gzip|identity)$/ix ? lc $1 : () }
        split /\s*,\s*/x, $val;

    return join q(,) => @encoding;
}


around getinfo => sub {
    my $orig = shift;
    my $self = shift;

    for (ref($_[0])) {
        when ('ARRAY') {
            my @val;
            for my $name (@{$_[0]}) {
                my $const = AnyEvent::Net::Curl::Const::info($name);
                next unless defined $const;
                push @val, $self->$orig($const);
            }
            return @val;
        } when ('HASH') {
            my %val;
            for my $name (keys %{$_[0]}) {
                my $const = AnyEvent::Net::Curl::Const::info($name);
                next unless defined $const;
                $val{$name} = $self->$orig($const);
            }

            # write back to HashRef if called under void context
            unless (defined wantarray) {
                while (my ($k, $v) = each %val) {
                    $_[0]->{$k} = $v;
                }
                return;
            } else {
                return \%val;
            }
        } when ('') {
            my $const = AnyEvent::Net::Curl::Const::info($_[0]);
            return defined $const ? $self->$orig($const) : $const;
        } default {
            carp "getinfo() expects array/hash reference or string!";
            return;
        }
    }
};


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::Net::Curl::Queued::Easy - Net::Curl::Easy wrapped by Moo

=head1 VERSION

version 0.047

=head1 SYNOPSIS

    package MyIEDownloader;
    use strict;
    use utf8;
    use warnings qw(all);

    use Moo;
    use Net::Curl::Easy qw(/^CURLOPT_/);

    extends 'AnyEvent::Net::Curl::Queued::Easy';

    after init => sub {
        my ($self) = @_;

        $self->setopt(CURLOPT_ENCODING,         '');
        $self->setopt(CURLOPT_FOLLOWLOCATION,   1);
        $self->setopt(CURLOPT_USERAGENT,        'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0)');
        $self->setopt(CURLOPT_VERBOSE,          1);
    };

    after finish => sub {
        my ($self, $result) = @_;

        if ($self->has_error) {
            printf "error downloading %s: %s\n", $self->final_url, $result;
        } else {
            printf "finished downloading %s: %d bytes\n", $self->final_url, length ${$self->data};
        }
    };

    around has_error => sub {
        my $orig = shift;
        my $self = shift;

        return 1 if $self->$orig(@_);
        return 1 if $self->getinfo(Net::Curl::Easy::CURLINFO_RESPONSE_CODE) =~ m{^5[0-9]{2}$};
    };

    1;

=head1 WARNING: GONE MOO!

This module isn't using L<Any::Moose> anymore due to the announced deprecation status of that module.
The switch to the L<Moo> is known to break modules that do C<extend 'AnyEvent::Net::Curl::Queued::Easy'> / C<extend 'YADA::Worker'>!
To keep the compatibility, make sure that you are using L<MooseX::NonMoose>:

    package YourSubclassingModule;
    use Moose;
    use MooseX::NonMoose;
    extends 'AnyEvent::Net::Curl::Queued::Easy';
    ...

Or L<MouseX::NonMoose>:

    package YourSubclassingModule;
    use Mouse;
    use MouseX::NonMoose;
    extends 'AnyEvent::Net::Curl::Queued::Easy';
    ...

Or the L<Any::Moose> equivalent:

    package YourSubclassingModule;
    use Any::Moose;
    use Any::Moose qw(X::NonMoose);
    extends 'AnyEvent::Net::Curl::Queued::Easy';
    ...

However, the recommended approach is to switch your subclassing module to L<Moo> altogether (you can use L<MooX::late> to smoothen the transition):

    package YourSubclassingModule;
    use Moo;
    use MooX::late;
    extends 'AnyEvent::Net::Curl::Queued::Easy';
    ...

=head1 DESCRIPTION

The class you should overload to fetch stuff your own way.

=head1 ATTRIBUTES

=head2 curl_result

libcurl return code (C<Net::Curl::Easy::Code>).

=head2 data

Receive buffer.

=head2 force

Force request processing, despite the uniqueness signature.

=head2 header

Header buffer.

=head2 http_response

Encapsulate the response with L<HTTP::Response> (only when the scheme is HTTP/HTTPS).
Default: disabled.

=head2 post_content

Cache POST content to perform retries.

=head2 initial_url

URL to fetch (string).

=head2 final_url

Final URL (after redirections).

=head2 opts

C<HashRef> to be passed to C<setopt()> during initialization (inside C<init()>, before C<on_init()> callback).

=head2 queue

L<AnyEvent::Net::Curl::Queued> circular reference.

=head2 sha

Uniqueness detection helper.
Setup via C<sign> and access through C<unique>.

=head2 response

Encapsulated L<HTTP::Response> instance, if L</http_response> was set.

=head2 res

Deprecated alias for L</response>.

=head2 retry

Number of retries (default: 10).

=head2 stats

L<AnyEvent::Net::Curl::Queued::Stats> instance.

=head2 use_stats

Set to true to enable stats computation.
Note that extracting C<libcurl> time/size data degrades performance slightly.

=head2 on_init

Callback you can define instead of extending the C<init> method.
Almost the same as C<after init =E<gt> sub { ... }>

=head2 on_finish

Callback you can define instead of extending the C<finish> method.
Almost the same as C<after finish =E<gt> sub { ... }>

=head1 METHODS

=head2 unique()

Returns the unique signature of the request.
By default, the signature is derived from L<Digest::SHA> of the C<initial_url>.

=head2 sign($str)

Use C<$str> to compute the C<unique> value.
Useful to successfully enqueue POST parameters.

=head2 init()

Initialize the instance.
We can't use the default C<BUILD> method as we need the initialization to be done B<after> the instance is in the queue.

You are supposed to build your own stuff after/around/before this method using L<method modifiers|Moose::Manual::MethodModifiers>.

=head2 has_error()

Error handling: if C<has_error> returns true, the request is re-enqueued (until the retries number is exhausted).

You are supposed to build your own stuff after/around/before this method using L<method modifiers|Moose::Manual::MethodModifiers>.
For example, to retry on server error (HTTP 5xx response code):

    around has_error => sub {
        my $orig = shift;
        my $self = shift;

        return 1 if $self->$orig(@_);
        return 1 if $self->getinfo('response_code') =~ m{^5[0-9]{2}$};
    };

=head2 finish($result)

Called when the download is finished.
C<$result> holds the C<Net::Curl::Easy::Code>.

You are supposed to build your own stuff after/around/before this method using L<method modifiers|Moose::Manual::MethodModifiers>.

=head2 clone()

Clones the instance, for re-enqueuing purposes.

You are supposed to build your own stuff after/around/before this method using L<method modifiers|Moose::Manual::MethodModifiers>.

=head2 setopt(OPTION => VALUE [, OPTION => VALUE])

Extends L<Net::Curl::Easy> C<setopt()>, allowing option lists:

    $self->setopt(
        CURLOPT_ENCODING,         '',
        CURLOPT_FOLLOWLOCATION,   1,
        CURLOPT_USERAGENT,        'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0)',
        CURLOPT_VERBOSE,          1,
    );

Or even shorter:

    $self->setopt(
        encoding            => '',
        followlocation      => 1,
        useragent           => 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0)',
        verbose             => 1,
    );

Complete list of options: L<http://curl.haxx.se/libcurl/c/curl_easy_setopt.html>

If C<CURLOPT_POSTFIELDS> is a C<HashRef> or looks like a valid JSON (validates via L<JSON>),
it is encoded as UTF-8 and C<Content-Type: application/json; charset=utf-8> header is set automatically.

=head2 getinfo(VAR_NAME [, VAR_NAME])

Extends L<Net::Curl::Easy> C<getinfo()> so it is able to get several variables at once;
C<HashRef> parameter under void context will fill respective values in the C<HashRef>:

    my $x = {
        content_type    => 0,
        speed_download  => 0,
        primary_ip      => 0,
    };
    $self->getinfo($x);

C<HashRef> parameter will return another C<HashRef>:

    my $x = $self->getinfo({
        content_type    => 0,
        speed_download  => 0,
        primary_ip      => 0,
    });

C<ArrayRef> parameter will return a list:

    my ($content_type, $speed_download, $primary_ip) =
        $self->getinfo([qw(content_type speed_download primary_ip)]);

Complete list of options: L<http://curl.haxx.se/libcurl/c/curl_easy_getinfo.html>

=head1 FUNCTIONS

=head2 FOREIGNBUILDARGS

Internal.
Required for L<Moo> to operate properly on C<new> parameters.

=for Pod::Coverage BUILDARGS
res

=head1 SEE ALSO

=over 4

=item *

L<Moo>

=item *

L<Net::Curl::Easy>

=back

=head1 AUTHOR

Stanislaw Pusep <stas@sysd.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Stanislaw Pusep.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
