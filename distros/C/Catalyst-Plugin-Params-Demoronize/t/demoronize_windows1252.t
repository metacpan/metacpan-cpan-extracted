use Test::More tests => 5;

use strict;
use warnings;

use Test::MockObject::Extends;
use Test::MockObject;

use_ok('Catalyst::Plugin::Params::Demoronize');

my $c		= new Test::MockObject::Extends 'Catalyst::Plugin::Params::Demoronize';
my $req		= new Test::MockObject;
my $params	= {};

$c->set_always(req => $req);
$c->set_always(config => {});
$req->set_always(params => $params);

# PASS 1

$c->prepare_parameters;
is_deeply($params, {}, 'empty parameter hashref');

# PASS 2

$params->{string} = '"pan galactic gargle blaster" \'ZOOP!\'  @$% \'';

$c->prepare_parameters;
is_deeply($params, { string => '"pan galactic gargle blaster" \'ZOOP!\'  @$% \'' }, 'parameter "string" unchanged');

# PASS 3

$params->{string} = join ' ', map { chomp && $_ } <DATA>;

$c->prepare_parameters;

my $string =	qq|You see, "state of the art" Microsoft Office applications | .
				qq|sport a nifty feature called "smart quotes".  (Rule of | .
				qq|thumb - every time Microsoft use the word "smart", be on | .
				qq|the lookout for something dumb).  This feature is on by | .
				qq|default in both Word and PowerPoint and can be disabled | .
				qq|only by finding the little box buried among the dozens | .
				qq|of bewildering option panels these products contain.  If | .
				qq|enabled, and you type the string '"Halt," he cried, | .
				qq|"this is the police!"', "smart quotes" transforms the | .
				qq|ASCII quote characters automatically into the | .
				qq|incompatible Microsoft opening and closing quotes.|;

is_deeply($params, { string => $string }, 'string correctly demoronized');

# PASS 4

$params->{array} = [ 'some text', 'SOME "OTHER" TEXT', '2 • 2 ‹ 5' ];

$c->prepare_parameters;

is_deeply($params, { string => $string, array => [ 'some text', 'SOME "OTHER" TEXT', '2 * 2 < 5' ] }, 'string correctly demoronized');

__DATA__
You see, “state of the art” Microsoft Office applications sport a nifty
feature called “smart quotes”.  (Rule of thumb – every time Microsoft
use the word “smart”, be on the lookout for something dumb).  This feature
is on by default in both Word and PowerPoint and can be disabled only by finding
the little box buried among the dozens of bewildering option panels these
products contain.  If enabled, and you type the string ‘“Halt,” he
cried, “this is the police!”’, “smart quotes” transforms the
ASCII quote characters automatically into the incompatible Microsoft opening and
closing quotes.
