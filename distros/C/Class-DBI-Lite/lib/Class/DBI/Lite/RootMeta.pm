
package 
Class::DBI::Lite::RootMeta;

use strict;
use warnings 'all';
use List::Util 'shuffle';

our %instances = ( );


#==============================================================================
sub new
{
  my ($s, $dsn) = @_;
#warn "$s.new(@$dsn) => host=" . ( $ENV{HTTP_HOST} || 'N/A' );
  
  my $key = join ':', @$dsn;
  if( my $inst = $instances{$key} )
  {
    return $inst;
  }
  else
  {
    return $instances{$key} = bless {
      dsn         => $dsn,      # Global
      schema      => $dsn->[0], # Global
      master      => $dsn,
      slaves      => [ ],
      has_slaves  => 0,
    }, $s;
  }# end if()
}# end new()

sub dsn     { my $s = shift; @_ ? $s->{dsn}     = shift : $s->{dsn} }
sub schema  { my $s = shift; @_ ? $s->{schema}  = shift : $s->{schema} }
sub master  { my $s = shift; @_ ? $s->{master}  = shift : $s->{master} }
sub slaves  { shift->{slaves} }
sub has_slaves { shift->{has_slaves} }
sub add_slave { my $s = shift; $s->{has_slaves} = 1; push @{$s->{slaves}}, @_; $s->_randomize_slaves(); }

sub random_slave
{
  my $s = shift;
  push @{ $s->{slaves} }, shift( @{ $s->{slaves} } );
  $s->{slaves}->[0];
}# end random_slave()


sub _randomize_slaves
{
  my $s = shift;
  
  @{ $s->{slaves} } = shuffle( @{ $s->{slaves} } );
}# end _randomize_slaves()

1;# return true:

