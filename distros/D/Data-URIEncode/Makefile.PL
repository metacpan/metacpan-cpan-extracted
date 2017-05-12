use ExtUtils::MakeMaker;

###----------------------------------------------------------------###
#  Copyright 2003 - Paul Seamons                                     #
#  Distributed under the GNU General Public License without warranty #
###----------------------------------------------------------------###

WriteMakefile(
              NAME          => "Data::URIEncode",
              AUTHOR        => "Paul Seamons",
              ABSTRACT_FROM => "lib/Data/URIEncode.pm",
              VERSION_FROM  => "lib/Data/URIEncode.pm",
              INSTALLDIRS   => 'site',
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
