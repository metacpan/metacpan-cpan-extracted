use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Akamai::PropertyFetcher',
    VERSION_FROM => 'lib/Akamai/PropertyFetcher.pm',
    PREREQ_PM    => {
        'Akamai::Edgegrid' => 0,
        'JSON'             => 0,
        'File::Spec'       => 0,
        'File::Path'       => 0,
        'Parallel::ForkManager' => 0,
    },
    AUTHOR       => 'Kawamura Shingo <pannakoota@gmail.com>',
    ABSTRACT     => 'Akamaiプロパティのアクティブバージョン情報を取得するモジュール',
);
