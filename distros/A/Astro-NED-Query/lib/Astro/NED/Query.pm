# --8<--8<--8<--8<--
#
# Copyright (C) 2007 Smithsonian Astrophysical Observatory
#
# This file is part of Astro::NED::Query
#
# Astro::NED::Query is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package Astro::NED::Query;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.31';

use autouse Carp => qw/ croak carp confess /;

use WWW::Mechanize;

use constant NED_URL => 'http://nedwww.ipac.caltech.edu/index.html';

#---------------------------------------------------------------------------


# this is designed to be invoked by a subclass.
sub new
{
  my ( $class, %fields ) = @_;
  $class = ref $class || $class;

  croak( __PACKAGE__, '->new: illegal call to abstract base class' )
    if $class eq __PACKAGE__;

  my $self = bless {}, $class;

  # grab top level page
  $self->{_ua} = WWW::Mechanize->new();
  $self->{_ua}->get( NED_URL );

  croak( $class, '->new: error accessing NED: ',
	 $self->{_ua}->res->status_line )
    if $self->{_ua}->res->is_error;

  $self->_init;
  $self->save_as_defaults;

  # process fields
  while( my ( $key, $value ) = each %fields )
  {
    croak( $class, "->new unknown attribute: `$key'" )
      unless defined $self->field($key);
    $self->set( $key, $value );
  }

  return $self;
}

sub _init
{
    my ( $self ) = @_;
    croak( ref $self, ': internal implementation error; _init undefined' );
}


sub field {

    my ( $self, $key ) = @_;

    return exists $self->Field->{$key} ? $self->Field->{$key} : undef;
}


#---------------------------------------------------------------------------


sub set
{
  my ( $self, $name, $value ) = @_;

  confess( ref $self, '->set: Wrong number of arguments' )
    unless 3 == @_;

  if ( defined ( my $field = $self->field($name) ) )
  {
    eval {
      $self->{_ua}->field( $field, $value );
    };
    croak( ref $self, "->set($name):  illegal value" )
      if $@;
  }
  else
  {
    $self->{$name} = $value;
  }

  return;
}

sub get
{
  my ( $self, $name ) = @_;

  confess( ref $self, '->get: Wrong number of arguments' )
    unless defined $name;

  my $field = $self->field($name);

  return defined($field)
     ? $self->{_ua}->current_form->value( $field )
     : $self->{$name};
}

#---------------------------------------------------------------------------

# map between Multiple values and form inputs.

#  HTML::Table creates a separate input for each value in a checkbox
#  or option.  this routine creates a hash matching the values to the
#  input to make it easier to set the inputs.  In some cases a single
#  logical list of options is split into several so the GUI looks
#  cleaner. this will merge them.

sub _setupMultiple
{
  my ( $self, $type, $alias, @names  ) = @_;

  my %input;

  foreach my $name ( @names )
  {
    $name = qr/^$name$/ unless 'Regexp' eq ref $name;

    foreach my $input ( $self->{_ua}->current_form->inputs )
    {
      next unless defined $input->name &&
	            $input->name =~ /$name/ && $input->type eq $type;

      my @value = grep { defined $_ } $input->possible_values;
      croak( ref $self, "->setupMultiple: ($name,$type) multivalued multiple\n" )
	if @value > 1;
      $input{$value[0]} = $input;
    }
  }

  $self->{_Multiple}{$alias} = \%input;

  return;
}

# steal a page (well, actually code) from Class::Accessor for inputs
# which have multiple values
sub _mkMultipleAccessor {
    my($self, @fields) = @_;
    my $class = ref $self || $self;

    foreach my $field (@fields) {
	if ( $field eq 'DESTROY' ) {
	    require Carp;
	    Carp::carp('Having a data accessor named DESTROY  in '.
			"'$class' is unwise.");
	}

	my $accessor = sub {
	    my $self = shift;

	    return 1 == @_ ?
	      $self->getMultiple( $field, @_ ) :
		$self->setMultiple( $field, @_ );
	};

	my $alias = "_${field}_accessor";

	## no critic (ProhibitNoStrict)
	no strict 'refs';

	*{$class."\:\:$field"}  = $accessor
	  unless defined &{$class."\:\:$field"};

	*{$class."\:\:$alias"}  = $accessor
	  unless defined &{$class."\:\:$alias"};
    }

    return;
}

sub setMultiple
{
  my ( $self, $name, $value, $state ) = @_;

  croak( ref $self, "->setMultiple: wrong number of arguments\n" )
    unless @_ == 4;

  croak( ref $self, "->setMultiple: illegal value for $name: `$value'\n" )
    unless exists $self->{_Multiple}{$name}{$value};

  my $input = $self->{_Multiple}{$name}{$value};

  if ( defined $state && $state )
  {
    $input->value( $value );
  }
  else
 {
    $input->value( undef );
  }

  return;
}

sub getMultiple
{
  my ( $self, $name, $value ) = @_;

  confess( "Wrong number of arguments\n" )
    unless @_ == 3;

  croak( ref $self, "->getMultiple: illegal value for $name: `$value'\n" )
    unless exists $self->{_Multiple}{$name}{$value};

  my $input = $self->{_Multiple}{$name}{$value};

  return $input->value;
}

#---------------------------------------------------------------------------

sub possible_values
{
  my ( $self, $ifield ) = @_;

  defined $ifield or
    croak( ref $self, "->possible_values: missing field name\n" );

  # is this a multiple value beast?
  if ( exists  $self->{_Multiple}{$ifield} )
  {
    return keys %{$self->{_Multiple}{$ifield}}
  }
  elsif ( defined ( my $field = $self->field($ifield) ) )
  {
    return $self->{_ua}->current_form->find_input($field)->possible_values;
  }

  else
  {
    croak( ref $self, "->possible_values: unknown field: $ifield\n" );
  }
}

#---------------------------------------------------------------------------

sub dump
{
    my ( $self ) = @_;

    $self->{_ua}->current_form->dump;

    return;
}

sub form
{
    my ( $self ) = @_;
    return $self->{_ua}->current_form->form;
}

#---------------------------------------------------------------------------

sub save_as_defaults
{
  my $self = shift;

  # save current form field values.
  my @ivalues = map { [ $_ , $_->value ] } $self->{_ua}->current_form->inputs;
  $self->{_ivalues} = \@ivalues;

  return;
}

sub set_to_defaults
{
  my $self = shift;

  for my $field ( @{$self->{_ivalues}} )
  {
      my ( $obj, $value ) = @{$field};
      $obj->value($value)
	if defined $value;
  }

  return;
}

# alias old names for compatibility
*Astro::NED::Query::reset = *set_to_defaults;
*Astro::NED::Query::set_default = *save_as_defaults;


#---------------------------------------------------------------------------


sub query
{
  my $self = shift;

  # get class specific query presets
  $self->_query;

  my $ua = $self->{_ua};

  $ua->click;

  if ( $ua->res->is_error )
  {
    $ua->back;
    croak( ref($self), '->query: ', $ua->res->status_line );
  }

  my $content = $ua->content;
  $ua->back;

  return $self->_parse_query( $content );
}

sub _query
{
    my ( $self ) = @_;
    croak( $self, ': internal implementation error; _query undefined' );
}

sub _parse_query
{
    my ( $self ) = @_;
    croak( ref $self,
	   ': internal implementation error; _parse_query undefined' );
}

#---------------------------------------------------------------------------

sub timeout
{
    my ( $self, @args ) = @_;

    return $self->{_ua}->timeout( @args );
}

#---------------------------------------------------------------------------
1;
__END__


=head1 NAME

Astro::NED::Query - base class for NED queries

=head1 SYNOPSIS

  use base qw/ Astro::NED::Query /;


=head1 DESCRIPTION

This class is the base class for queries to NED.  As such, it is
I<not> used directly in end-user applications.  Use the classes
B<Astro::NED::Query::ByName>,
B<Astro::NED::Query::NearName>,
B<Astro::NED::Query::NearPosition> instead.

I<However>, since most of the functionality of those classes is
derived from this one, most of the documentation for their use
is found here.  Documentation for the other classes will provide
class specific details.

=head1 USAGE

=head2 Constructing a query

Queries are constructed by creating a query object.  The object should
be created in one of the classes listed above.  _You cannot construct a
pure B<Astro::NED::Query> object. 

For example, the construct a C<by name> query, 

  $query = Astro::NED::Query::ByName->new( Field1 => $value1,
                                           Field2 => $value2, ... );

This constructs a query, setting the query parameters B<Field1> and
B<Field2>.  It does I<not> send off the query.  Only single valued
parameters may be set when constructing the query.

When an object is constructed, the appropriate search parameter form
is retrieved from NED.  To avoid repeatedly doing this, reuse a query
object as much as possible.

=head2 Query Parameters and Accessor Methods

Query parameters come in two flavors: single valued and multiple
valued.  As shown above, single valued query parameters may be
specified in the constructor.

Once a query has been constructed, parameters may be set or retrieved
using accessor methods.  These methods have the same name as the
parameter.  For single valued fields,

  $query->Field1( $value );
  $value = $query->Field1;

Accessor methods for fields which can have multiple concurrent values
have a slightly different syntax:

  $query->MField( $value => $state );
  $state = $query->MField( $value );

Here, C<$state> is a boolean value which indicates whether or not
the field should contain that value.  Think of it as a check box toggle
switch.  The value returned by the accessor will be empty if the
field contains that value, else it is the actual value.

All of the parameters may be set to their default state by calling the
B<set_to_defaults> method.  To make the default values look like the
current values, use the B<save_as_defaults> method.

Some parameters may have values which are restricted to a given set.
To determine what the available values are, use the B<possible_values>
method.

=head2 Sending off the request

Once a query has been constructed, it is sent off to NED with the B<query>
method.  This method will return an object (in the computer science sense)
which contains the results of the query.  The type of object returned
depends upon the type of query. For instance, queries which fall under
the NED "Objects" rubric all return an B<Astro::NED::Response::Objects>
object.

The query object may be reused as often as one would like; simply change
the parameter values and reissue the B<query> method.

=head2 Examples

=over

=item Querying by name

  $req = Astro::NED::Query::ByName->new( ObjName => 'Abell 2166',
                                         Extend => 1 );
  $res = $req->query;
  print $_->Name, "\n" foreach $res->objects;

=item Querying near name for Galaxies with X-ray emission

  $req = Astro::NED::Query::NearName->new( ObjName => 'Abell 2166');
  $req->IncObjType( Galaxies => 1 );
  $req->IncObjType( Xray => 1 );
  $req->ObjTypeInclude( 'ALL' );
  $res = $req->query;
  print $_->Name, "\n" foreach $res->objects;

=back

=head1 GENERIC OBJECT METHODS

All of the various B<Query> classes share the following methods.
Make sure to read the documentation for the actual Query class which
will be used.  It contains class specific information.

=over

=item new

This is the object constructor.  It takes a list of keyword and value
pairs.  The keywords may be the names of single valued query
parameters.  These are documented for each Query class.

=item dump

Returns the current parameters as a textual representation.
See B<HTML::Form::dump()> for more information.

=begin internal_docs

=item field

  $form_field_name = $req->field( $parameter_name );

Return the actual form field name associated with the given parameter name as
defined by the subclass.

=end internal_docs

=item form

  @keyw = $req->form;

Returns the current parameters as a sequence of key/value pairs.
See B<HTML::Form::form()> for more information.

=item get

  $req->get( $field_name );

Generic method to get a field value.  Cannot be used for multiple value fields.


=item getMultiple

  $state = $req->getMultiple( $field_name, $value);

Generic method to get a multiple value field's state.

=item possible_values

  @values = $req->possible_values( $field_name );

This returns a list of the possible values for a query parameter.  This
is only useful for parameters whose values are limited to a specific
set of values.  For other parameters, an empty list is returned.


=item set_to_defaults

  $req->set_to_defaults;

This method sets the parameter values to their defaults.  The default
values are initially taken from the NED defaults, but may be changed
with the B<save_as_defaults> method.

=begin podfool

=item reset

=end  podfool

=item set

  $req->set( $field_name, $value );

Generic method to set a field's value.  Cannot be used for multiple value fields.

=item setMultiple

  $req->setMultiple( $field_name, $value);
  $req->setMultiple( $field_name, $value, $state );

Generic method to set a multiple value field's state.  If C<$state> is
not present or is zero then the value is removed from the field, otherwise the value is set.

=item save_as_defaults

  $req->save_as_defaults;

This saves the current parameter values as the default values.

=begin podfool

=item set_default

=end  podfool

=item query

  $res = $req->query;

Send the query off to NED.  It returns a container containing
the results of the query.  See the documentation for the separate
Query classes for information on the type of container and how
to extract data from it.

=item timeout

  $req->timeout();
  $req->timeout( $seconds );

Get/set the timeout value in seconds.  See
B<LWP::UserAgent::timeout()> for more information.

=back

=begin internal_docs

=head1 GENERIC CLASS METHODS

=over

=item Field

Return a hashref of the Classes permitted fields

=back

=end internal_docs

=head2 EXPORT

None by default.

=head1 AUTHOR

Diab Jerius, E<lt>djerius@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (C) 2003 Smithsonian Astrophysical Observatory.
All rights are of course reserved.

It is released under the GNU General Public License.  You may find a
copy at

   http://www.fsf.org/copyleft/gpl.html

=head1 SEE ALSO

L<Astro::NED::Query::Objects>,
L<Astro::NED::Query::ByName>,
L<Astro::NED::Query::NearName>,
L<Astro::NED::Query::NearPosition>,
L<Astro::NED::Query::Response::Objects>,
L<Astro::NED::Query::Response::Object>,
L<perl>.

=cut
