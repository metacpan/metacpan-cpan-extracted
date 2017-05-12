use 5.010001;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Captcha::NocaptchaMailru',
    VERSION_FROM      => 'lib/Captcha/NocaptchaMailru.pm',
    PREREQ_PM         => {
        LWP::UserAgent => 5,
        JSON => 2,
        URI::Escape => 3,
    },
    LICENSE           => 'mit',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Captcha/NocaptchaMailru.pm', # retrieve abstract from module
       AUTHOR         => 'Oleg Kovalev <man0xff@gmail.com>') : ()),
);
