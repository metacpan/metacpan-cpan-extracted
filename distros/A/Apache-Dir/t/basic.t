#!/usr/bin/perl -w

use strict;
use Test::More tests => 9;

use constant DECLINED               => -1;
use constant DIR_MAGIC_TYPE         => 'httpd/unix-directory';
use constant HTTP_MOVED_PERMANENTLY => 301;

{
    package Apache::FakeRequest;
    no warnings 'redefine';
    sub new {
        my $class = shift;
        bless { @_ } => $class;
    }
    sub content_type { shift->{content_type}      }
    sub uri          { shift->{uri}               }
    sub args         { shift->{args}              }
    sub header_out   {
        my $self = shift;
        $self->{header_out} = [@_];
    }
}

BEGIN { use_ok 'Apache::Dir' or die }

my $req = Apache::FakeRequest->new(
    uri => '/foo/',
    content_type => DIR_MAGIC_TYPE,
);
is( Apache::Dir::handler($req), DECLINED, "Check valid URI" );


$req = Apache::FakeRequest->new(
    uri => '/foo',
    content_type => 'foo',
);
is( Apache::Dir::handler($req), DECLINED, "Check valid file" );


$req = Apache::FakeRequest->new(
    uri => '/foo',
    content_type => DIR_MAGIC_TYPE,
);
is( Apache::Dir::handler($req), HTTP_MOVED_PERMANENTLY, "Check invalid URI" );
is( $req->{header_out}[0], 'Location', "Check for Location header");
is( $req->{header_out}[1], '/foo/', "Check Location header value");

my $args = 'bar=bim&boom=hello';
$req = Apache::FakeRequest->new(
    uri => '/foo',
    content_type => DIR_MAGIC_TYPE,
    args => $args
);
is( Apache::Dir::handler($req), HTTP_MOVED_PERMANENTLY, "Check invalid URI with args" );
is( $req->{header_out}[0], 'Location', "Check for Location header");
is( $req->{header_out}[1], "/foo/?$args", "Check Location header value");

__END__
