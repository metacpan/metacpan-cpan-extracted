use Test2::V0 -no_srand => 1;
use experimental qw( signatures );
use Data::Section::Pluggable;

package Data::Section::Pluggable::Plugin::MyPlugin1 {
    use Role::Tiny::With;
    with 'Data::Section::Pluggable::Role::ContentProcessorPlugin';
    sub extensions ($class) {
      package main;
      is(
        [$class],
        ['Data::Section::Pluggable::Plugin::MyPlugin1'],
        'arguments to ->extensions'
      );
      return ('txt')
    }
    sub process_content ($class, $dps, $content) {
      package main;
      is(
        [ $class, $dps, $content ],
        [ 'Data::Section::Pluggable::Plugin::MyPlugin1', object { prop isa => 'Data::Section::Pluggable' }, "Hello\n" ],
        'arguments to ->process_content',
      );
      return "[$content]"
    }
}

is(
    Data::Section::Pluggable->new->add_plugin('my_plugin1'),
    object {
        prop isa => 'Data::Section::Pluggable';
        call get_data_section => hash {
            field 'hello.txt' => "[Hello\n]";
            field 'hello.html' => "<html>\n";
            etc;
        };
    },
    'simple',
);

package Data::Section::Pluggable::Plugin::MyPlugin2 {
    use Role::Tiny::With;
    with 'Data::Section::Pluggable::Role::ContentProcessorPlugin';
    sub extensions ($class) { ('txt','html') }
    sub process_content ($class, $dps, $content) { "[$content]" }
}

is(
    Data::Section::Pluggable->new->add_plugin('my_plugin2'),
    object {
        prop isa => 'Data::Section::Pluggable';
        call get_data_section => hash {
            field 'hello.txt' => "[Hello\n]";
            field 'hello.html' => "[<html>\n]";
            etc;
        };
    },
    'extensions returns list',
);

package Data::Section::Pluggable::Plugin::MyPlugin3 {
    use Role::Tiny::With;
    with 'Data::Section::Pluggable::Role::ContentProcessorPlugin';
    sub extensions ($class) { ['txt','html'] }
    sub process_content ($class, $dps, $content) { "[$content]" }
}

is(
    Data::Section::Pluggable->new->add_plugin('my_plugin3'),
    object {
        prop isa => 'Data::Section::Pluggable';
        call get_data_section => hash {
            field 'hello.txt' => "[Hello\n]";
            field 'hello.html' => "[<html>\n]";
            etc;
        };
    },
    'extensions returns array ref',
);

package Data::Section::Pluggable::Plugin::MyPlugin4 {
    use Role::Tiny::With;
    with 'Data::Section::Pluggable::Role::ContentProcessorPlugin';
    sub new ($class, %args) {
        my $self = bless {}, __PACKAGE__;
        package main;
        is(
            [$class, \%args],
            ['Data::Section::Pluggable::Plugin::MyPlugin4', { foo => 'bar'}],
            'arguments to ->new',
        );
        return $self;
    }
    sub extensions ($self) {
      package main;
      is(
        [$self],
        [object { prop isa => 'Data::Section::Pluggable::Plugin::MyPlugin4' }],
        'arguments to ->extensions'
      );
      return ('txt')
    }
    sub process_content ($self, $dps, $content) {
      package main;
      is(
        [ $self, $dps, $content ],
        [ object { prop isa => 'Data::Section::Pluggable::Plugin::MyPlugin4' }, object { prop isa => 'Data::Section::Pluggable' }, "Hello\n" ],
        'arguments to ->process_content',
      );
      return "[$content]"
    }
}

is(
    Data::Section::Pluggable->new->add_plugin('my_plugin4', foo => 'bar'),
    object {
        prop isa => 'Data::Section::Pluggable';
        call get_data_section => hash {
            field 'hello.txt' => "[Hello\n]";
            field 'hello.html' => "<html>\n";
            etc;
        };
    },
    'extensions returns array ref',
);

done_testing;

__DATA__
@@ hello.txt
Hello
@@ hello.html
<html>
__END__
