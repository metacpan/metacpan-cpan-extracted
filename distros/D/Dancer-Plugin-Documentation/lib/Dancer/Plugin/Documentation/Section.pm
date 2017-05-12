package Dancer::Plugin::Documentation::Section;

use strict;
use warnings;

use Moo;
use MooX::Types::MooseLike::Base qw{Str};
use namespace::clean;

extends 'Dancer::Plugin::Documentation::Base';

has section => (
	is => 'ro',
	isa => sub { (Str)->($_[0]); die "section must not be the empty string" if $_[0] eq '' },
	coerce => sub { defined $_[0] ? lc $_[0] : undef },
	default => undef,
);

1;
