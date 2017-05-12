use strict;
use warnings;
use inc::Module::Install;

name 'DBIx-Class-DynamicDefault';
all_from 'lib/DBIx/Class/DynamicDefault.pm';

requires 'DBIx::Class' => '0.08127';

build_requires 'DBICx::TestDatabase';

makemaker_args(depend => { dist => 'README' });
auto_provides;
extra_tests;

WriteAll;

package MY;

sub postamble {
    return <<"EOM";
testcover:
\tHARNESS_PERL_SWITCHES=-MDevel::Cover \$(MAKE) test
\tcover

README: lib/DBIx/Class/DynamicDefault.pm
\tpod2text \$< > \$@
EOM
}
