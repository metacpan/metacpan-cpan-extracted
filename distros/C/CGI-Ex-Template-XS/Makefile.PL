use ExtUtils::MakeMaker;

###----------------------------------------------------------------###
#  Copyright 2007 - Paul Seamons                                     #
#  Distributed under the same terms as Perl itself without warranty  #
###----------------------------------------------------------------###

WriteMakefile(
              NAME          => "CGI::Ex::Template::XS",
              AUTHOR        => "Paul Seamons",
              ABSTRACT_FROM => "lib/CGI/Ex/Template/XS.pm",
              VERSION_FROM  => "lib/CGI/Ex/Template/XS.pm",
              INSTALLDIRS   => 'site',
              PREREQ_PM     => {
                  'CGI::Ex'             => '2.14',
                  'Template::Alloy::XS' => '1.002',
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
