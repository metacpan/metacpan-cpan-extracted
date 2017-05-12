# Test client subroutines.
#
# This script tests the client module's subroutines.

use strict;

use IO::String;

use Test::More tests => 11;

BEGIN {use_ok('Alien::Taco');}
BEGIN {use_ok('Alien::Taco::Object');}

my $t = new TestClient();


# Test interaction method.

$t->prepare_input('{"action": "result", "result": 46}');
is($t->_interact({action => 'test'}), 46, 'read result');

is($t->get_output(), '{"action":"test"}', 'write test action');

$t->prepare_input('{"action": "non-existent action"}');
eval {$t->_interact({action => 'test'});};
ok($@, 'detect unknown action error');
like($@, qr/unknown action/, 'raise unknown action error');

$t->prepare_input('{"action": "exception", "message": "test_exc"}');
eval {$t->_interact({action => 'test'});};
ok($@, 'receive exception');
like($@, qr/test_exc/, 're-raise exception');


# Test object handling.

$t->prepare_input('{"action": "result", "result": {"_Taco_Object_": 678}}');
$t->get_output();
my $res = $t->_interact({x => new Alien::Taco::Object($t, 78)});

is($t->get_output(), '{"x":{"_Taco_Object_":78}}', 'replace object');

isa_ok($res, 'Alien::Taco::Object');
is($res->_number(), 678, 'interpret object number');


# Dummy Taco client without invoking a server script.

package TestClient;

use parent 'Alien::Taco';

sub new {
    my $class = shift;

    my $in_io = new IO::String();
    my $out_io = new IO::String();

    my $self = bless {
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

sub _destroy_object {
}
