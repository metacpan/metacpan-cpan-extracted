use warnings;
use 5.020;
use Data::Section::Pluggable;

my $dsp = Data::Section::Pluggable->new
                                  ->add_plugin('trim');

# prints "Welcome to Perl" without prefix
# or trailing white space.
say $dsp->get_data_section('hello.txt');

__DATA__

@@ hello.txt
  Welcome to Perl


__END__
