use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => "Authen::PluggableCaptcha",
    VERSION_FROM => "lib/Authen/PluggableCaptcha.pm",
    PREREQ_PM    => {
                     'Time::HiRes'=> 0,
                     'Digest::MD5'=> 0,
                     'Number::Spell'=> '0.04',
                     'Data::Dumper'=> 0,
                     'HTML::Email::Obfuscate'=> '0.02',
                    },
);
