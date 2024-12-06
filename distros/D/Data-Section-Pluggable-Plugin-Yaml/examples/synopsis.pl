use warnings;
use 5.020;
use Data::Section::Pluggable;

my $dsp = Data::Section::Pluggable->new
                                  ->add_plugin('yaml');

# prints "Welcome to Perl"
say $dsp->get_data_section('hello.yml')->{message};

__DATA__
@@ hello.yml
---
message: Welcome to Perl
