use warnings;
use 5.020;
use experimental qw( signatures );
use Data::Section::Pluggable;

package Data::Section::Pluggable::Plugin::MyPlugin {
    use Role::Tiny::With;
    use Class::Tiny qw( extensions );
    with 'Data::Section::Pluggable::Role::ContentProcessorPlugin';

    sub process_content ($self, $dps, $content) {
        $content =~ s/\s*\z//;  # trim trailing whitespace
        return "[$content]";
    }
}

my $dps = Data::Section::Pluggable->new
                                  ->add_plugin('my_plugin', extensions => ['txt']);

# prints '[Welcome to Perl]'
say $dps->get_data_section('hello.txt');

__DATA__
@@ hello.txt
Welcome to Perl

