use strict;
use warnings;
use inc::Module::Install 0.87;

name 'Catalyst-View-Mason';
all_from 'lib/Catalyst/View/Mason.pm';
author 'Florian Ragwitz <rafl@debian.org>';
license 'perl';

requires 'Catalyst'     => '5.50';
requires 'HTML::Mason'  => 0;
requires 'Scalar::Util' => 0;
requires 'File::Spec'   => 0;
requires 'parent'       => 0;
requires 'MRO::Compat'  => 0;

auto_provides;
extra_tests;

resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/Catalyst-View-Mason/trunk/';

WriteAll;

package MY;

sub postamble {
    return <<"EOM"
testcover: pm_to_blib
\t-HARNESS_PERL_SWITCHES=-MDevel::Cover \$(MAKE) test
\tcover

README: lib/Catalyst/View/Mason.pm
\tpod2text \$< > \$@
EOM
}
