#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

our $FORCE_OUTPUT = 0;

my @LAST_WARNING;
local $SIG{__WARN__} = sub { # here we get the warning
    @LAST_WARNING = @_;
    print STDERR $_[0] if $FORCE_OUTPUT;
}; 

my $dirs = ['./t/tmpl'];
my( $template, $test_string, $context, $test_head);

$template = get_template('error_tag.txt', 'dirs' => $dirs)->render();
ok( $LAST_WARNING[0] =~ /error_tag.txt/si, 'Unknown tag error message: template filename');
ok( $LAST_WARNING[0] =~ /Line: 5/si, 'Unknown tag error message: line number');
ok( $LAST_WARNING[0] =~ /duplicate/si, 'Unknown tag error message: possible reason');

$template = get_template('error_undisclosed.txt', 'dirs' => $dirs)->render();

ok( $LAST_WARNING[0] =~ /error_undisclosed.txt/si, 'Undisclosed tag error message: template filename');
ok( $LAST_WARNING[0] =~ /endif/si, 'Undisclosed tag error message: tag name');
ok( $LAST_WARNING[0] =~ /Line: 36/si, 'Undisclosed tag error message: line number');
ok( $LAST_WARNING[0] =~ /with/si, 'Undisclosed tag error message: possible cause, inner block');
ok( $LAST_WARNING[0] =~ /at line 21/si, 'Undisclosed tag error message: possible cause, inner block line number');

$template = get_template('error_unknown_filter.txt', 'dirs' => $dirs)->render();

ok($LAST_WARNING[0] =~ /error_unknown_filter.txt/si, 'Unknown filter error message: template filename');
ok($LAST_WARNING[0] =~ /unknown_something/si, 'Unknown filter error message: filter name');
ok($LAST_WARNING[0] =~ /Line: 36/si, 'Unknown filter error message: source line number');

eval{$template = get_template('error_double_empty.txt', 'dirs' => $dirs)->render();};
$test_head = 'Double empty block: ';
ok($@ =~ /\Qthere can be only one {% empty %} block\E/si, $test_head.'error message');
ok($@ =~ /error_double_empty.txt/si, $test_head.'template name');
ok($@ =~ /\QLine: 46\E/si, $test_head.'line number');
ok($@ =~ /\QDTL::Fast::Tag::For\E/si, $test_head.'parent block');
ok($@ =~ /at line 42/si, $test_head.'parent block line');

eval{$template = DTL::Fast::Template->new('{{var1|date:"D"}}');};
print STDERR $@ if $FORCE_OUTPUT;
ok( $@ eq '', "Undef time value passed");

eval{get_template('error_variable_name.txt', 'dirs' => $dirs);};
#print $@;
$test_head = 'Wrong variable name: ';
ok( $@ =~ /\Qvariable `a=b` contains incorrect symbols\E/, $test_head.'error message');
ok( $@ =~ /\QLine: 37\E/, $test_head.'line number');

eval{get_template('error_autoescape_bla.txt', 'dirs' => $dirs);};
print STDERR $@ if $FORCE_OUTPUT;
ok( $@ =~ m{\Qautoescape tag undertands only `on` and `off` parameters\E}, 'Wrong autoescape parameter: error message');
ok( $@ =~ m{\Q./t/tmpl/error_autoescape_bla.txt\E}, 'Wrong autoescape parameter: filename');
ok( $@ =~ m{\QLine: 41\E}, 'Wrong autoescape parameter: line number');

eval{get_template('error_now_parameter.txt', 'dirs' => $dirs);};
print STDERR $@ if $FORCE_OUTPUT;
ok( $@ =~ m{\Qno time format specified\E}, '`now` without a parameter: error message');
ok( $@ =~ m{\Q./t/tmpl/error_now_parameter.txt\E}, '`now` without a parameter: filename');
ok( $@ =~ m{\QLine: 41\E}, '`now` without a parameter: line number');

# expression
eval{get_template('error_expression_unpaired_brackets.txt', 'dirs' => $dirs);};
print STDERR $@ if $FORCE_OUTPUT;
ok( $@ =~ m{\Qunpaired brackets in expression\E}, 'Unpaired brackets: error message');
ok( $@ =~ m{\Q./t/tmpl/error_expression_unpaired_brackets.txt\E}, 'Unpaired brackets: filename');
ok( $@ =~ m{\QLine: 36\E}, 'Unpaired brackets: line number');
ok( $@ =~ m{\Q(2 > 1\E}, 'Unpaired brackets: expression');

eval{get_template('error_expression_binary_no_left.txt', 'dirs' => $dirs);};
print STDERR $@ if $FORCE_OUTPUT;
ok( $@ =~ m{\Qbinary operator `>` has no left argument\E}, 'Missing left argument: error message');
ok( $@ =~ m{\Q./t/tmpl/error_expression_binary_no_left.txt\E}, 'Missing left argument: filename');
ok( $@ =~ m{\QLine: 36\E}, 'Missing left argument: line number');
ok( $@ =~ m{\Q> 1\E}, 'Missing left argument: expression');

eval{get_template('error_expression_binary_no_right.txt', 'dirs' => $dirs);};
print STDERR $@ if $FORCE_OUTPUT;
ok( $@ =~ m{\Qoperator `==` has no right argument\E}, 'Missing right argument: error message');
ok( $@ =~ m{\Q./t/tmpl/error_expression_binary_no_right.txt\E}, 'Missing right argument: filename');
ok( $@ =~ m{\QLine: 36\E}, 'Missing right argument: line number');
ok( $@ =~ m{\Qa ==\E}, 'Missing right argument: expression');

eval{get_template('error_expression_unary_got_left.txt', 'dirs' => $dirs);};
print STDERR $@ if $FORCE_OUTPUT;
ok( $@ =~ m{\Qunary operator `not` got left argument\E}, 'Extra left argument: error message');
ok( $@ =~ m{\Q./t/tmpl/error_expression_unary_got_left.txt\E}, 'Extra left argument: filename');
ok( $@ =~ m{\QLine: 36\E}, 'Extra left argument: line number');
ok( $@ =~ m{\Qa not b\E}, 'Extra left argument: expression');

eval{get_template('error_block_unnamed.txt', 'dirs' => $dirs);};
print STDERR $@ if $FORCE_OUTPUT;
ok( $@ =~ m{\Qno name specified in the block tag\E}, 'Unnamed block: error message');
ok( $@ =~ m{\Q./t/tmpl/error_block_unnamed.txt\E}, 'Unnamed block: filename');
ok( $@ =~ m{\QLine: 23\E}, 'Unnamed block: line number');

eval{get_template('error_block_duplicated.txt', 'dirs' => $dirs);};
print STDERR $@ if $FORCE_OUTPUT;
ok( $@ =~ m{\Qblock name `abc` must be unique in the template\E}, 'Duplicate block: error message');
ok( $@ =~ m{\Q./t/tmpl/error_block_duplicated.txt\E}, 'Duplicate block: filename');
ok( $@ =~ m{\QLine: 27\E}, 'Duplicate block: line number');
ok( $@ =~ m{\Qblock `abc` was already defined at line 2\E}, 'Duplicate block: first definition');

my $template1 = get_template('error_render_variable.txt', 'dirs' => $dirs);
my $template2 = get_template('error_render_variable_include.txt', 'dirs' => $dirs);

$context = {
    'var1' => {
        'hash' => {
            'array' => undef
        }
    }
};
eval{$template1->render($context);};
print STDERR $@ if $FORCE_OUTPUT;
ok( $@ =~ m{\Qnon-reference value encountered on step `0` while traversing context path\E}, 'Context error, non-reference: error message');
ok( $@ =~ m{\Q./t/tmpl/error_render_variable.txt\E}, 'Context error, non-reference: filename');
ok( $@ =~ m{\QLine: 9\E}, 'Context error, non-reference: line number');
ok( $@ =~ m{\Qhash.array.0\E}, 'Context error, non-reference: traversing path');
ok( $@ =~ m{\Q'array' => undef\E}, 'Context error, non-reference: traversed variable');

eval{$template2->render($context);};
print STDERR $@ if $FORCE_OUTPUT;
ok( $@ =~ m{\Qnon-reference value encountered on step `0` while traversing context path\E}, 'Context error, non-reference, included: error message');
ok( $@ =~ m{\Q./t/tmpl/error_render_variable.txt\E}, 'Context error, non-reference, included: filename');
ok( $@ =~ m{\QLine: 9\E}, 'Context error, non-reference, included: line number');
ok( $@ =~ m{\Qhash.array.0\E}, 'Context error, non-reference, included: traversing path');
ok( $@ =~ m{\Q'array' => undef\E}, 'Context error, non-reference, included: traversed variable');
ok( $@ =~ m{\Q./t/tmpl/error_render_variable_include.txt\E}, 'Context error, non-reference, included: trace');

$context = {
    'var1' => {
        'hash' => ['blabla']
    }
};
eval{$template1->render($context);};
print STDERR $@ if $FORCE_OUTPUT;
ok( $@ =~ m{\Qdon't know how continue traversing ARRAY (ARRAY) with step `array`\E}, 'Context error, untraceble: error message');
ok( $@ =~ m{\Q./t/tmpl/error_render_variable.txt\E}, 'Context error, untraceble: filename');
ok( $@ =~ m{\QLine: 9\E}, 'Context error, untraceble: line number');
ok( $@ =~ m{\Qhash.array.0\E}, 'Context error, untraceble: traversing path');
ok( $@ =~ m{\$VAR1\s+\=\s+\{\s+'hash'\s+\=>\s+\[\s+'blabla'\s+\]\s+\}\;}s, 'Context error, untraceble: traversed variable');

eval{$template2->render($context);};
print STDERR $@ if $FORCE_OUTPUT;
ok( $@ =~ m{\Qdon't know how continue traversing ARRAY (ARRAY) with step `array`\E}, 'Context error, untraceble, included: error message');
ok( $@ =~ m{\Q./t/tmpl/error_render_variable.txt\E}, 'Context error, untraceble, included: filename');
ok( $@ =~ m{\QLine: 9\E}, 'Context error, untraceble, included: line number');
ok( $@ =~ m{\Qhash.array.0\E}, 'Context error, untraceble, included: traversing path');
ok( $@ =~ m{\$VAR1\s+\=\s+\{\s+'hash'\s+\=>\s+\[\s+'blabla'\s+\]\s+\}\;}s, 'Context error, untraceble, included: traversed variable');
ok( $@ =~ m{./t/tmpl/error_render_variable_include.txt}, 'Context error, untraceble, included: trace');

eval{$template = get_template('error_slice_noarg.txt', 'dirs' => $dirs);};
ok( $@ =~ m{\Qno slicing settings specified\E}, 'Slice without argument: message');
ok( $@ =~ m{\Q./t/tmpl/error_slice_noarg.txt\E}, 'Slice without argument: filename');
ok( $@ =~ m{\QLine: 24\E}, 'Slice without argument: line number');

$template = get_template('error_slice_value.txt', 'dirs' => $dirs);

$context = {
    'somevar' => undef
    , 'slice_param' => '1:2'
};
eval{ $template->render($context); };
$test_head = 'Slice undef value: ';
ok( $@ =~ m{\Qunable to slice undef value\E}, $test_head.'message');
ok( $@ =~ m{\Q./t/tmpl/error_slice_value.txt\E}, $test_head.'filename');
ok( $@ =~ m{\QLine: 36\E}, $test_head.'line number');

$context = {
    'somevar' => 'here I am'
    , 'slice_param' => undef
};

eval{ $template->render($context); };
$test_head = 'Slice with undef parameter: ';
ok( $@ =~ m{\Qslicing format is not defined in current context\E}, $test_head.'message');
ok( $@ =~ m{\Q./t/tmpl/error_slice_value.txt\E}, $test_head.'filename');
ok( $@ =~ m{\QLine: 36\E}, $test_head.'line number');

$context = {
    'somevar' => 'here I am'
    , 'slice_param' => 'bullshit'
};

eval{ $template->render($context); };
$test_head = 'Slice with unrecognized parameter: ';
ok( $@ =~ m{\Qarray slicing option may be specified in one of the following formats:\E}, $test_head.'message');
ok( $@ =~ m{\Q./t/tmpl/error_slice_value.txt\E}, $test_head.'filename');
ok( $@ =~ m{\QLine: 36\E}, $test_head.'line number');

$context = {
    'somevar' => \*STDOUT
    , 'slice_param' => '1..2'
};

eval{ $template->render($context); };
$test_head = 'Slicing GLOB: ';
ok( $@ =~ m{\Qcan slice only HASH, ARRAY or SCALAR values, not GLOB (GLOB)\E}, $test_head.'message');
ok( $@ =~ m{\Q./t/tmpl/error_slice_value.txt\E}, $test_head.'filename');
ok( $@ =~ m{\QLine: 36\E}, $test_head.'line number');

eval{$template = get_template('error_with_params.txt', 'dirs' => $dirs);};
$test_head = 'Wrong with parameter: ';
ok( $@ =~ m{\Qthere is an error in `with` parameters\E}, $test_head.'message');
ok( $@ =~ m{\Q./t/tmpl/error_with_params.txt\E}, $test_head.'filename');
ok( $@ =~ m{\QLine: 21\E}, $test_head.'line number');
ok( $@ =~ m{\Qbla==1 bla1==2\E}, $test_head.'parameter');

# rendering operators
eval{$template = get_template('error_with_params.txt', 'dirs' => $dirs);};
$test_head = 'Wrong with parameter: ';
ok( $@ =~ m{\Qthere is an error in `with` parameters\E}, $test_head.'message');
ok( $@ =~ m{\Q./t/tmpl/error_with_params.txt\E}, $test_head.'filename');
ok( $@ =~ m{\QLine: 21\E}, $test_head.'line number');
ok( $@ =~ m{\Qbla==1 bla1==2\E}, $test_head.'parameter');

$template = get_template('error_in_operator.txt', 'dirs' => $dirs );
$test_head = 'In operator (mistype): ';
eval{$template->render({'var1' => {}, 'var2' => 'test' })};
ok( $@ =~ m{\QDon't know how to check that HASH\E}, $test_head.'message');
ok( $@ =~ m{\Q./t/tmpl/error_in_operator.txt\E}, $test_head.'filename');
ok( $@ =~ m{\QLine: 2\E}, $test_head.'line number');

# numberformat with undef value

# stringformat with undef value
# stringformat with undef format

# minus with types

# mod with unknwon type

# mistyped mul

# hash + mistyped

# pow mistyped

# filters
# no argument to add
# add something to hash
# add to non-array, hash

# center without arguments
# center by negative

# cut filter without arguments
# default filter without arguments

# dictsort without parameters
# dictsort of non-array

# divisable without divider
# first with non-array
# get_digit without digit

# join without separator
# join non-array or non-hash

# last with non-array

# lengthis without length

# random with non-array

# removetags without tags

# reverse with unknown value type

# split without pattern
# split with empty pattern

# sprintf without format
# srpintf with undef format

# truncatechars without max chars

# truncatewords without max words

# unordered list with non-array

# urlizetrunc without chars

# wordwrap without wrapping chars

# tags
# withratio, less than 3 params
# withratio, incorrect params

# url with bad paramaters
# false model path
# no url_source parameter
# mix of positional and hash args
# mix of hash and positional args

# unknown templatetag

# ssi with unparasble parameters
# ssi without ssi_dirs argument
# ssi without file

# traversable target value in regroup
# unparsable parameter value
# unexisted grouper value
# regroup of unknown type

# now without format
# now with false format

# include missing file

# extend without parameter
# multiple extends

# dump without variable

# for multi-test

done_testing();
