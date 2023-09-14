#!perl

use 5.010;
use strict;
use warnings;

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!

our $VERSION = '0.02';

use Config::JSON::Enhanced;

# this json is in the module's pod
# Testing it works
my $con = <<'EOJ';
{
    "a" : "abc",
    "b" : {
      /* this is a comment */
      "c" : <%begin-verbatim-section%>
  This is a multiline string
/* all spaces between the start of the line and
   the first char will be erased.
   Newlines are escaped and kept.
*/
  with "quoted text" and 'this also'
  and comments like /* this */ or
  # this
  will be retained in the string
/* white space from beginning and end will be erased */

<%end-verbatim-section%>
      ,
      "d" : [1,2,<% tempvar0 %>],
      "e" : "< % tempvar1 % > user and <%tempvar2%>!"
    }
} 
EOJ

my $json = config2perl({
	'string' => $con,
	'commentstyle' => 'C,CPP',
	'variable-substitutions' => {
		# substitutions do not add extra quotes
		'tempvar0' => 42,  
		'tempvar1' => 'hello',
		'tempvar2' => 'goodbye',
	},
});
ok(defined $json, 'config2perl()'." : called and got defined result.");
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
ok(exists($json->{'b'}), 'config2perl()'." : called and result contains required key.");

ok(exists($json->{'b'}->{'d'}), 'config2perl()'." : called and result contains required key.");
my $x = $json->{'b'}->{'d'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), 'ARRAY', 'config2perl()'." : called and result contains required key and it is an ARRAY.");
is(scalar(@{$x}), 3, 'config2perl()'." : called and result contains required key and it is an ARRAY of 3 items.");
unlike($x, qr/<%\s*tempvar0\s*%>/, 'config2perl()'." : template substitution (1) was correct.");

ok(exists($json->{'b'}->{'e'}), 'config2perl()'." : called and result contains required key.");
$x = $json->{'b'}->{'e'};
ok(defined($x), 'config2perl()'." : called and result contains required key and it is defined.");
is(ref($x), '', 'config2perl()'." : called and result contains required key and it is a string.");

done_testing();
