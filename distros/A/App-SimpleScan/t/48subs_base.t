use Test::More tests=>24;
use Test::Exception;
use Test::Differences;
use App::SimpleScan::Substitution;
use App::SimpleScan::Substitution::Line;

# new() tests
my %hash;
my $substitution;
lives_ok { $substitution = new App::SimpleScan::Substitution; } 'simplest object';

dies_ok { $substitution = new App::SimpleScan::Substitution 'bad' }
  'die on simple scalar';
like $@, qr/Argument to new is not a hash reference/, 'right message';
dies_ok { $substitution = new App::SimpleScan::Substitution [] }
  'die on non-hash ref';
like $@, qr/Argument to new is not a hash reference/, 'right message';

dies_ok { $substitution = 
            new App::SimpleScan::Substitution {dictionary =>'bad' } }
  'die on non-hash dictionary';
like $@, qr/'dictionary' must be a hash reference/, 'right message';
dies_ok { $substitution = 
            new App::SimpleScan::Substitution {find_vars_callback =>'bad' } }
  'die on non-code find_vars_callback';
like $@, qr/'find_vars_callback' must be a code reference/, 'right message';

lives_ok { $substitution = 
             new App::SimpleScan::Substitution {dictionary =>\%hash } }
  'good dictionary';
lives_ok { $substitution = 
            new App::SimpleScan::Substitution {find_vars_callback => sub {} } }
  'good find_vars_callback';

# insert_value_callback test
my $insert = $substitution->insert_value_callback();
my($which, $result) = $insert->("this is <a> test", "the","the");
is $which, "", "not inserted";
is $result, "this is <a> test", "no change";
($which, $result) = $insert->("this is <a> test", "a","the");
is $which, 1, "inserted";
is $result, "this is the test", "changed";


# _find_angle_bracketed test
my $find_sub_ref = $substitution->find_vars_callback();

my $test_string;
$test_string = 'this is a test';
eq_or_diff [$find_sub_ref->($test_string)], [],
 'no angle-bracketed item';

$test_string = 'this is a <test>';
eq_or_diff [$find_sub_ref->($test_string)], [qw(test)],
 'one angle-bracketed item';

$test_string = 'this is a <more_complex_<test>> than <before>';
my @result = sort $find_sub_ref->($test_string);
eq_or_diff \@result, 
          [sort qw(before more_complex_<test> test)],
          'nested angle-bracketed item';

# _deepest_substitution test
$substitution->dictionary({test=>[qw(foo)]});
eq_or_diff [sort $substitution->_deepest_substitution($test_string)],
          [sort qw(before test)],
          'nested substitutions, discard undefined';
$substitution->dictionary( {
                             test => [qw(foo)],
                             before => [qw(earlier)],
                             more_complex_foo => [qw(baz)],
                             intl =>[qw(able baker charlie)],
                           } );
@result = $substitution->_deepest_substitution($test_string);
eq_or_diff [sort $substitution->_deepest_substitution($test_string)],
          [sort qw(test before)],
          'multiple nested substitutions resolved';
@result = $substitution->_deepest_substitution("http://<<intl>_staging> /Yahoo!/ Y brand on <<intl>_staging>");
eq_or_diff \@result, [qw(intl)], "second nested check";

# _substitution_value tested in t/35comb.t
# _comb tested in t/35comb.t
# _comb_index tested in t/35comb.t
my $test_line_obj = App::SimpleScan::Substitution::Line->new($test_string);
my @new_objects = $substitution->_expand_variables($test_line_obj);
my $expected = App::SimpleScan::Substitution::Line->new('this is a baz than earlier');
$expected->fixed({ before =>[qw(earlier)],
                   test   =>[qw(foo)] });
is_deeply \@new_objects, [$expected], "identical list of objects";

$test_line_obj = App::SimpleScan::Substitution::Line->new($test_string);
my @new_lines = ('this is a baz than earlier');
eq_or_diff \@new_lines, [$substitution->expand($test_string)], "identical strings";

$substitution->dictionary( {
                             test => [qw(foo bar)],
                             before => [qw(earlier later)],
                             more_complex_foo => [qw(baz)],
                             more_complex_bar => [qw(quux zonk)],
                           } );
@new_lines = ( 
   'this is a baz than earlier',
   'this is a baz than later',
   'this is a quux than earlier',
   'this is a quux than later',
   'this is a zonk than earlier',
   'this is a zonk than later',
);
eq_or_diff [sort @new_lines], [sort $substitution->expand($test_string)], "identical strings";
