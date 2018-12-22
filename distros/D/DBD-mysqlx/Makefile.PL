use ExtUtils::MakeMaker;
use DBI::DBD;

my $dbi_arch_dir = dbd_dbi_arch_dir();
my %opts = (
        'NAME'         => 'DBD::mysqlx',
        'VERSION_FROM' => 'lib/DBD/mysqlx.pm',
        'dist'         => { 'SUFFIX'   => '.gz',
                            'COMPRESS' => 'gzip -9f' },
        'realclean'    => { FILES => '*.xsi' },
        'PREREQ_PM'    => { 'DBI' => 1.609 },
        'OBJECT'       => '$(O_FILES)',
        'INC'          => "-I$dbi_arch_dir -I/usr/include/mysql-cppconn-8 -std=c99",
        'LIBS'         => '-lmysqlcppconn8',
);

WriteMakefile(%opts);

package MY;
sub postamble { return DBI::DBD::dbd_postamble(@_); }
