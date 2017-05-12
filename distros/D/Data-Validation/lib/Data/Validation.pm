package Data::Validation;

use 5.010001;
use namespace::autoclean;
use version; our $VERSION = qv( sprintf '0.28.%d', q$Rev: 1 $ =~ /\d+/gmx );

use Data::Validation::Constants qw( EXCEPTION_CLASS FALSE HASH NUL SPC );
use Data::Validation::Constraints;
use Data::Validation::Filters;
use Data::Validation::Utils     qw( throw );
use List::Util                  qw( first );
use Try::Tiny;
use Unexpected::Functions       qw( FieldComparison ValidationErrors );
use Unexpected::Types           qw( HashRef NonZeroPositiveInt );
use Moo;

has 'constraints' => is => 'ro', isa => HashRef, default => sub { {} };

has 'fields'      => is => 'ro', isa => HashRef, default => sub { {} };

has 'filters'     => is => 'ro', isa => HashRef, default => sub { {} };

has 'level'       => is => 'ro', isa => NonZeroPositiveInt, default => 1;

# Private functions
my $_comparisons = sub {
   return { 'eq' => sub { $_[ 0 ] eq $_[ 1 ] },
            '==' => sub { $_[ 0 ] == $_[ 1 ] },
            'ne' => sub { $_[ 0 ] ne $_[ 1 ] },
            '!=' => sub { $_[ 0 ] != $_[ 1 ] },
            '>'  => sub { $_[ 0 ] >  $_[ 1 ] },
            '>=' => sub { $_[ 0 ] >= $_[ 1 ] },
            '<'  => sub { $_[ 0 ] <  $_[ 1 ] },
            '<=' => sub { $_[ 0 ] <= $_[ 1 ] }, };
};

my $_get_methods = sub {
   return split SPC, $_[ 0 ] // NUL;
};

my $_should_compare = sub {
   return first { $_ eq 'compare' } $_get_methods->( $_[ 0 ]->{validate} );
};

# Private methods
my $_filter = sub {
   my ($self, $filters, $id, $v) = @_;

   for my $method ($_get_methods->( $filters )) {
      my $attr    = { %{ $self->filters->{ $id } // {} }, method => $method, };
      my $dvf_obj = Data::Validation::Filters->new_from_method( $attr );

      $v = $dvf_obj->filter( $v );
   }

   return $v;
};

my $_compare_fields = sub {
   my ($self, $prefix, $form, $lhs_name) = @_;

   my $id         = $prefix.$lhs_name;
   my $constraint = $self->constraints->{ $id } // {};
   my $rhs_name   = $constraint->{other_field}
      or throw 'Constraint [_1] has no comparison field', [ $id ];
   my $op         = $constraint->{operator} // 'eq';
   my $compare    = $_comparisons->()->{ $op }
      or throw 'Constraint [_1] unknown comparison operator [_2]', [ $id, $op ];
   my $lhs        = $form->{ $lhs_name } // NUL;
   my $rhs        = $form->{ $rhs_name } // NUL;

   $compare->( $lhs, $rhs ) and return;

   $lhs_name = $self->fields->{ $prefix.$lhs_name }->{label} // $lhs_name;
   $rhs_name = $self->fields->{ $prefix.$rhs_name }->{label} // $rhs_name;
   throw FieldComparison, [ $lhs_name, $op, $rhs_name ], level => $self->level;
};

my $_validate = sub {
   my ($self, $valids, $id, $v) = @_;

   $valids !~ m{ isMandatory }mx and (not defined $v or not length $v)
      and return;

   my $params = $self->constraints->{ $id } // {};
   my $label = $self->fields->{ $id }->{label} // $id;

   for my $methods (grep { $_ ne 'compare' } $_get_methods->( $valids )) {
      my @fails;

      for my $method (split m{ [|] }mx, $methods) {
         my $constraint = Data::Validation::Constraints->new_from_method
            ( { %{ $params }, method => $method, } );
        (my $class = $method) =~ s{ \A is }{}mx;

         if ($constraint->validate( $v )) { @fails = (); last }

         push @fails, $class;
      }

      @fails == 1 and throw sub { $fails[ 0 ] }, [ $label ],
                            constraints => $params, level => $self->level;
      @fails  > 1 and throw 'Field [_1] is none of [_2]',
                            [ $label, join ' | ', @fails ],
                            level => $self->level;
   }

   return;
};

# Public methods
sub check_form { # Validate all fields on a form by repeated calling check_field
   my ($self, $prefix, $form) = @_; my @errors = (); $prefix ||= NUL;

   ($form and ref $form eq HASH) or throw 'Form parameter not a hash ref';

   for my $name (sort keys %{ $form }) {
      my $id = $prefix.$name; my $conf = $self->fields->{ $id };

      ($conf and ($conf->{filters} or $conf->{validate})) or next;

      try   {
         $form->{ $name } = $self->check_field( $id, $form->{ $name } );
         $_should_compare->( $conf )
            and $self->$_compare_fields( $prefix, $form, $name );
      }
      catch { push @errors, $_ };
   }

   @errors and throw ValidationErrors, \@errors, level => $self->level;

   return $form;
}

sub check_field { # Validate a single form field value
   my ($self, $id, $v) = @_; my $conf;

   unless ($id and $conf = $self->fields->{ $id }
           and ($conf->{filters} or $conf->{validate})) {
      throw 'Field [_1] validation configuration not found', [ $id, $v ];
   }

   $conf->{filters } and $v = $self->$_filter( $conf->{filters }, $id, $v );
   $conf->{validate} and    $self->$_validate( $conf->{validate}, $id, $v );

   return $v;
}

1;

__END__

=pod

=encoding utf-8

=begin html

<a href="https://travis-ci.org/pjfl/p5-data-validation"><img src="https://travis-ci.org/pjfl/p5-data-validation.svg?branch=master" alt="Travis CI Badge"></a>
<a href="https://roxsoft.co.uk/coverage/report/data-validation/latest"><img src="https://roxsoft.co.uk/coverage/badge/data-validation/latest" alt="Coverage Badge"></a>
<a href="http://badge.fury.io/pl/Data-Validation"><img src="https://badge.fury.io/pl/Data-Validation.svg" alt="CPAN Badge"></a>
<a href="http://cpants.cpanauthors.org/dist/Data-Validation"><img src="http://cpants.cpanauthors.org/dist/Data-Validation.png" alt="Kwalitee Badge"></a>

=end html

=head1 Name

Data::Validation - Filter and validate data values

=head1 Version

Describes version v0.28.$Rev: 1 $ of L<Data::Validation>

=head1 Synopsis

   use Data::Validation;

   sub check_field {
      my ($self, $config, $id, $value) = @_;

      my $dv_obj = $self->_build_validation_obj( $config );

      return $dv_obj->check_field( $id, $value );
   }

   sub check_form  {
      my ($self, $config, $form) = @_;

      my $dv_obj = $self->_build_validation_obj( $config );
      my $prefix = $config->{form_name}.q(.);

      return $dv_obj->check_form( $prefix, $form );
   }

   sub _build_validation_obj {
      my ($self, $config) = @_;

      return Data::Validation->new( {
         constraints => $config->{constraints} // {},
         fields      => $config->{fields}      // {},
         filters     => $config->{filters}     // {} } );
   }

=head1 Description

This module implements filters and common constraints in builtin
methods and uses a factory pattern to implement an extensible list of
external filters and constraints

Data values are filtered first before testing against the constraints. The
filtered data values are returned if they conform to the constraints,
otherwise an exception is thrown

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<constraints>

Hash containing constraint attributes. Keys are the C<id> values passed
to L</check_field>. See L<Data::Validation::Constraints>

=item C<fields>

Hash containing field definitions. Keys are the C<id> values passed
to L</check_field>. Each field definition can contain a space
separated list of filters to apply and a space separated list of
constraints. Each constraint method must return true for the value to
be accepted

The constraint method can also be a list of methods separated by | (pipe)
characters. This has the effect of requiring only one of the constraints
to be true

   isMandatory isHexadecimal|isValidNumber

This constraint would require a value that was either hexadecimal or a
valid number

=item C<filters>

Hash containing filter attributes. Keys are the C<id> values passed
to L</check_field>. See L<Data::Validation::Filters>

=item C<level>

Positive integer defaults to 1. Used to select the stack frame from which
to throw the C<check_field> exception

=back

=head1 Subroutines/Methods

=head2 check_form

   $form = $dv->check_form( $prefix, $form );

Calls L</check_field> for each of the keys in the C<form> hash. In
the calls to L</check_field> the C<form> keys have the C<prefix>
prepended to them to create the key to the C<fields> hash

If one of the fields constraint names is C<compare>, then the fields
value is compared with the value for another field. The constraint
attribute C<other_field> determines which field to compare and the
C<operator> constraint attribute gives the comparison operator which
defaults to C<eq>

All fields are checked. Multiple error objects are stored, if they occur,
in the C<args> attribute of the returned error object

=head2 check_field

   $value = $dv->check_field( $id, $value );

Checks one value for conformance. The C<id> is used as a key to the
C<fields> hash whose C<validate> attribute contains the list of space
separated constraint names. The value is tested against each
constraint in turn. All tests must pass or the subroutine will use the
C<EXCEPTION_CLASS> class to C<throw> an error

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo>

=item L<Try::Tiny>

=item L<Unexpected>

=back

=head1 Incompatibilities

OpenDNS. I have received reports that hosts configured to use OpenDNS fail the
C<isValidHostname> test. Apparently OpenDNS causes the core Perl function
C<gethostbyname> to return it's argument rather than undefined as per the
documentation

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Validation.  Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2016 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:

