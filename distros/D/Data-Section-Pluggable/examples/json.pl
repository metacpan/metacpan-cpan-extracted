use warnings;
use 5.020;
use Data::Section::Pluggable;

my $dsp = Data::Section::Pluggable->new
                                  ->add_plugin('json');

# prints "Welcome to Perl"
say $dsp->get_data_section('hello.json')->{message};

__DATA__
@@ hello.json
{"message":"Welcome to Perl"}
