package Brannigan;

# ABSTRACT: Comprehensive, flexible system for validating and parsing input, mainly targeted at web applications.

our $VERSION = "1.100001";
$VERSION = eval $VERSION;

use warnings;
use strict;
use Brannigan::Tree;

=head1 NAME

Brannigan - Comprehensive, flexible system for validating and parsing input, mainly targeted at web applications.

=head1 SYNOPSIS

	use Brannigan;

	my %scheme1 = ( name => 'scheme1', params => ... );
	my %scheme2 = ( name => 'scheme2', params => ... );
	my %scheme3 = ( name => 'scheme3', params => ... );

	# use the OO interface
	my $b = Brannigan->new(\%scheme1, \%scheme2);
	$b->add_scheme(\%scheme3);

	my $parsed = $b->process('scheme1', \%params);
	if ($parsed->{_rejects}) {
		die $parsed->{_rejects};
	} else {
		return $parsed;
	}

	# Or use the functional interface
	my $parsed = Brannigan::process(\%scheme1, \%params);
	if ($parsed->{_rejects}) {
		die $parsed->{_rejects};
	} else {
		return $parsed;
	}

For a more comprehensive example, see L</"MANUAL"> in this document
or the L<Brannigan::Examples> document.

=head1 DESCRIPTION

Brannigan is an attempt to ease the pain of collecting, validating and
parsing input parameters in web applications. It's designed to answer both of
the main problems that web applications face:

=over 2

=item * Simple user input

Brannigan can validate and parse simple, "flat", user input, possibly
coming from web forms.

=item * Complex data structures

Brannigan can validate and parse complex data structures, possibly
deserialized from JSON or XML data sent to web services and APIs.

=back

Brannigan's approach to data validation is as follows: define a structure
of parameters and their needed validations, and let the module automatically
examine input parameters against this structure. Brannigan provides you
with common validation methods that are used everywhere, and also allows
you to create custom validations easily. This structure also defines how,
if at all, the input should be parsed. This is akin to schema-based
validations such as XSD, but much more functional, and most of all
flexible.

Check the next section for an example of such a structure. I call this
structure a validation/parsing scheme. Schemes can inherit all the properties
of other schemes, which allows you to be much more flexible in certain
situations. Imagine you have a blogging application. A base scheme might
define all validations and parsing needed to create a new blog post from
a user's input. When editing a post, however, some parameters that were
required when creating the post might not be required now (so you can
just use older values), and maybe new parameters are introduced. Inheritance
helps you avoid repeating yourself. You can another scheme which gets
all the properties of the base scheme, only changing whatever it is needs
changing (and possibly adding specific properties that don't exist in
the base scheme).

=head1 MANUAL

In the following manual, we will look at the following example. It is based
on L<Catalyst>, but should be fairly understandable for non-Catalyst users.
Do not be alarmed by the size of this, this is only because it displays
basically every aspect of Brannigan.

This example uses L<Catalyst>, but should be pretty self explanatory. It's
fairly complex, since it details pretty much all of the available Brannigan
functionality, so don't be alarmed by the size of this thing.

	package MyApp::Controller::Post;

	use strict;
	use warnings;
	use Brannigan;

	# create a new Brannigan object with two validation/parsing schemes:
	my $b = Brannigan->new({
		name => 'post',
		ignore_missing => 1,
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

					return undef unless $value;
					
					return $value =~ m/^lorem ipsum/ ? 1 : undef;
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
				parse => sub {
					my $val = shift;
					
					my $ret = $val == 1 ? 'reviews' :
						  $val == 2 ? 'receips' :
						  'general';
						  
					return { section => $ret };
				},
			},
			id => {
				required => 1,
				exact_length => 10,
				value_between => [1000000000, 2000000000],
			},
			'/^picture_(\d+)$/' => {
				length_between => [3, 100],
				validate => sub {
					my ($value, $num) = @_;

					...
				},
			},
			picture_1 => {
				default => 'http://www.example.com/avatar.png',
			},
			array_of_ints => {
				array => 1,
				min_length => 3,
				values => {
					integer => 1,
				},
			},
			hash_of_langs => {
				hash => 1,
				keys => {
					_all => {
						exact_length => 10,
					},
					en => {
						required => 1,
					},
				},
			},
		},
		groups => {
			date => {
				params => [qw/year mon day/],
				parse => sub {
					my ($year, $mon, $day) = @_;
					return undef unless $year && $mon && $day;
					return { date => $year.'-'.$mon.'-'.$day };
				},
			},
			tags => {
				regex => '/^tags_(en|he|fr)$/',
				forbid_words => ['bad_word', 'very_bad_word'],
				parse => sub {
					return { tags => \@_ };
				},
			},
		},
	}, {
		name => 'edit_post',
		inherits_from => 'post',
		params => {
			subject => {
				required => 0, # subject is no longer required
			},
			id => {
				forbidden => 1,
			},
		},
	});

	# create the custom 'forbid_words' validation method
	$b->custom_validation('forbid_words', sub {
		my $value = shift;

		foreach (@_) {
			return 0 if $value =~ m/$_/;
		}

		return 1;
	});

	# post a new blog post
	sub new_post : Local {
		my ($self, $c) = @_;

		# get input parameters hash-ref
		my $params = $c->request->params;

		# process the parameters
		my $parsed_params = $b->process('post', $params);

		if ($parsed_params->{_rejects}) {
			die $c->list_errors($parsed_params);
		} else {
			$c->model('DB::BlogPost')->create($parsed_params);
		}
	}

	# edit a blog post
	sub edit_post : Local {
		my ($self, $c, $id) = @_;

		my $params = $b->process('edit_posts', $c->req->params);

		if ($params->{_rejects}) {
			die $c->list_errors($params);
		} else {
			$c->model('DB::BlogPosts')->find($id)->update($params);
		}
	}

=head2 HOW BRANNIGAN WORKS

In essence, Brannigan works in three stages (which all boil down to one
single command):

=over

=item * Input stage and preparation

Brannigan receives a hash-ref of input parameters, or a hash-ref based
data structure, and the name of a scheme to validate against. Brannigan
then loads the scheme and prepares it (by merging it with inherited schemes)
for later processing.

=item * Data validation

Brannigan invokes all validation methods defined in the scheme on the
input data, and generates a hash-ref of rejected parameters. For every
parameter in this hash-ref, a list of failed validations is created in an
array-ref.

=item * Data parsing

Regardless of the previous stage, every parsing method defined in the scheme
is applied on the relevant data. The data resulting from these parsing
methods, along with the values of all input parameters for which no parsing
methods were defined, is returned to the user in a hash-ref. This hash-ref
also includes a _rejects key whose value is the rejects hash created in
the previous stage.

The reason I say this stage isn't dependant on the previous stage is
simple. First of all, it's possible no parameters failed validation, but
the truth is this stage doesn't care if a parameter failed validation. It
will still parse it and return it to the user, and no errors are ever
raised by Brannigan. It is the developer's (i.e. you) job to decide what
to do in case rejects are present.

=back

=head2 HOW SCHEMES LOOK

The validation/parsing scheme defines the structure of the data you're
expecting to receive, along with information about the way it should be
validated and parsed. Schemes are created by passing them to the Brannigan
constructor. You can pass as many schemes as you like, and these schemes
can inherit from one another. You can create the Brannigan object that
gets these schemes wherever you want. Maybe in a controller of your web
app that will directly use this object to validate and parse input it
gets, or maybe in a special validation class that will hold all schemes.
It doesn't matter where, as long as you make the object available for
your application.

A scheme is a hash-ref based data structure that has the following keys:

=over

=item * name

Defines the name of the scheme. Required.

=item * ignore_missing

Boolean value indicating whether input parameters that are not referenced
in the scheme should be added to the parsed output or not. Optional,
defaults to false (i.e. parameters missing from the scheme will be added
to the output as-is). You might find it is probably a good idea to turn
this on, so any input parameters you're not expecting to receive from users
are ignored.

=item * inherits_from

Either a scalar naming a different scheme or an array-ref of scheme names.
The new scheme will inherit all the properties of the scheme(s) defined
by this key. If an array-ref is provided, the scheme will inherit their
properties in the order they are defined. See the L</"CAVEATS"> section for some
"heads-up" about inheritance.

=item * params

The params key is the most important part of the scheme, as it defines
the expected input. This key takes a hash-ref containing the names of
input parameters. Every such name (i.e. key) in itself is also a hash-ref.
This hash-ref defines the necessary validation methods to assert for this
parameter, and optionally a 'parse' and 'default' method. The idea is this: use the name
of the validation method as the key, and the appropriate values for this
method as the value of this key. For example, if a certain parameter, let's
say 'subject', must be between 3 to 10 characters long, then your scheme
will contain:

	subject => {
		length_between => [3, 10]
	}

The 'subject' parameter's value (from the user input), along with both of
the values defined above (3 and 10) will be passed to the C<length_between()> validation
method. Now, suppose a certain subject sent to your app failed the
C<length_between()> validation; then the rejects hash-ref described
earlier will have something like this:

	subject => ['length_between(3, 10)']

Notice the values of the C<length_between()> validation method were added
to the string, so you can easily know why the parameter failed the validation.

B<Custom validation methods:> Aside for the built-in validation methods
that come with Brannigan, a custom validation method can be defined for
each parameter. This is done by adding a 'validate' key to the parameter,
and an anonymous subroutine as the value. As with built-in methods, the
parameter's value will be automatically sent to this method. So, for
example, if the subject parameter from above must start with the words
'lorem ipsum', then we can define the subject parameter like so:

	subject => {
		length_between => [3, 10],
		validate => sub {
			my $value = shift;

			return $value =~ m/^lorem ipsum/ ? 1 : 0;
		}
	}

Custom validation methods, just like built-in ones, are expected to return
a true value if the parameter passed the validation, or a false value
otherwise. If a parameter failed a custom validation method, then 'validate'
will be added to the list of failed validations for this parameter. So,
in our 'subject' example, the rejects hash-ref will have something like this:

	subject => ['length_between(3, 10)', 'validate']

B<Default values:> For your convenience, Brannigan allows you to set default
values for parameters that are not required (so, if you set a default
value for a parameter, don't add the C<required()> validation method to
it). There are two ways to add a default value: either directly, or
through an anonymous subroutine (just like the custom validation method).
For example, maybe we'd like the 'subject' parameter to have a default
value of 'lorem ipsum dolor sit amet'. Then we can have the following definition:

	subject => {
		length_between => [3, 10],
		validate => sub {
			my $value = shift;

			return $value =~ m/^lorem ipsum/ ? 1 : 0;
		},
		default => 'lorem ipsum dolor sit amet'
	}

Alternatively, you can give a parameter a generated default value by using
an anonymous subroutine, like so:

	subject => {
		length_between => [3, 10],
		validate => sub {
			my $value = shift;

			return $value =~ m/^lorem ipsum/ ? 1 : 0;
		},
		default => sub {
			return int(rand(100000000));
		}
	}

Notice that default values are added to missing parameters only at the
parsing stage (i.e. stage 3 - after the validation stage), so validation
methods do not apply to default values.

B<Parse methods:> It is more than possible that the way input parameters are passed to your
application will not be exactly the way you'll eventually use them. That's
where parsing methods can come in handy. Brannigan doesn't have any
built-in parsing methods (obviously), so you must create these by yourself,
just like custom validation methods. All you need to do is add a 'parse'
key to the parameter's definition, with an anonymous subroutine. This
subroutine also receives the value of the parameter automatically,
and is expected to return a hash-ref of key-value pairs. You will probably
find it that most of the time this hash-ref will only contain one key-value
pair, and that the key will probably just be the name of the parameter. But
note that when a parse method exists, Brannigan makes absolutely no assumptions
of what else to do with that parameter, so you must tell it exactly how to
return it. After all parameters were parsed by Brannigan, all these little hash-refs are
merged into one hash-ref that is returned to the caller. If a parse
method doesn't exist for a paramter, Brannigan will simply add it "as-is"
to the resulting hash-ref. Returning to our subject example (which we
defined must start with 'lorem ipsum'), let's say we want to substitute
'lorem ipsum' with 'effing awesome' before using this parameter. Then the
subject definition will now look like this:

	subject => {
		length_between => [3, 10],
		validate => sub {
			my $value = shift;

			return $value =~ m/^lorem ipsum/ ? 1 : 0;
		},
		default => 'lorem ipsum dolor sit amet',
		parse => sub {
			my $value = shift;

			$value =~ s/^lorem ipsum/effing awesome/;
			
			return { subject => $value };
		}
	}

If you're still not sure what happens when no parse method exists, then
you can imagine Brannigan uses the following default parse method:

	param => {
		parse => sub {
			my $value = shift;

			return { param => $value };
		}
	}

B<Regular expressions:> As of version 0.3, parameter names can also be regular expressions in the
form C<'/regex/'>. Sometimes you cannot know the names of all parameters passed
to your app. For example, you might have a dynamic web form which starts with
a single field called 'url_1', but your app allows your visitors to dynamically
add more fields, such as 'url_2', 'url_3', etc. Regular expressions are
handy in such situations. Your parameter key can be C<'/^url_(\d+)$/'>, and
all such fields will be matched. Regex params have a special feature: if
your regex uses capturing, then captured values will be passed to the
custom C<validate> and C<parse> methods (in their order) after the parameter's
value. For example:

	'/^url_(\d+)$/' => {
		validate => sub {
			my ($value, $num) = @_;
			
			# $num has the value captured by (\d+) in the regex

			return $value =~ m!^http://! ? 1 : undef;
		},
		parse => sub {
			my ($value, $num) = @_;

			return { urls => { $num => $value } };
		},
	}

Please note that a regex must be defined with a starting and trailing
slash, in single quotes, otherwise it won't work. It is also important to
note what happens when a parameter matches a regex rule (or perhaps rules),
and also has a direct reference in the scheme. For example, let's say
we have the following rules in our scheme:

	'/^sub(ject|headline)$/' => {
		required => 1,
		length_between => [3, 10],
	},
	subject => {
		required => 0,
	}

When validating and parsing the 'subject' parameter, Brannigan will
automatically merge both of these references to the subject parameter,
giving preference to the direct reference, so the actual structure on
which the parameter will be validated is as follows:

	subject => {
		required => 0,
		length_between => [3, 10],
	}

If your parameter matches more than one regex rule, they will all be
merged, but there's no way (yet) to ensure in which order these regex
rules will be merged.

B<Complex data structures:> As previously stated, Brannigan can also validate and parse a little more
complex data structures. So, your parameter no longer has to be just a
string or a number, but maybe a hash-ref or an array-ref. In the first
case, you tell Brannigan the paramter is a hash-ref by adding a 'hash'
key with a true value, and a 'keys' key with a hash-ref which is just
like the 'params' hash-ref. For example, suppose you're receiving a 'name'
parameter from the user as a hash-ref containing first and last names.
That's how the 'name' parameter might be defined:

	name => {
		hash => 1,
		required => 1,
		keys => {
			first_name => {
				length_between => [3, 10],
			},
			last_name => {
				required => 1,
				min_length => 3,
			},
		}
	}

What are we seeing here? We see that the 'name' parameter must be a
hash-ref, that it's required, and that it has two keys: first_name, whose
length must be between 3 to 10 if it's present, and last_name, which must
be 3 characters or more, and must be present.

An array parameter, on the other hand, is a little different. Similar to hashes,
you define the parameter as an array-ref with the 'array' key with a true
value, and a 'values' key. This key has a hash-ref of validation and parse
methods that will be applied to EVERY value inside this array. For example,
suppose you're receiving a 'pictures' parameter from the user as an array-ref
containing URLs to pictures on the web. That's how the 'pictures' parameter
might be defined:

	pictures => {
		array => 1,
		length_between => [1, 5],
		values => {
			min_length => 3,
			validate => sub {
				my $value = shift;

				return $value =~ m!^http://! ? 1 : 0;
			},
		},
	}

What are we seeing this time? We see that the 'pictures' parameter must
be an array, with no less than one item (i.e. value) and no more than five
items (notice that we're using the same C<length_between()> method from
before, but in the context of an array, it doesn't validate against
character count but item count). We also see that every value in the
'pictures' array must have a minimum length of three (this time it is
characterwise), and must match 'http://' in its beginning.

Since complex data structures are supported, you can define default values
for parameters that aren't just strings or numbers (or methods), for example:

	complex_param => {
		hash => 1,
		keys => {
			...
		},
		default => { key1 => 'def1', key2 => 'def2' }
	}		

What Brannigan returns for such structures when they fail validations is
a little different than before. Instead of an array-ref of failed validations,
Brannigan will return a hash-ref. This hash-ref might contain a '_self' key
with an array-ref of validations that failed specifically on the 'pictures'
parameter (such as the 'required' validation for the 'name' parameter or
the 'length_between' validation for the 'pictures' parameter), and/or
keys for each value in these structures that failed validation. If it's a
hash, then the key will simply be the name of that key. If it's an array,
it will be its index. For example, let's say the 'first_name' key under
the 'name' parameter failed the C<length_between(3, 10)> validation method,
and that the 'last_name' key was not present (and hence failed the
C<required()> validation). Also, let's say the 'pictures' parameter failed
the C<length_between(1, 5)> validation (for the sake of the argument, let's
say it had 6 items instead of the maximum allowed 5), and that the 2nd
item failed the C<min_length(3)> validation, and the 6th item failed the
custom validate method. Then our rejects hash-ref will have something like
this:

	name => {
		first_name => ['length_between(3, 10)'],
		last_name => ['required(1)'],
	},
	pictures => {
		_self => ['length_between(1, 5)'],
		1 => ['min_length(3)'],
		5 => ['validate'],
	}

Notice the '_self' key under 'pictures' and that the numbering of the
items of the 'pictures' array starts at zero (obviously).

The beauty of Brannigan's data structure support is that it's recursive.
So, it's not that a parameter can be a hash-ref and that's it. Every key
in that hash-ref might be in itself a hash-ref, and every key in that
hash-ref might be an array-ref, and every value in that array-ref might
be a hash-ref... well, you get the idea. How might that look like? Well,
just take a look at this:

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

So, we have a pictures array that every value in it is a hash-ref with a
filename key and a source key whose value is a hash-ref with a website
key and a license key.

B<Local validations:> The _all "parameter" can be used in a scheme to define rules that apply
to all of the parameters in a certain level. This can either be used directly
in the 'params' key of the scheme, or in the 'keys' key of a hash parameter.

	_all => {
		required => 1
	},
	subject => {
		length_between => [3, 255]
	},
	text => {
		min_length => 10
	}

In the above example, both 'subject' and 'text' receive the C<required()>
validation methods.

=item * groups

Groups are very useful to parse parameters that are somehow related
together. This key takes a hash-ref containing the names of the groups
(names are irrelevant, they're more for you). Every group will also take
a hash-ref, with a rule defining which parameters are members of this group,
and a parse method to use with these parameters (just like our custom
parse method from the 'params' key). This parse method will
automatically receive the values of all the parameters in the group, in
the order they were defined.

For example, suppose our app gets a user's birth date by using three web
form fields: day, month and year. And suppose our app saves this date
in a database in the format 'YYYY-MM-DD'. Then we can define a group,
say 'date', that automatically does this. For example:

	date => {
		params => [qw/year month day/],
		parse => sub {
			my ($year, $month, $day) = @_;

			$month = '0'.$month if $month < 10;
			$day = '0'.$day if $day < 10;

			return { date => $year.'-'.$month.'-'.$day };
		},
	}

Alternative to the 'params' key, you can define a 'regex' key that takes
a regex. All parameters whose name matches this regex will be parsed as
a group. As oppose to using regexes in the 'params' key of the scheme,
captured values in the regexes will not be passed to the parse method,
only the values of the parameters will. Also, please note that there's no
way to know in which order the values will be provided when using regexes
for groups.

For example, let's say our app receives one or more URLs (to whatever
type of resource) in the input, in parameters named 'url_1', 'url_2',
'url_3' and so on, and that there's no limit on the number of such
parameters we can receive. Now, suppose we want to create an array
of all of these URLs, possibly to push it to a database. Then we can
create a 'urls' group such as this:

	urls => {
		regex => '/^url_(\d+)$/',
		parse => sub {
			my @urls = @_;

			return { urls => \@urls };
		}
	}

=back

=head2 BUILT-IN VALIDATION METHODS

As mentioned earlier, Brannigan comes with a set of built-in validation
methods which are most common and useful everywhere. For a list of all
validation methods provided by Brannigan, check L<Brannigan::Validations>.

=head2 CROSS-SCHEME CUSTOM VALIDATION METHODS

Custom C<validate> methods are nice, but when you want to use the same
custom validation method in different places inside your scheme, or more
likely in different schemes altogether, repeating the definition of each
custom method in every place you want to use it is not very comfortable.
Brannigan provides a simple mechanism to create custom, named validation
methods that can be used across schemes as if they were internal methods.

The process is simple: when creating your schemes, give the names of the
custom validation methods and their relevant supplement values as with
every built-in validation method. For example, suppose we want to create
a custom validation method named 'forbid_words', that makes sure a certain
text does not contain any words we don't like it to contain. Suppose this
will be true for a parameter named 'text'. Then we define 'text' like so:

	text => {
		required => 1,
		forbid_words => ['curse_word', 'bad_word', 'ugly_word'],
	}

As you can see, we have provided the name of our custom method, and the words
we want to forbid. Now we need to actually create this C<forbid_words()>
method. We do this after we've created our Brannigan object, by using the
C<custom_validation()> method, as in this example:

	$b->custom_validation('forbid_words', sub {
		my ($value, @forbidden) = @_;

		foreach (@forbidden) {
			return 0 if $value =~ m/$_/;
		}

		return 1;
	});

We give the C<custom_validation()> method the name of our new method, and
an anonymous subroutine, just like in "local" custom validation methods.

And that's it. Now we can use the C<forbid_words()> validation method
across our schemes. If a paremeter failed our custom method, it will be
added to the rejects like built-in methods. So, if 'text' failed our new
method, our rejects hash-ref will contain:

	text => [ 'forbid_words(curse_word, bad_word, ugly_word)' ]

As an added bonus, you can use this mechanism to override Brannigan's
built-in validations. Just give the name of the validation method you wish
to override, along with the new code for this method. Brannigan gives
precedence to cross-scheme custom validations, so your method will be used
instead of the internal one.

=head2 NOTES ABOUT PARSE METHODS

As stated earlier, your C<parse()> methods are expected to return a hash-ref
of key-value pairs. Brannigan collects all of these key-value pairs
and merges them into one big hash-ref (along with all the non-parsed
parameters).

Brannigan actually allows you to have your C<parse()> methods be two-leveled.
This means that a value in a key-value pair in itself can be a hash-ref
or an array-ref. This allows you to use the same key in different places,
and Brannigan will automatically aggregate all of these occurrences, just like
in the first level. So, for example, suppose your scheme has a regex
rule that matches parameters like 'tag_en' and 'tag_he'. Your parse
method might return something like C<< { tags => { en => 'an english tag' } } >>
when it matches the 'tag_en' parameter, and something like
C<< { tags => { he => 'a hebrew tag' } } >> when it matches the 'tag_he'
parameter. The resulting hash-ref from the process method will thus
include C<< { tags => { en => 'an english tag', he => 'a hebrew tag' } } >>.

Similarly, let's say your scheme has a regex rule that matches parameters
like 'url_1', 'url_2', etc. Your parse method might return something like
C<< { urls => [$url_1] } >> for 'url_1' and C<< { urls => [$url_2] } >>
for 'url_2'. The resulting hash-ref in this case will be
C<< { urls => [$url_1, $url_2] } >>.

Take note however that only two-levels are supported, so don't go crazy
with this.

=head2 SO HOW DO I PROCESS INPUT?

OK, so we have created our scheme(s), we know how schemes look and work,
but what now?

Well, that's the easy part. All you need to do is call the C<process()>
method on the Brannigan object, passing it the name of the scheme to
enforce and a hash-ref of the input parameters/data structure. This method
will return a hash-ref back, with all the parameters after parsing. If any
validations failed, this hash-ref will have a '_rejects' key, with the
rejects hash-ref described earlier. Remember: Brannigan doesn't raise
any errors. It's your job to decide what to do, and that's a good thing.

Example schemes, input and output can be seen in L<Brannigan::Examples>.

=head1 CONSTRUCTOR

=head2 new( \%scheme | @schemes )

Creates a new instance of Brannigan, with the provided scheme(s) (see
L</"HOW SCHEMES LOOK"> for more info on schemes).

=cut

sub new {
	my $class = shift;

	return bless { map { $_->{name} => $_ } @_ }, $class;
}

=head1 OBJECT METHODS

=head2 add_scheme( \%scheme | @schemes )

Adds one or more schemes to the object. Every scheme hash-ref should have
a C<name> key with the name of the scheme. Existing schemes will be overridden.
Returns the object itself for chainability.

=cut

sub add_scheme {
	my $self = shift;

	foreach (@_) {
		$self->{$_->{name}} = $_;
	}

	return $self;
}

=head2 process( $scheme, \%params )

Receives the name of a scheme and a hash-ref of input parameters (or a data
structure), and validates and parses these paremeters according to the
scheme (see L</"HOW SCHEMES LOOK"> for detailed information about this process).

Returns a hash-ref of parsed parameters according to the parsing scheme,
possibly containing a list of failed validations for each parameter.

Actual processing is done by L<Brannigan::Tree>.

=head2 process( \%scheme, \%params )

Same as above, but takes a scheme hash-ref instead of a name hash-ref. That
basically gives you a functional interface for Brannigan, so you don't have
to go through the regular object oriented interface. The only downsides to this
are that you cannot define custom validations using the C<custom_validation()>
method (defined below) and that your scheme must be standalone (it cannot inherit
from other schemes). Note that when directly passing a scheme, you don't need
to give the scheme a name.

=cut

sub process {
	if (ref $_[0] eq 'Brannigan') {
		my ($self, $scheme, $params) = @_;

		return unless $scheme && $params && ref $params eq 'HASH' && $self->{$scheme};
		$self->_build_tree($scheme, $self->{validations})->process($params);
	} else {
		Brannigan::Tree->new($_[0])->process($_[1]);
	}
}

=head2 custom_validation( $name, $code )

Receives the name of a custom validation method (C<$name>), and a reference to an
anonymous subroutine (C<$code>), and creates a new validation method with
that name and code, to be used across schemes in the Brannigan object as
if they were internal methods. You can even use this to override internal
validation methods, just give the name of the method you want to override
and the new code.

=cut

sub custom_validation {
	my ($self, $name, $code) = @_;

	return unless $name && $code && ref $code eq 'CODE';

	$self->{validations}->{$name} = $code;
}

############################
##### INTERNAL METHODS #####
############################

# _build_tree( $scheme, [ \%custom_validations ] )
# ------------------------------------------------
# Builds the final "tree" of validations and parsing methods to be performed
# on the parameters hash during processing. Optionally receives a hash-ref
# of cross-scheme custom validation methods defined in the Brannigan object
# (see L</"CROSS-SCHEME CUSTOM VALIDATION METHODS"> for more info).

sub _build_tree {
	my ($self, $scheme, $customs) = @_;

	my @trees;

	# get a list of all schemes to inherit from
	my @schemes = $self->{$scheme}->{inherits_from} && ref $self->{$scheme}->{inherits_from} eq 'ARRAY' ? @{$self->{$scheme}->{inherits_from}} : $self->{$scheme}->{inherits_from} ? ($self->{$scheme}->{inherits_from}) : ();

	foreach (@schemes) {
		next unless $self->{$_};
		push(@trees, $self->_build_tree($_));
	}

	my $tree = Brannigan::Tree->new(@trees, $self->{$scheme});
	$tree->{_custom_validations} = $customs;

	return $tree;
}

=head1 CAVEATS

Brannigan is still in an early stage. Currently, no checks are made to
validate the schemes built, so if you incorrectly define your schemes,
Brannigan will not croak and processing will probably fail. Also, there
is no support yet for recursive inheritance or any crazy inheritance
situation. While deep inheritance is supported, it hasn't been tested
extensively. Also bugs are popping up as I go along, so keep in mind that
you might encounter bugs (and please report any if that happens).

=head1 IDEAS FOR THE FUTURE

The following list of ideas may or may not be implemented in future
versions of Brannigan:

=over

=item * Cross-scheme custom parsing methods

Add an option to define custom parse methods in the Brannigan object that
can be used in the schemes as if they were built-in methods (cross-scheme
custom validations are already supported, next up is parse methods).

=item * Support for third-party validation methods

Add support for loading validation methods defined in third-party modules
(written like L<Brannigan::Validations>) and using them in schemes as if they
were built-in methods.

=item * Validate schemes by yourself

Have Brannigan use itself to validate the schemes it receives from the
developers (i.e. users of this module).

=item * Support loading schemes from JSON/XML

Allow loading schemes from JSON/XML files or any other source. Does that
make any sense?

=item * Something to aid rejects traversal

Find something that would make traversal of the rejects list easier or
whatever. Plus, printing the name of the validation method and its supplement
values in the rejects list isn't always a good idea. For example, if we
use the C<one_of()> validation method with a big list of say 100 options,
our rejects list will contain all these 100 options, and that's not nice.
So, think about something there.

=back

=head1 SEE ALSO

L<Brannigan::Validations>, L<Brannigan::Tree>, L<Brannigan::Examples>.

=head1 AUTHOR

Ido Perlmuter, C<< <ido at ido50 dot net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-brannigan at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Brannigan>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Brannigan

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Brannigan>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Brannigan>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Brannigan>

=item * Search CPAN

L<http://search.cpan.org/dist/Brannigan/>

=back

=head1 ACKNOWLEDGEMENTS

Brannigan was inspired by L<Oogly> (Al Newkirk) and the "Ketchup" jQuery
validation plugin (L<http://demos.usejquery.com/ketchup-plugin/>).

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Ido Perlmuter

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
