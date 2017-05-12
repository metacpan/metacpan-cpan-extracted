use strict;
use warnings;
use Test::More;
use Test::Exception;
use t::TestUtils;

#-- InitialValue in FormalParameters/DataFields

my $xml = q|
    <DataFields>
        <DataField Id="number">
            <DataType><BasicType Type="INTEGER"/></DataType>
            <InitialValue>55</InitialValue>
        </DataField>
        <DataField Id="string" IsArray="0">
            <DataType><BasicType Type="STRING"/></DataType>
            <InitialValue>'Some Thing'</InitialValue>
        </DataField>
        <DataField Id="array" IsArray="1">
            <DataType><BasicType Type="INTEGER"/></DataType>
            <InitialValue>[55,56]</InitialValue>
        </DataField>
        <DataField Id="hash">
            <DataType><SchemaType/></DataType>
            <InitialValue>{ some => 'thing' }</InitialValue>
        </DataField>
        <DataField Id="hasharray" IsArray="1">
            <DataType><SchemaType></SchemaType></DataType>
            <InitialValue>[{ nr => var.array.0, desc => [attribute('hash').some] }]</InitialValue>
        </DataField>
    </DataFields>
|;


{
my ($engine, $process) = process_wrap($xml);
my $pi = $process->new_instance();

is($pi->attribute('number')->value, 55);
is($pi->attribute('string')->value, 'Some Thing');
is_deeply($pi->attribute('array')->value, [55,56]);
is_deeply($pi->attribute('hash')->value, { some => 'thing' });
is_deeply($pi->attribute('hasharray')->value, [{ nr => 55, desc => ['thing'] }]);
}

#-- Condition

#-- ActualParameters

#-- Assignments
{
$xml .= q|
    <Assignments>
        <Assignment AssignTime="End">
            <Target>hash.some</Target>
            <Expression>'A2'</Expression>
        </Assignment>
        <Assignment AssignTime="Start">
            <Target>hasharray.0.nr</Target>
            <Expression>var.array.1</Expression>
        </Assignment>
    </Assignments>
|;
my ($engine, $process) = process_wrap($xml);
my $pi = $process->new_instance();
$engine->start_process_instance($pi);

is_deeply($pi->attribute('hash')->value, { some => 'A2' });
is_deeply($pi->attribute('hasharray')->value, [{ nr => 56, desc => ['thing'] }]);

}


#-- Script


done_testing;
