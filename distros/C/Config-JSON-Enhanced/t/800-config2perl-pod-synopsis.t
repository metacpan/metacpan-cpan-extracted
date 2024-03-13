#!perl

use 5.010;
use strict;
use warnings;

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!
use FindBin;

use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

our $VERSION = '0.10';

use Config::JSON::Enhanced;

# these json are in the module's pod, section SYNOPSIS
# Testing it works and also to dump their output back in the pod
my $con = <<'EOJ';
     {
        /* 'a' is ... */
        "a" : "abc",
        # b is ...
        "b" : [1,2,3],
        "c" : 12 // c is ...
     }
EOJ

my $json = config2perl({
	'string' => $con,
	'commentstyle' => 'C,shell,CPP',
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
for (qw/a b c/){
	ok(exists($json->{$_}), 'config2perl()'." : called and result contains required key ($_).");
}
is(ref($json->{'b'}), 'ARRAY', 'config2perl()'." : called and result contains 'b' which is an ARRAY.");
#diag perl2dump($json, {indent=>0});

########################
##### another example
########################
$con = <<'EOJ';
     {
      "a" : <%begin-verbatim-section%>
      This is a multiline
      string
      "quoted text" and 'quoted like this also'
      will be retained in the string escaped.
      Comments like /* this */ or # this comment
      will be removed.
      White space from beginning and end will be chomped.

      <%end-verbatim-section%>
      ,
      "b" : 123
     }
EOJ

$json = config2perl({
	'string' => $con,
	'commentstyle' => 'C,CPP',
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
for (qw/a b/){
	ok(exists($json->{$_}), 'config2perl()'." : called and result contains required key ($_).");
}
#diag perl2dump($json,{indent=>0});

########################
##### another example
########################
$con = <<'EOJ';
     {
       "d" : [1,2,<% tempvar0 %>],
       "configfile" : "<%SCRIPTDIR%>/config/myapp.conf",
       "username" : "<% username %>"
     }
EOJ

$json = config2perl({
	'string' => $con,
	'commentstyle' => 'C,CPP',
	'variable-substitutions' => {
		# substitutions do not add extra quotes
		'tempvar0' => 42,  
		'username' => getlogin,
		'SCRIPTDIR' => $FindBin::Bin,
	},
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");
for (qw/d configfile username/){
	ok(exists($json->{$_}), 'config2perl()'." : called and result contains required key ($_).");
}
my $varname = 'tempvar0'; unlike($json->{'d'}->[2], qr/<%\s*${varname}\s*%>/, 'config2perl()'." : template substitution (for '$varname') was correct.");
$varname = 'configfile'; unlike($json->{$varname}, qr/<%\s*${varname}\s*%>/, 'config2perl()'." : template substitution (for '$varname') was correct.");
$varname = 'username'; unlike($json->{$varname}, qr/<%\s*${varname}\s*%>/, 'config2perl()'." : template substitution (for '$varname') was correct.");

is($json->{'d'}->[2], 42, 'config2perl()'." : called and result contains 42!!!");
#diag perl2dump($json,{indent=>0});


done_testing();
