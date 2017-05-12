use 5.006000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Coro::Generator',
    VERSION_FROM      => 'lib/Coro/Generator.pm',
    ABSTRACT_FROM     => 'lib/Coro/Generator.pm',
    AUTHOR            => 'Brock Wilcox <awwaiid@thelackthereof.org>',
    LICENSE           => 'perl',
    PREREQ_PM         => {
      Coro            => 0,
    },
);

