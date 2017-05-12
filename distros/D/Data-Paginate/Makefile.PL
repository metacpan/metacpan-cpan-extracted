use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Data::Paginate',
    VERSION_FROM      => 'Paginate.pm',
    PREREQ_PM         => {
                             'version'           => 0,
                             'Class::Std'        => 0,
                             'Class::Std::Utils' => 0, 
                         },
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'Paginate.pm', 
       AUTHOR         => 'Daniel Muey, <http://drmuey.com/cpan_contact.pl>') : ()),
);
