#!perl

use 5.010;
use strict;
use warnings;

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!
use File::Temp 'tempfile';
use FindBin;
use Cwd 'abs_path';

our $VERSION = '0.10';

use Config::JSON::Enhanced;

# this json is in the module's pod
# Testing it works
my $con = <<'EOJ';
  {
    "long bash script" : ["/usr/bin/bash",
  /* This is a verbatim section, this comment is removed */
  <%begin-verbatim-section%>
    # save current dir, this comment remains
    pushd . &> /dev/null
    # following quotes will be escaped
    echo "My 'appdir' is \"<%appdir%>\""
    echo "My current dir: " $(echo $PWD) " and bye"
    # go back to initial dir, this comment remains
    popd &> /dev/null
  <%end-verbatim-section%>
  /* this is the end of the verbatim section, this comment is removed */
    ],
    // this is an example of a template variable
    "expected result" : "<% expected-res123 %>"
  }
EOJ

my $appdir = Cwd::abs_path($FindBin::Bin);

my $json = config2perl({
	'string' => $con,
	'commentstyle' => 'C,shell,CPP',
	'variable-substitutions' => {
		'appdir' => $appdir,
		'expected-res123' => 42
	},
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and result is HASHref.");

# print the result in order to copy-paste it into the pod
# under L<Verbatim Sections>
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/; diag perl2dump($json);

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

# now let's save the bash script to file and see
my ($FH, $afile) = tempfile(UNLINK=>1);
close $FH;
ok(open($FH, '>:utf8', $afile), "Created a tempfile ($afile) for writing out the bash script") or BAIL_OUT;
print $FH $json->{'long bash script'}->[1] . "\n"; # this newline is important, heredoc adds a newline!
close $FH;

# now read it,
ok(open($FH, '<:utf8', $afile), "Opened tempfile ($afile) for reading the bash script") or BAIL_OUT;
my $contents;
{ local $/ = undef; $contents = <$FH> } close $FH;

my $expected = <<'EOJ';
# save current dir, this comment remains
pushd . &> /dev/null
# following quotes will be escaped
echo "My 'appdir' is \"<%appdir%>\""
echo "My current dir: " $(echo $PWD) " and bye"
# go back to initial dir, this comment remains
popd &> /dev/null
EOJ
$expected =~ s/<%appdir%>/${appdir}/;

is($expected, $contents, "Bash script looks good");

done_testing();
