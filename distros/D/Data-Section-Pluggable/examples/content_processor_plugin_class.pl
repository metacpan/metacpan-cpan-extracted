use warnings;
use 5.020;
use experimental qw( signatures );
use Data::Section::Pluggable;

package Data::Section::Pluggable::Plugin::MyPlugin {
    use Role::Tiny::With;
    with 'Data::Section::Pluggable::Role::ContentProcessorPlugin';

    sub extensions ($class) {
        return ('txt');
    }

    sub process_content ($class, $dsp, $content) {
        $content =~ s/\s*\z//;  # trim trailing whitespace
        return "[$content]";
    }
}

my $dsp = Data::Section::Pluggable->new
                                  ->add_plugin('my_plugin');

# prints '[Welcome to Perl]'
say $dsp->get_data_section('hello.txt');

__DATA__
@@ hello.txt
Welcome to Perl

