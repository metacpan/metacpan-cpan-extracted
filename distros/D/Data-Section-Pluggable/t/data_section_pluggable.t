use Test2::V0 -no_srand => 1;
use experimental qw( signatures );
use Data::Section::Pluggable;
use Path::Tiny ();

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

my $dir = Path::Tiny->tempdir;

Data::Section::Pluggable
  ->new
  ->extract($dir);

is(
    $dir,
    object {
        call [child => 'etc/foo.yml'] => object {
            call slurp_utf8 => "---\na: config\n";
        };
        call [child => 'foo.txt'] => object {
            call slurp_utf8 => "plain hello world\n";
        };
        call [child => 'foo.bin'] => object {
            call slurp_raw => "Hello world\n";
        }
    },
    'method ->extract',
);

$dir->child('etc/foo.yml')->spew_raw("---\nb: config\n");
$dir->child('foo.txt')->remove;
$dir->child('foo.bin')->spew_raw("Replaced Hello world\n");

is(
    Data::Section::Pluggable->new(prefer_filesystem => $dir),
    object {
        call get_data_section => hash {
            field 'foo.txt' => "plain hello world\n";
            field 'foo.bin' => "Replaced Hello world\n";
            field 'etc/foo.yml' => "---\nb: config\n";
            etc;
        };
    },
    'attribute ->prefer_filesystem',
);

is(
    Data::Section::Pluggable->new(filename => "corpus/lib/Bugs.pm"),
    object {
        call get_data_section => hash {
            field 'foo.txt' => "Hello World!\n";
            end;
        };
    },
    'attribute ->filename',
);

done_testing;

__DATA__
@@ etc/foo.yml
---
a: config
@@ foo.txt
plain hello world
@@ foo.bin (base64)
SGVsbG8gd29ybGQK
__END__
