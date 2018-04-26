use strict;
no warnings;

use Config;
use Test::More;

plan skip_all => "skip outside CPAN client"
  unless exists $ENV{PERL_MM_USE_DEFAULT};

plan skip_all => "this perl doesn't have this"
  unless $Config{default_inc_excludes_dot} eq 'define';

eval { require t::Foo };

like $@, qr/Can't locate t.Foo\.pm/;
unlike $@, qr/Do not load me/;

done_testing;


