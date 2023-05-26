#!/usr/bin/env perl
use FindBin qw($Bin);
use lib $Bin;
use t_Common qw/oops/; # strict, warnings, Carp, etc.
use t_TestCommon ':silent', qw/bug $debug t_ok t_is t_like/; # Test2::V0 etc.

use Data::Dumper::Interp;
$Data::Dumper::Interp::Debug = $debug if $debug;

$Data::Dumper::Interp::Foldwidth = 40;
my $data = {aaa => 100,bbb => 200,ccc => 300, ddd => 400};

t_is(vis($data), do{chomp(local $_=<<'EOF'); $_} );
{
  aaa => 100,bbb => 200,ccc => 300,
  ddd => 400
}
EOF
t_is(visnew->Pad("")->vis($data), do{chomp(local $_=<<'EOF'); $_} );
{
  aaa => 100,bbb => 200,ccc => 300,
  ddd => 400
}
EOF
t_is(visnew->Pad("  ")->vis($data), do{chomp(local $_=<<'EOF'); $_} );
{
    aaa => 100,bbb => 200,ccc => 300,
    ddd => 400
  }
EOF
t_is(visnew->Pad("~~~FOOEY~~~")->vis($data), do{chomp(local $_=<<'EOF'); $_} );
{
~~~FOOEY~~~  aaa => 100,bbb => 200,
~~~FOOEY~~~  ccc => 300,ddd => 400
~~~FOOEY~~~}
EOF

done_testing();
