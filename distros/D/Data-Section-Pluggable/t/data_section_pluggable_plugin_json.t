use Test2::V0 -no_srand => 1;
use Data::Section::Pluggable;

is(
    Data::Section::Pluggable->new,
    object {
        call [add_plugin => 'json'] => object {
            prop isa => 'Data::Section::Pluggable';
        };
        call get_data_section => {
            'foo.json' => {a => 1},
            'foo.txt'  => "{\"a\":1}\n",
        };
    },
    'add_plugin',
);

done_testing;

__DATA__
@@ foo.json
{"a":1}
@@ foo.txt
{"a":1}
__END__
