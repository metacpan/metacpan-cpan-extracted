use 5.010000;
use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DB::SQL::Migrations',
    VERSION_FROM      => 'lib/DB/SQL/Migrations.pm', # finds $VERSION
    PREREQ_PM         => {
      'Mojo' => 0,
      'DBIx::MultiStatementDo' => 0,
      'File::Basename' => 0,
      'File::Slurp' => 0

    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DB/SQL/Migrations.pm', # retrieve abstract from module
       AUTHOR         => 'Jonathan Taylor <jon@local>') : ()),

    ($mm_ver >= 6.31
        ? (LICENSE => 'perl_5')
        : ()
    ),

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.010)
        : ()
    ),

    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                bugtracker  => 'http://rt.cpan.org/Public/Dist/Display.html?Name=DB-SQL-Migrations',
                repository  => {
                    type => 'git',
                    web  => 'https://github.com/jontaylor/DB-SQL-Migrations',
                    url  => 'git://github.com/jontaylor/DB-SQL-Migrations.git',
                },
            },
          })
    ),

);
