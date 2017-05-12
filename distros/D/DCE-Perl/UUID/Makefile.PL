use ExtUtils::MakeMaker;

WriteMakefile(
     TYPEMAPS => '../typemap',	       
     NAME => "DCE::UUID",
     VERSION_FROM => "UUID.pm",
);

