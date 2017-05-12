use ExtUtils::MakeMaker;
use File::Copy;

if ($^V lt v5.10) {

   die("Algorithm::TicketClusterer has only been tested on Perl 5.10.0.\n" .
   "Your perl version is $].\n");
}

copy("perl/MANIFEST.perl","MANIFEST");

WriteMakefile(
    NAME         => 'Algorithm::TicketClusterer',
    VERSION_FROM => 'lib/Algorithm/TicketClusterer.pm',
    PREREQ_PM    => {  Spreadsheet::ParseExcel => '0.59',
                       Spreadsheet::XLSX => '0.13',
                       Text::Iconv => '1.7',
                       WordNet::QueryData => '1.47',
                    },
    AUTHOR       => 'Avinash Kak (kak@purdue.edu)',
    ABSTRACT     => 'A Perl Module for Retrieving Tickets Similar to a Given Ticket',
    clean        => {FILES => join(" ",
                                   map { "$_ */$_ */*/$_" }
                                   qw( *% *.html *.b[ac]k *.old *.orig ) )
                    },
);
