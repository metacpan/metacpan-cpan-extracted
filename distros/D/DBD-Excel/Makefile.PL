# -*- perl -*-
use DBI;
use DBI::DBD;
use ExtUtils::MakeMaker;
ExtUtils::MakeMaker::WriteMakefile(
        'NAME'         => 'DBD::Excel',
        'VERSION_FROM' => 'Excel.pm',
        'INC'          => $DBI_INC_DIR,
        'dist'         => { 'SUFFIX' => '.gz',
                            'COMPRESS' => 'gzip -9f' },
        'realclean'    => {'*.xsi'},
        'PREREQ_PM'    => {
                            Spreadsheet::ParseExcel => 0.22,
                            Spreadsheet::WriteExcel => 0.31,
                            DBI                     => 1,
                            SQL::Statement          => ,
                            }, # e.g., Module::Name => 1.1
    );

package MY;
sub postamble { DBI::DBD::dbd_postamble(@_); }
sub libscan {
    my($self, $path) = @_;
    ($path =~ /\~$/) ? undef : $path;
}
__DATA__
