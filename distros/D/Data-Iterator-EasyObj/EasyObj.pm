package Data::Iterator::EasyObj;

use strict;
use vars qw/$AUTOLOAD $VERSION/;
$VERSION = 0.01;
use Data::Dumper;

sub new {
  my ($class,$data,$fields,%args) = @_;
  my $fieldshash;
#  warn "fields : \n", Dumper($fields), "\n";
  if (lc(ref $fields) eq "hash") {
    foreach my $key (keys %$fields) {
      if (ref($fields->{$key})) {
	$fieldshash->{$key} = $fields->{$key};
	warn "using id\n";
      } else {
	$fieldshash->{$key} = { id => $fields->{$key} };
	warn "creating id\n";
      }
    }
  } elsif (lc(ref $fields) eq "array") {
    my $i = 0;
    foreach my $field (@$fields) {
      $fieldshash->{$field} = { id => $i++} ;
    }
  } else {
    die "fields must be an arrayref or hashref\n";
  }
#  warn "fieldshash : \n", Dumper($fieldshash), "\n";
  my $self = [ $data, $fieldshash, -1, scalar @{$data}, {}, 0];
  bless ($self,ref($class) || $class);
  $args{limit} ||= $self->[3];
  $self->offset($args{offset}) if ($args{offset});
  $self->limit($args{limit}) if ($args{limit});
  return $self;
}

sub next {
#  warn "getting next record\n";
  my $self = shift;
  $self->[2]+= $self->[5] if ($self->[2] < 0 );
  $self->[2]++;
  my $return = 1;
  if ($self->[2] >= $self->[3]) {
    $return = 0;
    $self->[2] = -1;
  } elsif ($self->[2] >= $self->[6]) {
    $return = 0;
    $self->[2] = -1;
  }
  $self->[4] = $self->[0][$self->[2]];
#  warn "current record ::\n", Dumper(@{$self->[4]});
  return $return;
}

sub offset {
  my ($self,$offset) = @_;
  $self->[5] = $offset;
  $self->[2] = $offset if ($self->[2] >= 0 && $self->[2] < $offset);
  my $return = 1;
  return $return;
}

sub limit {
  my ($self,$limit) = @_;
  my $return = 1;
  $self->[6] = $limit + $self->[5];
  return $return;
}


sub count {
  my $self = shift;
  return $self->[3];
}

sub add_column {
  my ($self, $name) = @_;
  my $fieldcount = keys %{$self->[1]};
#  warn "adding column : fieldcount is $fieldcount\n";
  $self->[1]{$name}{id}=$fieldcount;
}

sub add_value {
  my ($self, $field,$value) = @_;
#  warn"adding value : $field / $value";
  $self->[4][$self->[1]{$field}{id}] = $value;
}

########################################################################################

sub AUTOLOAD {
  no strict "refs";
  my ($self) = @_;
  $AUTOLOAD =~ /.*::(\w+)/;
  my $field = $1;
#  warn "(autoload) getting $field \n";
  exists $self->[1]{$field} or die "no such field : $field \n";
  *{$AUTOLOAD} = sub {
#    warn "(magic) getting $field -- counter : $self->[2] -- field : ", Dumper(%{$self->[1]{$field}})," -- value : $self->[4][$self->[1]{$field}{id}]\n";
    return $self->[4][$self->[1]{$field}{id}]
  };
  return $self->[4][$self->[1]{$field}{id}];
}

########################################################################################
########################################################################################

1;

###########################################################################

__END__

=head1

NAME Data::Iterator::EasyObj - Turn an array of arrays into an iterator object

=head1 SYNOPSIS

use Data::Iterator::EasyObj;

my $data = [
             [ 'AAAA', 'test foo A', '1111', $iterator2 ],

             [ 'BBBB', 'test foo B', '2222', $iterator2 ],
           ];
my $fields = [ 'Name', 'About' ,'Value', 'Loopy' ];
my $iterator = Data::Iterator::EasyObj->new($data,$fields);

$iterator->offset(2);

$iterator->limit(4);

while ($iterator->next) {

  $iterator->add_column('Extra');

  $iterator->add_value('Extra','extra stuff here');

  print "Name : ", $iterator->Name(), "\n";

  while ($iterator->Loop()->next) {
    print ".. ", $iterator->Loop()->subAA(),"\n"; 
  }

  print " extra : ", $iterator->Extra() , "\n";

}

=head1 DESCRIPTION

Data::Iterator::EasyObj makes your array of arrays into a handy iterator object with the ability to further nest additional data structures including Data::Iterator::EasyObj objects.

The iterator object provides direct access to the iterator contents - as well as the ability to add or update fields as you use the object.

The iterator object can also be limited or offset on the fly ideal for paging or grouping data sets.

=head1 USING

=head2 creating

When creating an iterator your data should be an array of arrays - like say dbi's fetchall_arrayref output or the contents of a CSV file - see the example data below

my $data = [
             [ 'AAAA', 'test foo A', '1111', $iterator2, { sadj=>'sas', sasas=>1} ],

                    .    .   .

             [ 'BBBB', 'test foo B', '2222', $iterator2, { sadj=>'sadas', sasas=>2} ],
           ];

Your field names can be a hashref or arrayref as in these examples :

my $fields = [ 'Name', 'About' ,'Value', 
                'Loopy', 'Deeper' ];

my $fields = { 'Name'=>0 , 'About'=>1 ,
               'Value'=>2, 'Loopy'=>3, 'Deeper'=>4 };

my $fields = { 'Name'=>{id => 0}, 'About'=>{id => 1},
               'Value'=>{id => 2}, 'Loopy'=>{id => 3},
               'Deeper' => {id => 4} };

You create the iterator by passing the data and fields, you can also pass extra arguments such as offset and limit

my $iterator = Data::Iterator::EasyObj->new($data,$fields);

my $iterator = Data::Iterator::EasyObj->new($data,$fields,offset=>$offset,limit=>10); # offset and limit are optional and independant of each other

Once the iterator has been created it waits for the next method to be called to move it to the first (or offset) record.

=head2 iterating

The eastiest way to iterate through the objects records is to call next in a while loop - next returns 0 when it hits the end (or limit) of the iterators data. When it reaches the end it resets itself to the start or offset.

while ($iterator->next) {

#  . . . loop through code

}

=head2 getting and setting values

To get the 'Name' field of the current record in the object, first ensure you are iterating through the data with $iterator->next() then call $iterator->Name() which returns the value or reference in Name for this record. The contents of the field can be a reference or a scalar or even another iterator.

To set the value of 'Name' for the current record call $iterator->add_value('Name',$new_value) where $new_value is the new value.

=head2 adding new fields

To add a new field to the iterator object (the new field will be added to every record but remain empty until set with the add_value method) call $iterator->add_column($column_name);

=head2 limit and offset

You can limit or offset the iterator much like a MySQL query, this is handy for paging or grouping through data.

When you call $iterator->offset(5) the iterator will start from the 6th record or skip straight to it if you are already started but haven't reached it. If you have already iterated past the offset then the iterator will continue and the will start from the offset the next time it iterates.

When you call $iterator->limit(10) the iterator will stop when it reaches the last record of the iterator or the offset record (i.e. 11th) and reset. If you have already iterated past the offset, then the iterator will stop iterating and reset itself when you next call $iterator->next();

=head1 EXPORT

None

=head1 AUTHOR

A. J. Trevena, E<lt>teejay@droogs.orgE<gt>

=head1 SEE ALSO

L<perl>.

Data::Iterator

=cut

