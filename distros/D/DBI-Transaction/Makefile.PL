# File : Makefile.pl

use ExtUtils::MakeMaker;
WriteMakefile(
     'NAME' => 'DBI::Transaction',
#     'DISTNAME' => 'DBI::Transaction',
     'VERSION' => 0.101,
     'AUTHOR' => "Victor Porton <support@ex-code.com>",
     'ABSTRACT' => "Advanced object-oriented support for database transactions",
#     'ABSTRACT_FROM' => 'DBI/FastLogics.pod',
     'PREREQ_PM' => { 'DBI'=>0 },
#     'PMLIBDIRS' => ['DBI'],
     'PM' => {
       'lib/Transaction.pm' => '$(INST_LIBDIR)/Transaction.pm',
       'lib/Transaction/Repeated.pm' => '$(INST_LIBDIR)/Transaction/Repeated.pm',
     }
);
