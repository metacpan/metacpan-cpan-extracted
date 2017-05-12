# Test server subroutines.
#
# This script tests the server module's subroutines.

use strict;

use DateTime;
use IO::String;

use Test::More tests => 9;

BEGIN {use_ok('Alien::Taco::Server');}


# Test parameter handling.

foreach ([
                {},
                [],
                'get param empty',
        ],
        [
                {args => [qw/a b c/]},
                [qw/a b c/],
                'get param args',
        ],
        [
                {kwargs => {w => 1}},
                [qw/w 1/],
                'get param kwargs',
        ],
        [
                {args => [qw/x y z/], kwargs => {n => 2}},
                [qw/x y z n/, 2],
                'get param mixed',
        ]
        ) {
    is_deeply([Alien::Taco::Server::_get_param($_->[0])], $_->[1], $_->[2]);
}


# Test object handling.

my $s = new TestServer();

my $obj = DateTime->now();

my %hash = (test_object => $obj);

$s->_replace_objects(\%hash);

is_deeply($hash{'test_object'}, {_Taco_Object_ => 1}, 'replace object');

isa_ok($s->_get_object(1), 'DateTime');

$s->prepare_input('{"x": {"_Taco_Object_": 1}}');
my $r = $s->{'xp'}->read();
isa_ok($r->{'x'}, 'DateTime');

$s->_delete_object(1);

is($s->_get_object(1), undef, 'delete object');


# Dummy Taco server.

package TestServer;

use parent 'Alien::Taco::Server';

sub new {
    my $class = shift;

    my $in_io = new IO::String();
    my $out_io = new IO::String();

    my $self = bless {
        nobject => 0,
        objects => {},
        in_io => $in_io,
        out_io => $out_io,
    }, $class;

    $self->{'xp'} = $self->_construct_transport($in_io, $out_io);

    return $self;
}

sub prepare_input {
    my $self = shift;

    ${$self->{'in_io'}->string_ref()} = shift . "\n// END\n";
    $self->{'in_io'}->seek(0, 0);
}

sub get_output {
    my $self = shift;

    my $text = ${$self->{'out_io'}->string_ref()};
    ${$self->{'out_io'}->string_ref()} = '';
    $self->{'out_io'}->seek(0, 0);

    die 'end marker not found' unless $text =~ s/\n\/\/ END\n$//;
    return $text;
}
