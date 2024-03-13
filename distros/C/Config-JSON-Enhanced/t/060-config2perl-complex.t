#!perl

use 5.010;
use strict;
use warnings;

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!

use File::Temp qw/tempfile tempdir/;
use File::Spec;

our $VERSION = '0.10';

use Config::JSON::Enhanced;

# check if we can deal with comments
my $jsonstr_C = <<'EOJ';
{
/* gone1 */ "pissoir" /*gone2*/: /* gone 


3  */{ /* gone */
	"foncouir" : /* gone10 */ 12,
  /*abcb*//* gone
 more
	*/"foncouir2" : /* gone10 */ [12,/*gone 15*/13 /* goneind 
13 */
	]
     }
}
EOJ

my $jsonstr_CPP = <<'EOJ';
{
// gone1 */
  "pissoir" : // gone
    { // gone
	"foncouir" : 12, // gone10
  // abcd gone
	"foncouir2" : [12,13 // gone
	]
     }
}
EOJ

my $jsonstr_shell = <<'EOJ';
   # gone 0
{
	# gone1
	"pissoir" : { # gone2
		"foncouir" : 12, #gone 3
 # fodfne # gone gogne # gne
		"foncouir2" : [12, 13] # more gone
		#gon enen
	}
}
EOJ

my $jsonstr_mixed = <<EOJ;
{
	"C" : ${jsonstr_C},
	"CPP" : ${jsonstr_CPP},
	"shell" : ${jsonstr_shell}
}
EOJ

# data for verbatim sections, same as above but with verbatim
my $jsonstr_C_verbatim = <<'EOJ';
{
/* gone1 */ "pissoir" /*gone2*/: /* gone 


3  */{ /* gone */
	"foncouir" : /* gone10 */ 12,
  /*abcb*//* gone
 more
	*/"foncouir2" : /* gone10 */ [12,/*gone 15*/13 /* goneind 
13 */
	]
     },
     "crapper" :  {
                "script" : ["/usr/bin/bash",
/* verbatim sections: will be quoted in " " and remove all newlines
  (optionally followed by spaces) and substituted with a single '\n'   
*/
<%begin-verbatim-section%>


        pushd . &> /dev/null
        echo "My 'appdir' is \"<%appdir%>\""

        echo "My current dir: " $(echo $PWD) " and bye"
        popd &> /dev/null

        echo "NOW My current dir: " $(echo $PWD) " and bye"


<%end-verbatim-section%>  
                        ],
                "description" : "testing verbatim section"
     }
}
EOJ

my $jsonstr_CPP_verbatim = <<'EOJ';
{
// gone1 */
  "pissoir" : // gone
    { // gone
	"foncouir" : 12, // gone10
  // abcd gone
	"foncouir2" : [12,13 // gone
	]
     },
     "crapper" :  {
                "script" : ["/usr/bin/bash",
/* verbatim sections: will be quoted in " " and remove all newlines
  (optionally followed by spaces) and substituted with a single '\n'   
*/
<%begin-verbatim-section%>


        pushd . &> /dev/null
        echo "My 'appdir' is \"<%appdir%>\""

        echo "My current dir: " $(echo $PWD) " and bye"
        popd &> /dev/null

        echo "NOW My current dir: " $(echo $PWD) " and bye"


<%end-verbatim-section%>  
                        ],
                "description" : "testing verbatim section"
     }
}
EOJ

my $jsonstr_shell_verbatim = <<'EOJ';
   # gone 0
{
	# gone1
	"pissoir" : { # gone2
		"foncouir" : 12, #gone 3
 # fodfne # gone gogne # gne
		"foncouir2" : [12, 13] # more gone
		#gon enen
	},
	"crapper" :  {
                "script" : ["/usr/bin/bash",
# verbatim sections: will be quoted in " " and remove all newlines
#  (optionally followed by spaces) and substituted with a single '\n'
<%begin-verbatim-section%>

        pushd . &> /dev/null
        echo "My 'appdir' is \"<%appdir%>\""

        echo "My current dir: " $(echo $PWD) " and bye"

        popd &> /dev/null
        echo "NOW My current dir: " $(echo $PWD) " and bye"


<%end-verbatim-section%>  
                        ],
                "description" : "testing verbatim section"
       }
}
EOJ

my $jsonstr_mixed_verbatim = <<EOJ;
{
	"C" : ${jsonstr_C_verbatim},
	"CPP" : ${jsonstr_CPP_verbatim},
	"shell" : ${jsonstr_shell_verbatim}
}
EOJ

my ($json, $x, $script_content, $tempFH, $tempfile);

# for C style comments:
$json = config2perl({
	'string' => $jsonstr_C,
	'commentstyle' => 'C'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
ok(exists($json->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");

# for CPP style comments:
$json = config2perl({
	'string' => $jsonstr_CPP,
	'commentstyle' => 'CPP'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
ok(exists($json->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");

# for shell-style comments (#):
$json = config2perl({
	'string' => $jsonstr_shell,
	'commentstyle' => 'shell'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
ok(exists($json->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");

# for mix-style comments (#, /**/ and //):
$json = config2perl({
	'string' => $jsonstr_mixed,
	'commentstyle' => 'shell,C,CPP'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");

ok(exists($json->{'C'}), 'config2perl()'." : called and result contains required key.");
ok(exists($json->{'C'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'C'}->{'pissoir'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'C'}->{'pissoir'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined.");
$x = $json->{'C'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'C'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");

ok(exists($json->{'CPP'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'CPP'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'CPP'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'CPP'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'CPP'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'CPP'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");

ok(exists($json->{'shell'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'shell'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'shell'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}->{'pissoir'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'shell'}->{'pissoir'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined and it is a HASH.");
$x = $json->{'shell'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'shell'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");

# for C style comments with verbatim sections:
$json = config2perl({
	'string' => $jsonstr_C_verbatim,
	'commentstyle' => 'C'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
ok(exists($json->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
# verbatim checks
$x = $json->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
# JSON string should not contain newlines but \n (escaped somehow)
# but it failes when we replace realnewlines below with \n
# so:
$script_content = << 'EOC';
pushd . &> /dev/null
echo "My 'appdir' is \"<%appdir%>\""
echo "My current dir: " $(echo $PWD) " and bye"
popd &> /dev/null
echo "NOW My current dir: " $(echo $PWD) " and bye"
EOC
chomp($script_content);
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and second item contains required value.");

$json = config2perl({
	'string' => $jsonstr_CPP_verbatim,
	'commentstyle' => 'CPP'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
ok(exists($json->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
# verbatim checks
$x = $json->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
# JSON string should not contain newlines but \n (escaped somehow)
# but it failes when we replace realnewlines below with \n
# so:
$script_content = << 'EOC';
pushd . &> /dev/null
echo "My 'appdir' is \"<%appdir%>\""
echo "My current dir: " $(echo $PWD) " and bye"
popd &> /dev/null
echo "NOW My current dir: " $(echo $PWD) " and bye"
EOC
chomp($script_content);
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and second item contains required value.");

# for shell-style comments (#) with verbatim sections:
$json = config2perl({
	'string' => $jsonstr_shell_verbatim,
	'commentstyle' => 'shell'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
ok(exists($json->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

# for mix-style comments (#./**/.//) with verbatim sections:
$json = config2perl({
	'string' => $jsonstr_mixed_verbatim,
	'commentstyle' => 'shell,CPP,C'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");

ok(exists($json->{'C'}), 'config2perl()'." : called and result contains required key.");
ok(exists($json->{'C'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'C'}->{'pissoir'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'C'}->{'pissoir'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined.");
$x = $json->{'C'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'C'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'C'}->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'C'}->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

ok(exists($json->{'CPP'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'CPP'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'CPP'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'CPP'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'CPP'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'CPP'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'CPP'}->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'CPP'}->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

ok(exists($json->{'shell'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'shell'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'shell'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}->{'pissoir'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'shell'}->{'pissoir'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined and it is a HASH.");
$x = $json->{'shell'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'shell'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'shell'}->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'shell'}->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

# now do this last case (of mixed, verbatim) but save it to a file and use 'filename' param
($tempFH, $tempfile) = File::Temp::tempfile(UNLINK => 1);
print $tempFH $jsonstr_mixed_verbatim;
close($tempFH);

ok(-f $tempfile, "config file exists ($tempfile).") or BAIL_OUT;
$json = config2perl({
	'filename' => $tempfile,
	'commentstyle' => 'shell, C, CPP'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");

ok(exists($json->{'C'}), 'config2perl()'." : called and result contains required key.");
ok(exists($json->{'C'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'C'}->{'pissoir'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'C'}->{'pissoir'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined.");
$x = $json->{'C'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'C'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'C'}->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'C'}->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

ok(exists($json->{'CPP'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'CPP'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'CPP'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'CPP'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'CPP'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'CPP'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'CPP'}->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'CPP'}->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

ok(exists($json->{'shell'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'shell'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'shell'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}->{'pissoir'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'shell'}->{'pissoir'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined and it is a HASH.");
$x = $json->{'shell'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'shell'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'shell'}->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'shell'}->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

# now do this last case (of mixed, verbatim) but save it to a file and use 'filehandle' param
ok(-f $tempfile, "config file exists ($tempfile).") or BAIL_OUT; # still there?
ok(open($tempFH, '<', $tempfile), "tempfile '$tempfile' opened again for reading.");
$json = config2perl({
	'filehandle' => $tempFH,
	'commentstyle' => 'shell, C, CPP'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
close($tempFH);

ok(exists($json->{'C'}), 'config2perl()'." : called and result contains required key.");
ok(exists($json->{'C'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'C'}->{'pissoir'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'C'}->{'pissoir'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined.");
$x = $json->{'C'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'C'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'C'}->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'C'}->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

ok(exists($json->{'CPP'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'CPP'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'CPP'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'CPP'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'CPP'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'CPP'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'CPP'}->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'CPP'}->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

ok(exists($json->{'shell'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'shell'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'shell'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}->{'pissoir'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'shell'}->{'pissoir'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined and it is a HASH.");
$x = $json->{'shell'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'shell'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'shell'}->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'shell'}->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");


############################################################
# now write the JSON content to file and ask to read from it
############################################################

# for C style comments:
my $tmpdir = tempdir(CLEANUP => 1);
ok(-d $tmpdir, "Temp dir '$tmpdir' created.") or BAIL_OUT;
my $infile = File::Spec->catdir($tmpdir, 'complex.ejson');
my $FH;

ok(open($FH, '>:utf8', $infile), "Opened tempfile '$infile' for writing test JSON.") or BAIL_OUT("no ".$!);
print $FH $jsonstr_C; close $FH;
$json = config2perl({
	'filename' => $infile,
	'commentstyle' => 'C'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
ok(exists($json->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");

# for CPP style comments:
ok(open($FH, '>:utf8', $infile), "Opened tempfile '$infile' for writing test JSON.") or BAIL_OUT("no ".$!);
print $FH $jsonstr_CPP; close $FH;
$json = config2perl({
	'filename' => $infile,
	'commentstyle' => 'CPP'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
ok(exists($json->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");

# for shell-style comments (#):
ok(open($FH, '>:utf8', $infile), "Opened tempfile '$infile' for writing test JSON.") or BAIL_OUT("no ".$!);
print $FH $jsonstr_shell; close $FH;
$json = config2perl({
	'filename' => $infile,
	'commentstyle' => 'shell'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
ok(exists($json->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");

# for mix-style comments (#, /**/ and //):
ok(open($FH, '>:utf8', $infile), "Opened tempfile '$infile' for writing test JSON.") or BAIL_OUT("no ".$!);
print $FH $jsonstr_mixed; close $FH;
$json = config2perl({
	'filename' => $infile,
	'commentstyle' => 'shell,C,CPP'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");

ok(exists($json->{'C'}), 'config2perl()'." : called and result contains required key.");
ok(exists($json->{'C'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'C'}->{'pissoir'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'C'}->{'pissoir'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined.");
$x = $json->{'C'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'C'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");

ok(exists($json->{'CPP'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'CPP'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'CPP'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'CPP'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'CPP'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'CPP'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");

ok(exists($json->{'shell'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'shell'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'shell'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}->{'pissoir'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'shell'}->{'pissoir'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined and it is a HASH.");
$x = $json->{'shell'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'shell'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");

# for C style comments with verbatim sections:
ok(open($FH, '>:utf8', $infile), "Opened tempfile '$infile' for writing test JSON.") or BAIL_OUT("no ".$!);
print $FH $jsonstr_C_verbatim; close $FH;
$json = config2perl({
	'filename' => $infile,
	'commentstyle' => 'C'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
ok(exists($json->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
# verbatim checks
$x = $json->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
# JSON string should not contain newlines but \n (escaped somehow)
# but it failes when we replace realnewlines below with \n
# so:
$script_content = << 'EOC';
pushd . &> /dev/null
echo "My 'appdir' is \"<%appdir%>\""
echo "My current dir: " $(echo $PWD) " and bye"
popd &> /dev/null
echo "NOW My current dir: " $(echo $PWD) " and bye"
EOC
chomp($script_content);
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and second item contains required value.");

ok(open($FH, '>:utf8', $infile), "Opened tempfile '$infile' for writing test JSON.") or BAIL_OUT("no ".$!);
print $FH $jsonstr_CPP_verbatim; close $FH;
$json = config2perl({
	'filename' => $infile,
	'commentstyle' => 'CPP'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
ok(exists($json->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
# verbatim checks
$x = $json->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
# JSON string should not contain newlines but \n (escaped somehow)
# but it failes when we replace realnewlines below with \n
# so:
$script_content = << 'EOC';
pushd . &> /dev/null
echo "My 'appdir' is \"<%appdir%>\""
echo "My current dir: " $(echo $PWD) " and bye"
popd &> /dev/null
echo "NOW My current dir: " $(echo $PWD) " and bye"
EOC
chomp($script_content);
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and second item contains required value.");

# for shell-style comments (#) with verbatim sections:
ok(open($FH, '>:utf8', $infile), "Opened tempfile '$infile' for writing test JSON.") or BAIL_OUT("no ".$!);
print $FH $jsonstr_shell_verbatim; close $FH;
$json = config2perl({
	'filename' => $infile,
	'commentstyle' => 'shell'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
ok(exists($json->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

# for mix-style comments (#./**/.//) with verbatim sections:
ok(open($FH, '>:utf8', $infile), "Opened tempfile '$infile' for writing test JSON.") or BAIL_OUT("no ".$!);
print $FH $jsonstr_mixed_verbatim; close $FH;
$json = config2perl({
	'filename' => $infile,
	'commentstyle' => 'shell,CPP,C'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");

ok(exists($json->{'C'}), 'config2perl()'." : called and result contains required key.");
ok(exists($json->{'C'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'C'}->{'pissoir'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'C'}->{'pissoir'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined.");
$x = $json->{'C'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'C'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'C'}->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'C'}->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

ok(exists($json->{'CPP'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'CPP'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'CPP'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'CPP'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'CPP'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'CPP'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'CPP'}->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'CPP'}->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

ok(exists($json->{'shell'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'shell'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'shell'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}->{'pissoir'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'shell'}->{'pissoir'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined and it is a HASH.");
$x = $json->{'shell'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'shell'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'shell'}->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'shell'}->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

# now do this last case (of mixed, verbatim) but save it to a file and use 'filename' param
($tempFH, $tempfile) = File::Temp::tempfile(UNLINK => 1);
print $tempFH $jsonstr_mixed_verbatim;
close($tempFH);

ok(-f $tempfile, "config file exists ($tempfile).") or BAIL_OUT;
$json = config2perl({
	'filename' => $tempfile,
	'commentstyle' => 'shell, C, CPP'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");

ok(exists($json->{'C'}), 'config2perl()'." : called and result contains required key.");
ok(exists($json->{'C'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'C'}->{'pissoir'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'C'}->{'pissoir'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined.");
$x = $json->{'C'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'C'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'C'}->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'C'}->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

ok(exists($json->{'CPP'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'CPP'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'CPP'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'CPP'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'CPP'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'CPP'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'CPP'}->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'CPP'}->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

ok(exists($json->{'shell'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'shell'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'shell'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}->{'pissoir'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'shell'}->{'pissoir'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined and it is a HASH.");
$x = $json->{'shell'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'shell'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'shell'}->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'shell'}->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

# now do this last case (of mixed, verbatim) but save it to a file and use 'filehandle' param
ok(-f $tempfile, "config file exists ($tempfile).") or BAIL_OUT; # still there?
ok(open($tempFH, '<', $tempfile), "tempfile '$tempfile' opened again for reading.");
$json = config2perl({
	'filehandle' => $tempFH,
	'commentstyle' => 'shell, C, CPP'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
close($tempFH);

ok(exists($json->{'C'}), 'config2perl()'." : called and result contains required key.");
ok(exists($json->{'C'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'C'}->{'pissoir'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'C'}->{'pissoir'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined.");
$x = $json->{'C'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'C'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'C'}->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'C'}->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

ok(exists($json->{'CPP'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'CPP'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'CPP'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'CPP'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'CPP'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'CPP'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'CPP'}->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'CPP'}->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

ok(exists($json->{'shell'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'shell'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'shell'}->{'pissoir'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}->{'pissoir'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'shell'}->{'pissoir'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined and it is a HASH.");
$x = $json->{'shell'}->{'pissoir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'foncouir'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'foncouir'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'shell'}->{'pissoir'}->{'foncouir2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'shell'}->{'crapper'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'shell'}->{'crapper'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

done_testing();
