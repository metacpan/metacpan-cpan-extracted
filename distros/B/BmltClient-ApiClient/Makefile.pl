 use 5.30.0;
 use ExtUtils::MakeMaker;

 WriteMakefile(
   NAME             => 'BmltClient::ApiClient',
   VERSION_FROM     => 'lib/BmltClient/Configuration.pm',
   ABSTRACT_FROM    => 'lib/BmltClient/ApiClient.pm',
   AUTHOR           => 'BMLT Enabled',
   LICENSE          => 'MIT',
   MIN_PERL_VERSION => '5.30.0',
   PREREQ_PM        => {
     'POSIX' => 0,
   },
   (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
     'meta-spec' => { version => 2 },
     resources => {
       repository => {
         type => 'git',
           url  => 'https://github.com/bmlt-enabled/bmlt-root-server-perl-client.git',
           web  => 'https://github.com/bmlt-enabled/bmlt-root-server-perl-client',
       },
     }})
   : ()
   ),
 );
