
#    FormValidator.pm - Object that validates form input data.
#
#    This file is part of Data::FormValidator.
#
#    Author: Francis J. Lacoste
#    Previous Maintainer: Mark Stosberg <mark@stosberg.com>
#    Maintainer: David Farrell <dfarrell@cpan.org>
#
#    Copyright (C) 1999 Francis J. Lacoste, iNsu Innovations
#    Parts Copyright 1996-1999 by Michael J. Heins
#    Parts Copyright 1996-1999 by Bruce Albrecht
#    Parts Copyright 2001-2005 by Mark Stosberg
#
#    Parts of this module are based on work by
#    Bruce Albrecht,  contributed to
#    MiniVend.
#
#    Parts also based on work by Michael J. Heins
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms same terms as perl itself.


package Data::FormValidator;
use Exporter 'import';
use File::Spec qw();
use 5.008;

use Data::FormValidator::Results;
*_arrayify = \&Data::FormValidator::Results::_arrayify;
use Data::FormValidator::Filters ':filters';
use Data::FormValidator::Constraints qw(:validators :matchers);

our $VERSION = 4.88;

our %EXPORT_TAGS = (
    filters => [qw/
        filter_alphanum
        filter_decimal
        filter_digit
        filter_dollars
        filter_integer
        filter_lc
        filter_neg_decimal
        filter_neg_integer
        filter_phone
        filter_pos_decimal
        filter_pos_integer
        filter_quotemeta
        filter_sql_wildcard
        filter_strip
        filter_trim
        filter_uc
        filter_ucfirst
    /],
    validators => [qw/
        valid_american_phone
        valid_cc_exp
        valid_cc_number
        valid_cc_type
        valid_email
        valid_ip_address
        valid_phone
        valid_postcode
        valid_province
        valid_state
        valid_state_or_province
        valid_zip
        valid_zip_or_postcode
    /],
    matchers => [qw/
        match_american_phone
        match_cc_exp
        match_cc_number
        match_cc_type
        match_email
        match_ip_address
        match_phone
        match_postcode
        match_province
        match_state
        match_state_or_province
        match_zip
        match_zip_or_postcode
    /],
);
our @EXPORT_OK = (@{ $EXPORT_TAGS{filters} }, @{ $EXPORT_TAGS{validators} }, @{ $EXPORT_TAGS{matchers} });


use strict;
use Symbol;


sub DESTROY {}

=pod

=head1 NAME

Data::FormValidator - Validates user input (usually from an HTML form) based
on input profile.

=head1 SYNOPSIS

 use Data::FormValidator;

 my $results = Data::FormValidator->check(\%input_hash, \%dfv_profile);

 if ($results->has_invalid or $results->has_missing) {
     # do something with $results->invalid, $results->missing
     # or  $results->msgs
 }
 else {
     # do something with $results->valid
 }


=head1 DESCRIPTION

Data::FormValidator's main aim is to make input validation expressible in a
simple format.

Data::FormValidator lets you define profiles which declare the
required and optional fields and any constraints they might have.

The results are provided as an object, which makes it easy to handle
missing and invalid results, return error messages about which constraints
failed, or process the resulting valid data.

=cut

sub new {
    my $proto = shift;
    my $profiles_or_file = shift;
    my $defaults = shift;

    my $class = ref $proto || $proto;

    if ($defaults) {
        ref $defaults eq 'HASH' or
            die 'second argument to new must be a hash ref';
    }

    my ($file, $profiles);

    if (ref $profiles_or_file) {
        $profiles = $profiles_or_file;
    }
    else {
        $file = File::Spec->rel2abs( $profiles_or_file );
    }


    bless {
        profile_file => $file,
        profiles     => $profiles,
        defaults     => $defaults,
    }, $class;
}

=head1 VALIDATING INPUT

=head2 check()

 my $results = Data::FormValidator->check(\%input_hash, \%dfv_profile);

C<check> is the recommended method to use to validate forms. It returns its results as a
L<Data::FormValidator::Results|Data::FormValidator::Results> object.  A
deprecated method C<validate> described below is also available, returning its results as an
array.

 use Data::FormValidator;
 my $results = Data::FormValidator->check(\%input_hash, \%dfv_profile);

Here, C<check()> is used as a class method, and takes two required parameters.

The first a reference to the data to be be validated. This can either be a hash
reference, or a CGI.pm-like object. In particular, the object must have a param()
method that works like the one in CGI.pm does. CGI::Simple and Apache::Request
objects are known to work in particular. Note that if you use a hash reference,
multiple values for a single key should be presented as an array reference.

The second argument is a reference to the profile you are validating.

=head2 validate()

    my( $valids, $missings, $invalids, $unknowns ) =
        Data::FormValidator->validate( \%input_hash, \%dfv_profile);

C<validate()> provides a deprecated alternative to C<check()>. It has the same input
syntax, but returns a four element array, described as follows

=over

=item valids

This is a hash reference to the valid fields which were submitted in
the data. The data may have been modified by the various filters specified.

=item missings

This is a reference to an array which contains the name of the missing
fields. Those are the fields that the user forget to fill or filled
with spaces. These fields may comes from the I<required> list or the
I<dependencies> list.

=item invalids

This is a reference to an array which contains the name of the fields which
failed one or more of their constraint checks. If there are no invalid fields,
an empty arrayref will be returned.

Fields defined with multiple constraints will have an array ref returned in the
@invalids array instead of a string. The first element in this array is the
name of the field, and the remaining fields are the names of the failed
constraints.

=item unknowns

This is a list of fields which are unknown to the profile. Whether or
not this indicates an error in the user input is application
dependent.

=back

=head2 new()

Using C<new()> is only needed for advanced usage, including these cases:

=over

=item o

Loading more than one profile at a time. Then you can select the profile you
want by name later with C<check()>. Here's an example:

 my $dfv = Data::FormValidator->new({
    profile_1 => { # usual profile definition here },
    profile_2 => { # another profile definition },
 });


As illustrated, multiple profiles are defined through a hash ref whose keys point
to profile definitions.

You can also load several profiles from a file, by defining several profiles as shown above
in an external file. Then just pass in the name of the file:

 my $dfv = Data::FormValidator->new('/path/to/profiles.pl');

If the input profile is specified as a file name, the profiles will be reread
each time that the disk copy is modified.

Now when calling C<check()>, you just need to supply the profile name:

 my $results = $dfv->check(\%input_hash,'profile_1');

=item o

Applying defaults to more than one input profile. There are some parts
of the validation profile that you might like to re-use for many form
validations.

To facilitate this, C<new()> takes a second argument, a hash reference. Here
the usual input profile definitions can be made. These will act as defaults for
any subsequent calls to C<check()> on this object.

Currently the logic for this is very simple. Any definition of a key in your
validation profile will completely overwrite your default value.

This means you can't define two keys for C<constraint_regexp_map> and expect
they will always be there. This kind of feature may be added in the future.

The exception here is definitions for your C<msgs> key. You will safely  be
able to define some defaults for the top level keys within C<msgs> and not have
them clobbered just because C<msgs> was defined in a validation profile.

One way to use this feature is to create your own sub-class that always provides
your defaults to C<new()>.

Another option is to create your own wrapper routine which provides these defaults to
C<new()>.  Here's an example of a routine you might put in a
L<CGI::Application|CGI::Application> super-class to make use of this feature:

 # Always use the built-in CGI object as the form data
 # and provide some defaults to new constructor
 sub check_form {
     my $self = shift;
     my $profile = shift
        || die 'check_form: missing required profile';

     require Data::FormValidator;
     my $dfv = Data::FormValidator->new({},{
        # your defaults here
     });
     return $dfv->check($self->query,$profile);
 }


=back

=cut

sub validate {
    my ($self,$data,$name) = @_;

    my $data_set = $self->check( $data,$name );

    my $valid   = $data_set->valid();
    my $missing = $data_set->missing();
    my $invalid = $data_set->{validate_invalid} || [];
    my $unknown = [ $data_set->unknown ];

    return ( $valid, $missing, $invalid, $unknown );
}

sub check {
    my ( $self, $data, $name ) = @_;

    # check can be used as a class method for simple cases
    if (not ref $self) {
        my $class = $self;
        $self = {};
        bless $self, $class;
    }

    my $profile;
    if ( ref $name ) {
        $profile = $name;
    } else {
        $self->load_profiles;
        $profile = $self->{profiles}{$name};
        die "No such profile $name\n" unless $profile;
    }
    die "input profile must be a hash ref" unless ref $profile eq "HASH";

    # add in defaults from new(), if any
    if ($self->{defaults}) {
        $profile = { %{$self->{defaults}}, %$profile };
    }

    # check the profile syntax or die with an error.
    _check_profile_syntax($profile);

    my $results = Data::FormValidator::Results->new( $profile, $data );

    # As a special case, pass through any defaults for the 'msgs' key.
    $results->msgs($self->{defaults}->{msgs}) if $self->{defaults}->{msgs};

    return $results;
}

=head1 INPUT PROFILE SPECIFICATION

An input profile is a hash reference containing one or more of the following
keys.

Here is a very simple input profile. Examples of more advanced options are
described below.

    use Data::FormValidator::Constraints qw(:closures);

    my $profile = {
        optional => [qw( company
                         fax
                         country )],

        required => [qw( fullname
                         phone
                         email
                         address )],

        constraint_methods => {
            email => email(),
        }
    };


That defines some fields as optional, some as required, and defines that the
field named 'email' must pass the constraint named 'email'.

Here is a complete list of the keys available in the input profile, with
examples of each.

=head2 required

This is an array reference which contains the name of the fields which are
required. Any fields in this list which are not present or contain only
spaces will be reported as missing.

=head2 required_regexp

 required_regexp => qr/city|state|zipcode/,

This is a regular expression used to specify additional field names for which values
will be required.

=head2 require_some

 require_some => {
    # require any two fields from this group
    city_or_state_or_zipcode => [ 2, qw/city state zipcode/ ],
 }

This is a reference to a hash which defines groups of fields where 1 or more
fields from the group should be required, but exactly which fields doesn't
matter. The keys in the hash are the group names.  These are returned as
"missing" unless the required number of fields from the group has been filled
in. The values in this hash are array references. The first element in this
array should be the number of fields in the group that is required. If the
first field in the array is not an a digit, a default of "1" will be used.

=head2 optional

 optional => [qw/meat coffee chocolate/],

This is an array reference which contains the name of optional fields.
These are fields which MAY be present and if they are, they will be
checked for valid input. Any fields not in optional or required list
will be reported as unknown.

=head2 optional_regexp

 optional_regexp => qr/_province$/,

This is a regular expression used to specify additional fields which are
optional. For example, if you wanted all fields names that begin with I<user_>
to be optional, you could use the regular expression, /^user_/

=head2 dependencies

 dependencies   => {

    # If cc_no is entered, make cc_type and cc_exp required
    "cc_no" => [ qw( cc_type cc_exp ) ],

    # if pay_type eq 'check', require check_no
    "pay_type" => {
        check => [ qw( check_no ) ],
     }

    # if cc_type is VISA or MASTERCARD require CVV
    "cc_type" => sub {
        my $dfv  = shift;
        my $type = shift;

        return [ 'cc_cvv' ] if ($type eq "VISA" || $type eq "MASTERCARD");
        return [ ];
    },
 },

This is for the case where an optional field has other requirements.  The
dependent fields can be specified with an array reference.

If the dependencies are specified with a hash reference then the additional
constraint is added that the optional field must equal a key for the
dependencies to be added.

If the dependencies are specified as a code reference then the code will be
executed to determine the dependent fields.  It is passed two parameters,
the object and the value of the field, and it should return an array reference
containing the list of dependent fields.

Any fields in the dependencies list that are missing when the target is present
will be reported as missing.

=head2 dependency_groups

 dependency_groups  => {
     # if either field is filled in, they all become required
     password_group => [qw/password password_confirmation/],
 }

This is a hash reference which contains information about groups of
interdependent fields. The keys are arbitrary names that you create and
the values are references to arrays of the field names in each group.

=head2 dependencies_regexp

 dependencies_regexp => {
    qr/Line\d+\_ItemType$/ => sub {
       my $dfv = shift;
       my $itemtype = shift;
       my $field = shift;

       if ($type eq 'NeedsBatteries') {
          my ($prefix, $suffix) = split(/\_/, $field);

          return([$prefix . '_add_batteries]);
       } else {
          return([]);
       }
    },
 },

This is a regular expression used to specify additional fields which are
dependent. For example, if you wanted to add dependencies for all fields which
meet a certain criteria (such as multiple items in a shopping cart) where you
do not know before hand how many of such fields you may have.

=head2 dependent_optionals

 dependent_optionals => {
    # If delivery_address is specified then delivery_notes becomes optional
    "delivery_address" => [ qw( delivery_notes ) ],

    # if delivery_type eq 'collection', collection_notes becomes optional
    "delivery_type" => {
       collection => [ qw( collection_notes ) ],
    }

    # if callback_type is "phone" or "email" then additional_notes becomes optional
    "callback_type" => sub {
       my $dfv = shift;
       my $type = shift;

       if ($type eq 'phone' || $type eq 'email') {
          return(['additional_notes']);
       } else {
          return([]);
       }
    },
 },

This is for the case where an optional field can trigger other optional fields.
The dependent optional fields can be specified with an array reference.

If the dependent optional fields are specified with a hash reference, then an
additional constraint is added that the optional field must equal a key for the
additional optional fields to be added.

If the dependent optional fields are specified as a code reference then the
code will be executed to determine the additional optional fields. It is passed
two parameters, the object and the value of the field, and it should return an
array reference containing the list of additional optional fields.

=head2 dependent_require_some

 dependent_require_some => {
    # require any fields from this group if AddressID is "new"
    AddressID => sub {
       my $dfv = shift;
       my $value = shift;

       if ($value eq 'new') {
          return({
             house_name_or_number => [ 1, 'HouseName', 'HouseNumber' ],
          });
       } else {
          return;
       }
    },
 }

Sometimes a field will need to trigger additional dependencies but you only
require some of the fields. You cannot set them all to be dependent as you
might only have some of them, and you cannot set them all to be optional as
you must have some of them. This method allows you to specify this in a
similar way to the equire_some method but dependent upon other values. In
the example above if the AddressID submitted is "new" then at least 1 of
HouseName and HouseNumber must also be supplied. See require_some for the
valid options for the return.

=head2 defaults

 defaults => {
     country => "USA",
 },

This is a hash reference where keys are field names and
values are defaults to use if input for the field is missing.

The values can be code refs which will be used to calculate the
value if needed. These code refs will be passed in the DFV::Results
object as the only parameter.

The defaults are set shortly before the constraints are applied, and
will be returned with the other valid data.

=head2 defaults_regexp_map

  defaults_regexp_map => {
      qr/^opt_/ => 1,
  },

This is a hash reference that maps  regular expressions to default values to
use for matching optional or required fields.

It's useful if you have generated many checkbox fields with the similar names.
Since checkbox fields submit nothing at all when they are not checked, it's
useful to set defaults for them.

Note that it doesn't make sense to use a default for a field handled by
C<optional_regexp> or C<required_regexp>.  When the field is not submitted,
there is no way to know that it should be optional or required, and thus there's
no way to know that a default should be set for it.

=head2 filters

 # trim leading and trailing whitespace on all fields
 filters       => ['trim'],

This is a reference to an array of filters that will be applied to ALL optional
and required fields, B<before> any constraints are applied.

This can be the name of a built-in filter
(trim,digit,etc) or an anonymous subroutine which should take one parameter,
the field value and return the (possibly) modified value.

Filters modify the data returned through the results object, so use them carefully.

See L<Data::FormValidator::Filters> for details on the built-in filters.

=head2 field_filters

 field_filters => {
     cc_no => ['digit'],
 },

A hash ref with field names as keys. Values are array references of built-in
filters to apply (trim,digit,etc) or an anonymous subroutine which should take
one parameter, the field value and return the (possibly) modified value.

Filters are applied B<before> any constraints are applied.

See L<Data::FormValidator::Filters> for details on the built-in filters.

=head2 field_filter_regexp_map

 field_filter_regexp_map => {
     # Upper-case the first letter of all fields that end in "_name"
     qr/_name$/    => ['ucfirst'],
 },

'field_filter_regexp_map' is used to apply filters to fields that match a
regular expression.  This is a hash reference where the keys are the regular
expressions to use and the values are references to arrays of filters which
will be applied to specific input fields. Just as with 'field_filters', you
can you use a built-in filter or use a coderef to supply your own.

=head2 constraint_methods

 use Data::FormValidator::Constraints qw(:closures);

 constraint_methods => {
    cc_no      => cc_number({fields => ['cc_type']}),
    cc_type    => cc_type(),
    cc_exp     => cc_exp(),
  },

A hash ref which contains the constraints that will be used to check whether or
not the field contains valid data.

B<Note:> To use the built-in constraints, they need to first be loaded into your
name space using the syntax above. (Unless you are using the old C<constraints> key,
documented in L<BACKWARDS COMPATIBILITY>).

The keys in this hash are field names. The values can be any of the following:

=over

=item o

A named constraint.

B<Example>:

 my_zipcode_field     => zip(),

See L<Data::FormValidator::Constraints> for the details of which
built-in constraints that are available.


=item o

A perl regular expression

B<Example>:

 my_zipcode_field   => qr/^\d{5}$/, # match exactly 5 digits

If this field is named in C<untaint_constraint_fields> or C<untaint_regexp_map>,
or C<untaint_all_constraints> is effective, be aware of the following: If you
write your own regular expressions and only match part of the string then
you'll only get part of the string in the valid hash. It is a good idea to
write you own constraints like /^regex$/. That way you match the whole string.

=item o

a subroutine reference, to supply custom code

This will check the input and return true or false depending on the input's validity.
By default, the constraint function receives a L<Data::FormValidator::Results>
object as its first argument, and the value to be validated as the second.  To
validate a field based on more inputs than just the field itself, see
L<VALIDATING INPUT BASED ON MULTIPLE FIELDS>.

B<Examples>:

 # Notice the use of 'pop'--
 # the object is the first arg passed to the method
 # while the value is the second, and last arg.
 my_zipcode_field => sub { my $val = pop;  return $val =~ '/^\d{5}$/' },

 # OR you can reference a subroutine, which should work like the one above
 my_zipcode_field => \&my_validation_routine,

 # An example of setting the constraint name.
 my_zipcode_field => sub {
    my ($dfv, $val) = @_;
    $dfv->set_current_constraint_name('my_constraint_name');
    return $val =~ '/^\d{5}$/'
 },

=item o

an array reference

An array reference is used to apply multiple constraints to a single
field. Any of the above options are valid entries the array.
See L<MULTIPLE CONSTRAINTS> below.

For more details see L<VALIDATING INPUT BASED ON MULTIPLE FIELDS>.

=back

=head2 constraint_method_regexp_map

 use Data::FormValidator::Constraints qw(:closures);

 # In your profile.
 constraint_method_regexp_map => {
     # All fields that end in _postcode have the 'postcode' constraint applied.
     qr/_postcode$/    => postcode(),
 },

A hash ref where the keys are the regular expressions to
use and the values are the constraints to apply.

If one or more constraints have already been defined for a given field using
C<constraint_methods>, C<constraint_method_regexp_map> will add an additional
constraint for that field for each regular expression that matches.

=head2 untaint_all_constraints

 untaint_all_constraints => 1,

If this field is set, all form data that passes a constraint will be untainted.
The untainted data will be returned in the valid hash.  Untainting is based on
the pattern match used by the constraint.  Note that some constraint routines
may not provide untainting.

See L<Writing your own constraint routines|Data::FormValidator::Constraints/"WRITING YOUR OWN CONSTRAINT ROUTINES"> for more information.

This is overridden by C<untaint_constraint_fields> and C<untaint_regexp_map>.

=head2 untaint_constraint_fields

 untaint_constraint_fields => [qw(zipcode state)],

Specifies that one or more fields will be untainted if they pass their
constraint(s). This can be set to a single field name or an array reference of
field names. The untainted data will be returned in the valid hash.

This overrides the untaint_all_constraints flag.

=head2 untaint_regexp_map

 untaint_regexp_map => [qr/some_field_\d/],

Specifies that certain fields will be untainted if they pass their constraints
and match one of the regular expressions supplied. This can be set to a single
regex, or an array reference of regexes. The untainted data will be returned
in the valid hash.

The above example would untaint the fields named C<some_field_1>, and C<some_field_2>
but not C<some_field>.

This overrides the untaint_all_constraints flag.

=head2 missing_optional_valid

 missing_optional_valid => 1

This can be set to a true value to cause optional fields with empty values to
be included in the valid hash. By default they are not included-- this is the
historical behavior.

This is an important flag if you are using the contents of an "update" form to
update a record in a database. Without using the option, fields that have been
set back to "blank" may fail to get updated.

=head2 validator_packages

 # load all the constraints and filters from these modules
 validator_packages => [qw(Data::FormValidator::Constraints::Upload)],

This key is used to define other packages which contain constraint routines or
filters.  Set this key to a single package name, or an arrayref of several. All
of its constraint and filter routines  beginning with 'match_', 'valid_' and
'filter_' will be imported into Data::FormValidator.  This lets you reference
them in a constraint with just their name, just like built-in routines.  You
can even override the provided validators.

See L<Writing your own constraint routines|Data::FormValidator::Constraints/"WRITING YOUR OWN CONSTRAINT ROUTINES">
documentation for more information

=head2 msgs

This key is used to define parameters related to formatting error messages
returned to the user.

By default, invalid fields have the message "Invalid" associated with them
while missing fields have the message "Missing" associated with them.

In the simplest case, nothing needs to be defined here, and the default values
will be used.

The default formatting applied is designed for display in an XHTML web page.
That formatting is as followings:

    <span style="color:red;font-weight:bold" class="dfv_errors">* %s</span>

The C<%s> will be replaced with the message. The effect is that the message
will appear in bold red with an asterisk before it. This style can be overridden by simply
defining "dfv_errors" appropriately in a style sheet, or by providing a new format string.

Here's a more complex example that shows how to provide your own default message strings, as well
as providing custom messages per field, and handling multiple constraints:

 msgs => {

     # set a custom error prefix, defaults to none
     prefix=> 'error_',

     # Set your own "Missing" message, defaults to "Missing"
     missing => 'Not Here!',

     # Default invalid message, default's to "Invalid"
     invalid => 'Problematic!',

     # message separator for multiple messages
     # Defaults to ' '
     invalid_separator => ' <br /> ',

     # formatting string, default given above.
     format => 'ERROR: %s',

     # Error messages, keyed by constraint name
     # Your constraints must be named to use this.
     constraints => {
                     'date_and_time' => 'Not a valid time format',
                     # ...
     },

     # This token will be included in the hash if there are
     # any errors returned. This can be useful with templating
     # systems like HTML::Template
     # The 'prefix' setting does not apply here.
     # defaults to undefined
     any_errors => 'some_errors',
 }

The hash that's prepared can be retrieved through the C<msgs> method
described in the L<Data::FormValidator::Results> documentation.

=head2 msgs - callback

I<This is a new feature. While it expected to be forward-compatible, it hasn't
yet received the testing the rest of the API has.>

If the built-in message generation doesn't suit you, it is also possible to
provide your own by specifying a code reference:

 msgs  =>  \&my_msgs_callback

This will be called as a L<Data::FormValidator::Results> method.  It may
receive as arguments an additional hash reference of control parameters,
corresponding to the key names usually used in the C<msgs> area of the
profile. You can ignore this information if you'd like.

If you have an alternative error message handler you'd like to share, stick in
the C<Data::FormValidator::ErrMsgs> name space and upload it to CPAN.

=head2 debug

This method is used to print details about what is going on to STDERR.

Currently only level '1' is used. It provides information about which
fields matched constraint_regexp_map.

=head2 A shortcut for array refs

A number of parts of the input profile specification include array references
as their values.  In any of these places, you can simply use a string if you
only need to specify one value. For example, instead of

 filters => [ 'trim' ]

you can simply say

 filters => 'trim'

=head2 A note on regular expression formats

In addition to using the preferred method of defining regular expressions
using C<qr>, a deprecated style of defining them as strings is also supported.

Preferred:

 qr/this is great/

Deprecated, but supported

 'm/this still works/'

=head1 VALIDATING INPUT BASED ON MULTIPLE FIELDS

You can pass more than one value into a constraint routine.  For that, the
value of the constraint should be a hash reference. If you are creating your
own routines, be sure to read the section labeled
L<WRITING YOUR OWN CONSTRAINT ROUTINES>,
in the Data::FormValidator::Constraints documentation.  It describes
a newer and more flexible syntax.

Using the original syntax, one key should be named C<constraint> and should
have a value set to the reference of the subroutine or the name of a built-in
validator.  Another required key is C<params>. The value of the C<params> key
is a reference to an array of the other elements to use in the validation. If
the element is a scalar, it is assumed to be a field name. The field is known
to Data::FormValidator, the value will be filtered through any defined filters
before it is passed in.  If the value is a reference, the reference is passed
directly to the routine.  Don't forget to include the name of the field to
check in that list, if you are using this syntax.

B<Example>:

 cc_no  => {
     constraint  => "cc_number",
     params         => [ qw( cc_no cc_type ) ],
 },


=head1 MULTIPLE CONSTRAINTS

Multiple constraints can be applied to a single field by defining the value of
the constraint to be an array reference. Each of the values in this array can
be any of the constraint types defined above.

When using multiple constraints it is important to return the name of the
constraint that failed so you can distinguish between them. To do that,
either use a named constraint, or use the hash ref method of defining a
constraint and include a C<name> key with a value set to the name of your
constraint.  Here's an example:

  my_zipcode_field => [
      'zip',
      {
        constraint_method =>  '/^406/',
        name              =>  'starts_with_406',
      }
  ],

You can use an array reference with a single constraint in it if you just want
to have the name of your failed constraint returned in the above fashion.

Read about the C<validate()> function above to see how multiple constraints
are returned differently with that method.

=cut

sub load_profiles {
    my $self = shift;

    my $file = $self->{profile_file};
    return unless $file;

    die "No such file: $file\n" unless -f $file;
    die "Can't read $file\n"    unless -r _;

    my $mtime = (stat _)[9];
    return if $self->{profiles} and $self->{profiles_mtime} <= $mtime;

    $self->{profiles} = do $file;
    die "Input profiles didn't return a hash ref: $@\n"
      unless ref $self->{profiles} eq "HASH";

    $self->{profiles_mtime} = $mtime;
}



# check the profile syntax and die if we have an error
sub _check_profile_syntax {
    my $profile = shift;

    (ref $profile eq 'HASH') or
        die "Invalid input profile: needs to be a hash reference\n";

    my @invalid;

    # check top level keys
    {
        my @valid_profile_keys = (qw/
            constraint_methods
            constraint_method_regexp_map
            constraint_regexp_map
            constraints
            defaults
            defaults_regexp_map
            dependencies
            dependencies_regexp
            dependency_groups
            dependent_optionals
            dependent_require_some
            field_filter_regexp_map
            field_filters
            filters
            missing_optional_valid
            msgs
            optional
            optional_regexp
            require_some
            required
            required_regexp
            untaint_all_constraints
            validator_packages
            untaint_constraint_fields
            untaint_regexp_map
            debug
        /);

        # If any of the keys in the profile are not listed as
        # valid keys here, we die with an error
        for my $key (keys %$profile) {
            push @invalid, $key unless grep $key eq $_, @valid_profile_keys;
        }

        local $" = ', ';
        if (@invalid) {
            die "Invalid input profile: keys not recognised [@invalid]\n";
        }
    }

    # Check that constraint_methods are always code refs or REs
    {
        # Cases:
        # 1. constraint_methods          => { field      => func() }
        # 2. constraint_methods          => { field      => [ func() ] }
        # 3. constraint_method_regex_map => { qr/^field/ => func()   }
        # 4. constraint_method_regex_map => { qr/^field/ => [ func() ] }
        # 5. constraint_methods => { field => { constraint_method => func() } }

        # Could be improved by also naming the associated key for the bad value.
        for my $key (grep { $profile->{$_} } qw/constraint_methods constraint_method_regexp_map/) {
            for my $val (map { _arrayify($_) } values %{ $profile->{$key} }) {
                if (ref $val eq 'HASH' && !grep(ref $val->{constraint_method} eq $_, 'CODE','Regexp'))  {
                    die "Value for constraint_method within hashref '$val->{constraint_method}' not a code reference or Regexp . Do you need func(), not 'func'?";
                }
                # Cases 1 through 4.
                elsif (!grep(ref $val eq $_, 'HASH','CODE','Regexp')) {
                    die "Value for constraint_method '$val' not a code reference or Regexp . Do you need func(), not 'func'?";
                }
                # Case 5.
                else {
                    # We're cool. Nothing to do.
                }
            }
        }
    }

    # Check constraint hash keys
    {
        my @valid_constraint_hash_keys = (qw/
            constraint
            constraint_method
            name
            params
        /);

        my @constraint_hashrefs = grep { ref $_ eq 'HASH' } values %{ $profile->{constraints} }
            if $profile->{constraints};
        push @constraint_hashrefs, grep { ref $_ eq 'HASH' } values %{ $profile->{constraint_regexp_map} }
            if $profile->{constraint_regexp_map};

        for my $href (@constraint_hashrefs) {
            for my $key (keys %$href) {
                push @invalid, $key unless grep $key eq $_, @valid_constraint_hash_keys;
            }
        }

        if (@invalid) {
            die "Invalid input profile: constraint hashref keys not recognised [@invalid]\n";
        }
    }

    # Check msgs keys
    {
        my @valid_msgs_hash_keys = (qw/
                prefix
                missing
                invalid
                invalid_separator
                invalid_seperator
                format
                constraints
                any_errors
        /);
        if (ref $profile->{msgs} eq 'HASH') {
            for my $key (keys %{ $profile->{msgs} }) {
                push @invalid, $key unless grep $key eq $_, @valid_msgs_hash_keys;
            }
        }
        if (@invalid) {
            die "Invalid input profile: msgs keys not recognized: [@invalid]\n";
        }
    }

}


1;

__END__

=pod

=head1 ADVANCED VALIDATION

For even more advanced validation, you will likely want to read the
documentation for other modules in this distribution, linked below. Also keep
in mind that the  Data::FormValidator profile structure is just another data
structure. There is no reason why it needs to be defined statically. The
profile could also be built on the fly with custom Perl code.

=head1 BACKWARDS COMPATIBILITY

=head2 validate()

    my( $valids, $missings, $invalids, $unknowns ) =
        Data::FormValidator->validate( \%input_hash, \%dfv_profile);

C<validate()> provides a deprecated alternative to C<check()>. It has the same input
syntax, but returns a four element array, described as follows

=over

=item valids

This is a hash reference to the valid fields which were submitted in
the data. The data may have been modified by the various filters specified.

=item missings

This is a reference to an array which contains the name of the missing
fields. Those are the fields that the user forget to fill or filled
with spaces. These fields may comes from the I<required> list or the
I<dependencies> list.

=item invalids

This is a reference to an array which contains the name of the fields
which failed one or more of their constraint checks.

Fields defined with multiple constraints will have an array ref returned in the
@invalids array instead of a string. The first element in this array is the
name of the field, and the remaining fields are the names of the failed
constraints.

=item unknowns

This is a list of fields which are unknown to the profile. Whether or
not this indicates an error in the user input is application
dependent.

=back

=head2 constraints (profile key)

This is a supported but deprecated profile key. Using C<constraint_methods> is
recommended instead, which provides a simpler, more versatile interface.

 constraints => {
    cc_no      => {
        constraint  => "cc_number",
        params        => [ qw( cc_no cc_type ) ],
    },
    cc_type    => "cc_type",
    cc_exp    => "cc_exp",
  },

A hash ref which contains the constraints that
will be used to check whether or not the field contains valid data.

The keys in this hash are field names. The values can be any of the following:

=over

=item o

A named constraint.

B<Example>:

 my_zipcode_field     => 'zip',

See L<Data::FormValidator::Constraints> for the details of which
built-in constraints that are available.

=back

=head2 hashref style of specifying constraints

Using a hash reference to specify a constraint is an older technique
used to name a constraint or supply multiple parameters.

Both of these interface issues are now better addressed with C<constraint_methods>
and C<$self-\>name_this('foo')>.

 # supply multiple parameters
 cc_no  => {
     constraint  => "cc_number",
     params      => [ qw( cc_no cc_type ) ],
 },

 # name a constraint, useful for returning error messages
 last_name => {
     name => "ends_in_name",
     constraint => qr/_name$/,
 },

Using a hash reference for a constraint permits the passing of multiple
arguments. Required arguments are C<constraint> or C<constraint_method>.
Optional arguments are C<name> and C<params>.

A C<name> on a constraints 'glues' the constraint to its error message
in the validator profile (refer C<msgs> section below). If no C<name> is
given then it will default to the value of C<constraint> or
C<constraint_method> IF they are NOT a CODE ref or a RegExp ref.

The C<params> value is a reference to an array of the parameters to pass
to the constraint method.
If an element of the C<params> list is a scalar, it is assumed to be naming
a key of the %input_hash and that value is passed to the routine.
If the parameter is a reference, then it is treated literally and passed
unchanged to the routine.

If you are using the older C<constraint> over
the new C<constraint_method> then don't forget to include the name of the
field to check in the C<params> list. C<constraint_method> provides access
to this value via the C<get_current_*> methods
(refer L<Data::FormValidator::Constraints>)

For more details see L<VALIDATING INPUT BASED ON MULTIPLE FIELDS>.

=head2 constraint_regexp_map (profile key)

This is a supported but deprecated profile key. Using
C<constraint_methods_regexp_map> is recommended instead.

 constraint_regexp_map => {
     # All fields that end in _postcode have the 'postcode' constraint applied.
     qr/_postcode$/    => 'postcode',
 },

A hash ref where the keys are the regular expressions to
use and the values are the constraints to apply.

If one or more constraints have already been defined for a given field using
"constraints", constraint_regexp_map will add an additional constraint for that
field for each regular expression that matches.

=head1 SEE ALSO

B<Other modules in this distribution:>

L<Data::FormValidator::Constraints|Data::FormValidator::Constraints>

L<Data::FormValidator::Constraints::Dates|Data::FormValidator::Constraints::Dates>

L<Data::FormValidator::Constraints::Upload|Data::FormValidator::Constraints::Upload>

L<Data::FormValidator::ConstraintsFactory|Data::FormValidator::ConstraintsFactory>

L<Data::FormValidator::Filters|Data::FormValidator::Filters>

L<Data::FormValidator::Results|Data::FormValidator::Results>

B<A sample application by the maintainer:>

Validating Web Forms with Perl, L<http://mark.stosberg.com/Tech/perl/form-validation/>

B<Related modules:>

L<Data::FormValidator::Tutorial|Data::FormValidator::Tutorial>

L<Data::FormValidator::Util::HTML|Data::FormValidator::Util::HTML>

L<CGI::Application::ValidateRM|CGI::Application::ValidateRM>, a
CGI::Application & Data::FormValidator glue module

L<HTML::Template::Associate::FormValidator|HTML::Template::Associate::FormValidator> is designed
to make some kinds of integration with HTML::Template easier.

L<Params::Validate|Params::Validate> is useful for validating function parameters.

L<Regexp::Common|Regexp::Common>,
L<Data::Types|Data::Types>,
L<Data::Verify|Data::Verify>,
L<Email::Valid|Email::Valid>,
L<String::Checker|String::Checker>,
L<CGI::ArgChecker|CGI::ArgChecker>,
L<CGI::FormMagick::Validator|CGI::FormMagick::Validator>,
L<CGI::Validate|CGI::Validate>

B<Document Translations:>

Japanese: L<http://perldoc.jp/docs/modules/>

B<Distributions which include Data::FormValidator>

FreeBSD includes a port named B<p5-Data-FormValidator>

Debian GNU/Linux includes a port named B<libdata-formvalidator-perl>

=head1 CREDITS

Some of these input validation functions have been taken from MiniVend
by Michael J. Heins.

The credit card checksum validation was taken from contribution by Bruce
Albrecht to the MiniVend program.

=head1 BUGS

Bug reports and patches are welcome. Reports which include a failing Test::More
style test are helpful and will receive priority.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-FormValidator>

=head1 CONTRIBUTING

This project is maintained on L<Github|https://github.com/dnmfarrell/Data-FormValidator>.

=head1 AUTHOR

Currently maintained by David Farrell <dfarrell@cpan.org>

Parts Copyright 2001-2006 by Mark Stosberg <mark at summersault.com>, (previous maintainer)

Copyright (c) 1999 Francis J. Lacoste and iNsu Innovations Inc.  All rights reserved.
(Original Author)

Parts Copyright 1996-1999 by Michael J. Heins <mike@heins.net>

Parts Copyright 1996-1999 by Bruce Albrecht  <bruce.albrecht@seag.fingerhut.com>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms as perl itself.

=cut



