package Data::Transpose::Validator;

use strict;
use warnings;
use Module::Load;
use Try::Tiny;
# use Data::Dumper;
use Data::Transpose::Validator::Subrefs;
use Data::Transpose::Validator::Group;
use Data::Transpose::Iterator::Errors;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use namespace::clean;

=head1 NAME

Data::Transpose::Validator - Filter and validate data.

=head1 SYNOPSIS

  use Data::Transpose::Validator;
  my $dtv = Data::Transpose::Validator->new();
  $dtv->prepare(email => {validator => 'EmailValid',
                          required => 1},
                password => {validator => 'PasswordPolicy',
                             required => 1}
               );
  
  my $form = {
              email => "aklasdfasdf",
              password => "1234"
             };
  
  my $clean = $dtv->transpose($form);
  if ($clean) {
      # the validator says it's valid, and the hashref $clean is validated
      # $clean is the validated hash
  } else {
      my $errors = $dtv->errors; # arrayref with the errors
      # old data
      my $invalid_but_filtered = $dtv->transposed_data; # hashref with the data
  }

=head1 DESCRIPTION

This module provides an interface to validate and filter hashrefs,
usually (but not necessarily) from HTML forms.

=head1 METHODS


=head2 new

The constructor. It accepts a hash as argument, with options:

C<stripwhite>: strip leading and trailing whitespace from strings (default: true)

C<collapse_whitespace>: collapse all the consecutive whitespace
characters into a single space. This basically will do a C<s/\s+/ /gs>
against the value, so will remove all newlines and tabs as well.
Default is false.

C<requireall>: require all the fields of the schema (default: false)

C<unknown>: what to do if other fields, not present in the schema, are passed.

=over 4

C<fail>: The transposing routine will die with a message stating the unknown fields

C<pass>: The routine will accept them and return them in the validated hash 

C<skip>: The routine will ignore them and not return them in the validated hash. This is the default.

=back

C<missing>: what to do if an optional field is missing

=over 4

C<pass>: do nothing, don't add to the returning hash the missing keys. This is the default.

C<undefine>: add the key with the C<undef> value

C<empty>: set it to the empty string;

=back

=cut 

has stripwhite => (is => 'rw',
                   isa => Bool,
                   default => sub { 1 });

has collapse_whitespace => (is => 'rw',
                            isa => Bool,
                            default => sub { 0 });

has requireall => (is => 'rw',
                   isa => Bool,
                   default => sub { 0 });

has unknown => (is => 'rw',
                isa => Enum[qw/skip fail pass/],
                default => sub { 'skip' });

has missing => (is => 'rw',
                isa => Enum[qw/pass undefine empty/],
                default => sub { 'pass' });

has success => (is => 'rwp',
                isa => Maybe[Bool],
               );

has errors_iterator => (is => 'ro',
                        default => sub {
                            Data::Transpose::Iterator::Errors->new;
                        });

has _fields => (is => 'rw',
                isa => HashRef,
                default => sub { {} });

has _ordering => (is => 'rw',
                  isa => ArrayRef,
                  default => sub { [] });

has transposed_data => (is => 'rwp',
                        isa => Maybe[HashRef]);

has groups => (is => 'rwp',
               isa => ArrayRef,
               default => sub { [] });


=head2 option($option, [ $value ]);

Accessor to the options set. With an optional argument, set that option.

  $dtv->option("requireall"); # get 
  $dtv->option(requireall => 1); # set

This is another way to say $dtv->requireall(1);

=cut

sub option {
    my ($self, $key, $value) = @_;
    return unless $key;
    my %supported = map { $_ => 1 } $self->options;
    die "Bad option $key, should be one of " . join(" ", $self->options)
      unless $supported{$key};
    if (defined $value) {
        $self->$key($value);
    }
    return $self->$key;
}

=head2 option_for_field($option, $field)

Accessor to get the option for this particular field. First it looks
into the fields options, then into the global ones, returning the
first defined value.

  $dtv->option(email => "stripwhite");

=cut

sub option_for_field {
    my ($self, $option, $field) = @_;
    return unless ($field && $option);
    my $hash = $self->field($field)->dtv_options;
    # print Dumper($hash);
    if ($hash and (ref($hash) eq 'HASH') and exists $hash->{$option}) {
        return $hash->{$option};
    }
    return $self->option($option) # return the global one;
}




=head2 options

Accessor to get the list of the options

  $dtv->options;
  # -> requireall, stripwhite, unknown

=cut

sub options {
    return qw/collapse_whitespace
              missing
              requireall
              stripwhite
              unknown
             /;
}

=head2 prepare(%hash) or prepare([ {}, {}, ... ])

C<prepare> takes a hash and pass the key/value pairs to C<field>. This
method can accept an hash or an array reference. When an arrayref is
passed, the output of the errors will keep the provided sorting (this
is the only difference).

You can call prepare as many times you want before the transposing.
Fields are added or replaced, but you could end up with messy errors
if you provide duplicates, so please just don't do it (but feel free
to add the fields at different time I<as long you don't overwrite
them>.

To prevent bad configuration, as of version 0.0005 overwriting an
existing field raises an exception.

  $dtv->prepare([
                  { name => "country" ,
                    required => 1,
                  },
                  {
                   name => "country2",
                   validator => 'String'},
                  {
                   name => "email",
                   validator => "EmailValid"
                  },
                 ]
                );
  
or

  $dtv->prepare(
                country => {
                            required => 1,
                           },
                country2 => {
                             validator => "String"
                            }
               );
  
  ## other code here

  $dtv->prepare(
               email => {
                         validator => "EmailValid"
                        }
               );


The validator value can be an string, a hashref or a coderef.

When a string is passed, the class which will be loaded will be
prefixed by C<Data::Transpose::Validator::> and initialized without
arguments.

If a coderef is passed as value of validator, a new object
L<Data::Transpose::Validator::Subrefs> is created, with the coderef as
validator.

If a hashref is passed as value of validator, it must contains the key
C<class> and optionally C<options> as an hashref. As with the string,
the class will be prefixed by C<Data::Transpose::Validator::>, unless
you pass the C<absolute> key set to a true value.


  $dtv->prepare(
          email => {
              validator => "EmailValid",
               },
  
          # ditto
          email2 => {
               validator => {
                       class => "EmailValid",
                      }
              },
  
          # tritto
          email3 => {
               validator => {
                       class => "Data::Transpose::Validator::EmailValid",
                       absolute => 1,
                      }
              },

          # something more elaborate
          password => {
                 validator => {
                       class => PasswordPolicy,
                       options => {
                             minlength => 10,
                             maxlength => 50,
                             disabled => {
                                    username => 1,
                                   }
                            }
                      }
              }
         );
  
=head3 Groups

You can set the groups either calling C<group> (see below) or with
C<prepare>, using the validator C<Group> with C<fields>.

Using an arrayref:

  $dtv->prepare([
                 {
                   name => 'password',
                   required => 1,
                  },
                  {
                   name => 'confirm_password',
                   required => 1,
                  },
                  {
                   name => 'passwords',
                   validator => 'Group',
                   fields => [
                              qw/password confirm_password/,
                             ],
                   equal => 1,
                  },
                 ]
                 );

Or using an hash

  $dtv->prepare(password => { required => 1 },
                confirm_password => { required => 1 },
                passwords_matching => {
                                       validator => 'Group',
                                       fields => [ "password", "confirm_password" ]
                                      });

By default, if a group is set, it will be checked if all the fields
match. So using the above schema, you'll get:

  ok $dtv->transpose({ password => "a", confirm_password => "a" });
  ok !$dtv->transpose({ password => "a", confirm_password => "b" });


=head3 Bundled classes

Each class has its own documentation for the available options. The
options are passed to the C<new> constructor of the validator's class.

=over 4

=item CreditCard

See L<Data::Transpose::Validator::CreditCard>

Options: C<types> and C<country>

=item EmailValid

See L<Data::Transpose::EmailValid> (no special options)

=item NumericRange

See L<Data::Transpose::Validator::NumericRange>

Options: C<min>, C<max>, C<integer>

=item PasswordPolicy

See L<Data::Transpose::PasswordPolicy> (plenty of options, refers to
the documentation).

=item Set

See L<Data::Transpose::Validator::Set>.

Options: C<list> pointing to an arrayref and the C<multiple> boolean
(to validate an arrayref).

=item String

See L<Data::Transpose::Validator::String> (no special options).

=item URL

See L<Data::Transpose::Validator::URL> (no special options).

=back

=cut

sub prepare {
    my $self = shift;
    # groups should be processed at the end, because, expecially if an
    # hash is passed, they could be processed before the fields are
    # created.
    my @groups;
    if (@_ == 1) {
        # we have an array;
        my $arrayref = shift;
        die qq{Wrong usage! If you pass a single argument, must be a arrayref\n"}
          unless (ref($arrayref) eq 'ARRAY');
        foreach my $field (@$arrayref) {
            # defer the group building
            if (exists $field->{validator} and $field->{validator}) {
                if ($field->{validator} eq 'Group') {
                    push @groups, $field;
                    next;
                }
            }
            my $fieldname = $field->{name};
            die qq{Wrong usage! When an array is passed, "name" must be set!}
              unless $fieldname;
            $self->field($fieldname, $field);
        }
    }
    else {
        my %fields = @_;
        while (my ($k, $v) = each %fields) {
            if (ref($v)
                and ref($v) eq 'HASH'
                and exists $v->{validator}
                and $v->{validator} eq 'Group') {
                my $grp =  { %$v };
                $grp->{name} = $k;
                push @groups, $grp;
                next;
            }
            $self->field($k, $v);
        }
    }
    # fields are fine, build the groups
    # in the configuration we can't have objects
    foreach my $g (@groups) {
        die "Missing group name" unless $g->{name};
        die "Missing fields for $g->{name} group!" unless $g->{fields};
        my @gfields;
        foreach my $f (@{ $g->{fields} }) {
            my $obj = $self->field($f);
            die "Couldn't retrieve field object for group $g->{name}, field $f"
              unless $obj;
            push @gfields, $obj;
        }
        die "No fields found for group $g->{name}" unless @gfields;
        # build the group
        my $group_obj = $self->group($g->{name}, @gfields);
        # and now loops over the other keys and try to call the methods.
        # say ->equal(0)
        my %skip = (
                    name => 1,
                    fields => 1,
                    validator => 1,
                   );
        foreach my $method (keys %$g) {
            next if $skip{$method};
            # e.g $group_obj->equal(1)
            $group_obj->$method($g->{$method});
        }
    }
}

=head2 field($field)

This accessor sets the various fields and their options. It's intended
to be used only internally, but you can add individual fields with it

  $dtv->field(email => { required => 1 });

If the second argument is a string, it is assumed as the validator name. E.g.

  $dtv->field(email => 'EmailValid');

This by itself use the EmailValid with the default settings. If you
want fine control you need to pass an hashref. Also note that unless
you specified C<requireall> as true in the constructor, you need to
set the require.

So these syntaxes do the same:

    $dtv->field(email => { required => 1,
                           validator => 'EmailValid',
                         });
    $dtv->field(email => 'EmailValid')->required(1);

With 1 argument retrieves the object responsible for the validation of
that field, so you can call methods on them:

  $dtv->field(email => { required => 0 })->required(1);
  $dtv->field('email')->required # return true

You can also pass options for the validator, e.g.:

 $dtv->field('month' => { validator => 'NumericRange',
                          options => {
                              min => 1,
                              max => 12,
                              integer => 1
                          },
                         });

WARNING: Earlier versions of this method without any argument would
have retrieved the whole structure. Now it dies instead.

=cut

sub field {
    my ($self, $field, $args) = @_;
    # initialize
    unless ($field) {
        my $deprecation =<<'DEATH';
As of version 0.0005, the retrieval of the whole structure without
field argument is deprecated, as fields return an object instead!
DEATH
        die $deprecation unless $field;
    }

    if ($args) {
        unless (ref($field) eq '') {
            die "Wrong usage, $field must be a string with the field name!\n" 
        };

        # if a string is passed, consider it as a validator
        unless (ref($args)) {
            $args = { validator => $args };
        }
        #  validate the args and store them
        if (ref($args) eq 'HASH') {
            $self->_field_args_are_valid($field => keys %$args);
            my $obj = $self->_build_object($field, $args);
            # prevent to mix up rules.
            if ($self->_fields->{$field}) {
                die "$field has already a validation rule!\n";
            }
            $self->_fields->{$field} = $obj;
        }
        else {
            # raise exception to prevent bad configurations
            die "Argument for $field must be an hashref, got $args!\n";
        }
        # add the field to the list
        $self->_sorted_fields($field);
    }
    return $self->_fields->{$field};
}

sub _sorted_fields {
    my ($self, $field) = @_;
    if ($field) {
        push @{$self->_ordering}, $field;
    }
    return @{$self->_ordering};
}

# return the sorted list of fields

=head2 group (name => $field1, $field2, $field3, ...)

Create a named group of fields and schedule them for validation.

The logic is:

First, the individual fields are normally checked according to the
rules provided with C<prepare> or C<field>.

If they pass the test, the group operation are checked.

Group by itself returns a L<Data::Transpose::Validator::Group> object,
so you can call methods on them to set the rules.

E.g. $self->group("passwords")->equal(1) # not needed it's the default

=head2 groups

Retrieve the list of the group objects scheduled for validation

=cut

sub group {
    my ($self, $name, @objects) = @_;
    die "Wrong usage, first argument must be a string!" unless $name && !ref($name);
    if (@objects) {
        my @group;
        foreach my $field (@objects) {
            my $obj = $field;
            unless (ref($field)) {
                $obj = $self->field($field);
            }
            # if we couldn't retrieve the field, die, we can't build the group
            die "$obj could not be retrieved! Too early for this?" unless $obj;
            push @group, $obj;
        }
        my $group = Data::Transpose::Validator::Group->new(name => $name,
                                                           fields => \@group);

        push @{ $self->groups }, $group;
        # store it in the dtv object and return it
        return $group;
    }
    # retrieve
    foreach my $g (@{ $self->groups }) {
        if ($g->name eq $name) {
            return $g;
        }
    }
    return;
}


=head2 transpose

The main method. It validates the hash and return a validated one or
nothing if there were errors.

=cut




sub transpose {
    my ($self, $hash) = @_;
    die "Wrong usage! A hashref is needed as argument for transpose method!\n"
      unless ($hash and (ref($hash) eq 'HASH'));
    $self->reset_self;


    my (%output, %status);

    # remember which keys we had processed
    $status{$_} = 1 for keys %$hash;

    # we loop over the schema
    foreach my $field ($self->_sorted_fields) {
        my $obj = $self->field($field);
        $obj->reset_dtv_value;
        my $value;
        # the incoming hash could not have such a field
        if (exists $status{$field}) {

            delete $status{$field};
            $value = $hash->{$field};

            # strip white if the option says so
            if ($self->option_for_field('stripwhite', $field)) {
                $value = $self->_strip_white($value);
            }
            if ($self->option_for_field(collapse_whitespace => $field)) {
                $value = $self->_collapse_white($value);
            }
            # then we set it in the ouput, it could be undef;
            $output{$field} = $value;
        }
        else {
            my $missingopt = $self->option_for_field('missing', $field);
            # basically, with "pass", the default, we don't store the
            # value
            if ($missingopt eq 'undefine') {
                $value = undef;
                $output{$field} = $value;
            }
            elsif ($missingopt eq 'empty') {
                $value = "";
                $output{$field} = $value;
            }
        }
        

        # if it's required and the only thing provided is "" or undef,
        # we set an error
        if ((not defined $value) or
            ((ref($value) eq '') and $value eq '') or
            ((ref($value) eq 'HASH') and (not %$value)) or
            ((ref($value) eq 'ARRAY') and (not @$value))) {

            if ($self->field_is_required($field)) {
                # set the error list to ["required" => "Human readable" ];
                $self->errors($field,
                              [
                               [ "required" => "Missing required field $field" ]
                              ]
                             );
            }
            next;
        } 
        # we have something, validate it
        unless ($obj->is_valid($value)) {
            my @errors = $obj->error;
            $self->errors($field, \@errors)
        }
        $obj->dtv_value($value);
    }


    # if there is no error, check the groups
    unless ($self->errors) {
        foreach my $group (@{$self->groups}) {
            unless ($group->is_valid) {
                my @errors = $group->error;
                $self->errors($group->name, \@errors);
            }
        }
    }

    # now the filtering loop has ended. See if we have still things in the hash.
    if (keys %status) {
        my $unknown = $self->option('unknown');
        if ($unknown eq 'pass') {
            for (keys %status) {
                $output{$_} = $hash->{$_};
            }
        } elsif ($unknown eq 'fail') {
            die "Unknown fields in input: ", join(',', keys %status), "\n";
        }
    }
    # remember what we did
    $self->_set_transposed_data(\%output);

    if ($self->errors) {
        # return undef if we have errors
        $self->_set_success(0);
        return;
    }

    # return the data
    $self->_set_success(1);

    return $self->transposed_data;
}

=head2 success

Returns true on success, 0 on failure and undef validation
didn't take place.

=head2 transposed_data

Accessor to the transposed hash. This is handy if you want to retrieve
the filtered data after a failure (because C<transpose> will return
undef in that case).

=head2 errors

Accessor to set or retrieve the errors (returned as an arrayref of
hashes). Each element has the key C<field> set to the fieldname and
the key C<errors> holds the error list. This, in turn, is a list
of arrays, where the first element is the error code, and the second
the human format set by the module (in English). See the method belows
for a more accessible way for the errors.

=cut

sub errors {
    my ($self, $field, $error) = @_;
    if ($error and $field) {
        $self->errors_iterator->append({field => $field,
                                         errors => $error});
    }

    if ($self->errors_iterator->count) {
        return $self->errors_iterator->records;
    }

    return;
}

=head2 errors_iterator

Returns error iterator.

=cut

=head2 errors_hash

Return an hashref where each key is the name of the error field, and
the value is an arrayref of hashrefs with two keys, C<name> and
C<value>.

Example of the returned hash:

          {
           year => [
                    {
                     value => 'Not a number',
                     name => 'notanumber',
                    },
                    {
                     name => 'notinteger',
                     value => 'Not an integer',
                    }
                   ],
           mail => [
                    {
                     value => 'Missing required field mail',
                     name => 'required',
                    }
                   ],
          }

=cut

sub errors_hash {
    my ( $self ) = @_;

    return $self->errors_iterator->errors_hash;
}

sub _reset_errors {
    shift->errors_iterator->records([]);
}

=head2 faulty_fields 

Accessor to the list of fields where the validator detected errors.

=cut

sub faulty_fields {
    my $self = shift;
    my @ffs;

    while (my $err = $self->errors_iterator->next) {
        push @ffs, $err->{field};
    }

    $self->errors_iterator->reset;

    return @ffs;
}

=head2 errors_as_hashref_for_humans

Accessor to get a list of the failed checks. It returns an hashref
with the keys set to the faulty fields, and the value as an arrayref
to a list of the error messages.

=cut

sub errors_as_hashref_for_humans {
    my $self = shift;
    return $self->_get_errors_field(1);
}

=head2 errors_as_hashref

Same as above, but for machine processing. It returns the lists of
error codes as values.

=cut

sub errors_as_hashref {
    my $self = shift;
    return $self->_get_errors_field(0);
}


=head2 packed_errors($fieldsep, $separator)

As convenience, this method will join the human readable strings using
the second argument, and introduced by the name of the field
concatenated to the first argument. Example with the defaults (colon
and comma):

  password: Wrong length, No special characters, No letters in the
  password, Found common password, Not enough different characters,
  Found common patterns: 1234
  country: My error
  email2: rfc822

In scalar context it returns a string, in list context returns the
errors as an array, so you still can process it easily.

=cut


sub packed_errors {
    my $self = shift;
    my $fieldsep = shift || ": ";
    my $separator = shift || ", ";

    my $errs = $self->errors_as_hashref_for_humans;
    my @out;
    # print Dumper($errs);
    foreach my $k ($self->faulty_fields) {
        push @out, $k . $fieldsep . join($separator, @{$errs->{$k}});
    }
    return wantarray ? @out : join("\n", @out);
}


sub _get_errors_field {
    my $self = shift;
    my $i = shift;
    my %errors;

    while (my $err = $self->errors_iterator->next) {
        my $f = $err->{field};
        $errors{$f} = [] unless exists $errors{$f};
        foreach my $string (@{$err->{errors}}) {
            push @{$errors{$f}}, $string->[$i];
        }
    }

    $self->errors_iterator->reset;

    return \%errors;
}

=head2 field_is_required($field)

Check if the field is required. Return true unconditionally if the
option C<requireall> is set. If not, look into the schema and return
the value provided in the schema.

=cut


sub field_is_required {
    my ($self, $field) = @_;
    return unless defined $field;
    return 1 if $self->option("requireall");
    return $self->field($field)->required;
}

sub _build_object {
    my ($self, $name, $params) = @_;
    my $validator = $params->{validator};
    my $type = ref($validator);
    my $obj;
    # print "Building $name... " . Dumper($params);
    # if we got a string, the class is Data::Transpose::$string
    if ($type eq 'CODE') {
        $obj = Data::Transpose::Validator::Subrefs->new($validator);
    }
    else {
        my ($class, $classoptions);
        if ($type eq '') {
            my $module = $validator || "Base";
            die "No group is allowed here" if $module eq 'Group';
            $class = __PACKAGE__ . '::' . $module;
            # use options from params
            $classoptions = $params->{options} || {};
        }
        elsif ($type eq 'HASH') {
            $class = $validator->{class};
            die "Missing class for $name!" unless $class;
            unless ($validator->{absolute}) {
                die "No group is allowed here" if $class eq 'Group';
                $class = __PACKAGE__ . '::' . $class;
            }
            $classoptions = $validator->{options} || {};
            # print Dumper($classoptions);
        }
        else {
            die "Wrong usage. Pass a string, an hashref or a sub!\n";
        }
        # lazy loading, avoiding to load the same class twice
        try {
            $obj = $class->new(%$classoptions);
        } catch {
            load $class;
            $obj = $class->new(%$classoptions);
        };
    }
    if ($params->{options}) {
        $obj->dtv_options($params->{options});
    }
    if ($self->option('requireall') || $params->{required}) {
        $obj->required(1);
    }
    return $obj;
}

sub _strip_white {
    my ($self, $string) = @_;
    return unless defined $string;
    return $string unless (ref($string) eq ''); # scalars only
    return "" if ($string eq ''); # return the empty string
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

sub _collapse_white {
    my ($self, $string) = @_;
    return unless defined $string;
    return $string unless (ref($string) eq '');
    # convert all 
    $string =~ s/\s+/ /gs;
    return $string;
}


sub _field_args_are_valid {
    my ($self, $field, @keys) = @_;
    my %valid = (
                 validator => 1,
                 name => 1,
                 required => 1,
                 options => 1,
                );
    foreach my $k (@keys) {
        unless ($valid{$k}) {
            die "$field has unrecognized option $k!\n";
        }
    }
}


=head2 reset_self

Clear all the internal data stored during validations, to make the
reusing of the transposing possible.

This is called by C<transpose> before doing any other operation

=cut

sub reset_self {
    my $self = shift;
    $self->_set_success(undef);
    $self->_reset_errors;
}

1;

__END__

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<http://xkcd.com/936/>

=head1 AUTHOR

Marco Pessotto, E<lt>melmothx@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013-2016 by Marco Pessotto

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
