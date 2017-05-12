use inc::Module::Install;

name('Data-SExpression');
license('Perl');

version_from('lib/Data/SExpression.pm');

requires('Class::Accessor::Fast');

build_requires('Test::More');
build_requires('Test::Deep');

postamble(<<"END_MAKEFILE");
lib/Data/SExpression/Parser.pm: lib/Data/SExpression/Parser.yp
\t\$(PERL) build/regen_parser.pl
END_MAKEFILE

no_index directory => 'build';
no_index package   => 'Parse::Yapp::Driver';

WriteAll;
