use ExtUtils::MakeMaker;

###----------------------------------------------------------------###
#  Copyright 2003 - Paul Seamons                                     #
#  Distributed under the GNU General Public License without warranty #
###----------------------------------------------------------------###

WriteMakefile(
              NAME          => "CGI::Ex",
              AUTHOR        => "Paul Seamons",
              ABSTRACT_FROM => "lib/CGI/Ex.pm",
              VERSION_FROM  => "lib/CGI/Ex.pm",
              INSTALLDIRS   => 'site',
              PREREQ_PM     => {
                  'Template::Alloy' => '1.016',
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
