#!perl

#################################################################
#### NOTE: this test is expected to FAIL, all is well ###########
#################################################################

use 5.010;
use strict;
use warnings;

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!
use FindBin;
use Cwd qw/abs_path/;

our $VERSION = '0.10';

use Config::JSON::Enhanced;

# this should fail because of not closing the verbatim section
my $con = <<'EOJ';
  {
    "long bash script" : ["/usr/bin/bash",
  /* This is a verbatim section */
  <%begin-verbatim-section%>
    pushd . &> /dev/null
    echo "My 'appdir' is \"<%appdir%>\""
    echo "My current dir: " $(echo $PWD) " and bye"
    popd &> /dev/null
    ],
    // this is an example of a template variable
    "expected result" : "<% expected-res123 %>"
  }
EOJ

# this must return undef, it is expected to fail!
my $json = config2perl({
	'string' => $con,
	'commentstyle' => 'C,CPP',
	'variable-substitutions' => {
		'appdir' => Cwd::abs_path($FindBin::Bin),
		'expected-res123' => 42
	},
});
ok( ! defined $json, 'config2perl()'." : called and got failed result AS EXPECTED.");

done_testing();
