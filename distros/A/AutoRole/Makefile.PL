use ExtUtils::MakeMaker;

###----------------------------------------------------------------###
#  Copyright 2010 - Paul Seamons                                     #
#  Distributed under the GNU General Public License without warranty #
###----------------------------------------------------------------###

WriteMakefile(
              NAME          => "AutoRole",
              AUTHOR        => "Paul Seamons",
              ABSTRACT_FROM => "lib/AutoRole.pm",
              VERSION_FROM  => "lib/AutoRole.pm",
              INSTALLDIRS   => 'site',
              PREREQ_PM     => {
              },
              dist          => {
                DIST_DEFAULT => 'all tardist',
                COMPRESS     => 'gzip -vf',
                SUFFIX       => '.gz',
              },
              clean          => {
                FILES        => '*~',
              },
              realclean         => {
                FILES        => '*~',
              },
              );

package MY;

sub postamble {
  return qq^
    
pm_to_blib: README

README: \$(VERSION_FROM)
	pod2text \$(VERSION_FROM) > README
^;
}

1;
