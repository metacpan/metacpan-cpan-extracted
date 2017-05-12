# $Id$
package DBIx::Class::Validation;
use strict;
use warnings;
our $VERSION = '0.02005';

BEGIN {
    use base qw/DBIx::Class Class::Accessor::Grouped/;
    use English qw/-no_match_vars/;
    use FormValidator::Simple 0.17;
    use Carp qw/croak/;

    __PACKAGE__->mk_group_accessors('inherited', qw/
        validation_profile
        validation_auto
        validation_filter
        _validation_module_accessor
    /);
};
__PACKAGE__->validation_auto(1);
__PACKAGE__->validation_module('FormValidator::Simple');

=head1 NAME

DBIx::Class::Validation - Validate all data before submitting to your database.

=head1 SYNOPSIS

In your base L<"DBIx::Class"> package:

  __PACKAGE__->load_components(qw/... Validation/);

And in your subclasses:

  __PACKAGE__->validation(
    module => 'FormValidator::Simple',
    profile => { ... },
    filter => 0,
    auto => 1,
  );

And then somewhere else:

  eval{ $obj->validate() };
  if( my $results = $EVAL_ERROR ){
    ...
  }

=head1 METHODS

=head2 validation

  __PACKAGE__->validation(
    module => 'FormValidator::Simple',
    profile => { ... },
    filter => 0,
    auto => 1,
  );

Calls L</"validation_module">, L</"validation_profile"> and L</"validation_auto">
if the corresponding argument is defined.

=cut

sub validation {
    my ($self, %args) = @_;

    $self->validation_module($args{module}) if exists $args{module};
    $self->validation_profile($args{profile}) if exists $args{profile};
    $self->validation_auto($args{auto}) if exists $args{auto};
    $self->validation_filter($args{filter}) if exists $args{filter};
};

=head2 validation_module

  __PACKAGE__->validation_module('Data::FormValidator');

Sets the validation module to use.  Any module that supports a check() method
just like L<"Data::FormValidator">'s can be used here, such as
L<"FormValidator::Simple">.

Defaults to FormValidator::Simple.

=cut

sub validation_module {
    my ($self, $class) = @_;

    if ($class) {
        if (!eval "require $class") {
            $self->throw_exception("Unable to load the validation module '$class' because  $@");
        } elsif (!$class->can('check')) {
            $self->throw_exception("The '$class' module does not support the check() method");
        } else {
            $self->_validation_module_accessor($class->new);
        };
    };

    return ref $self->_validation_module_accessor;
};

=head2 validation_profile

  __PACKAGE__->validation_profile(
    { ... }
  );

Sets the profile that will be passed to the validation module.  Expects either
a HASHREF or a reference to a subroutine.  If it's a subref it will be passed
the result row object as it's first parameter so that you can perform complex
data validation for cases when you'd like to have access to the actual result.

For example, you could use the following to return an error if the named field
is not unique in the table:

    my $profile = sub {
        my $result = shift @_;
    
        return {
            required => [qw/email/],
            constraint_methods => {
                email => sub {
                    my ($dvf, $val) = @_;
                    return $result->result_source->resultset->find({email=>$val}) ? 0:1;
                },
            },
        };
    };

Please note that the subref needs to return a hashref/arrayref suitable for use
in the validation module you have chosen.

=head2 validation_auto

  __PACKAGE__->validation_auto( 1 );

Turns on and off auto-validation.  This feature makes all UPDATEs and
INSERTs call the L</"validate"> method before doing anything.

The default is for validation_auto is to be on.

=head2 validation_filter

  __PACKAGE__->validation_filter( 1 );

Turns on and off validation filters. When on, this feature will make all
UPDATEs and INSERTs modify your data to that of the values returned by
your validation modules C<check> method. This is primarily meant for use
with L<"Data::FormValidator"> but may be used with any validation module
that returns a results object that supports a C<valid()> method just
like L<"Data::FormValidator::Results">.

B<Filters modify your data, so use them carefully>.

The default is for validation_filter is to be off.

=head2 validate

  $obj->validate();

Validates all the data in the object against the pre-defined validation
module and profile.  If there is a problem then a hard error will be
thrown.  If you put the validation in an eval you can capture whatever
the module's check() method returned.

=cut

sub validate {
    my $self = shift;
    my %data = $self->get_columns;
    my $module = $self->validation_module;
    my $profile = $self->validation_profile;

    if (ref $profile eq 'CODE') {
        $profile = $profile->($self);
    };
    my $result = $module->check( \%data => $profile );

    if ($result->success) {
        if ($self->validation_filter && $result->can('valid')) {
            $self->$_($result->valid($_)) for ($result->valid);
        };
        return $result;
    } else {
        croak $result;
    };
};

=head1 EXTENDED METHODS

The following L<"DBIx::Class::Row"> methods are extended by this module:-

=over 4

=item insert

=cut

sub insert {
    my $self = shift;
    $self->validate if $self->validation_auto;
    $self->next::method(@_);
}

=item update

=cut

sub update {
    my $self = shift;
    my $columns = shift;

    $self->set_inflated_columns($columns) if $columns;
    $self->validate if $self->validation_auto;
    $self->next::method(@_);
};

1;
__END__

=back

=head1 SEE ALSO

L<"DBIx::Class">, L<"FormValidator::Simple">, L<"Data::FormValidator">

=head1 AUTHOR

Aran C. Deltac <bluefeet@cpan.org>

=head1 CONTRIBUTORS

Tom Kirkpatrick <tkp@cpan.org>

Christopher Laco <claco@cpan.org>

John Napiorkowski <jjn1056@yahoo.com>

Sergio Salvi <sergio@developerl.com>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.
