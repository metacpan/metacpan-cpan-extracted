use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Catalyst::Plugin::Captcha',
    VERSION_FROM      => 'lib/Catalyst/Plugin/Captcha.pm',
    PREREQ_PM         => {
        'GD::SecurityImage' => 0,
        'Catalyst' => 5.30,
        'Catalyst::Plugin::Session' => 0,
        'HTTP::Date' => 0
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Catalyst/Plugin/Captcha.pm',
       AUTHOR         => 'Masahiro Nagano <kazeburo@nomadscafe.jp>') : ()),
);
