package t::APISchema::Generator::Markdown::Formatter;
use lib '.';
use t::test;
use t::test::fixtures;

use APISchema::Generator::Markdown::Formatter ();

sub _type : Tests {
    for my $case (
        [{} => 'undefined'],
        [{type => 'object'} => '`object`'],
        [{type => ['object', 'number']} =>  '`"object"`&#124;`"number"`'],
        [{'$ref' => '#/resource/foo'} =>  '[`foo`](#resource-foo)'],
        [{oneOf => [{ type =>'object'}, {type =>'number'}]} =>  '`object`&#124;`number`'],
    ) {
       is APISchema::Generator::Markdown::Formatter::type($case->[0]), $case->[1], $case->[2] || $case->[1];
    }
}