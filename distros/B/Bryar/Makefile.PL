use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'              => 'Bryar',
    'VERSION_FROM'      => 'lib/Bryar.pm',
    'EXE_FILES'         => ['bryar-newblog'],
    'PREREQ_PM'         => {
           File::Find::Rule => 0.09,
           Template => 2.0,
           Template::Provider::Encoding => 0,
           Time::Piece => 1.0,
           DateTime => 0,
           Digest::MD5 => 0,
           Calendar::Simple => 0,
           HTTP::Date => 0,
           UNIVERSAL::require => 0
        },
    NO_META => 1,
);

print "\nYou probably want to run bryar-newblog in a likely home for\n";
print "your blog once we've finished installing.\n\n";
print "If you are upgrading, please read the Changes file\n\n";
