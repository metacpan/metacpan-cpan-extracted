#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.006

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Data/Sah.pm','lib/Data/Sah/Compiler.pm','lib/Data/Sah/Compiler/Prog.pm','lib/Data/Sah/Compiler/Prog/TH.pm','lib/Data/Sah/Compiler/Prog/TH/all.pm','lib/Data/Sah/Compiler/Prog/TH/any.pm','lib/Data/Sah/Compiler/TH.pm','lib/Data/Sah/Compiler/TextResultRole.pm','lib/Data/Sah/Compiler/human.pm','lib/Data/Sah/Compiler/human/TH.pm','lib/Data/Sah/Compiler/human/TH/Comparable.pm','lib/Data/Sah/Compiler/human/TH/HasElems.pm','lib/Data/Sah/Compiler/human/TH/Sortable.pm','lib/Data/Sah/Compiler/human/TH/all.pm','lib/Data/Sah/Compiler/human/TH/any.pm','lib/Data/Sah/Compiler/human/TH/array.pm','lib/Data/Sah/Compiler/human/TH/bool.pm','lib/Data/Sah/Compiler/human/TH/buf.pm','lib/Data/Sah/Compiler/human/TH/cistr.pm','lib/Data/Sah/Compiler/human/TH/code.pm','lib/Data/Sah/Compiler/human/TH/date.pm','lib/Data/Sah/Compiler/human/TH/datenotime.pm','lib/Data/Sah/Compiler/human/TH/datetime.pm','lib/Data/Sah/Compiler/human/TH/duration.pm','lib/Data/Sah/Compiler/human/TH/float.pm','lib/Data/Sah/Compiler/human/TH/hash.pm','lib/Data/Sah/Compiler/human/TH/int.pm','lib/Data/Sah/Compiler/human/TH/num.pm','lib/Data/Sah/Compiler/human/TH/obj.pm','lib/Data/Sah/Compiler/human/TH/re.pm','lib/Data/Sah/Compiler/human/TH/str.pm','lib/Data/Sah/Compiler/human/TH/timeofday.pm','lib/Data/Sah/Compiler/human/TH/undef.pm','lib/Data/Sah/Compiler/perl.pm','lib/Data/Sah/Compiler/perl/TH.pm','lib/Data/Sah/Compiler/perl/TH/all.pm','lib/Data/Sah/Compiler/perl/TH/any.pm','lib/Data/Sah/Compiler/perl/TH/array.pm','lib/Data/Sah/Compiler/perl/TH/bool.pm','lib/Data/Sah/Compiler/perl/TH/buf.pm','lib/Data/Sah/Compiler/perl/TH/cistr.pm','lib/Data/Sah/Compiler/perl/TH/code.pm','lib/Data/Sah/Compiler/perl/TH/date.pm','lib/Data/Sah/Compiler/perl/TH/datenotime.pm','lib/Data/Sah/Compiler/perl/TH/datetime.pm','lib/Data/Sah/Compiler/perl/TH/duration.pm','lib/Data/Sah/Compiler/perl/TH/float.pm','lib/Data/Sah/Compiler/perl/TH/hash.pm','lib/Data/Sah/Compiler/perl/TH/int.pm','lib/Data/Sah/Compiler/perl/TH/num.pm','lib/Data/Sah/Compiler/perl/TH/obj.pm','lib/Data/Sah/Compiler/perl/TH/re.pm','lib/Data/Sah/Compiler/perl/TH/str.pm','lib/Data/Sah/Compiler/perl/TH/timeofday.pm','lib/Data/Sah/Compiler/perl/TH/undef.pm','lib/Data/Sah/Human.pm','lib/Data/Sah/Lang.pm','lib/Data/Sah/Lang/fr_FR.pm','lib/Data/Sah/Lang/id_ID.pm','lib/Data/Sah/Lang/zh_CN.pm','lib/Data/Sah/Manual.pod','lib/Data/Sah/Manual/Contributing.pod','lib/Data/Sah/Manual/Developer.pod','lib/Data/Sah/Manual/Extending.pod','lib/Data/Sah/Manual/ParamsValidating.pod','lib/Data/Sah/Type/BaseType.pm','lib/Data/Sah/Type/Comparable.pm','lib/Data/Sah/Type/HasElems.pm','lib/Data/Sah/Type/Sortable.pm','lib/Data/Sah/Type/all.pm','lib/Data/Sah/Type/any.pm','lib/Data/Sah/Type/array.pm','lib/Data/Sah/Type/bool.pm','lib/Data/Sah/Type/buf.pm','lib/Data/Sah/Type/cistr.pm','lib/Data/Sah/Type/code.pm','lib/Data/Sah/Type/date.pm','lib/Data/Sah/Type/datenotime.pm','lib/Data/Sah/Type/datetime.pm','lib/Data/Sah/Type/duration.pm','lib/Data/Sah/Type/float.pm','lib/Data/Sah/Type/hash.pm','lib/Data/Sah/Type/int.pm','lib/Data/Sah/Type/num.pm','lib/Data/Sah/Type/obj.pm','lib/Data/Sah/Type/re.pm','lib/Data/Sah/Type/str.pm','lib/Data/Sah/Type/timeofday.pm','lib/Data/Sah/Type/undef.pm','lib/Data/Sah/Util/Func.pm','lib/Data/Sah/Util/Role.pm','lib/Data/Sah/Util/Type/Date.pm','lib/Data/Sah/Util/TypeX.pm','lib/Test/Data/Sah.pm','lib/Test/Data/Sah/Human.pm','lib/Test/Data/Sah/Perl.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
