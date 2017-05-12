package Dancer::Plugin::Documentation::Base;

use strict;
use warnings;

use Moo;
use MooX::Types::MooseLike::Base qw{Str};
use namespace::clean;

has app => (
	is => 'ro',
	isa => Str,
	default => undef,
);

has documentation => (
	is => 'ro',
);

1;
