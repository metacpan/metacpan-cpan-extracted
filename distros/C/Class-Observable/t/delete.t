use strict; use warnings;

use Test::More tests => 6;

{
	package Something;
	use Class::Observable;
	our @ISA = 'Class::Observable';
	sub new { bless {}, $_[0] }
}

my $test = Something->new;

my %counter;

sub obs_inst_1  { ++$counter{'inst'} }
sub obs_inst_2  { ++$counter{'inst'} }
sub obs_class_1 { ++$counter{'class'} }
sub obs_class_2 { ++$counter{'class'} }

$test->add_observer(\&obs_inst_1);
$test->add_observer(\&obs_inst_2);

Something->add_observer(\&obs_class_1);
Something->add_observer(\&obs_class_2);

$test->notify_observers;
is $counter{'inst'}, 2, 'Both instance observers called';
is $counter{'class'}, 2, '... as well as both class observers';
%counter = ();

$test->delete_observer(\&obs_inst_1);

$test->notify_observers;
is $counter{'inst'}, 1, 'After instance observer deletion only one is called';
is $counter{'class'}, 2, '... as well as both class observers';
%counter = ();

Something->delete_observer(\&obs_class_1);

$test->notify_observers;
is $counter{'class'}, 1, 'After class observer deletion only one is called';
is $counter{'inst'}, 1, '... as well as one instance observers';
%counter = ();
