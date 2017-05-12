package BGPmon::CPM::PList::Manager;

use base qw(Rose::DB::Object::Manager);

our $VERSION = '1.02';

sub object_class { 'BGPmon::CPM::PList' }

__PACKAGE__->make_manager_methods('plists');

=head1 SUBROUTINES/METHODS

=head2 getListNames

Get an array of list names available in this DB

Input : None

Output: An array of strings

=cut
sub getListNames
{
  my $list_ref = BGPmon::CPM::PList::Manager->get_plists;
  my @lists;
  foreach my $list (@$list_ref){
    push @lists,$list->name;
  }
  return @lists;
}

=head2 getListByName

Get an array of list names available in this DB

Input : A reference to the PList object, list name

Output: A reference to the loaded list

=cut
sub getListByName
{
  my $self = shift;
  my $name = shift;
  my $list = BGPmon::CPM::PList->new(name=>$name);
  my $res =  $list->load; 
  if(!defined($res)){
    return undef;
  }
  return $res;
 
}

=head2 createListByName

Create a new list with the given name

Input : A reference to the PList object, list name

Output: The DBID of the new list or 0 on failure

=cut
sub createListByName
{
  my $self = shift;
  my $name = shift;
  my $list = BGPmon::CPM::PList->new(name=>$name);
  my $obj = $list->load;
  if($obj){
    return 0;
  }
  $obj = $list->save;
  if($obj){
    return $list->dbid;
  }
  return 0;
}

=head2 export2CSV

Export the list to a list of comma seperated values

Input : A reference to the PList object, list name

Output: An array of values

=cut
sub export2CSV
{
  my $self = shift;
  my $name = shift;
 
  my $list = BGPmon::CPM::PList->new(name=>$name);
  $list->load; 

  my @prefixes = $list->prefixes;
  return @prefixes;
  #my @formatted;
  #foreach my $prefix (@prefixes){
    #push @formatted,$prefix->prefix;
  #}
  #return @formatted;
}

1;
__END__

=head1 NAME

BGPmon::CPM::PList::Manager - A helper module for accessing the PList module

=head1 SYNOPSIS

  use BGPmon::CPM::PList;

=head1 DESCRIPTION


=head2 EXPORT


=head1 SEE ALSO


=head1 AUTHOR

Cathie Olschanowsky, E<lt>bgpmon@cs.colostate.eduE<gt>

=head1 COPYRIGHT AND LICENSE

COPYRIGHT AND LICENCE

      Copyright (c) 2012 Colorado State University

      Permission is hereby granted, free of charge, to any person
      obtaining a copy of this software and associated documentation
      files (the "Software"), to deal in the Software without
      restriction, including without limitation the rights to use,
      copy, modify, merge, publish, distribute, sublicense, and/or
      sell copies of the Software, and to permit persons to whom
      the Software is furnished to do so, subject to the following
      conditions:

      The above copyright notice and this permission notice shall be
      included in all copies or substantial portions of the Software.

      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
      EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
      OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
      NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
      HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
      WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
      FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
      OTHER DEALINGS IN THE SOFTWARE.


=cut
