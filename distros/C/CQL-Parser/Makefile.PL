use inc::Module::Install 1.06;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/CQL/Parser.pm > README' );
}

perl_version '5.008';

name 'CQL-Parser';
all_from 'lib/CQL/Parser.pm';

requires 'String::Tokenizer' => '0.05';
requires 'Clone'             => '0.15';
requires 'Class::Accessor'   => '0.1';

test_requires 'Test::More';
test_requires 'Test::Exception';

repository "http://github.com/bricas/cql-parser";

WriteAll;
