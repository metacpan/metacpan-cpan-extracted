use Test2::V0 -no_srand => 1;
use Data::Section::Pluggable;

is(
    Data::Section::Pluggable->new,
    object {
        call [add_plugin => 'yaml'] => object {
            prop isa => 'Data::Section::Pluggable';
        };
        call get_data_section => {
            'foo.yaml' => {a => 1},
            'foo.txt'  => "---\na: 1\n",
        };
    },
    'add_plugin',
);

is(
    [Data::Section::Pluggable::Plugin::Yaml->extensions],
    ['yaml','yml'],
    '->extensions',
);

done_testing;

__DATA__
@@ foo.yaml
---
a: 1
@@ foo.txt
---
a: 1
__END__
