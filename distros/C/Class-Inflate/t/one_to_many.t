# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CapWiz-Object-Recipient-Legislator.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

package Class::Inflate::Test;

use Class::Inflate (
    person => {                       # name of table
        key => ['id'],                # primary key of table
	methods => {                  # object accessor => database field
	    id         => 'id',
	    first_name => 'first',
	    last_name  => 'last',
	},
    },
    bio => {
        key => ['id'],
	join => {
	    person => {               # table to join against
		'id' => 'id',         # person field => bio field
	    },
	},
	methods => {
	    hometown => 'hometown',
	},
    },
    location => {
        key => ['id', 'state'],
	join => {
	    person => {
		'id' => 'id',
	    },
	},
	methods => {
	    state => {
		fields  => ['state'],
		wantref => 1,
	    },
	},
    },
);

sub new {
    my $class = shift;
    bless {}, $class;
}

#--- accessors ---#

sub id {
    my $self = shift;
    @_ ? $self->{id} = shift : $self->{id};
}

sub first_name {
    my $self = shift;
    @_ ? $self->{first_name} = shift : $self->{first_name};
}

sub last_name {
    my $self = shift;
    @_ ? $self->{last_name} = shift : $self->{last_name};
}

sub hometown {
    my $self = shift;
    @_ ? $self->{hometown} = shift : $self->{hometown};
}

sub state {
    my $self = shift;
    @_ ? $self->{state} = shift : $self->{state};
}

package main;

use Test::Debugger;
use Devel::Messenger qw(note);

my $note = note { 'output' => 'debug.txt', 'level' => 7 };
#my $explain = note { 'output' => 'print', 'level' => 1 };
no warnings 'redefine';
local *note = $note;
local *Test::Debugger::note = $note;
local *Class::Inflate::note = $note;
use warnings;

my $t = Test::Debugger->new(
    'tests'    => 10,
    'start'    => 1,
    'log_file' => 'test.log',
);
$t->param_order('ok' => [qw(self expected actual message error)]);

#########################

# Insert your test code below.

use Data::Dumper;
use DBI;
use Module::Build;
my $build = Module::Build->current;
my $dsn = $build->notes('dsn');
my $dbh = DBI->connect($dsn, '', '');

note "creating test object\n";
my $person = Class::Inflate::Test->new();
$person->id(10);

note "inflating test object\n";
my @objects = $person->inflate($dbh);

use Data::Dumper;
my $c = 0;
foreach my $object (@objects) {
    note "object " . ++$c . ":\n";
    note Dumper($object) . "\n";
}

note "original object\n";
note Dumper($person) . "\n";

$t->ok(10, $person->id, 'id');
$t->ok('Nathan', $person->first_name, 'first_name');
$t->ok('Gray', $person->last_name, 'last_name');
$t->ok('Fairfax', $person->hometown, 'hometown');
$t->ok('DC, VA', join(', ', sort @{$person->state}), 'state');

$person = Class::Inflate::Test->new();
$person->hometown('Fairfax');
@objects = $person->inflate($dbh);

$c = 0;
foreach my $object (@objects) {
    note "object " . ++$c . ":\n";
    note Dumper($object) . "\n";
}

note "original object\n";
note Dumper($person) . "\n";

$t->ok(10, $person->id, 'id');
$t->ok('Nathan', $person->first_name, 'first_name');
$t->ok('Gray', $person->last_name, 'last_name');
$t->ok('Fairfax', $person->hometown, 'hometown');
$t->ok('DC, VA', join(', ', sort @{$person->state || []}), 'state');


