package DBIx::Class::BitField;
our $VERSION = '0.13';


use strict;
use warnings;

use Carp;

use base 'DBIx::Class';

sub register_column {
  my ($self, $column, $info, @rest) = @_;
  
  return $self->next::method($column, $info, @rest)
    unless($self->__is_bitfield($info));
    
  $info->{accessor} ||= '_'.$column;
  $info->{default_value} = 0;
  $info->{is_numeric} = 0;
  
  $self->next::method($column, $info, @rest);
  
  my $prefix = $info->{bitfield_prefix} || q{};
  
  my @fields = @{$info->{bitfield}};
  
  
  {
    my $i = 0;
    no strict qw(refs);
    foreach my $field (@fields) {
      if($self->can($prefix.$field) && 1 == 0) {
        carp 'Bitfield accessor '.$prefix.$field.' cannot be created since there is an accessor of that name already';
        $i++;
        next;
      }
      my $bit = 2**$i;
      *{$self.'::'.$prefix.$field} = sub { shift->__bitfield_item($field, $bit, $info->{accessor}, @_) };
      $i++;
    }
    
    *{$self.'::'.$column} = sub { shift->__bitfield($column, $info->{accessor}, \@fields, @_) };
  }
  
  
}

sub __is_bitfield {
  my ($self, $info) = @_;
  return defined $info->{data_type} && $info->{data_type} =~ /^int/xsmi && ref $info->{bitfield} eq "ARRAY";
}


sub __is_bitfield_item {
  my ($self, $column) = @_;
  return if($self->has_column($column));# || $self->is_relationship($column));
  foreach my $c ($self->columns) {
    my $info = $self->column_info($c);
    next unless($self->__is_bitfield($info));
    return $c if(grep { $_ eq $column } @{$info->{bitfield} || []});
    my $prefix = $info->{bitfield_prefix} || '';
    return $c if(grep { $prefix.$_ eq $column } @{$info->{bitfield} || []});
  }
  return;
}

sub store_column {
  my ($self, $column, $value) = @_;
  my $info= $self->column_info($column);
  if($self->__is_bitfield($info) && ($value !~ /^\d+$/ || int($value) ne $value)) {
    if(ref $value eq 'ARRAY') {
      foreach my $bit (@{$value || []}) {
        $self->can($bit) ? $self->$bit(1) : croak qq(bitfield item '$bit' does not exist);
      }
    } else {
      $self->can($value) ? $self->$value(1) : croak qq(bitfield item '$value' does not exist);
    }
    my $accessor = $info->{accessor};
    $value = $self->$accessor;
  }
  $self->next::method($column, $value);
}

sub __bitfield_item {
  my ($self, $field, $bit, $accessor, $set) = @_;
  my $value = $self->$accessor || 0;
  return ($value | $bit) == $value ? 1 : 0 unless defined $set;
  
  $self->$accessor($set ? $value | $bit | $bit : $value - ($value & $bit));
  return $set;
}

sub __bitfield {
  my ($self, $column, $accessor, $fields) = @_;
  
  my $value = $self->$accessor || return [];
  
  my @fields = ();
  my $i = 0;
  foreach my $field (@{$fields}) {
    push(@fields, $field) if(($value | 2**$i) == $value);
    $i++;
  }
  
  return \@fields;
}

sub new {
    my ($self, $data, @rest) = @_;
    my $bits = {};
    while(my ($column, $value) = each %{$data || {}}) {
        next unless(my $bitfield = $self->__is_bitfield_item($column));
        $bits->{$column} = $value;
        delete $data->{$column};
    }
    my $row = $self->next::method($data, @rest);
    
    while(my ($column, $value) = each %{$bits || {}}) {
        $row->$column($value);
    }
    
    
    return $row;
}

1;




=pod

=head1 NAME

DBIx::Class::BitField - Store multiple boolean fields in one integer field

=head1 VERSION

version 0.13

=head1 SYNOPSIS

  package MySchema::Item;

  use base 'DBIx::Class';

  __PACKAGE__->load_components(qw(BitField Core));

  __PACKAGE__->table('item');

  __PACKAGE__->add_columns(
    id     =>   { data_type => 'integer' },
    status =>   { data_type => 'integer', 
                  bitfield => [qw(active inactive foo bar)],
    },
    advanced_status => { data_type => 'integer', 
                         bitfield => [qw(1 2 3 4)], 
                         bitfield_prefix => 'status_', 
                         accessor => '_foobar',
                         is_nullable => 1,
    },

  );

  __PACKAGE__->set_primary_key('id');

  __PACKAGE__->resultset_class('DBIx::Class::ResultSet::BitField');

  1;

Somewhere in your code:

  my $rs = $schema->resultset('Item');
  my $item = $rs->create({
      status          => [qw(active foo)],
      advanced_status => [qw(status_1 status_3)],
  });

  $item2 = $rs->create({
        active   => 1,
        foo      => 1,
        status_1 => 1,
        status_3 => 1,
  });

  # $item->active   == 1
  # $item->foo      == 1
  # $item->status   == ['active', 'foo']
  # $item->_status  == 5
  # $item->status_1 == 1
  # $item->status_3 == 1

  $item->foo(0);
  $item->update;

=head1 DESCRIPTION

This module is useful if you manage data which has a lot of on/off attributes like I<active, inactive, deleted, important, etc.>. 
If you do not want to add an extra column for each of those attributes you can easily specify them in one C<integer> column.

A bit field is a way to store multiple bit values on one integer field.

=for html <p>Read <a href="http://en.wikipedia.org/wiki/Bit_field">this wikipedia article</a> for more information on that topic.</p>

The main benefit from this module is that you can add additional attributes to your result class whithout the need to 
deploy or change the schema on the data base.

B<This module encourages to not normalize your schema. You should consider a C<has_many> relationship to a table which holds
all the flags instead of this module.>

=head2 Example

A bit field C<status> with C<data_type> set to C<int> or C<integer> (case insensitive) and C<active, inactive, deleted> will create
the following accessors:

=over 

=item C<< $row->status >>

This is B<not> the value which is stored in the database. This accessor returns the status as an array ref. 
The array ref is empty if no status is applied. 

You can use this method to set the value as well:

  $row->status(['active', 'inactive']);
  # $row->status == ['active', 'inactive']

=item C<< $row->active >>, C<< $row->inactive >>, C<< $row->deleted >>

These accessors return either C<1> or C<0>. If you add a parameter they will act like normal column accessors by returning that value.

  my $foo = $row->active(1);
  # $foo         == 1
  # $row->active == 1
  # $row->status == ['active']

=item C<< $row->_status >>

This accessor will hold the internal integer representation of the bit field.

  $row->status(['active', 'inactive']);
  # $row->_status == 3

You can change the name of the accessor via the C<accessor> attribute:

  __PACKAGE__->add_columns(
      status =>   { data_type => 'integer', 
                    bitfield  => [qw(active inactive deleted)],
                    accessor  => '_status_accessor',
      },
  );

=back 

=head2 ResultSet operations

In order to use result set operations like C<search> or C<update> you need to set the result set class to
C<DBIx::Class::ResultSet::BitField> or to a class which inherits from it.

  __PACKAGE__->resultset_class('DBIx::Class::ResultSet::BitField');

=head3 update

  $rs->update({ status => ['active'] });

This will update the status of all items in the result to C<active>. This is done in a single SQL query.

=head3 search_bitfield

To search a result set for a specific value of the bitfield use C<search_bitfield>.

You can either make a OR search:

  my $new_rs = $rs->search_bitfield([ status2 => 1, status3 => 1 ]);

or AND:

  my $new_rs = $rs->search_bitfield({ status2 => 1, status3 => 1 });

This method uses bitwise operators in SQL. Depending on your database it is possible to create an index so
the search is as fast as using a single boolean column.
=head1 AUTHOR

  Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut 



__END__

