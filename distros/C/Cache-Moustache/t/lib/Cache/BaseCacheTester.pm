######################################################################
# $Id: BaseCacheTester.pm,v 1.7 2002/04/07 17:04:46 dclinton Exp $
# Copyright (C) 2001-2003 DeWitt Clinton  All Rights Reserved
#
# Software distributed under the License is distributed on an "AS
# IS" basis, WITHOUT WARRANTY OF ANY KIND, either expressed or
# implied. See the License for the specific language governing
# rights and limitations under the License.
######################################################################


package Cache::BaseCacheTester;


use strict;


sub new
{
  my ( $proto, $base_test_count ) = @_;
  my $class = ref( $proto ) || $proto;
  my $self  = {};
  bless ( $self, $class );

  $base_test_count = defined $base_test_count ? $base_test_count : 0 ;

  $self->_set_test_count( $base_test_count );

  return $self;
}


sub ok
{
  my ( $self ) = @_;

  my $test_count = $self->_get_test_count( );

  print "ok $test_count\n";

  $self->_increment_test_count( );
}


sub not_ok
{
  my ( $self, $message ) = @_;

  my $test_count = $self->_get_test_count( );

  print "not ok $test_count # failed '$message'\n";

  $self->_increment_test_count( );
}


sub skip
{
  my ( $self, $message ) = @_;

  my $test_count = $self->_get_test_count( );

  print "ok $test_count # skipped $message \n";

  $self->_increment_test_count( );
}


sub _set_test_count
{
  my ( $self, $test_count ) = @_;

  $self->{_Test_Count} = $test_count;
}


sub _get_test_count
{
  my ( $self ) = @_;

  return $self->{_Test_Count};
}


sub _increment_test_count
{
  my ( $self ) = @_;

  $self->{_Test_Count}++;
}


1;

