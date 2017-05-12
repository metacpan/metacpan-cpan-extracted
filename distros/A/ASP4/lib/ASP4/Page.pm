
package
ASP4::Page;

use strict;
use warnings 'all';
use base 'ASP4::HTTPHandler';
use Carp 'confess';
use ASP4::HTTPContext;
use ASP4::PageParser;


sub new
{
  my ($class, %args) = @_;
  
  my $s = bless {
    masterpage  => undef,
    package     => undef,
    filename    => undef,
    compiled_as => undef,
    script_name => $args{script_name} || undef,
    %args
  }, $class;
  
  $s->_init();
  
  return $s;
}# end new()


sub _init;


sub masterpage  { shift->{masterpage} }
sub package     { shift->{package} }
sub filename    { shift->{filename} }
sub script_name { shift->{script_name} }
sub compiled_as { shift->{compiled_as} }

1;# return true:

