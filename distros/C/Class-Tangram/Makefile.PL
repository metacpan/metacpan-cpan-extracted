use inc::Module::Install;

requires( perl => '5.004' );
auto_include    (1);


WriteMakefile
    (
     'PREREQ_PM' => {
		     Set::Object  => 1.04,
		     Test::Simple => 0.18,
		     Date::Manip  => 5.21,
		    },
     'NAME'          => "Class::Tangram",
     'VERSION_FROM'  => "lib/Class/Tangram.pm",
     ( ($] >= 5.005) && $ABSTRACT ?
       ## Add these new keywords supported since 5.005
      (ABSTRACT                 => "Automatic constructor, accessors & SQL DB mapping",
       AUTHOR                   => "Sam Vilain <sam@vilain.net>") : ()),
    );



