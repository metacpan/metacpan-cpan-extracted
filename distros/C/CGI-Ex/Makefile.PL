use 5.006;
use ExtUtils::MakeMaker;

###----------------------------------------------------------------###
#  Copyright - Paul Seamons                                          #
#  Distributed under the GNU General Public License without warranty #
###----------------------------------------------------------------###

WriteMakefile1(
              NAME          => "CGI::Ex",
              AUTHOR        => "Paul Seamons",
              ABSTRACT_FROM => "lib/CGI/Ex.pm",
              VERSION_FROM  => "lib/CGI/Ex.pm",
              INSTALLDIRS   => 'site',
              PREREQ_PM     => {
                'CGI'             => '0',
                'File::Temp'      => '0',
                'Template::Alloy' => '1.016',
              },
              LICENSE => 'perl_5',
              MIN_PERL_VERSION => '5.006',
              META_MERGE => {
                'meta-spec' => { version => 2 },
                'resources' => {
                  'homepage'   => 'https://metacpan.org/module/CGI::Ex',
                  'license'    => 'https://dev.perl.org/licenses/',
                  'bugtracker' => {
                    'web' => 'https://github.com/ljepson/CGI-Ex/issues',
                  },
                  'repository' => {
                    'type' => 'git',
                    'url'  => 'git://github.com/ljepson/CGI-Ex.git',
                    'web'  => 'https://github.com/ljepson/CGI-Ex',
                  },
                },
                'no_index' => {
                  'directory' => ['t', 'samples'],
                },
              },
              TEST_REQUIRES => {
                'Test::More' => '0',
                'Test::Warn' => '0',
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

sub WriteMakefile1 {  #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 0.23. Added by eumm-upgrade.
  my %params=@_;
  my $eumm_version=$ExtUtils::MakeMaker::VERSION;
  $eumm_version=eval $eumm_version;
  die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
  die "License not specified" if not exists $params{LICENSE};
  if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.5705) {
    $params{META_ADD}->{author}=$params{AUTHOR};
    $params{AUTHOR}=join(', ',@{$params{AUTHOR}});
  }
  if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
    $params{BUILD_REQUIRES}={ %{$params{BUILD_REQUIRES} || {}} , %{$params{TEST_REQUIRES}} };
    delete $params{TEST_REQUIRES};
  }
  if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
    #EUMM 6.5502 has problems with BUILD_REQUIRES
    $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
    delete $params{BUILD_REQUIRES};
  }
  delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
  delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
  delete $params{META_MERGE} if $eumm_version < 6.46;
  delete $params{META_ADD} if $eumm_version < 6.46;
  delete $params{LICENSE} if $eumm_version < 6.31;

  WriteMakefile(%params);
}

package MY;

sub postamble {
  return qq^

pm_to_blib: README

README: \$(VERSION_FROM)
	pod2text \$(VERSION_FROM) > README

README.md: \$(VERSION_FROM)
	pod2markdown \$(VERSION_FROM) README.md
^;
}

1;
