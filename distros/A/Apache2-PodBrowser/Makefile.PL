use strict;

use 5.008008;
use ExtUtils::MakeMaker qw/prompt/;

BEGIN {
  eval {
    require ModPerl::MM;
    require Apache::TestMM;
  };
  if( $@ ) {
    exit 0;
  }
  Apache::TestMM->import( qw(test clean) );
}

# accept the configs from command line
Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

my $prereq=
  {
   'Apache2::Const'    => 0,
   'ModPerl::MM'       => 0,
   'Apache::TestMM'    => 0,
   'File::Spec'        => 0,
   'Pod::Find'         => '1.3',
   'Pod::Simple::HTML' => 0,
   'Test::More'        => 0,
   'MMapDB'            => 0.11,
  };

unless( eval "use MMapDB; MMapDB->VERSION>=0.11" ) {
  if( prompt(<<'EOF'.'Do you want me to do so?', 'y') eq 'n' ) {
Apache2::PodBrowser can cache some values in a MMapDB object to speed up
access. It is recommended to install this module.

EOF
    delete $prereq->{MMapDB};
  }
}

ModPerl::MM::WriteMakefile(
    NAME            => 'Apache2::PodBrowser',
    VERSION_FROM    => 'lib/Apache2/PodBrowser.pm',
    ABSTRACT_FROM   => 'lib/Apache2/PodBrowser.pm',
    AUTHOR          => 'Torsten Foertsch <torsten.foertsch@gmx.net>',
    PREREQ_PM       => $prereq,
    dist => {
        COMPRESS => 'gzip -9f',
	PREOP    => './mk_README.sh',
    },
    clean        => {
	FILES=>"t/TEST",
    },
);


sub MY::postamble {
  return <<'EOF';
pure_all :: blib/lib/Apache2/PodBrowser/auto.css.gz \
            blib/lib/Apache2/PodBrowser/fancy.css.gz

%.gz : %
	gzip -9f <$< >$@

rpm: dist
	$(PERL) -i -pe 's/^(Version:\s*).*/$${1}$(VERSION)/' perl-Apache2-PodBrowser.spec
	rpmbuild -ba perl-Apache2-PodBrowser.spec

EOF
}
