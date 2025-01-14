#!perl -w

use strict;

# use lib 'lib';
use Test::Most tests => 7;

BEGIN {
	use_ok('CGI::Info')
}

isa_ok(CGI::Info->new(), 'CGI::Info', 'Creating CGI::Info object');
isa_ok(CGI::Info::new(), 'CGI::Info', 'Creating CGI::Info object');
isa_ok(CGI::Info->new()->new(), 'CGI::Info', 'Cloning CGI::Info object');
# ok(!defined(CGI::Info::new()));

# Create a new object with direct key-value pairs
my $info = CGI::Info->new(max_upload_size => 1024 * 1024, allow => [ 'jpg', 'png' ]);
cmp_ok($info->{max_upload_size}, '==', 1024 * 1024, 'direct key-value pairs');

# Test cloning behaviour by calling new() on an existing object
my $info2 = $info->new({ allow => [ 'gif' ], upload_dir => '/var/uploads' });
cmp_ok($info2->{max_upload_size}, '==', 1024 * 1024, 'clone keeps old args');
cmp_ok($info2->{upload_dir}, 'eq', '/var/uploads', 'clone adds new args');
