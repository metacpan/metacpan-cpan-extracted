package DBIx::Class::Result::Validation;

use strict;
use warnings;

use Carp;
use Try::Tiny;
use Scalar::Util 'blessed';
use DBIx::Class::Result::Validation::VException;

=head1 NAME

DBIx::Class::Result::Validation - DBIx::Class component to manage validation on result object

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';

=head1 SYNOPSIS

DBIx::Class::Result::Validation component call validate function before insert
or update object and unauthorized these actions if validation set
result_errors accessor.

In your result class load_component :

    Package::Schema::Result::MyClass;

    use strict;
    use warning;

    __PACKAGE__->load_component(qw/ ... Result::Validation /);

defined your _validate function which will be called by validate function

    sub _validate
    {
      my $self = shift;
      #validate if this object exist whith the same label
      my @other = $self->result_source->resultset->search({ label => $self->label
                                                            id => {"!=", $self->id}});
      if (scalar @other)
      {
        $self->add_result_error('label', 'label must be unique');
      }

    }

When you try to create or update an object Package::Schema::Result::MyClass,
if an other one with the same label exist, this one will be not created,
validate return 0 and $self->result_errors will be set.

$self->result_errors return :

    { label => ['label must be unique'] }

Otherwise, object is create, validate return 1 and $self->result_errors is undef.

It is possible to set more than one key error and more than one error by key

    $self->add_result_error('label', 'label must be unique');
    $self->add_result_error('label', "label must not be `$self->label'");
    $self->add_result_error('id', 'id is ok but not label');

$self->result_errors return :

    {
      label => [
              'label must be unique',
              "label must not be `my label'"
              ],
      id => [
           'id is ok but not label'
            ]
    }

=head1 Reserved Accessor

DBIx::Class::Result::Validation component create a new accessor to Result object.

    $self->result_errors

This field is used to store all errors

=cut

use base qw/ DBIx::Class Class::Accessor::Grouped /;
__PACKAGE__->mk_group_accessors(simple => qw(result_errors));

=head1 SUBROUTINES/METHODS

=head2 validate

This validate function is called before insert or update action.
If result_errors is not defined it return true

You can redefined it in your Result object and call back it with  :

    return $self->next::method(@_);

=cut

sub validate {
  my $self = shift;
  $self->_erase_result_error();
  my @columns = $self->result_source->columns;
  foreach my $field (@columns)
  {
      if ($self->result_source->column_info($field)->{'validation'})
      {
          my $validations;
          #convert every sources of validation in array
          if ( ref($self->result_source->column_info($field)->{'validation'}) ne 'ARRAY'){
            push @{$validations},$self->result_source->column_info($field)->{'validation'};
          }
          else{
             $validations = $self->result_source->column_info($field)->{'validation'};
          }
          if ( scalar(@{$validations}) >0 ){
              foreach my $validation (@{$validations}){
                  my $validation_function = "validate_" . $validation;
                  #Unvalid validation method cause a croak exception
                  try{
                     $self->$validation_function($field);
                  }
                  catch{
                      croak(
                              DBIx::Class::Result::Validation::VException->new(
                                  object  => $self,
                                  message => "Validation : $validation is not valid"
                                  )
                           );
                  }
              }
          }
      }
  }

  $self->_validate();
  return 0 if (defined $self->result_errors);
  return 1;
};

=head2 error_reporting

function to configure on object to find what is wrong after a Database throw

=cut

sub error_reporting {
  return 1;
};

=head2 _validate

_validate function is the function to redefine with validation behaviour object

=cut

sub _validate
{
  return 1;
}

=head2 add_result_error

    $self->add_result_error($key, $error_string)

Add a string error attributed to a key (field of object)

=cut

sub add_result_error
{
  my ($self, $key, $value) = @_;
  if (defined $self->result_errors)
  {
    if (defined $self->result_errors->{$key})
    { push(@{$self->result_errors->{$key}}, $value); }
    else
    { $self->result_errors->{$key} = [$value]; }
  }
  else
  { $self->result_errors({$key => [$value]}); }
}

=head2 insert

call before DBIx::Calss::Base insert

Insert is done only if validate method return true

=cut

sub insert {
    my $self = shift;

    my $insert = $self->next::can;
    return $self->_try_next_method($self->next::can, @_);
}

=head2 update

Call before DBIx::Class::Base update

Update is done only if validate method return true

=cut

sub update {
    my $self = shift;
    if ( my $columns = shift ) {
        $self->set_inflated_columns($columns);
    }
    return $self->_try_next_method( $self->next::can, @_ );
}

sub _try_next_method {
    my $self        = shift;
    my $next_method = shift;

    my $class = ref $self;
    my $result;
    try {
        if ( $self->validate ) {
            $result = $self->$next_method(@_);
        }
        else {
            my $errors = $self->_get_errors;
            croak("$class: Validation failed.\n$errors");
        }
    }
    catch {
        my $error = $_;
        $self->error_reporting();
        $self->add_result_error(uncaught => $error) if !defined $self->result_errors;
        croak $error
          if ref $error eq 'DBIx::Class::Result::Validation::VException';
        croak(
            DBIx::Class::Result::Validation::VException->new(
                object  => $self,
                message => "$error"
            )
        );
    };
    return $result;
}

sub _get_errors {
    my $self = shift;

    require Data::Dumper;
    no warnings 'once';
    local $Data::Dumper::Indent   = 1;
    local $Data::Dumper::Sortkeys = 1;
    local $Data::Dumper::Terse    = 1;
    return Data::Dumper::Dumper( $self->{result_errors} );
}

=head2 _erase_result_error

this function is called to re-init result_errors before call validate function

=cut

sub _erase_result_error
{
    my $self = shift;
    $self->result_errors(undef);
}


=head1 VALIDATION METHOD

set of function to validate fields

=cut

=head2 validate_enum function

validation of the enum field, should return a validation error if the field is set and is not in the list of enum

=cut

sub validate_enum {
    my ($self, $field) = @_;
    $self->add_result_error( $field, $field ." must be set with one of the following value: " .join(", ", @{$self->result_source->columns_info->{$field}->{extra}->{list}}) )
    if( 
            (!defined ($self->$field) && !defined($self->result_source->columns_info->{$field}->{default_value})
            or  
            (defined ($self->$field) && !($self->$field ~~ @{ $self->result_source->columns_info->{$field}->{extra}->{list} }))
      )
    );
}

=head2 validate_defined

validation of field which must be defined, return error if the field is not defined

=cut

sub validate_defined {
    my ($self, $field) = @_;

    $self->add_result_error( $field, "must be set" )
      unless defined $self->$field;
}

=head2 validate_not_empty

validation of a field which can be null but can't be empty

=cut

sub validate_not_empty {
    my ($self, $field) = @_;

    $self->add_result_error( $field, "can not be empty" )
      if defined $self->$field && $self->$field eq '';
}

=head2 validate_not_null_or_not_zero

validation of a field which can be null and not equal to 0
this can be used for data_type integer

=cut

sub validate_not_null_or_not_zero {
    my ($self, $field) = @_;

    $self->add_result_error( $field, "can not be null or equal to 0" )
      if !$self->$field;
}

1;
__END__

=head1 SEE ALSO

L<"DBIx::Class">

=head1 AUTHOR

Nicolas Oudard <nicolas@oudard.org>

=head1 CONTRIBUTORS


=head1 LICENSE

You may distribute this code under the same terms as Perl itself.
