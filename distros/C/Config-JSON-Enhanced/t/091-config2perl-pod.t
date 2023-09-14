#!perl

use 5.010;
use strict;
use warnings;

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!
use FindBin;
use Cwd qw/abs_path/;

our $VERSION = '0.02';

use Config::JSON::Enhanced;

# this json is in the module's pod
# Testing it works
my $con = <<'EOJ';
  {
    "long bash script" : ["/usr/bin/bash",
  /* This is a verbatim section */
  <%begin-verbatim-section%>
    pushd . &> /dev/null
    echo "My 'appdir' is \"<%appdir%>\""
    echo "My current dir: " $(echo $PWD) " and bye"
    popd &> /dev/null
  <%end-verbatim-section%>
    ],
    // this is an example of a template variable
    "expected result" : "<% expected-res123 %>"
  }
EOJ

my $json = config2perl({
	'string' => $con,
	'commentstyle' => 'C,CPP',
	'variable-substitutions' => {
		'appdir' => Cwd::abs_path($FindBin::Bin),
		'expected-res123' => 42
	},
});
ok(defined $json, 'config2perl()'." : called and got defined result.");
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");

#use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;
#diag perl2dump($json);

ok(exists($json->{'long bash script'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'long bash script'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'long bash script'}), 'ARRAY', 'config2perl()'." : called and result contains required key and it is an ARRAY.");

my $x = $json->{'long bash script'};
is(scalar(@$x), 2, 'config2perl()'." : returned result contains key 'long bash script' and it is an ARRAY of 2 items.");
unlike($x->[1], qr/<%\s*appdir\s*%>/, 'config2perl()'." : template substitution (1) was correct.");

ok(exists($json->{'expected result'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'expected result'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a scalar.");
unlike($x, qr/<%\s*expected-res123\s*%>/, 'config2perl()'." : template substitution (2) was correct.");
is($x, 42,  'config2perl()'." : template substitution (3) was correct.");

done_testing();
