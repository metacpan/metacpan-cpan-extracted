#!/usr/bin/env perl

use 5.16.1;
use warnings;

use Code::Crypt;

my $code = <<'CODE';
print "hello world!\n";
print "this code is secret and can't be read unless the user has the key\n";
CODE
print "#!/usr/bin/env perl\n\n" . Code::Crypt->new(
   code => $code,
   cipher => 'Crypt::Rijndael',
   get_key => q{
   require Sys::Hostname;
   $] . Sys::Hostname::hostname();
},
   key => $] . 'wanderlust',
)->final_code;
