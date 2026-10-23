use strict;
use warnings;
use Test::Most;
use Test::Exception;

use App::Actions::Expression;
use JSON::PP ();

my $expression = App::Actions::Expression->new;

my $context = {
    matrix => {
        perl => '5.38',
        os   => 'ubuntu-latest',
    },
    runner => { os => 'Linux', arch => 'X64' },
    env    => { FOO => 'bar' },
    steps  => {
        'perl-version' => {
            outputs => { version => '5.38.0' },
        },
    },
    github => {
        event_name => 'push',
        repository => 'njh/CGI-Info',
    },
};

my $success = { success => 1, failure => 0, cancelled => 0 };
my $failure = { success => 0, failure => 1, cancelled => 0 };

is($expression->evaluate('42', $context), 42, 'number literal');
is($expression->evaluate("'hello'", $context), 'hello', 'string literal');
is($expression->evaluate('true', $context), 1, 'true literal');
is($expression->evaluate('false', $context), 0, 'false literal');
ok(!defined $expression->evaluate('null', $context), 'null literal');

is($expression->evaluate('matrix.perl', $context), '5.38', 'property access');
is($expression->evaluate(q{matrix['perl']}, $context), '5.38', 'index access');
is($expression->evaluate('matrix.PERL', $context), '5.38', 'property lookup is case-insensitive');
is($expression->evaluate('steps.perl-version.outputs.version', $context), '5.38.0',
    'hyphenated property names');
is($expression->evaluate('github.event_name', $context), 'push', 'nested context');

is($expression->evaluate(q{matrix.perl == '5.38'}, $context), 1, 'equality');
is($expression->evaluate(q{matrix.perl != '5.40'}, $context), 1, 'inequality');
is($expression->evaluate(q{runner.os == 'Windows'}, $context), 0, 'false comparison');
is($expression->evaluate(q{5 < 6 && 6 <= 6}, $context), 1, 'relational operators');

is($expression->evaluate(q{!false}, $context), 1, 'logical not');
is($expression->evaluate(q{true && 'yes'}, $context), 'yes', 'logical and returns value');
is($expression->evaluate(q{false || 'fallback'}, $context), 'fallback', 'logical or returns value');
is($expression->evaluate(q{(matrix.perl == '5.38' && 'yes') || 'no'}, $context), 'yes',
    'parentheses and value-returning operators');

is($expression->evaluate(q{contains(matrix.os, 'ubuntu')}, $context), 1, 'contains string');
is($expression->evaluate(q{contains(fromJSON('["a","b"]'), 'b')}, $context), 1,
    'contains array');
is($expression->evaluate(q{startsWith(matrix.os, 'UBUNTU')}, $context), 1,
    'startsWith is case-insensitive');
is($expression->evaluate(q{endsWith(matrix.os, 'latest')}, $context), 1, 'endsWith');
is($expression->evaluate(q{format('{0}-{1}', matrix.perl, matrix.os)}, $context),
    '5.38-ubuntu-latest', 'format');
is($expression->evaluate(q{join(fromJSON('["a","b"]'), ':')}, $context), 'a:b', 'join');
is($expression->evaluate(q{fromJSON('{"a":1}').a}, $context), 1, 'fromJSON and property');
is($expression->evaluate(q{toJSON(fromJSON('{"a":1}'))}, $context), '{"a":1}', 'toJSON');

is($expression->evaluate('success()', $context, $success), 1, 'success()');
is($expression->evaluate('failure()', $context, $failure), 1, 'failure()');
is($expression->evaluate('always()', $context, $failure), 1, 'always()');
is($expression->evaluate('cancelled()', $context, $success), 0, 'cancelled()');

is($expression->interpolate(
    'Perl ${{ matrix.perl }} on ${{ runner.os }}', $context,
), 'Perl 5.38 on Linux', 'interpolate multiple expressions');
is($expression->interpolate('No expressions', $context), 'No expressions',
    'interpolate leaves plain text alone');
is($expression->interpolate_known(
    'Perl ${{ matrix.perl }} on ${{ github.ref_name }}', $context,
), 'Perl 5.38 on ${{ github.ref_name }}',
    'interpolate_known resolves what it can and leaves the rest as written');
is($expression->interpolate_known('${{ steps.perl-version.outputs.version }}', $context),
    '5.38.0', 'interpolate_known resolves a known step output');
is($expression->interpolate_known(
    '${{ steps.missing.outputs.version }}-${{ matrix.perl }}', $context,
), '${{ steps.missing.outputs.version }}-5.38',
    'interpolate_known leaves an unknown value in place of an empty string');
is($expression->interpolate('Perl ${{ matrix.perl }} on ${{ github.ref_name }}', $context),
    'Perl 5.38 on ', 'interpolate still turns an unknown value into an empty string');
is($expression->condition(q{${{ matrix.perl == '5.38' }}}, $context, $success), 1,
    'condition strips expression braces');
is($expression->condition(q{runner.os != 'Windows'}, $context, $success), 1,
    'bare condition');
is($expression->condition('always()', $context, $failure), 1, 'always condition');
is($expression->condition('success()', $context, $failure), 0, 'success condition fails');
is($expression->condition('failure()', $context, $failure), 1, 'failure condition');
is($expression->condition('', $context, $success), 1, 'empty condition is true');
is($expression->condition(0, $context, $success), 0, 'numeric false condition');

throws_ok { $expression->evaluate('unknownFunction()', $context) }
    qr/Unknown function/,
    'unknown function is rejected';
throws_ok { $expression->evaluate(q{hashFiles('**/*')}, $context) }
    qr/not supported/,
    'hashFiles is rejected';
throws_ok { $expression->evaluate("'unterminated", $context) }
    qr/Unterminated string/,
    'unterminated string is rejected';
throws_ok { $expression->interpolate('${{ matrix.perl', $context) }
    qr/Unclosed expression/,
    'unclosed interpolation is rejected';
throws_ok { $expression->evaluate('', $context) }
    qr/empty expression/,
    'empty expression is rejected';

# Booleans from JSON compare as numbers and print as words, as on GitHub.
{
    my $json = { flag => JSON::PP::false() };
    ok($expression->condition('flag == false', $json), 'a JSON false equals the literal false');
    ok(!$expression->condition('flag', $json), 'and is falsy');
    is($expression->interpolate('${{ flag }}', $json), 'false', 'and interpolates as false');
}

done_testing;
