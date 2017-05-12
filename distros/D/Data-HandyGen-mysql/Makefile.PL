use 5.008001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Data::HandyGen::mysql',
    VERSION_FROM      => 'lib/Data/HandyGen/mysql.pm', # finds $VERSION
    PREREQ_PM         => {
        "DBI"                   => 1.38,
        "SQL::Maker"            => 0,
        "Class::Accessor::Lite" => 0,
        "DateTime"              => 0,
        "DBD::mysql"            => 0,
        "Test::More"            => '0.87_01',
        "Test::Exception"       => 0,
        "Test::mysqld"          => 0,
        "Test::Warn"            => 0,
        "JSON"                  => 0,
        "YAML"                  => 0,
        "Getopt::Long"          => 0,
        "Data::Dumper"          => 0,
    }, 
    EXE_FILES         => [ 
        'script/hd_insert_bulk.pl', 
        'script/hd_delete_all.pl' 
    ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Data/HandyGen/mysql.pm', # retrieve abstract from module
       AUTHOR         => 'Takashi Egawa <egawa.takashi@gmail.com>') : ()),
);
