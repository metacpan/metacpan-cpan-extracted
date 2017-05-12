
package
ASP4::OutBuffer;

use strict;
use warnings 'all';


sub new
{
  return bless { data => '' }, shift;
}# end new()

sub add
{
  my ($s, $str) = @_;
  return unless defined($str);
  $s->{data} .= $str;
  return;
}# end add()

sub data  { shift->{data} }
sub clear { shift->{data} = '' }

sub DESTROY
{
  my $s = shift;
  delete($s->{data});
  undef(%$s);
}# end DESTROY()

1;# return true:

