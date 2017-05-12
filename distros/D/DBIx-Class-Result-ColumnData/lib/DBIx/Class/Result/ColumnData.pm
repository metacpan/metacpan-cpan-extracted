package DBIx::Class::Result::ColumnData;

use warnings;
use strict;
use Carp;

=head1 NAME

DBIx::Class::Result::ColumnData - Result::ColumnData component  for DBIx::Class

This module is used to extract column data only from a data object base on DBIx::Class::Core

It defined relationships methods to extract columns data only of relationships

=head1 VERSION

Version 0.16

=cut

our $VERSION = '0.16';


=head1 SYNOPSIS

in your DBIx::Class::Core base class declare Result::ColumnData component

    Package::Schema::Result::MyClass;

    use strict;
    use warning;

    __PACKAGE__->load_component(qw/ ... Result::DataColumn /);

    #Declare here associations before register_relationships_column_data
    __PACKAGE__->belongs_to(...);
    __PACKAGE__->has_many(...);

    __PACKAGE__->register_relationships_column_data();

you will use get_column_data functions on instance of MyClass

    $my_class->get_column_data
    $my_class->I<relationships>_column_data

you can also hide some columns with parameter hide_field on columns definition

    __PACKAGE__->add_columns("field_to_hide", {.... hide_field => 1});

=head2 columns_data

columns_data is decrecated, use get_column_data

=cut

sub columns_data
{
    carp "columns_data is decrecated, use get_column_data";
    my $obj = shift;

    $obj->get_column_data(@_);
}

=head2 get_column_data

return only column_data from an object DBIx::Class::Core without hide_field

=cut

sub get_column_data
{
    my ($obj, $options) = @_;
    my $rh_data;
    my $class = ref $obj;
    my @columns;
    if (defined $options->{columns} && ref $options->{columns} eq 'ARRAY' ){
        @columns = @{$options->{columns}};
    }
    else {
        @columns = $class->columns;
    }

    foreach my $key (@columns)
    {
        unless ($options->{with_all_fields})
        {
            next if ($class->column_info($key)->{hide_field});
        }
        if (ref($obj->get_column($key)) eq 'DateTime')
        {
            $rh_data->{$key} = $obj->_display_date($key) ;
        }
        else
        {
            $rh_data->{$key} = $obj->get_column($key);
        }
    }
    if ($obj->isa('DBIx::Class::VirtualColumns'))
    {
        #TODO : tests
        while (my ($virtual_column, $virtual_column_info) = each %{$class->_virtual_columns} )
        {
            if ( ref $virtual_column_info->{set_virtual_column} eq 'CODE')
            {
                $virtual_column_info->{set_virtual_column}->($obj);
            }
            $rh_data->{$virtual_column} = $obj->$virtual_column;
        }
    }

    if ($obj->isa('DBIx::Class::Result::Validation') && defined($obj->result_errors))
    {
        $rh_data->{result_errors} = $obj->result_errors;
    }
    return $rh_data;
}

=head2 get_all_column_data

return only column_data from an object DBIx::Class::Core with hide_field

=cut

sub get_all_column_data
{
  my $obj = shift;
  my $options = {with_all_fields => 1};
  return $obj->get_column_data($options);
}

sub _display_date
{
  my ($obj, $key) = @_;
  my $class = ref $obj;
  return $obj->$key->ymd  if $class->column_info($key)->{data_type} eq 'date';
  return $obj->$key->ymd.' '.$obj->$key->hms if $class->column_info($key)->{data_type} eq 'datetime';
  return '';
}

=head2 register_relationships_columns_data

register_relationships_columns_data is decrecated, use register_relationships_column_data

=cut

sub register_relationships_columns_data
{
    carp "register_relationships_columns_data is decrecated, use register_relationships_column_data";
    my $class = shift;

    $class->register_relationships_column_data(@_);
}

=head2 register_relationships_column_data

declare functions for each relationship on canva : I<relationship>_column_data which return a hash columns data for a single relationship and an list of hash columns data for multi relationships

    Package::Schema::Result::Keyboard->belongs_to( computer => "Package::Schema::Result::Computer", computer_id);
    Package::Schema::Result::Keyboard->has_many( keys => "Package::Schema::Result::Key", keyboard_id);

register_relationships_column_data generate instance functions for Keyboard object

    $keybord->keys_column_data()

    # return 
    #     [
    #       { id => 1, value => 'A', azerty_position => 1},
    #       { id => 2, value => 'B', azerty_position => 25},
    #       ....
    #     ];

    $keybord->cumputer_column_data()

    # return 
    #    { id => 1, os => 'ubuntu' };

=cut

sub register_relationships_column_data {
  my ($class) = @_;
  foreach my $relation ($class->relationships())
  {
    my $relation_type = $class->relationship_info($relation)->{attrs}->{accessor};
    if ($relation_type eq 'single')
    {
      my $method_name = $relation.'_column_data';
      my $method_code = sub {

        my $self = shift;
        my $relobject = $self->$relation;
        return $relobject->get_column_data() if defined $relobject;
        return undef;
      };
      {
        no strict 'refs';
        *{"${class}::${method_name}"} = $method_code;
      }
      my $old_method_name = $relation.'_columns_data';
      my $old_method_code = sub {
          carp "$old_method_name is decrecated, use $method_name";
          my $class = shift;

          return $class->$method_name(@_);
      };
      {
        no strict 'refs';
        *{"${class}::${old_method_name}"} = $old_method_code;
      }
    }
     if ($relation_type eq 'multi')
    {
      my $method_name = $relation.'_column_data';
      my $method_code = sub {

        my $self = shift;
        my @relobjects = $self->$relation;
        my @relobjects_column_data = ();
        foreach my $relobject (@relobjects)
        {
          push @relobjects_column_data, $relobject->get_column_data();
        }
        return @relobjects_column_data;
      };
      {
        no strict 'refs';
        *{"${class}::${method_name}"} = $method_code;
      }
      my $old_method_name = $relation.'_columns_data';
      my $old_method_code = sub {
          carp "$old_method_name is decrecated, use $method_name";
          my $class = shift;

          return $class->$method_name(@_);
      };
      {
        no strict 'refs';
        *{"${class}::${old_method_name}"} = $old_method_code;
      }

    }
  }
  if ($class->isa('DBIx::Class::IntrospectableM2M'))
  {
    foreach my $m2m_rel (keys(%{$class->_m2m_metadata}))
    {
      my $relation = $class->_m2m_metadata->{$m2m_rel}->{accessor};
      my $method_name = $relation.'_column_data';
      my $method_code = sub {

        my $self = shift;
        my @relobjects = $self->$relation;
        my @relobjects_column_data = ();
        foreach my $relobject (@relobjects)
        {
          push @relobjects_column_data, $relobject->get_column_data();
        }
        return @relobjects_column_data;
      };
      {
        no strict 'refs';
        *{"${class}::${method_name}"} = $method_code;
      }
      my $old_method_name = $relation.'_columns_data';
      my $old_method_code = sub {
          carp "$old_method_name is decrecated, use $method_name";
          my $class = shift;

          return $class->$method_name(@_);
      };
      {
        no strict 'refs';
        *{"${class}::${old_method_name}"} = $old_method_code;
      }

    }
  }
}

=head1 AUTHOR

Nicolas Oudard, <nicolas@oudard.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-result-columndata at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-Result-ColumnData>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Result::ColumnData


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Nicolas Oudard.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of DBIx::Class::Result::ColumnData
