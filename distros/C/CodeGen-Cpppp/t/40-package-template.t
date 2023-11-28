#! /usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/lib";
use Test2WithExplain;
use CodeGen::Cpppp;

ok( eval { require "$FindBin::RealBin/lib/TemplateAsPackage.pm" }, 'require TemplateAsPackage' )
   or do { diag $@; exit 2 };

my $t;
ok( eval { $t= TemplateAsPackage->new }, 'new TemplateAsPackage' )
   or do { diag $@; exit 2 };

is( $t->output, <<'END', 'initial output' );

Initial Line of Output

END

done_testing;
