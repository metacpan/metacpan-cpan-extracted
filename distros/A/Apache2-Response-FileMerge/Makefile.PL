use 5.00503;

use ExtUtils::MakeMaker;

use Apache::TestMM qw(test clean);
use Apache::TestRunPerl ();

Apache::TestMM::filter_args();

Apache::TestRunPerl->generate_script(bugreport => <<'EOF');
+-------------------------------------------------------------------+
| you probably got a coredump or something.  this is not my fault.  |
|                                                                   |
| see the README for more information and caveats                   |
+-------------------------------------------------------------------+
EOF

WriteMakefile(
  NAME          => 'Apache2-Response-FileMerge',
  VERSION_FROM  => 'lib/Apache2/Response/FileMerge.pm',
  PREREQ_PM     => {
      'mod_perl2' => 0,
#       'Apache::Test'             => 0,
#       'CSS::Minifier::XS'        => 0, 
#       'JavaScript::Minifier::XS' => 0,
#       'Compress::Zlib'           => 0,
  },
  ABSTRACT_FROM => 'lib/Apache2/Response/FileMerge.pm',
  AUTHOR        => 'Trevor Hall <wazzuteke@cpan.org>',
);
