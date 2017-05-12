package DBIx::Class::Result::ProxyField;

use warnings;
use strict;

use Data::Dumper 'Dumper';

use base qw/ DBIx::Class Class::Accessor::Grouped /;

=head1 NAME

DBIx::Class::Result::ProxyField - Component Result::ProxyField is a component for DBIx::Class object which permit to defined public name for each column object

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

First, this module would evolve, it is not completly finished

To use Result::ProxyField component, you need to declare it in Result and ResultSet of your DBIx::Class object

in your Result :

    package App::Schema::Result::Object;

    # declare columns : for each column you want use an other name, declare public_name

    __PACKAGE__->add_columns(
      "superobjectid",
      { data_type => "integer", is_nullable => 1, public_name => 'super_object_id' },
      "actif",
      { data_type => "tinyint", default_value => 1, is_nullable => 1 },
      "creation_datetime",
      { data_type => "datetime", is_nullable => 1, public_name => 'created_at'}
    );

    # after declare columns you can initialise the Result::ProxyField component

    __PACKAGE__->load_component(qw/Result::ProxyField/);
    __PACKAGE__->init_proxy_field();

in your ResultSet

    package App::Schema::ResultSet::Object;
    use base 'DBIx::Class::ResultSet::ProxyField';

On your code, you can use public_name to set or get column

    my $schema = App::Schema->connect('dbi:SQLite:db/example.db');

    my @objects = $schema->resultset('Object')->search({created_at => {"==", undef},super_object_id => 1});
    # is the same than
    my @objects = $schema->resultset('Object')->search({creation_datetime => {"==", undef}, superobjectid => 1});

    my $object = $objects[0];

    $object->created_at(DateTime.now());
    #is the same than
    $object->creation_datetime(DateTime.now());

    my $created_at = $object->created_at;
    #is the same than
    my $created_at = $object->creation_datetime;

    ...etc

becareful, the relationship id stay superobjectid

=head1 CLASS VARIABLES

$rh_ext_to_bdd store mapping table from public to database by class

$rh_bdd_to_ext store mapping table from database to public by class

=cut

my $rh_ext_to_bdd = {};
my $rh_bdd_to_ext = {};

=head1 SUBROUTINES/METHODS

=head2 rh_ext_to_bdd

Class function

Accessor to mapping table from public to database for a class

=cut

sub rh_ext_to_bdd {
  my ($class, $key, $value) = @_;
  die "this function is call with class" unless defined $class;
  if (@_ == 3) {
    return $rh_ext_to_bdd->{$class}->{$key} = $value;
  }
  elsif (@_ == 2) {
    return $rh_ext_to_bdd->{$class}->{$key};
  }
  else {
    return $rh_ext_to_bdd->{$class};
  }
}

=head2 rh_bdd_to_ext

Class function

Accessor to mapping table from database to public for a class

=cut

sub rh_bdd_to_ext {
  my ($class, $key, $value) = @_;
  die "this function is call with class" unless defined $class;
  if (@_ == 3) {
    return $rh_bdd_to_ext->{$class}->{$key} = $value;
  }
  elsif (@_ == 2) {
    return $rh_bdd_to_ext->{$class}->{$key};
  }
  else {
    return $rh_bdd_to_ext->{$class};
  }
}

=head2 init_proxy_field

Class function

Init function which defined accessor from class definition

=cut

sub init_proxy_field
{
  my $class = shift;
  my @new_field;
  foreach my $col($class->columns)
  {
    if (defined $class->column_info($col)->{public_name})
    {
      push @new_field, $class->column_info($col)->{public_name};
      $class->rh_bdd_to_ext($col, $class->column_info($col)->{public_name});
      $class->rh_ext_to_bdd($class->column_info($col)->{public_name}, $col);
    }
  }
  foreach my $accessor (@new_field)
  {
    my $field = $class->rh_ext_to_bdd($accessor);
    my $method_code = sub{
      my ($self,$value) = @_;
      return $self->$field($value) if (@_ == 2);
      return $self->$field;
    };
    {
      no strict 'refs';
      *{"${class}::${accessor}"} = $method_code;
    }
  }
}

=head2 adaptator_to_ext

Instance function

set public accessor from database accessor


sub adaptator_to_ext
{
  my $self = shift;
  my $class = ref $self;
  foreach my $key_bdd (keys %{$rh_bdd_to_ext->{$class}})
  {
    my $key_ext = $rh_bdd_to_ext->{$class}->{$key_bdd};
    $self->$key_ext( $self->$key_bdd );
  }
}
=cut

=head2 adaptator_to_bdd

Instance function

set database accessor from public accessor


sub adaptator_to_bdd
{
  my $self = shift;
  my $class = ref $self;
  foreach my $key_ext (keys %{$rh_ext_to_bdd->{$class}})
  {
#    $key = champ bdd
    my $key_bdd = $rh_ext_to_bdd->{$class}->{$key_ext};
    $self->$key_bdd( $self->$key_ext ) if defined $self->$key_ext;
  }
}
=cut

=head2 class_adaptator_to_bdd

Class function

format hash columns data of object with public accessor

=cut

sub class_adaptator_to_bdd
{
  my ($class, $attributes) = @_;
  if (ref $attributes eq 'HASH')
  {
    foreach my $key_ext (keys %{$rh_ext_to_bdd->{$class}})
    {
      my $key_bdd = $rh_ext_to_bdd->{$class}->{$key_ext};
      if (exists $attributes->{$key_ext})
      {
        $attributes->{$key_bdd} = $attributes->{$key_ext};
        delete $attributes->{$key_ext};
      }
#    $key = champ bdd
    }
  }
  return $attributes;
}

=head2 columns_data

Instance function

re defined columns_data function to component Result::DataColumns

return only column data Hash with public name

=cut

sub columns_data
{
  my $self = shift;
  my $class = ref $self;
  my $rh_data = $self->next::method(@_);
  foreach my $key_bdd (keys %{$rh_bdd_to_ext->{$class}})
  {
    my $key_ext = $rh_bdd_to_ext->{$class}->{$key_bdd};
    my $value = $self->$key_bdd;
    $value = $value->ymd.' '.$value->hms if (ref $value eq 'DateTime');
    $rh_data->{$key_ext} = $value;
    delete $rh_data->{$key_bdd};
  }
  return $rh_data;
}

=head2 update

Instance function

re defined update to adapt object field before update

=cut

sub update
{
  my $self = shift;
  my $rh_attrs = $_[0];
  if (defined $rh_attrs)
  {
    my $class = ref $self;
    $class->class_adaptator_to_bdd($rh_attrs);
  }
  return $self->next::method($rh_attrs);
}

=head2 insert

Instance function

re defined insert to adapt object field before insert

=cut

sub insert
{
  my $self = shift;
  return $self->next::method(@_);
}

=head2 delete

Instance function

re defined delete to adapt object field before delete

=cut

sub delete
{
  my $self = shift;
  return $self->next::method(@_);
}

=head1 AUTHOR

Nicolas Oudard, C<nicolas@oudard.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-result-proxyfield at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-Result-ProxyField>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Result::ProxyField

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-Result-ProxyField>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-Result-ProxyField>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-Result-ProxyField>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-Result-ProxyField/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Nicolas Oudard.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of DBIx::Class::Result::ProxyField
