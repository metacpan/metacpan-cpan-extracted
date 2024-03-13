#!perl

use 5.010;
use strict;
use warnings;

use Test::More;
use Test2::Plugin::UTF8; # rids of the Wide Character in TAP message!
use FindBin;
use Cwd 'abs_path';
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

our $VERSION = '0.10';

use Config::JSON::Enhanced;

my $appdir = Cwd::abs_path($FindBin::Bin);

# this json is in the module's pod
# Testing it works
my $con = <<'EOJ';
  {
    "long bash script" : ["/usr/bin/bash",
  /* This is a verbatim section */
  <%begin-verbatim-section%>
    # save current dir
    pushd . &> /dev/null
    echo "My 'appdir' is \"<%appdir%>\""
    echo "My current dir: " $(echo $PWD) " and bye"
    # restore current dir
    popd &> /dev/null
  <%end-verbatim-section%>
  /* end of the verbatim section */
    ],
    "long CPP program" :
  /* This is a verbatim section */
  <%begin-verbatim-section%>
    int main(void){
      int a;
      /* allocate some memory */
      char *str = (char *)malloc(100*sizeof(char));
      strcpy(str, "hello");
      // release the memory
      free(str);
      return 0;
    }
  <%end-verbatim-section%>
  ,
  /* end of the verbatim section */
    // this is an example of a template variable
    "expected result" : "<% expected-res123 %>"
  }
EOJ

my $json = config2perl({
	'string' => $con,
	'commentstyle' => 'shell,C,CPP',
	'variable-substitutions' => {
		'appdir' => Cwd::abs_path($FindBin::Bin),
		'expected-res123' => 42
	},
});
ok(defined $json, 'config2perl()'." : called and got defined result.") or BAIL_OUT;
is(ref($json), 'HASH', 'config2perl()'." : called and got defined result which is a HASH.") or BAIL_OUT;
for ('long CPP program', 'long bash script', 'expected result'){
	ok(exists($json->{$_}), 'config2perl()'." : called and got defined result which contains key '$_'.") or BAIL_OUT(perl2dump($json)."no see above");
}
is($json->{'long CPP program'}, "int main(void){\nint a;\n/* allocate some memory */\nchar *str = (char *)malloc(100*sizeof(char));\nstrcpy(str, \"hello\");\n// release the memory\nfree(str);\nreturn 0;\n}", 'config2perl()'." : called and got correct CPP program contents") or BAIL_OUT(perl2dump($json)."no see above");
is(ref($json->{'long bash script'}), "ARRAY", 'config2perl()'." : called and got good result as an ARRAY.") or BAIL_OUT;
is(scalar(@{ $json->{'long bash script'} }), 2, 'config2perl()'." : called and got good result of 2 items.") or BAIL_OUT;

my $expected = "# save current dir\npushd . &> /dev/null\necho \"My 'appdir' is \\\"<%appdir%>\\\"\"\necho \"My current dir: \" \$(echo \$PWD) \" and bye\"\n# restore current dir\npopd &> /dev/null";
$expected =~ s/<%appdir%>/${appdir}/;
is($json->{'long bash script'}->[1], $expected, 'config2perl()'." : called and got correct CPP program contents") or BAIL_OUT(perl2dump($json)."no see above");
is($json->{'expected result'}, 42, 'config2perl()'." : called and got correct expected result") or BAIL_OUT(perl2dump($json)."no see above");

done_testing();
