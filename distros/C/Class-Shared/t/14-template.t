use strict;
use warnings;

use Test::More;
use Test::Needs;

# The Template Toolkit is not a dependency of Class::Shared.  It is a good
# example of what the backend is for, because it is big and every site that
# uses it loads its own copy, so it is used when it is installed and skipped
# when it is not.
use Test::Needs 'Template';

use Class::Shared ();

BEGIN {
	test_needs 'Test::Permissions';

	plan skip_all => 'a backend needs unix sockets in an owner-only directory, '
		. 'which this perl cannot provide (Class::Shared is Unix-only)'
		unless Class::Shared::_has_unix_sockets()
			&& Test::Permissions::can_revoke_create();
}

use File::Temp qw(tempdir);
use lib 't/lib';

use Class::Shared::Frontend;
use Shared::Page;

my $dir = tempdir(CLEANUP => 1);

my $shared = Class::Shared::Frontend->new('Shared::Page', dir => $dir);

# The same class, used here in this process.  Whatever it answers is what a
# frontend must answer: the backend adds no behaviour of its own.
my $direct = Shared::Page->new;

is($shared->shared_status->{classes}[0], 'Shared::Page', 'the backend loaded the class');

# --------------------------------------------- the same answers as the class

my $people = [
	{ name => 'Ada',   score => 36 },
	{ name => 'Grace', score => 42 },
	{ name => "Z\x{fc}rich \x{263A}", score => 7 },
];

for my $case (
	['plain text',                  'no placeholders',                                  {}],
	['a variable',                  'Hello [% name %]!',                                { name => 'Nigel' }],
	['a number',                    'You have [% n %] items',                           { n => 3 }],
	['a nested value',              '[% user.address.city %]',                          { user => { address => { city => 'Ramsgate' } } }],
	['a list, looped',              '[% FOREACH p IN people %][% p.name %]=[% p.score %];[% END %]', { people => $people }],
	['a condition',                 '[% IF n > 1 %]many[% ELSE %]one[% END %]',         { n => 5 }],
	['a filter',                    '[% text | html %]',                                { text => '<b>"x" & y</b>' }],
	['a missing variable',          '[[% nothing %]]',                                  {}],
	['text that is not ASCII',      'caf[% e %] [% smile %]',                           { e => "\x{e9}", smile => "\x{263A}" }],
	['a virtual method',            '[% names.sort.join(",") %]',                       { names => [qw(c a b)] }],
	['no variables at all',         'just text',                                        undef],
) {
	my ($name, $template, $vars) = @{$case};

	my $expected = $direct->render($template, $vars);
	my $got = $shared->render($template, $vars);

	is($got, $expected, "$name: the same as calling the class directly");
}

# ------------------------------------------------- spot checks on the values

# These pin the output, so that "the same as the class" is not "the same wrong answer".
is($shared->render('Hello [% name %]!', { name => 'Nigel' }), 'Hello Nigel!', 'a variable is filled in');
is($shared->render('[% text | html %]', { text => '<b>' }), '&lt;b&gt;', 'a filter is applied');
is($shared->render('caf[% e %]', { e => "\x{e9}" }), "caf\x{e9}", 'text that is not ASCII comes back whole');

# ------------------------------------------------------ a larger reply

# A page is bigger than a greeting.  This is a few hundred kilobytes of output.
{
	my $template = '[% FOREACH i IN rows %]<tr><td>[% i %]</td><td>row number [% i %] of many</td></tr>' . "\n" . '[% END %]';
	my $vars = { rows => [1 .. 8000] };

	my $expected = $direct->render($template, $vars);

	cmp_ok(length $expected, '>', 300_000, 'the page is large');
	is($shared->render($template, $vars), $expected, 'and it comes back unchanged');
}

# -------------------------------------------------------------- errors

# The error is the class's own, and the connection stays usable afterwards.
{
	my $lost = eval { $shared->render('[% IF %]'); 1 };

	ok(!$lost, 'a template with a syntax error is an error');
	like($@, qr/parse error/i, 'and the error is the class\'s own');

	is($shared->render('still [% word %]', { word => 'working' }), 'still working',
		'the frontend is still usable afterwards');
}

# ------------------------------------------- a reference you pass is a copy

# This is why the class has a render method.  Template's own process method
# writes into a variable it is given a reference to, and a reference that is
# sent to the backend is a copy: the backend fills in its copy, and the
# caller's variable stays empty.  The call itself works, which is what makes it
# easy to get wrong.
{
	my $text;
	my $worked = $shared->process(\'Hello [% name %]!', { name => 'Nigel' }, \$text);

	ok($worked, 'process reports that it worked');
	is($text, undef, 'but the variable passed to it is not filled in');

	my $here;
	$direct->process(\'Hello [% name %]!', { name => 'Nigel' }, \$here);

	is($here, 'Hello Nigel!', 'as it is when the class is used in this process');
}

# --------------------------------------- each frontend has its own object

# An object is made for each frontend, so settings given to one are not seen by another.
{
	my $trimming = Class::Shared::Frontend->new('Shared::Page', dir => $dir, ctor => [TRIM => 1]);

	my $template = "\n  padded  \n";

	is($trimming->render($template), 'padded', 'a frontend made with TRIM => 1 trims its output');
	is($shared->render($template), $template, 'and another frontend of the same class does not');
	is($shared->shared_status->{objects}, 2, 'one object is held for each frontend');
	is($trimming->shared_pid, $shared->shared_pid, 'in the same backend');
}

$shared->shared_shutdown;

ok(!-S $shared->shared_socket_path, 'the backend removed its socket on shutdown');

done_testing();
