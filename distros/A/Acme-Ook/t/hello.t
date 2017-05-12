use Acme::Ook;
use File::Spec;

print "1..1\n";

my $ook = File::Spec->catfile("ook", "hello.ook");
my $Ook = Acme::Ook->new;
my $out = tie *STDOUT, 'FakeOut';
$Ook->Ook($ook);
# Copy this then undef $out to avoid untie attempted while 1 inner references
# warning from perl pre 5.8
my $output = $$out;
undef $out;
untie *STDOUT;
print $output eq "Hello World!" ? "ok 1\n" : "not ok 1 # $output\n";

package FakeOut;
sub TIEHANDLE {
  bless(\(my $text), $_[0]);
}
sub clear {
  ${ $_[0] } = '';
}
sub PRINT {
  my $self = shift;
  $$self .= join('', @_);
}
