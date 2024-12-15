use Test2::V0 -no_srand => 1;
use experimental qw( signatures );
use Data::Section::Writer;

plan 3;

package Data::Section::Pluggable::Plugin::MyPlugin1 {
    use Role::Tiny::With;
    with 'Data::Section::Pluggable::Role::FormatContentPlugin';

    sub extensions ($class) {
        package main;
        is(
            [$class],
            ['Data::Section::Pluggable::Plugin::MyPlugin1'],
            'arguments to ->extensions'
        );
        return ('txt')
    }

    sub format_content ($class, $writer, $content) {
        package main;
        is(
            [ $class, $writer, $content ],
            [ 'Data::Section::Pluggable::Plugin::MyPlugin1', object { prop isa => 'Data::Section::Writer' }, "hello world" ],
            'arguments to ->process_content',
        );
        return "[$content]"
    }

}

is(
    Data::Section::Writer->new->add_plugin('my_plugin1'),
    object {
        prop isa => 'Data::Section::Writer';
        call [add_file => "hello.txt", "hello world"] => object {};
        call [add_file => "hello.t2", "hello world"] => object {};
        call render_section => "__DATA__\n" .
                               "\@\@ hello.t2\n" .
                               "hello world\n" .
                               "\@\@ hello.txt\n" .
                               "[hello world]\n";
    },
    'simple',
);

done_testing;
