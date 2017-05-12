use strict;
use lib 't/lib';  # distributed here until changes are incorporated into the real version
use Apache::test qw(test);
use Test;

my %requests = 
  (
   2  => '/docs/simple.html',
   3  => {uri=>'/docs/simple.html',
          headers=>{'Accept-Encoding' => 'gzip'},
         },
  );


my %special_tests = 
  (
   3 => {content => \&decomp}, 
  );

plan tests => 1+keys(%requests);
ok 1;

foreach my $testnum (sort {$a<=>$b} keys %requests) {
  my $response = Apache::test->fetch($requests{$testnum});
  my $content = $response->content;
  
  if ($special_tests{$testnum}{content}) {
    $content = $special_tests{$testnum}{content}->($content);
  }
  unless (ok $content, scalar `cat t/check/$testnum`) {
    print $response->headers_as_string();
  }
}

######################################################################
use Compress::Zlib;

sub decomp {
  my $content = shift;
  my $file = 't/tmp';
  open TMP, ">$file" or die "Can't create $file: $!";
  print TMP $content;
  close TMP;
  
  my $gz = gzopen($file, 'rb') or die $!;
  my $buffer;
  $gz->gzread($buffer, 400);
  
  unlink $file;
  return $buffer;
}
