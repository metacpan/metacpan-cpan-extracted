package Hoge;
our $count = 0;
sub new{
  my $class = shift;
  $count++;
  warn "new";
  return bless {},$class;
}
sub hoge{return  $count;}

package main;
use Test::More;
use File::Temp;
BEGIN { use_ok('Aspect::Loader') };
my $tmp  = new File::Temp;
my $yaml = <<__END_YAML__;
aspects:
 - library: Singleton
   call: Hoge::new
 - library: Singleton
   call: Aspect::Loader::TestMock::Object::hoge
__END_YAML__

print $tmp $yaml;
$tmp->close;

Aspect::Loader->yaml_loader($tmp->filename);
is(Hoge->new->hoge,1);
is(Hoge->new->hoge,1);
is(Aspect::Loader::TestMock::Object->new->hoge,"hoge","Dynamic load");
done_testing;
