package Brannigan;

# ABSTRACT: Flexible library for validating and processing input.

use warnings;
use strict;

use Hash::Merge;

our $VERSION = "2.1";
$VERSION = eval $VERSION;

=head1 NAME

Brannigan - Flexible library for validating and processing input.

=head1 SYNOPSIS

    use Brannigan;

    my %schema1 = ( params => ... );
    my %schema2 = ( params => ... );
    my %schema3 = ( params => ... );

    # use the OO interface
    my $b = Brannigan->new();
    $b->register_schema('schema1', \%schema1);
    $b->register_schema('schema2', \%schema2);
    $b->register_schema('schema3', \%schema3);

    my $rejects = $b->process('schema1', \%params);
    if ($rejects) {
        die $rejects;
    }

    # %params is valid and ready for use.

    # Or use the functional interface
    my $rejects = Brannigan::process(\%schema1, \%params);
    if ($rejects) {
        die $rejects;
    }

For a more comprehensive example, see L</"MANUAL">.

=head1 DESCRIPTION

Brannigan is an attempt to ease the pain of collecting, validating and processing
input parameters in user-facing applications. It's designed to answer both of
the main problems that such applications face:

=over 2

=item * Simple User Input

Brannigan can validate and process simple, "flat" user input, possibly coming
from web forms.

=item * Complex Data Structures

Brannigan can validate and process complex data structures, possibly deserialized
from JSON or XML data sent to web services and APIs.

=back

Brannigan's approach to data validation is as follows: define a schema of
parameters and their validation rules, and let the module automatically examine
input parameters against this structure. Brannigan provides you with common
validators that are used everywhere, and also allows you to create custom
validators easily. This structure also defines how, if at all, the input should
be processed. This is akin to schema-based validations such as XSD, but much more
functional, and most of all flexible.

Check the next section for an example of such a schema. Schemas can extend other
schemas, allowing you to be much more flexible in certain situations. Imagine you
have a blogging application. A base schema might define all validations and
processing needed in order to create a new blog post from user input. When
editing a post, however, some parameters that were required when creating the
post might not be required now, and maybe new parameters are introduced.
Inheritance helps you avoid repeating yourself.

=head1 MANUAL

Let's look at a complete usage example. Do not be alarmed by the size of these
schemas, as they showcases almost all features of Brannigan.

    package MyApp;

    use strict;
    use warnings;
    use Brannigan;

    # Create a new Brannigan object
    my $b = Brannigan->new({ handle_unknown => "ignore" });

    # Create a custom 'forbid_words' validator that can be used in any schema.
    $b->register_validator('forbid_words', sub {
        my $value = shift;

        foreach (@_) {
            return 0 if $value =~ m/$_/;
        }

        return 1;
    });

    # Create a schema for validating input to a create_post function
    $b->register_schema('create_post', {
        params => {
            subject => {
                required => 1,
                length_between => [3, 40],
            },
            text => {
                required => 1,
                min_length => 10,
                validate => sub {
                    my $value = shift;
                    return defined $value && $value =~ m/^lorem ipsum/ ? 1 : 0;
                }
            },
            day => {
                required => 0,
                integer => 1,
                value_between => [1, 31],
            },
            mon => {
                required => 0,
                integer => 1,
                value_between => [1, 12],
            },
            year => {
                required => 0,
                integer => 1,
                value_between => [1900, 2900],
            },
            section => {
                required => 1,
                integer => 1,
                value_between => [1, 3],
                postprocess => sub {
                    my $val = shift;

                    return $val == 1 ? 'reviews' :
                           $val == 2 ? 'receips' : 'general';
                },
            },
            id => {
                required => 1,
                exact_length => 10,
                value_between => [1000000000, 2000000000],
            },
            array_of_ints => {
                array => 1,
                min_length => 3,
                values => {
                    integer => 1,
                },
                preprocess => sub {
                    # Sometimes you'll find that input that is supposed to be
                    # an array is received as a single non-array item, most
                    # often because deserializers do not know the item should
                    # be in an array. This is common in XML inputs. A
                    # preprocess function can be used to fix that.
                    my $val = shift;
                    return [$val]
                        if defined $val && ref $val ne 'ARRAY';
                    return $val;
                }
            },
            hash_of_langs => {
                hash => 1,
                keys => {
                    en => {
                        required => 1,
                    },
                },
            },
        },
    });

    # Create a schema for validating input to an edit_post function. The schema
    # inherits the create_post schema with one small change.
    $b->register_schema('edit_post', {
        inherits_from => 'create_post',
        params => {
            subject => {
                required => 0, # subject is no longer required
            }
        }
    });

    # Now use Brannigan to validate input in your application:
    sub create_post {
        my ($self, $params) = @_;

        # Process and validate the parameters with the 'post' schema
        my $rejects = $b->process('create_post', $params);

        if ($rejects) {
            # Turn validation errors into a structure that fits your application
            die list_errors($rejects);
        }

        # Validation and processing suceeded, save the parameters to a database
        $self->_save_post_to_db($params);
    }

    sub edit_post {
        my ($self, $id, $params) = @_;

        # Process and validate the parameters with the 'edit_post' schema
        my $rejects = $b->process('edit_post', $params);

        if ($rejects) {
            # Turn validation errors into a structure that fits your application
            die list_errors($rejects);
        }

        # Validation and processing succeeded, update the post in the database
        $self->_update_post_in_db($params);
    }

=head2 HOW BRANNIGAN WORKS

In essence, Brannigan works in five stages (which all boil down to one single
command):

=over 5

=item 1. SCHEMA PREPARATION

Brannigan receives the name of a validation schema, and a hash reference of input
parameters. Brannigan then loads the schema and prepares it (merging it with
inherited schemas, if any) for later processing. Finalized schemas are cached
for improved performance.

=item 2. DATA PREPROCESSING

Brannigan invokes all C<preprocess> functions defined in the schema on the input
data, if there are any. These functions are allowed to modify the input.

Configured default values will also be provided to their respective parameters in
this stage as well, if those parameters are not provided in the input.

=item 3. DATA VALIDATION

Brannigan invokes all validation methods defined in the schema on the input data,
and generates a hash reference of rejected parameters, if there were any. For
every parameter in this hash-ref, an array-ref of failed validations is
created.

If one or more parameters failed validation, the next step (data postprocessing)
will be skipped.

=item 4. DATA POSTPROCESSING

If the previous stage (validation) did not fail, Brannigan will call every
C<postprocess> function defined in the schema. There are two types of
C<postprocess> functions:

=over 2

=item * parameter-specific

These are defined on specific parameters. They get the parameter's value and
should return a new value for the parameter (possibly the same one, but they
must return a value).

=item * global

The schema may also have one global C<postprocess> function. This function gets
the entire parameter hash-ref as input. It is free to modify the hash-ref as
it sees fit. The function should not return any value.

=back

=item 5. FINAL RESULT

If all input parameters passed validation, an undefined value is returned to
the caller. Otherwise, a hash-reference of rejects is returned. This is a
flattened structure where keys are "fully qualified" parameter names (meaning
dot notation is used for nested parameters), and values are hash-references
containing the validators for which the parameter had failed. For example, let's
look at the following rejects hash-ref:

    {
        'subject'      => { required => 1 },
        'text'         => { max_length => 500 },
        'pictures.2'   => { matches => qr!^http://! },
        'phone.mobile' => { required => 1 }
    }

This hash-ref tells us:

=over 4

=item 1. The "subject" parameter is required but was not provided.

=item 2. The "text" parameter was provided, but is longer than the maximum of 500
characters.

=item 3. The third value of the "pictures" array does not start with "http://".

=item 4. The "mobile" key of the "phone" hash parameter was not provided.

=back

=back

=head2 HOW SCHEMAS LOOK

The validation/processing schema defines the structure of the data you're
expecting to receive, along with information about the way it should be
validated and processed. Schemas are created by passing them to the Brannigan
constructor. You can pass as many schemas as you like, and these schemas
can inherit from other schemas.

A schema is a hash-ref that contains the following keys:

=over

=item * inherits_from

Either a scalar naming a different schema or an array-ref of schema names.
The new schema will inherit all the properties of the schema(s) defined by this
key. If an array-ref is provided, the schema will inherit their properties in
the order they are defined. See the L</"CAVEATS"> section for some "heads-up"
about inheritance.

=item * params

Defines the expected input. This key takes a hash-ref whose keys are the names
of input parameters as they are expected to be received. The values are also
hash references which define the necessary validation functions to assert for
the parameters, and other optional settings such as default values, post- and
pre- processing functions, and custom validation functions.

For example, if a certain parameter, let's say 'subject', must be between 3 to 10
characters long, then your schema will contain:

    subject => { length_between => [3, 10] }

If a "subject" parameter sent to your application fails the "length_between"
validator, then the rejects hash-ref described earlier will have the exact same
key-value pair as above:

    subject => { length_between => [3, 10] }

The following extra keys can also be used in a parameter's configuration:

B<validate>: Used to create a custom validation function for the parameter.
Accepts a subroutine reference. The subroutine accepts the value from the input
as its only parameter, and returns a boolean value indicating whether the value
passed the validation or not.

For example, this custom validation function requires that the 'subject' input
parameter will always begin with the string "lorem ipsum":

    subject => {
        length_between => [3, 10],
        validate => sub {
            my $value = shift;
            return $value =~ m/^lorem ipsum/ ? 1 : 0;
        }
    }

If a parameter fails a custom validation function, 'validate' will be added to
the failed validations hash-ref of the parameter in the rejects hash-ref:

    subject => {
        length_between => [3, 10],
        validate => 1
    }

B<default>: Used to set a default value for parameters that are not required
and are not provided in the input hash-ref. Accepts a scalar value or a
subroutine reference. In the latter case, the subroutine will be called with no
parameters, and it should return the generated default value.

    subject => {
        length_between => [3, 10],
        default => 'lorem ipsum'
    }

    # Or...

    subject => {
        length_between => [3, 10],
        default => sub { UUID->new->hex }
    }

Note that default values are given to missing parameters before the
validation stage, meaning they must conform with the parameters' validators.

B<preprocess>: Used to process parameter values before validation functions are
called. This can be useful to trim leading or trailing whitespace from string
values, or turning scalars into arrays (a common task for XML inputs where the
deserializer cannot tell whether an item actually belongs in an array or not).
Accepts a subroutine reference with the parameter's value from the input. The
function must return the new value for the parameter, even if it had decided not
to do any actual changes.

B<postprocess>: Similar to C<preprocess>, but happens after validation functions
had been called.

    subject => {
        required => 1,
        length_between => [3, 10],
        preprocess => sub {
            # Trim whitespace before validating
            my $value = shift;
            $value =~ s/^\s\*//;
            $value =~ s/\s\*$//;
            return $value;
        }
        validate => sub {
            # Ensure value does not start with "lorem ipsum"
            my $value = shift;
            return $value =~ m/^lorem ipsum/ ? 0 : 1;
        },
        postprocess => sub {
            # Lowercase the value
            my $value = shift;
            return lc $value;
        }
    }

=item * postprocess

Global postprocessing function. If provided, it will be called after all
preprocessing, input validation, and parameter-specific postprocessing had
completed. As opposed to parameter-specific postprocess functions, this one
receives the complete parameter hash-ref as its only input. It is not expected
to return any values. It may modify the parameter hash-ref as it sees fit.

=back

=head2 BUILT-IN VALIDATORS

=head3 { required => $boolean }

If C<$boolean> has a true value, this method will check that a required
parameter was indeed provided; otherwise (i.e. if C<$boolean> is not true)
this method will simply return a true value to indicate success.

You should note that if a parameter is required, and a non-true value is
received (i.e. 0 or the empty string ""), this method considers the
requirement as fulfilled (i.e. it will return true). If you need to make sure
your parameters receive true values, take a look at the C<is_true()> validation
method.

Please note that if a parameter is not required and indeed isn't provided
with the input parameters, any other validation methods defined on the
parameter will not be checked.

=head3 { is_true => $boolean }

If C<$boolean> has a true value, this method will check that C<$value>
has a true value (so, C<$value> cannot be 0 or the empty string); otherwise
(i.e. if C<$boolean> has a false value), this method does nothing and
simply returns true.

=head3 { length_between => [ $min_length, $max_length ] }

Makes sure the value's length (stringwise) is inside the range of
C<$min_length>-C<$max_length>, or, if the value is an array reference,
makes sure it has between C<$min_length> and C<$max_length> items.

=head3 { min_length => $min_length }

Makes sure the value's length (stringwise) is at least C<$min_length>, or,
if the value is an array reference, makes sure it has at least C<$min_length>
items.

=head3 { max_length => $max_length }

Makes sure the value's length (stringwise) is no more than C<$max_length>,
or, if the value is an array reference, makes sure it has no more than
C<$max_length> items.

=head3 { exact_length => $length }

Makes sure the value's length (stringwise) is exactly C<$length>, or,
if the value is an array reference, makes sure it has exactly C<$exact_length>
items.

=head3 { integer => $boolean }

If boolean is true, makes sure the value is an integer.

=head3 { function => $boolean }

If boolean is true, makes sure the value is a function
(subroutine reference).

=head3 { value_between => [ $min_value, $max_value ] }

Makes sure the value is between C<$min_value> and C<$max_value>.

=head3 { min_value => $min_value }

Makes sure the value is at least C<$min_value>.

=head3 { max_value => $max_value }

Makes sure the value is no more than C<$max_value>.

=head3 { array => $boolean }

If C<$boolean> is true, makes sure the value is actually an array reference.

=head3 { hash => $boolean }

If C<$boolean> is true, makes sure the value is actually a hash reference.

=head3 { one_of => \@values }

Makes sure a parameter's value is one of the provided acceptable values.

=head3 { matches => $regex }

Returns true if C<$value> matches the regular express (C<qr//>) provided.
Will return false if C<$regex> is not a regular expression.

=head3 { min_alpha => $integer }

Returns a true value if C<$value> is a string that has at least C<$integer>
alphabetic (C<A-Z> and C<a-z>) characters.

=head3 { max_alpha => $integer }

Returns a true value if C<$value> is a string that has at most C<$integer>
alphabetic (C<A-Z> and C<a-z>) characters.

=head3 { min_digits => $integer }

Returns a true value if C<$value> is a string that has at least
C<$integer> digits (C<0-9>).

=head3 { max_digits => $integer }

Returns a true value if C<$value> is a string that has at most
C<$integer> digits (C<0-9>).

=head3 { min_signs => $integer }

Returns a true value if C<$value> has at least C<$integer> special or
sign characters (e.g. C<%^&!@#>, or basically anything that isn't C<A-Za-z0-9>).

=head3 { max_signs => $integer }

Returns a true value if C<$value> has at most C<$integer> special or
sign characters (e.g. C<%^&!@#>, or basically anything that isn't C<A-Za-z0-9>).

=head3 { max_consec => $integer }

Returns a true value if C<$value> does not have a sequence of consecutive
characters longer than C<$integer>. Consequtive characters are either
alphabetic (e.g. C<abcd>) or numeric (e.g. C<1234>).

=head3 { max_reps => $integer }

Returns a true value if C<$value> does not contain a sequence of a repeated
character longer than C<$integer>. So, for example, if C<$integer> is 3,
then "aaa901" will return true (even though there's a repetition of the
'a' character it is not longer than three), while "9bbbb01" will return
false.

=head2 ADVANCED FEATURES AND TIPS

=head3 COMPLEX DATA STRUCTURES

Brannigan can validate and process hash references of arbitrary complexity.
Input parameters may also be hash or array references.

For arrays, the parameter needs to be marked with C<< array => 1 >>. The
validations and processing for the array's values are then provided as a hash
reference named C<values>. For example:

    pictures => {
        array => 1,
        length_between => [1, 5],
        values => {
            min_length => 3,
            validate => sub {
                my $value = shift;
                return $value =~ m!^http://! ? 1 : 0;
            }
        }
    }

In this example, "pictures" is an array parameter. When provided, the array must
contain between 1 and 5 items. Every item in the array must be a string of 3
characters or more, and must begin with the prefix "http://".

For hashes, the parameter needs to be marked with C<< hash => 1 >>. The
validations and processing for the hash's attributes are then provided as a hash
reference named C<keys>. For example:

    name => {
        hash => 1,
        keys => {
            first_name => {
                length_between => [3, 10],
            },
            last_name => {
                required => 1,
                min_length => 3
            }
        }
    }

In this example, "name" is a hash paremeter. When provided, it must contain an
attribute called "first_name", which is an optional string between 3 or 10
characters long, and "last_name", which is a required string at least 3
characters longs.

Array and hash parameters can also accept default values:

    complex_param => {
        hash => 1,
        keys => {
            ...
        },
        default => { key1 => 'def1', key2 => 'def2' }
    }

Hash and arrays can fail validation in two ways: they can fail as a unit
(for example, schemas can enforce that an array will have between 2 and 5 items),
and specific items within them can fail (for example, schemas can enforce that
items in an array will be integers lower than 100).

An array that failed as a unit will appear in the rejects hash-ref with its own
name. A specific array item or hash key that failed validation will appear with
dot notation:

    'name.first_name' => { length_between => [3, 10] },
    'name.last_name' => { required => 1 },
    'pictures' => { exact_length => 3 },
    'numbers.1' => { max_value => 10 },

In this example, specific keys failed in the "name" hash parameter. The "pictures"
array parameter failed as a unit (it should have exactly 3 items). The second
item in the "numbers" array parameter failed the "max_value" validator too.

Brannigan's data structure support is infinitely recursive:

    pictures => {
        array => 1,
        values => {
            hash => 1,
            keys => {
                filename => {
                    min_length => 5,
                },
                source => {
                    hash => 1,
                    keys => {
                        website => {
                            validate => sub { ... },
                        },
                        license => {
                            one_of => [qw/GPL FDL CC/],
                        },
                    },
                },
            },
        },
    }

=head3 CROSS-SCHEMA CUSTOM VALIDATION METHODS

Ad-hoc C<validate> functions are nice, but when you want to use the same custom
validation function in multiple places inside your schema (or in multiple
schemas), this can become unwieldy.

Brannigan provides a simple mechanism to create custom, named validation
functions that can be used across schemas as if they were internal methods.

This example creates a validation function called "forbid_words", which fails
string parameters that contain certain words:

    my $b = Brannigan->new();

    $b->register_validator('forbid_words', sub {
        my ($value, @forbidden) = @_;
        foreach (@forbidden) {
            return 0 if $value =~ m/$_/;
        }
        return 1;
    });

    $b->register_schema('user_input', {
        params => {
            text => {
                required => 1,
                forbid_words => ['curse_word', 'bad_word', 'ugly_word'],
            }
        }
    });

Note how the custom validation function accepts the value provided in the input,
and whatever was provided to 'forbid_words' in the configuration of the specific
parameter. In this case, the parameter called "text" forbids the words
"curse_word", "bad_word" and "ugly_word".

If a parameter fails a named custom validation function, it will be added to the
rejects hash-ref like any other built-in validation function:

    text => [ 'forbid_words(curse_word, bad_word, ugly_word)' ]

As an added bonus, you can use this mechanism to override Brannigan's built-in
validations. Just give the name of the validation method you wish to override,
along with the new code for this method.

Note that you do not have to register a named validator before you register a
schema that uses it. You can register the schema first.

=head3 REPEATING RULES FOR MULTIPLE PARAMETERS

In previous versions, Brannigan allowed providing rules to multiple parameters
via regular expressions. This feature has been removed in version 2.0. Instead,
users can take advantage of the fact that schemas are simply Perl structures
and reuse rules via variables:

    my $date = { required => 1, matches => qr/^\d{4}-\d{2}-\d{2}$/ };

    my $schema = {
        name => 'person',
        params => {
            birth_date => $date,
            death_date => $date
        }
    };

=head1 CONSTRUCTOR

=head2 new( [ %options ] )

Creates a new instance of Brannigan. Schemas must be registered separately
using the C<register_schema> method.

Options:

=over 1

=item * C<handle_unknown>

What to do with input parameters that are not defined in the processing schema.
Values: 'ignore' (default, keep unknown parameters as they are), 'remove' (delete
unknown parameters from the input), 'reject' (add to rejects and fail the
processing).

=back

=cut

sub new {
    my ( $class, $options ) = @_;

    $options ||= {};

    my $self = bless {
        schemas        => {},
        validators     => {},
        merger         => Hash::Merge->new('LEFT_PRECEDENT'),
        handle_unknown => $options->{handle_unknown} || 'ignore',
        _schema_cache  => {},    # Cache for finalized schemas
    }, $class;

    $self->register_validator(
        'required',
        sub {
            my ( $value, $boolean ) = @_;

            return !$boolean || defined $value;
        }
    );
    $self->register_validator(
        'is_true',
        sub {
            my ( $value, $boolean ) = @_;

            return !$boolean || $value;
        }
    );
    $self->register_validator(
        'length_between',
        sub {
            my ( $value, $min, $max ) = @_;

            return _length($value) >= $min && _length($value) <= $max;
        }
    );
    $self->register_validator(
        'min_length',
        sub {
            my ( $value, $min ) = @_;

            return _length($value) >= $min;
        }
    );
    $self->register_validator(
        'max_length',
        sub {
            my ( $value, $max ) = @_;

            return _length($value) <= $max;
        }
    );
    $self->register_validator(
        'exact_length',
        sub {
            my ( $value, $exlength ) = @_;

            return _length($value) == $exlength;
        }
    );
    $self->register_validator(
        'integer',
        sub {
            my ( $value, $boolean ) = @_;

            return !$boolean || $value =~ m/^\d+$/;
        }
    );
    $self->register_validator(
        'function',
        sub {
            my ( $value, $boolean ) = @_;

            return !$boolean || ref $value eq 'CODE';
        }
    );
    $self->register_validator(
        'value_between',
        sub {
            my ( $value, $min, $max ) = @_;

            return defined $value && $value >= $min && $value <= $max;
        }
    );
    $self->register_validator(
        'min_value',
        sub {
            my ( $value, $min ) = @_;

            return defined $value && $value >= $min;
        }
    );
    $self->register_validator(
        'max_value',
        sub {
            my ( $value, $max ) = @_;

            return defined $value && $value <= $max;
        }
    );
    $self->register_validator(
        'one_of',
        sub {
            my ( $value, @values ) = @_;

            foreach (@values) {
                return 1 if $value eq $_;
            }

            return;
        }
    );
    $self->register_validator(
        'matches',
        sub {
            my ( $value, $regex ) = @_;

            return ref $regex eq 'Regexp' && $value =~ $regex;
        }
    );
    $self->register_validator(
        'min_alpha',
        sub {
            my ( $value, $integer ) = @_;

            my @matches = ( $value =~ m/[A-Za-z]/g );

            return scalar @matches >= $integer;
        }
    );
    $self->register_validator(
        'max_alpha',
        sub {
            my ( $value, $integer ) = @_;

            my @matches = ( $value =~ m/[A-Za-z]/g );

            return scalar @matches <= $integer;
        }
    );
    $self->register_validator(
        'min_digits',
        sub {
            my ( $value, $integer ) = @_;

            my @matches = ( $value =~ m/[0-9]/g );

            return scalar @matches >= $integer;
        }
    );
    $self->register_validator(
        'max_digits',
        sub {
            my ( $value, $integer ) = @_;

            my @matches = ( $value =~ m/[0-9]/g );

            return scalar @matches <= $integer;
        }
    );
    $self->register_validator(
        'min_signs',
        sub {
            my ( $value, $integer ) = @_;

            my @matches = ( $value =~ m/[^A-Za-z0-9]/g );

            return scalar @matches >= $integer;
        }
    );
    $self->register_validator(
        'max_signs',
        sub {
            my ( $value, $integer ) = @_;

            my @matches = ( $value =~ m/[^A-Za-z0-9]/g );

            return scalar @matches <= $integer;
        }
    );
    $self->register_validator(
        'max_consec',
        sub {
            my ( $value, $integer ) = @_;

            # the idea here is to break the string into an array of characters,
            # go over each character in the array starting at the first one,
            # and making sure that character does not begin a sequence longer
            # than allowed ($integer). This means we have recursive loops here,
            # because for every character, we compare it to the following
            # character and while they form a sequence, we move to the next pair
            # and compare them until the sequence is broken. To make it a tad
            # faster, our outer loop won't go over the entire characters array,
            # but only up to the last character that might possibly form an
            # invalid sequence. This character would be positioned $integer+1
            # characters from the end.
            my @chars = split( //, $value );
            for ( my $i = 0 ; $i <= scalar(@chars) - $integer - 1 ; $i++ ) {
                my $fc = $i;        # first character for comparison
                my $sc = $i + 1;    # second character for comparison
                my $sl = 1;         # sequence length
                while ( $sc <= $#chars
                    && ord( $chars[$sc] ) - ord( $chars[$fc] ) == 1 )
                {
                    # characters are in sequence, increase counters
                    # and compare next pair
                    $sl++;
                    $fc++;
                    $sc++;
                }
                return if $sl > $integer;
            }

            return 1;
        }
    );
    $self->register_validator(
        'max_reps',
        sub {
            my ( $value, $integer ) = @_;

            # The idea here is pretty much the same as in max_consec but we
            # truely compare each pair of characters.

            my @chars = split( //, $value );
            for ( my $i = 0 ; $i <= scalar(@chars) - $integer - 1 ; $i++ ) {
                my $fc = $i;        # First character for comparison
                my $sc = $i + 1;    # Second character for comparison
                my $sl = 1;         # Sequence length
                while ( $sc <= $#chars && $chars[$sc] eq $chars[$fc] ) {

                    # Characters are in sequence, increase counters
                    # and compare next pair
                    $sl++;
                    $fc++;
                    $sc++;
                }
                return if $sl > $integer;
            }

            return 1;
        }
    );
    $self->register_validator(
        'array',
        sub {
            my ( $value, $boolean ) = @_;

            $boolean
              ? ref $value eq 'ARRAY'
                  ? 1
                  : return
              : ref $value eq 'ARRAY' ? return
              :                         1;
        }
    );
    $self->register_validator(
        'hash',
        sub {
            my ( $value, $boolean ) = @_;

            $boolean
              ? ref $value eq 'HASH'
                  ? 1
                  : return
              : ref $value eq 'HASH' ? return
              :                        1;
        }
    );

    # Inject the schema validator schema used to validate user schemas. This is
    # a Brannigan validation schema itself!
    # TODO: figure out the best way to validate parameter definitions, as they
    # are named by the user, can contain validators we don't know yet, and other
    # complications.
    $self->{schemas}->{'__brannigan_schema_validator__'} = {
        name   => { required => 1, min_length => 1 },
        schema => {
            params => {
                required => 1,
                hash     => 1,
            },
            inherits_from => {
                array      => 1,
                preprocess => sub {
                    my $value = shift;

                    # Convert single string to array for uniform processing
                    return ref $value eq 'ARRAY' ? $value : [$value]
                      if defined $value;
                    return $value;
                }
            },
            postprocess => {
                function => 1,
            }
        }
    };

    return $self;
}

=head1 OBJECT METHODS

=head2 register_schema( $name, \%schema )

Registers a validation schema with the given name. If a schema with the same
name already exists, it will be overridden. The schema hash-ref should not
contain a C<name> key as it's provided separately. Returns the C<Brannigan>
object itself for chain-ability.

=cut

sub register_schema {
    my ( $self, $name, $schema ) = @_;

    die "Schema name is required"         unless defined $name && length $name;
    die "Schema must be a hash reference" unless ref $schema eq 'HASH';

    # Validate the schema structure before storing it
    $self->_validate_schema_definition( $name, $schema );

    # Store the schema with the provided name
    $self->{schemas}->{$name} = $schema;

    # Clear the schema cache since we have a new/updated schema
    $self->{_schema_cache} = {};

    return $self;
}

=head2 register_validator( $name, $code )

Registers a new named validator function. C<$code> is a reference to a subroutine
that receives a value as a parameter and returns a boolean value indicating
whether the value is valid or not. The method can be used to override
built-in validation functions.

=cut

sub register_validator {
    my ( $self, $name, $code ) = @_;
    return unless $name && $code && ref $code eq 'CODE';
    $self->{validators}->{$name} = $code;
}

=head2 handle_unknown( [$value] )

Gets or sets the behavior for handling unknown input parameters.
Accepted values: 'ignore', 'remove', 'reject'.

=cut

sub handle_unknown {
    my ( $self, $value ) = @_;

    if ( defined $value ) {
        die "Invalid handle_unknown value: $value"
          unless $value =~ /^(ignore|remove|reject)$/;
        $self->{handle_unknown} = $value;
        return $self;
    }

    return $self->{handle_unknown};
}

=head2 process( $schema, \%params )

Receives the name of a schema and a hash reference of input parameters.
Performs pre-processing, validation and post-processing as described in the
manual.

Any processing that modifies the input is performed in-place.

Returns an undefined value if there were no rejects. Returns a hash reference
of rejects if there were any.

=head1 FUNCTIONAL INTERFACE

=head2 process( \%schema, \%params )

Accepts a schema hash-ref and an input hash-ref, and performs pre-processing,
validation and post-processing. If no parameters failed validation, an undefined
value is returned. Otherwise a hash reference of rejects is returned.

Note that this interface does not allow for custom validation functions and
schema inheritance. You are not required to give the schema a name when using
this interface.

    my $rejects = Brannigan::process( $schema, $params );

=cut

sub process {

    # Called as a method
    if ( scalar @_ == 3 && ref $_[0] eq __PACKAGE__ ) {
        my ( $self, $schema_name, $params ) = @_;

        # Finalize the schema, merging it with any inherited schemas
        my $schema = $self->_finalize_schema($schema_name);

        # Execute preprocessing on input parameters
        $self->_preprocess( $schema, $params );

        # Validate input parameters
        my $rejects = $self->_validate( $params, $schema->{params} );
        if ($rejects) {
            return $rejects;
        }

        # Execute postprocessing on input parameters
        $self->_postprocess( $schema, $params );

        return;
    }

    # Called as a function
    my ( $schema, $params ) = @_;
    my $b = Brannigan->new();
    $b->register_schema( 'temp', $schema );
    return $b->process( 'temp', $params );
}

############################
##### INTERNAL METHODS #####
############################

# _length( $value )
# ------------------------------------------------------------------------
# Returns the length of a string value in characters, or an array value in
# items.

sub _length {
    return ref $_[0] eq 'ARRAY' ? scalar( @{ $_[0] } ) : length( $_[0] );
}

# _finalize_schema( $schema_name )
# --------------------------------------------------------------------------
# Builds the final "tree" of validations and parsing methods to be performed
# on the parameter hash-ref during processing.

sub _finalize_schema {
    my ( $self, $schema_name ) = @_;

    # Check cache first
    return $self->{_schema_cache}->{$schema_name}
      if exists $self->{_schema_cache}->{$schema_name};

    my $schema = $self->{schemas}->{$schema_name}
      || die "Unknown schema $schema_name";

    # get a list of all schemas to inherit from
    if ( $schema->{inherits_from} ) {
        my @inherited_schemas =
          $schema->{inherits_from}
          && ref $schema->{inherits_from} eq 'ARRAY'
          ? @{ $schema->{inherits_from} }
          : $schema->{inherits_from} ? ( $schema->{inherits_from} )
          :                            ();

        foreach my $inherited_schema_name (@inherited_schemas) {
            my $inherited_schema = $self->{schemas}->{$inherited_schema_name}
              || next;

            # Recursively finalize inherited schemas to handle deep inheritance
            $inherited_schema = $self->_finalize_schema($inherited_schema_name);
            $schema = $self->{merger}->merge( $schema, $inherited_schema );
        }
    }

    # Cache the finalized schema for future use
    $self->{_schema_cache}->{$schema_name} = $schema;

    return $schema;
}

# _validate( \%params, %rules )
# ------------------------------------------------
# Validates the hash-ref of input parameters against a finalized schema, returns
# undef if there are no rejects or a hash-ref of rejects if there are any.

sub _validate {
    my ( $self, $params, $rules ) = @_;

    my $rejects = {};

    # Handle unknown parameters according to the object's configuration
    $self->_handle_unknown_params( $params, $rules, $rejects );

    # Go over all the parameters in the schema and validate them
    foreach my $param ( sort keys %{$rules} ) {
        $self->_validate_param( $param, $params->{$param},
            $rules->{$param}, $rejects );
    }

    return $rejects if scalar keys %$rejects;
    return;
}

# _validate_param( $value, \%rules )
# ------------------------------------------------
# Receives a parameter value and a hash-ref of validation rules to assert.
# Returns a list of validations that failed for this parameter, if any.

sub _validate_param {
    my ( $self, $name, $value, $rules, $rejects ) = @_;

    # is this a scalar, array or hash parameter?
    if ( $rules->{hash} ) {
        $self->_validate_hash( $name, $value, $rules, $rejects );
    } elsif ( $rules->{array} ) {
        $self->_validate_array( $name, $value, $rules, $rejects );
    } else {
        $self->_validate_scalar( $name, $value, $rules, $rejects );
    }
}

# _validate_scalar( $value, \%rules, [$type] )
# ----------------------------------------------------------
# Receives the name of a parameter, its value, and a hash-ref of validations
# to assert against. Returns a list of all failed validations for this
# parameter. If the parameter is a child of a hash/array parameter, then
# C<$type> must be provided with either 'hash' or 'array'.

sub _validate_scalar {
    my ( $self, $name, $value, $rules, $rejects ) = @_;

    my $is_required = 0;

    foreach my $v (
        sort {
            return -1 if $a eq 'required';   # $a is 'required' → it comes first
            return 1  if $b eq 'required';   # $b is 'required' → it comes first
            return
              lc($a) cmp lc($b)
              ;    # otherwise sort alphabetically, case-insensitive
        } keys %{$rules}
      )
    {
        next
          if $v eq 'postprocess'
          || $v eq 'preprocess'
          || $v eq 'default'
          || $v eq 'values'
          || $v eq 'keys';

        $is_required = 1 if $v eq 'required' && $rules->{$v};

        last if !$is_required && !defined $value;

        # Get the arguments we're passing to the validation function
        my @args =
          ref $rules->{$v} eq 'ARRAY'
          ? @{ $rules->{$v} }
          : ( $rules->{$v} );

        my $validator_func =
          $v eq 'validate' ? $rules->{$v} : $self->{validators}->{$v};

        if ( !$validator_func->( $value, @args ) ) {
            if ( $v eq 'validate' ) {
                $rejects->{$name}->{$v} = 1;
            } else {
                $rejects->{$name}->{$v} = scalar @args > 1 ? \@args : $args[0];
            }

            # Do not bother with other validation functions if the 'required'
            # validator failed (i.e. parameter was not provided at all).
            if ( $v eq 'required' && $is_required ) {
                last;
            }
        }
    }
}

# _validate_array( $value, \%rules )
# ------------------------------------------------
# Receives a parameter value and a hash-ref of validation rules to assert.
# Returns a hash-ref of rejects for the value, if any, otherwise returns undef.

sub _validate_array {
    my ( $self, $name, $value, $rules, $rejects ) = @_;

    # Invoke validations on the array itself
    $self->_validate_scalar( $name, $value, $rules, $rejects );
    return if exists $rejects->{$name};

    # Invoke validations on the items of the array value
    if ( $rules->{values} ) {
        my $i = 0;
        foreach (@$value) {
            $self->_validate_param( "$name.$i", $_, $rules->{values},
                $rejects );
            $i++;
        }
    }
}

# _validate_hash( $value, \%rules )
# -----------------------------------------------
# Receives a parameter value and a hash-ref of rules to assert.
# Returns a hash-ref of rejects for the value, if any, or an undefined value
# otherwise.

sub _validate_hash {
    my ( $self, $name, $value, $rules, $rejects ) = @_;

    # Invoke validations on the parameter value itself
    $self->_validate_scalar( $name, $value, $rules, $rejects );
    return if exists $rejects->{$name};

    # Handle unknown keys in nested hash if rules are defined
    if ( $rules->{keys} && $self->{handle_unknown} ne 'ignore' ) {
        $self->_handle_unknown_nested_params( $name, $value, $rules->{keys},
            $rejects );
    }

    # Invoke validations on the key-value pairs of the hash
    if ( $rules->{keys} ) {
        foreach my $key ( keys %{ $rules->{keys} } ) {
            $self->_validate_param( "$name.$key", $value->{$key},
                $rules->{keys}->{$key}, $rejects );
        }
    }
}

# _preprocess( \%schema, \%params )
# -------------------------------------------------
# Receives a finalized schema and a hash-ref of parameter values, and performs
# preprocessing.

sub _preprocess {
    my ( $self, $schema, $params ) = @_;

    foreach my $param ( sort keys %{ $schema->{params} } ) {
        $self->_preprocess_param( $param, $params,
            $schema->{params}->{$param} );
    }
}

# _preprocess_param( $name, \%params, \%rules )
# -----------------------------------------------
# Recursively preprocesses a parameter, applying defaults and preprocess
# functions at all nesting levels (top-level, hashes, and array items).

sub _preprocess_param {
    my ( $self, $name, $params, $rules ) = @_;

    # Early exit if no preprocessing needed
    return
         unless ( defined $rules->{default} && !defined $params->{$name} )
      || ( defined $rules->{preprocess} && defined $params->{$name} )
      || ( $rules->{hash}               && $rules->{keys} )
      || ( $rules->{array}              && $rules->{values} );

    # Apply default value if parameter not provided
    if ( defined $rules->{default} && !defined $params->{$name} ) {
        $params->{$name} =
          ref $rules->{default} eq 'CODE'
          ? $rules->{default}->()
          : $rules->{default};
    }

    # Apply preprocess function if parameter exists and has preprocess
    if ( defined $rules->{preprocess} && defined $params->{$name} ) {
        $params->{$name} = $rules->{preprocess}->( $params->{$name} );
    }

    # Recursively preprocess nested structures
    if ( defined $params->{$name} ) {
        if (   $rules->{hash}
            && $rules->{keys}
            && ref( $params->{$name} ) eq 'HASH' )
        {
            # Preprocess hash keys recursively
            foreach my $key ( keys %{ $rules->{keys} } ) {
                $self->_preprocess_param( $key, $params->{$name},
                    $rules->{keys}->{$key} );
            }
        } elsif ( $rules->{array}
            && $rules->{values}
            && ref( $params->{$name} ) eq 'ARRAY' )
        {
            # Preprocess array items recursively
            for my $i ( 0 .. $#{ $params->{$name} } ) {
                if (   $rules->{values}->{hash}
                    && $rules->{values}->{keys}
                    && ref( $params->{$name}->[$i] ) eq 'HASH' )
                {
                    # Each array item is a hash - preprocess its keys
                    foreach my $key ( keys %{ $rules->{values}->{keys} } ) {
                        $self->_preprocess_param(
                            $key,
                            $params->{$name}->[$i],
                            $rules->{values}->{keys}->{$key}
                        );
                    }
                }

                # Note: We could extend this to handle other array item types,
                # but hash items are the most common use case
            }
        }
    }
}

# _postprocess( \%schema, \%params )
# -------------------------------------------------
# Receives a finalized schema and a hash-ref of parameter values, and performs
# postprocessing.

sub _postprocess {
    my ( $self, $schema, $params ) = @_;

    foreach my $param ( sort keys %{ $schema->{params} } ) {
        next if !defined $schema->{params}->{$param}->{postprocess};

        # This is a direct rule
        $params->{$param} =
          $schema->{params}->{$param}->{postprocess}->( $params->{$param} );
    }

    if ( $schema->{postprocess} && ref $schema->{postprocess} eq 'CODE' ) {
        $schema->{postprocess}->($params);
    }
}

# _handle_unknown_params( \%params, \%rules, \%rejects )
# ------------------------------------------------
# Handles input parameters that are not defined in the schema according
# to the object's handle_unknown setting.

sub _handle_unknown_params {
    my ( $self, $params, $rules, $rejects ) = @_;

    return if $self->{handle_unknown} eq 'ignore';

    # Find parameters in input that are not in the schema
    my @unknown_params;
    foreach my $param ( keys %$params ) {
        push @unknown_params, $param unless exists $rules->{$param};
    }

    if ( $self->{handle_unknown} eq 'remove' ) {

        # Remove unknown parameters from input
        delete $params->{$_} for @unknown_params;
    } elsif ( $self->{handle_unknown} eq 'reject' ) {

        # Add unknown parameters to rejects
        $rejects->{$_} = { unknown => 1 } for @unknown_params;
    }
}

# _handle_unknown_nested_params( $path, \%value, \%expected_keys, \%rejects )
# -------------------------------------------------------------------------
# Handles unknown parameters in nested hash structures according to the
# object's handle_unknown setting. Similar to _handle_unknown_params but
# works with nested paths and hash values.

sub _handle_unknown_nested_params {
    my ( $self, $path, $value, $expected_keys, $rejects ) = @_;

    return if $self->{handle_unknown} eq 'ignore';
    return unless ref($value) eq 'HASH';

    # Find keys in the hash that are not in the expected keys
    my @unknown_keys;
    foreach my $key ( keys %$value ) {
        push @unknown_keys, $key unless exists $expected_keys->{$key};
    }

    if ( $self->{handle_unknown} eq 'remove' ) {

        # Remove unknown keys from the nested hash
        delete $value->{$_} for @unknown_keys;
    } elsif ( $self->{handle_unknown} eq 'reject' ) {

        # Add unknown keys to rejects with nested path notation
        for my $key (@unknown_keys) {
            my $nested_path = $path ? "$path.$key" : $key;
            $rejects->{$nested_path} = { unknown => 1 };
        }
    }
}

# _validate_schema_definition( $name, \%schema )
# -----------------------------------------------
# Validates a schema definition for common errors before registration.
# Dies with descriptive error messages if the schema is invalid.

sub _validate_schema_definition {
    my ( $self, $name, $schema ) = @_;

    # Use Brannigan itself to validate schema definitions.

    # Skip validation for the schema validator schema itself
    return if $name eq '__brannigan_schema_validator__';

    my $handle_unknown = $self->{handle_unknown};
    $self->{handle_unknown} = 'ignore';
    my $rejects = $self->process(
        '__brannigan_schema_validator__',
        {
            name   => $name,
            schema => $schema
        }
    );
    $self->{handle_unknown} = $handle_unknown;

    die "Schema validation failed" if $rejects;
}

=head1 UPGRADING FROM 1.x TO 2.0

Version 2.0 of Brannigan includes significant breaking changes. This guide will
help you upgrade your existing code.

=head2 BREAKING CHANGES

=head3 Constructor and Schema Registration

B<Old (1.x):>

    my $b = Brannigan->new(
        { name => 'schema1', params => { ... } },
        { name => 'schema2', params => { ... } }
    );

B<New (2.0):>

    my $b = Brannigan->new();  # No schemas in constructor
    $b->register_schema('schema_name', { params => { ... } });
    $b->register_schema('another_schema', { params => { ... } });

=head3 Method Names

Several methods have been renamed for clarity:

=over 2

=item * C<add_scheme()> => C<register_schema()>

=item * C<custom_validation()> => C<register_validator()>

=back

=head3 Return Value Changes

The C<process()> method now returns different values:

B<Old (1.x):> Always returned a hash-ref with processed parameters and optional
C<_rejects> key.

B<New (2.0):> Returns C<undef> on success, hash-ref of rejects on failure.
Processing happens in-place on the input hash-ref.

    # Old style
    my $result = $b->process('schema', \%params);
    if ($result->{_rejects}) {
        # Handle errors
    }

    # New style
    my $rejects = $b->process('schema', \%params);
    if ($rejects) {
        # Handle $rejects hash-ref directly
    }
    # %params is modified in-place with processed values

=head3 Error Structure Changes

The structure of validation errors has changed significantly:

B<Old (1.x):>

    {
        _rejects => {
            parameter => ['required(1)', 'min_length(5)'],
            nested    => { path => { param => ['max_value(100)'] } }
        }
    }

B<New (2.0):>

    {
        'parameter'         => { required => 1, min_length => 5 },
        'nested.path.param' => { max_value => 100 }
    }

Key changes:

=over 4

=item * Error paths are flattened using dot notation

=item * Validator names and arguments are returned as key-value pairs

=item * No more C<_rejects> wrapper

=item * Unknown parameters are reported with C<< { unknown => 1 } >>

=back

=head3 Processing Function Changes

=over 3

=item * C<parse> functions → C<postprocess> functions

=item * Default values are now calculated B<before> validation (they can fail validation)

=item * C<postprocess> functions must return a replacement value, not a hash-ref

=back

B<Old (1.x):>

    parse => sub {
        my $value = shift;
        return { parameter_name => process($value) };
    }

B<New (2.0):>

    postprocess => sub {
        my $value = shift;
        return process($value);  # Return the processed value directly
    }

=head2 NEW FEATURES

=head3 Preprocessing

You can now preprocess input before validation:

    params => {
        username => {
            preprocess => sub { lc },  # Lowercase parameter value
            required => 1,
            min_length => 3
        }
    }

=head3 Global Postprocessing

Add a global postprocess function to your schema:

    {
        params => { ... },
        postprocess => sub {
            my $params = shift;
            $params->{computed_field} = calculate($params);
            # Modify $params in-place, no return value needed
        }
    }

=head3 Unknown Parameter Handling

Control how unknown parameters are handled:

    my $b = Brannigan->new();
    $b->handle_unknown('ignore');  # Default: preserve unknown params
    $b->handle_unknown('remove');  # Remove unknown params
    $b->handle_unknown('reject');  # Fail validation on unknown params

This works at all nesting levels (top-level, nested hashes, array items).

=head3 Enhanced Default Values

Default values now work in nested structures:

    params => {
        users => {
            array => 1,
            values => {
                hash => 1,
                keys => {
                    name => { required => 1 },
                    role => { default => 'user' }, # Applied to each array item
                    active => { default => 1 }
                }
            }
        }
    }

=head3 Improved Schema Inheritance

Schema inheritance now works recursively and merges parameter definitions:

    $b->register_schema('base', {
        params => {
            name => { required => 1, max_length => 50 }
        }
    });

    $b->register_schema('extended', {
        inherits => 'base',
        params => {
            name => { min_length => 2 },  # Merges with base constraints
            email => { required => 1 }    # Additional parameter
        }
    });

=head2 REMOVED FEATURES

The following features have been removed:

=over

=item * Parameter groups (use global C<postprocess> instead)

=item * Regular expression parameter definitions

=item * Scope-local "_all" validators

=item * C<max_dict> validator

=item * C<forbidden> validator (use C<< handle_unknown => 'reject' >> instead)

=item * C<ignore_missing> schema option (use C<handle_unknown> instead)

=back

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50 dot net> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/ido50/Brannigan>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Brannigan

=head1 ACKNOWLEDGEMENTS

Brannigan was inspired by L<Oogly> (Al Newkirk) and the "Ketchup" jQuery
validation plugin (L<http://demos.usejquery.com/ketchup-plugin/>).

=head1 LICENSE AND COPYRIGHT

Copyright 2025 Ido Perlmuter

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

1;
__END__
