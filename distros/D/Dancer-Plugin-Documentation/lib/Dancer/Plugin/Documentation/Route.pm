package Dancer::Plugin::Documentation::Route;

use strict;
use warnings;

use Moo;
use MooX::Types::MooseLike::Base qw{Str};
use namespace::clean;

extends 'Dancer::Plugin::Documentation::Base';

has method => (
	is => 'ro',
	isa => Str,
	coerce => sub { defined $_[0] ? lc $_[0] : undef },
	default => undef,
);

has path => (
	is => 'ro',
	isa => Str,
	default => undef,
);

has section => (
	is => 'ro',
	isa => Str,
	coerce => sub { defined $_[0] ? lc $_[0] : '' },
	default => '',
);

1;
