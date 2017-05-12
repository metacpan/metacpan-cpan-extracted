use Test::More tests => 4;

use strict;
use warnings;
use utf8;

use Test::MockObject::Extends;
use Test::MockObject;

use_ok('Catalyst::Plugin::Params::Demoronize');

my $c		= new Test::MockObject::Extends 'Catalyst::Plugin::Params::Demoronize';
my $req		= new Test::MockObject;
my $params	= {};

$c->set_always(req => $req);
$c->set_always(config => { demoronize => {replace_unicode => 1} });
$req->set_always(params => $params);

# pasted smart quotes from:
# http://office.microsoft.com/en-gb/word/HA101732421033.aspx
$params->{string} = q{pasted “smart quotes” string};
$c->prepare_parameters;
is_deeply($params, { string => q{pasted "smart quotes" string} }, 'pasted smart quotes');

# unicode smart quotes from:
# http://office.microsoft.com/en-gb/word/HA101732421033.aspx
$params->{string} = qq<unicoded \x{201c}smart quotes\x{201d} string>;
$c->prepare_parameters;
is_deeply($params, { string => q{unicoded "smart quotes" string} }, 'unicoded smart quotes');

# pasted phrase from
# http://office.microsoft.com/en-gb/word/HA101732421033.aspx
$params->{string} = qq<Click the AutoFormat As You Type tab, and under Replace as you type, select or clear the "Straight quotes" with “smart quotes” check box.>;
$c->prepare_parameters;
is_deeply($params, { string => q{Click the AutoFormat As You Type tab, and under Replace as you type, select or clear the "Straight quotes" with "smart quotes" check box.} }, 'pasted phrase from Microsoft site');

__DATA__
You see, state of the art Microsoft Office applications sport a nifty
feature called smart quotes.  (Rule of thumb  every time Microsoft
use the word smart, be on the lookout for something dumb).  This feature
is on by default in both Word and PowerPoint and can be disabled only by finding
the little box buried among the dozens of bewildering option panels these
products contain.  If enabled, and you type the string Halt, he
cried, this is the police!, smart quotes transforms the
ASCII quote characters automatically into the incompatible Microsoft opening and
closing quotes.

