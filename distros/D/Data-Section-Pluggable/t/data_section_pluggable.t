use Test2::V0 -no_srand => 1;
use experimental qw( signatures );
use Data::Section::Pluggable;

is(
    Data::Section::Pluggable->new,
    object {
        prop isa => 'Data::Section::Pluggable';
        call package => 'main';
        call [get_data_section => 'foo.txt'] => "plain hello world\n";
        call [get_data_section => 'foo.bin'] => "Hello world\n";
        call_list [get_data_section => 'bogus'] => [U()];
        call get_data_section => hash {
            field 'foo.txt' => "plain hello world\n";
            field 'foo.bin' => "Hello world\n";
            etc;
        };

        call [add_format => txt => sub ($, $c) { "||$c" }] => object {
            # returns self.
            prop isa => 'Data::Section::Pluggable';
        };

        call [get_data_section => 'foo.txt'] => "||plain hello world\n";

        call [add_format => bin => sub ($, $c) { ">>$c" }] => object {
            # returns self.
            prop isa => 'Data::Section::Pluggable';
        };

        call [get_data_section => 'foo.bin'] => ">>Hello world\n";

        call [add_format => bin => sub ($,$c) { "xx$c" }] => object {
            # returns self.
            prop isa => 'Data::Section::Pluggable';
        };

        call [get_data_section => 'foo.bin'] => "xx>>Hello world\n";
    },
    'all defaults',
);

is(
    Data::Section::Pluggable->new("Foo"),
    object {
        prop isa => 'Data::Section::Pluggable';
        call package => 'Foo';
    },
    'constructor with scalar',
);

is(
    Data::Section::Pluggable->new(package => "Foo"),
    object {
        prop isa => 'Data::Section::Pluggable';
        call package => 'Foo';
    },
    'constructor with hash',
);

is(
    Data::Section::Pluggable->new({ package => "Foo" }),
    object {
        prop isa => 'Data::Section::Pluggable';
        call package => 'Foo';
    },
    'constructor with hash ref',
);

done_testing;

__DATA__
@@ foo.txt
plain hello world
@@ foo.bin (base64)
SGVsbG8gd29ybGQK
__END__
