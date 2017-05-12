use ExtUtils::MakeMaker;
use 5.006001;
WriteMakefile(
    NAME		=> 'Config::ApacheFormat',
    VERSION_FROM	=> 'ApacheFormat.pm',
    PREREQ_PM		=> {
                            'Class::MethodMaker' => "1.08",
                            'Carp'               => 0,
                            'Text::Balanced'     => "1.89",
                            'File::Spec'         => "0.82",
                            'Scalar::Util'       => 0,
                           }, 
    ABSTRACT_FROM       => 'ApacheFormat.pm',
    AUTHOR              => 'Sam Tregar <sam@tregar.com>',
);
