# -*- perl -*-
use DBI;
use DBI::DBD;
use ExtUtils::MakeMaker;
ExtUtils::MakeMaker::WriteMakefile(
        'NAME'         => 'DBD::Excel',
        'VERSION_FROM' => 'lib/DBD/Excel.pm',
        'INC'          => $DBI_INC_DIR,
        'dist'         => { 'SUFFIX' => '.gz',
                            'COMPRESS' => 'gzip -9f' },
        'realclean'    => {'*.xsi'},
        'LICENSE'      => 'perl',
        'META_MERGE'     => {
            'resources' => {
                'repository' => 'https://github.com/asb-capfan/DBD-Excel',
            },
        },
        'PREREQ_PM'    => {
            'ExtUtils::MakeMaker' => 6.64,
            'Spreadsheet::ParseExcel' => 0.22,
            'Spreadsheet::WriteExcel' => 0.31,
            'DBI'                     => 1,
            'DBI::DBD'                => 1,
            'SQL::Statement'          => 1,
        }, # e.g., Module::Name => 1.1
        'TEST_REQUIRES' => {
            'Test::More' => 1.3,
        },
    );

package MY;
sub postamble { DBI::DBD::dbd_postamble(@_); }
sub libscan {
    my($self, $path) = @_;
    ($path =~ /\~$/) ? undef : $path;
}
__DATA__
