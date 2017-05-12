use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $module = 'lib/Acme/Your.pm';
WriteMakefile(
              'NAME'         => 'Acme::Your',
              'VERSION_FROM' => $module, # finds $VERSION
              'dist'         => {
                                 COMPRESS=>'gzip -9f',
                                 SUFFIX=>'gz',
                                 DIST_DEFAULT => 'tardist'
                                },
              PM             => {
                                 'lib/Acme/Your.pm'            => '$(INST_LIBDIR)/Your.pm',
                                 'lib/Acme/Your/Filter.pm'     => '$(INST_LIBDIR)/Your/Filter.pm',
                                },
              PREREQ_PM      => {
                                 'Test::More' => 0,
                                 'Filter::Simple' => '0.77',
                                 'Parse::RecDescent' => '1.80',
                                },
              $] >= 5.005 ? ('AUTHOR'   => 'Richard Clamp <richardc@unixbeard.net>, Mark Fowler <mark@twoshortplanks.com>',
                             'ABSTRACT' => 'Introduce an our variable into someone else\'s package',

                            ) : ()

             );

use Config;
use File::Spec::Functions;
sub MY::postamble {
    my $perl     = $Config{perlpath};
    my $pod2text = catfile($Config{bin}, "pod2text");
    return <<EOF
README: $module
\t$perl $pod2text $module > README
EOF
}
