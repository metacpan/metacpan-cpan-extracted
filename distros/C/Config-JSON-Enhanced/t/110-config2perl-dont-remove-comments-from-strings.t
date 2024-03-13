#!perl

use 5.010;
use strict;
use warnings;

use Test::More;
use File::Temp qw/tempfile/;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

our $VERSION = '0.10';

use Config::JSON::Enhanced;

# check if we can deal with comments
my $jsonstr_C = <<'EOJ';
{
/* gone1 */ "/*comment1*/κατούρ/*comment2*/" /*gone2*/: /* gone 


3  */{ /* gone */
	"φονο/*comment1*/κατούρ/*comment2*/" : /* gone10 */ 12,
  /*abcb*//* gone
 more
	*/"φονο/*comment1*/κατούρ/*comment2*/2" : /* gone10 */ [12,/*gone 15*/13 /* goneind 
13 */
	]
     }
}
EOJ

my $jsonstr_CPP = <<'EOJ';
{
// gone1 */
  "/*comment1*/κατούρ/*comment2*/" : // gone
    { // gone
	"φονο/*comment1*/κατούρ/*comment2*/" : 12, // gone10
  // abcd gone
	"φονο/*comment1*/κατούρ/*comment2*/2" : [12,13 // gone
	]
     }
}
EOJ

my $jsonstr_shell = <<'EOJ';
   # gone 0
{
	# gone1
	"/*comment1*/κατούρ/*comment2*/" : { # gone2
		"φονο/*comment1*/κατούρ/*comment2*/" : 12, #gone 3
 # fodfne # gone gogne # gne
		"φονο/*comment1*/κατούρ/*comment2*/2" : [12, 13] # more gone
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
/* gone1 */ "/*comment1*/κατούρ/*comment2*/" /*gone2*/: /* gone 


3  */{ /* gone */
	"φονο/*comment1*/κατούρ/*comment2*/" : /* gone10 */ 12,
  /*abcb*//* gone
 more
	*/"φονο/*comment1*/κατούρ/*comment2*/2" : /* gone10 */ [12,/*gone 15*/13 /* goneind 
13 */
	]
     },
     "/*comment5*/κα/*comment6*/ούρ#comment7" :  {
                "script" : ["/usr/bin/bash",
/* verbatim sections: will be quoted in " " and remove all newlines
  (optionally followed by spaces) and substituted with a single '\n'   
*/
<%begin-verbatim-section%>

        # remember current dir
        pushd . &> /dev/null
        echo "My 'appdir' is \"<%appdir%>\""

        echo "My current dir: " $(echo $PWD) " and bye"
        # go back to the initial dir
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
  "/*comment1*/κατούρ/*comment2*/" : // gone
    { // gone
	"φονο/*comment1*/κατούρ/*comment2*/" : 12, // gone10
  // abcd gone
	"φονο/*comment1*/κατούρ/*comment2*/2" : [12,13 // gone
	]
     },
     "/*comment5*/κα/*comment6*/ούρ#comment7" :  {
                "script" : ["/usr/bin/bash",
/* verbatim sections: will be quoted in " " and remove all newlines
  (optionally followed by spaces) and substituted with a single '\n'   
*/
<%begin-verbatim-section%>


        # remember current dir
        pushd . &> /dev/null
        echo "My 'appdir' is \"<%appdir%>\""

        echo "My current dir: " $(echo $PWD) " and bye"
        # go back to the initial dir
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
	"/*comment1*/κατούρ/*comment2*/" : { # gone2
		"φονο/*comment1*/κατούρ/*comment2*/" : 12, #gone 3
 # fodfne # gone gogne # gne
		"φονο/*comment1*/κατούρ/*comment2*/2" : [12, 13] # more gone
		#gon enen
	},
	"/*comment5*/κα/*comment6*/ούρ#comment7" :  {
                "script" : ["/usr/bin/bash",
# verbatim sections: will be quoted in " " and remove all newlines
#  (optionally followed by spaces) and substituted with a single '\n'
<%begin-verbatim-section%>

        # remember current dir
        pushd . &> /dev/null
        echo "My 'appdir' is \"<%appdir%>\""

        echo "My current dir: " $(echo $PWD) " and bye"

        # go back to the initial dir
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
	'commentstyle' => 'C',
	'remove-comments-in-strings' => 0,
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
ok(exists($json->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'φονο/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'φονο/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'/*comment1*/κατούρ/*comment2*/'}->{'φονο/*comment1*/κατούρ/*comment2*/2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");

# for CPP style comments:
$json = config2perl({
	'string' => $jsonstr_CPP,
	'remove-comments-in-strings' => 0,
	'commentstyle' => 'CPP'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
ok(exists($json->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'φονο/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'φονο/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'/*comment1*/κατούρ/*comment2*/'}->{'φονο/*comment1*/κατούρ/*comment2*/2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");

# for shell-style comments (#):
$json = config2perl({
	'string' => $jsonstr_shell,
	'remove-comments-in-strings' => 0,
	'commentstyle' => 'shell'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
ok(exists($json->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'φονο/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'φονο/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'/*comment1*/κατούρ/*comment2*/'}->{'φονο/*comment1*/κατούρ/*comment2*/2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");

# for mix-style comments (#, /**/ and //):
$json = config2perl({
	'string' => $jsonstr_mixed,
	'remove-comments-in-strings' => 0,
	'commentstyle' => 'shell,C,CPP'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");

ok(exists($json->{'C'}), 'config2perl()'." : called and result contains required key.");
ok(exists($json->{'C'}->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'C'}->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'C'}->{'/*comment1*/κατούρ/*comment2*/'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined.");
$x = $json->{'C'}->{'/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'φονο/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'φονο/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'C'}->{'/*comment1*/κατούρ/*comment2*/'}->{'φονο/*comment1*/κατούρ/*comment2*/2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");

ok(exists($json->{'CPP'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'CPP'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'CPP'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'CPP'}->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'CPP'}->{'/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'φονο/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'φονο/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'CPP'}->{'/*comment1*/κατούρ/*comment2*/'}->{'φονο/*comment1*/κατούρ/*comment2*/2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");

ok(exists($json->{'shell'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'shell'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'shell'}->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'shell'}->{'/*comment1*/κατούρ/*comment2*/'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined and it is a HASH.");
$x = $json->{'shell'}->{'/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'φονο/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'φονο/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'shell'}->{'/*comment1*/κατούρ/*comment2*/'}->{'φονο/*comment1*/κατούρ/*comment2*/2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");

# for C style comments with verbatim sections:
$json = config2perl({
	'string' => $jsonstr_C_verbatim,
	'remove-comments-in-strings' => 0,
	'commentstyle' => 'C'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
ok(exists($json->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'φονο/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'φονο/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
# verbatim checks
$x = $json->{'/*comment5*/κα/*comment6*/ούρ#comment7'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'/*comment5*/κα/*comment6*/ούρ#comment7'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
# JSON string should not contain newlines but \n (escaped somehow)
# but it failes when we replace realnewlines below with \n
# so:
$script_content = << 'EOC';
# remember current dir
pushd . &> /dev/null
echo "My 'appdir' is \"<%appdir%>\""
echo "My current dir: " $(echo $PWD) " and bye"
# go back to the initial dir
popd &> /dev/null
echo "NOW My current dir: " $(echo $PWD) " and bye"
EOC
chomp($script_content);
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and second item contains required value.");

$json = config2perl({
	'string' => $jsonstr_CPP_verbatim,
	'remove-comments-in-strings' => 0,
	'commentstyle' => 'CPP'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
ok(exists($json->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'φονο/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'φονο/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
# verbatim checks
$x = $json->{'/*comment5*/κα/*comment6*/ούρ#comment7'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'/*comment5*/κα/*comment6*/ούρ#comment7'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
# JSON string should not contain newlines but \n (escaped somehow)
# but it failes when we replace realnewlines below with \n
# so:
$script_content = << 'EOC';
# remember current dir
pushd . &> /dev/null
echo "My 'appdir' is \"<%appdir%>\""
echo "My current dir: " $(echo $PWD) " and bye"
# go back to the initial dir
popd &> /dev/null
echo "NOW My current dir: " $(echo $PWD) " and bye"
EOC
chomp($script_content);
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and second item contains required value.");

# for shell-style comments (#) with verbatim sections:
$json = config2perl({
	'string' => $jsonstr_shell_verbatim,
	'remove-comments-in-strings' => 0,
	'commentstyle' => 'shell'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
ok(exists($json->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'φονο/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'φονο/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'/*comment1*/κατούρ/*comment2*/'}->{'φονο/*comment1*/κατούρ/*comment2*/2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'/*comment5*/κα/*comment6*/ούρ#comment7'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'/*comment5*/κα/*comment6*/ούρ#comment7'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

# for mix-style comments (#./**/.//) with verbatim sections:
$json = config2perl({
	'string' => $jsonstr_mixed_verbatim,
	'remove-comments-in-strings' => 0,
	'commentstyle' => 'shell,CPP,C'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");

ok(exists($json->{'C'}), 'config2perl()'." : called and result contains required key.");
ok(exists($json->{'C'}->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'C'}->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'C'}->{'/*comment1*/κατούρ/*comment2*/'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined.");
$x = $json->{'C'}->{'/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'φονο/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'φονο/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'C'}->{'/*comment1*/κατούρ/*comment2*/'}->{'φονο/*comment1*/κατούρ/*comment2*/2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'C'}->{'/*comment5*/κα/*comment6*/ούρ#comment7'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'C'}->{'/*comment5*/κα/*comment6*/ούρ#comment7'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

ok(exists($json->{'CPP'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'CPP'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'CPP'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'CPP'}->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'CPP'}->{'/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'φονο/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'φονο/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'CPP'}->{'/*comment1*/κατούρ/*comment2*/'}->{'φονο/*comment1*/κατούρ/*comment2*/2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'CPP'}->{'/*comment5*/κα/*comment6*/ούρ#comment7'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'CPP'}->{'/*comment5*/κα/*comment6*/ούρ#comment7'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

ok(exists($json->{'shell'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'shell'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'shell'}->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'shell'}->{'/*comment1*/κατούρ/*comment2*/'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined and it is a HASH.");
$x = $json->{'shell'}->{'/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'φονο/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'φονο/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'shell'}->{'/*comment1*/κατούρ/*comment2*/'}->{'φονο/*comment1*/κατούρ/*comment2*/2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'shell'}->{'/*comment5*/κα/*comment6*/ούρ#comment7'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'shell'}->{'/*comment5*/κα/*comment6*/ούρ#comment7'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

# now do this last case (of mixed, verbatim) but save it to a file and use 'filename' param
($tempFH, $tempfile) = File::Temp::tempfile(UNLINK => 1);
binmode($tempFH, ":utf8");
print $tempFH $jsonstr_mixed_verbatim;
close($tempFH);

ok(-f $tempfile, "config file exists ($tempfile).") or BAIL_OUT;
$json = config2perl({
	'filename' => $tempfile,
	'remove-comments-in-strings' => 0,
	'commentstyle' => 'shell, C, CPP'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");

ok(exists($json->{'C'}), 'config2perl()'." : called and result contains required key.");
ok(exists($json->{'C'}->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'C'}->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'C'}->{'/*comment1*/κατούρ/*comment2*/'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined.");
$x = $json->{'C'}->{'/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'φονο/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'φονο/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'C'}->{'/*comment1*/κατούρ/*comment2*/'}->{'φονο/*comment1*/κατούρ/*comment2*/2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'C'}->{'/*comment5*/κα/*comment6*/ούρ#comment7'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'C'}->{'/*comment5*/κα/*comment6*/ούρ#comment7'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

ok(exists($json->{'CPP'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'CPP'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'CPP'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'CPP'}->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'CPP'}->{'/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'φονο/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'φονο/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'CPP'}->{'/*comment1*/κατούρ/*comment2*/'}->{'φονο/*comment1*/κατούρ/*comment2*/2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'CPP'}->{'/*comment5*/κα/*comment6*/ούρ#comment7'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'CPP'}->{'/*comment5*/κα/*comment6*/ούρ#comment7'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

ok(exists($json->{'shell'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'shell'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'shell'}->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'shell'}->{'/*comment1*/κατούρ/*comment2*/'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined and it is a HASH.");
$x = $json->{'shell'}->{'/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'φονο/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'φονο/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'shell'}->{'/*comment1*/κατούρ/*comment2*/'}->{'φονο/*comment1*/κατούρ/*comment2*/2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'shell'}->{'/*comment5*/κα/*comment6*/ούρ#comment7'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'shell'}->{'/*comment5*/κα/*comment6*/ούρ#comment7'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

# now do this last case (of mixed, verbatim) but save it to a file and use 'filehandle' param
ok(-f $tempfile, "config file exists ($tempfile).") or BAIL_OUT; # still there?
ok(open($tempFH, '<:utf8', $tempfile), "tempfile '$tempfile' opened again for reading.");
$json = config2perl({
	'filehandle' => $tempFH,
	'remove-comments-in-strings' => 0,
	'commentstyle' => 'shell, C, CPP'
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
close($tempFH);

ok(exists($json->{'C'}), 'config2perl()'." : called and result contains required key.");
ok(exists($json->{'C'}->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'C'}->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'C'}->{'/*comment1*/κατούρ/*comment2*/'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined.");
$x = $json->{'C'}->{'/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'φονο/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'φονο/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'C'}->{'/*comment1*/κατούρ/*comment2*/'}->{'φονο/*comment1*/κατούρ/*comment2*/2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'C'}->{'/*comment5*/κα/*comment6*/ούρ#comment7'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'C'}->{'/*comment5*/κα/*comment6*/ούρ#comment7'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

ok(exists($json->{'CPP'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'CPP'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'CPP'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'CPP'}->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'CPP'}->{'/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'φονο/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'φονο/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'CPP'}->{'/*comment1*/κατούρ/*comment2*/'}->{'φονο/*comment1*/κατούρ/*comment2*/2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'CPP'}->{'/*comment5*/κα/*comment6*/ούρ#comment7'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'CPP'}->{'/*comment5*/κα/*comment6*/ούρ#comment7'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

ok(exists($json->{'shell'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}), 'config2perl()'." : called and result contains required key and is defined.");
is(ref($json->{'shell'}), 'HASH', 'config2perl()'." : called and result contains required key and is a HASH.");
ok(exists($json->{'shell'}->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
ok(defined($json->{'shell'}->{'/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($json->{'shell'}->{'/*comment1*/κατούρ/*comment2*/'}), 'HASH', 'config2perl()'." : called and result contains required key and it is defined and it is a HASH.");
$x = $json->{'shell'}->{'/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
ok(exists($x->{'φονο/*comment1*/κατούρ/*comment2*/'}), 'config2perl()'." : called and result contains required key.");
$x = $x->{'φονο/*comment1*/κατούρ/*comment2*/'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a SCALAR.");
$x = $json->{'shell'}->{'/*comment1*/κατούρ/*comment2*/'}->{'φονο/*comment1*/κατούρ/*comment2*/2'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
# verbatim checks
$x = $json->{'shell'}->{'/*comment5*/κα/*comment6*/ούρ#comment7'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'HASH', 'config2perl()'." : called and result contains required key and it is a HASH.");
$x = $json->{'shell'}->{'/*comment5*/κα/*comment6*/ούρ#comment7'}->{'script'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is a ARRAY.");
is(scalar(@$x), 2, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items.");
ok($x->[0] eq '/usr/bin/bash', 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");
ok($x->[1] eq $script_content, 'config2perl()'." : called and result contains required key and it is an ARRAY of 2 items and first item contains required value.");

done_testing();
