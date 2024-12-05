use warnings;
use 5.020;
use Data::Section::Pluggable;

my $dsp = Data::Section::Pluggable->new
                                  ->add_plugin('trim')
                                  ->add_plugin('json');

# prints "Welcome to Perl" without prefix
# or trailing white space.
say $dsp->get_data_section('hello.txt');

# also prints "Welcome to Perl"
say $dsp->get_data_section('hello.json')->{message};

# prints "This is base64 encoded.\n"
say $dsp->get_data_section('hello.bin');

__DATA__

@@ hello.txt
  Welcome to Perl


@@ hello.json
{"message":"Welcome to Perl"}

@@ hello.bin (base64)
VGhpcyBpcyBiYXNlNjQgZW5jb2RlZC4K
