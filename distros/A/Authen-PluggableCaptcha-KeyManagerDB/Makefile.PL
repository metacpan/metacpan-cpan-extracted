use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => "Authen::PluggableCaptcha::KeyManagerDB",
    VERSION_FROM => "lib/Authen::PluggableCaptcha::KeyManagerDB.pm",
    PREREQ_PM    => {
                     'Time::HiRes'=> 0,
                     'Digest::MD5'=> 0,
                     'Data::Dumper'=> 0,
                     'Authen::PluggableCaptcha'=> '0.05',
                     'Rose::DB'=> '0.732',
                     'Rose::DB::Object'=> '0.760',
                    },
);
