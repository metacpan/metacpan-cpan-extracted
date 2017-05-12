
###
###  Copyright 2002-2003 University of Illinois Board of Trustees
###  Copyright 2002-2003 Mark D. Roth
###  All rights reserved. 
###
###  Config::Objective - Perl module for parsing object-oriented config files
###
###  Mark D. Roth <roth@uiuc.edu>
###  Campus Information Technologies and Educational Services
###  University of Illinois at Urbana-Champaign
###


package Config::Objective;

use 5.006;
use strict;
use warnings;
#use overload;

use Parse::Lex;

use Config::Objective::DataType;
use Config::Objective::Parser;


our $VERSION = '0.9.1';
our $AUTOLOAD;


###############################################################################
###  internal functions for use by parser
###############################################################################

sub _lexer
{
	my ($parser) = @_;
	my ($token, $lexer);

	$lexer = $parser->YYData->{'lexer'};
#	print "lexer = $lexer\n";

	while (1)
	{
		$token = $lexer->next;

		if ($lexer->eoi)
		{
#			print "lexer returning EOI\n";
			return ('', undef);
		}

		next
			if ($token->name eq 'COMMENT');

#		print "lexer returning (" . $token->name . ", \"" . $token->text . "\")\n";
		return ($token->name, $token->text);
	}
}


sub _error
{
	my ($parser) = @_;
	my ($config, $lexer, $file, $line);

	$config = $parser->YYData->{'config'};
	$file = $config->{'file_stack'}->[-1];

	$lexer = $parser->YYData->{'lexer'};
	$line = $lexer->line;

	die("$file:$line: parse error\n");
}


sub _call_obj_method
{
	my ($self, $obj, $method, @args) = @_;
	my ($retval, $line, $msg);

#	print "==> _call_obj_method('$obj', '$method'";
#	map { print ", '$_'"; } @args
#		if (@args > 1 || defined($args[0]));
#	print ")\n";

	die "$obj: unknown config object"
		if (!exists($self->{'objs'}->{$obj}));

	$method = 'default'
		if (!defined($method));

	$retval = eval { $self->{'objs'}->{$obj}->$method(@args); };
	if ($@)
	{
		if (@{$self->{'lexer_stack'}})
		{
			$line = $self->{'lexer_stack'}->[-1]->line;
			$msg = "$self->{'file_stack'}->[-1]:$line: ";
		}
		$msg .= "$obj";
		die "$msg: $@";
	}

#	print "<== _call_obj_method(): returning '"
#		. (defined($retval) ? $retval : 'undef') . "'\n";
	return $retval;
}


###############################################################################
###  constructor
###############################################################################

sub new
{
	my ($class, $file, $objs, %opts) = @_;
	my ($self);

	$self = \%opts;
	bless($self, $class);

	$self->{'objs'} = $objs;
	$self->{'objs'} = {}
		if (!defined($self->{'objs'}));

	$self->{'include_dir'} = '.'
		if (!defined($self->{'include_dir'}));

	$self->{'file_stack'} = [];
	$self->{'cond_stack'} = [];
	$self->{'list_stack'} = [];
	$self->{'hash_stack'} = [];

	$self->{'in_expr'} = 0;

	$self->parse($file);

	return $self;
}


###############################################################################
###  config parser
###############################################################################

sub parse
{
	my ($self, $file) = @_;
	my ($fh, $lexer, $parser);

#	print "==> parse('$file')\n";

	open($fh, $file)
		|| die "open($file): $!\n";
	push(@{$self->{'file_stack'}}, $file);

	$lexer = Parse::Lex->new(
		'AND',		'&&',
		'COMMA',	',',
		'COMMENT',	'(?<!\\\\)#.*$',
		'ELIF',		'^\%[ \t]*elif',
		'ELSE',		'^\%[ \t]*else',
		'ENDIF',	'^\%[ \t]*endif',
		'EOS',		';',
		'PAREN_START',	'\(',
		'PAREN_END',	'\)',
		'HASH_ARROW',	'=>',
		'HASH_START',	'{',
		'HASH_END',	'}',
		'IF',		'^\%[ \t]*if',
		'INCLUDE',	'^\%[ \t]*include',
		'LIST_START',	'\[',
		'LIST_END',	'\]',
		'METHOD_ARROW',	'->',
		'NOT',		'!',
		'OR',		'\|\|',
		'WORD',		'\w+',
		'QSTRING',	[
				  '(?<!\\\\)"',
				  '([^"]|(?<=\\\\)")*',
				  '(?<!\\\\)"'
				],
				sub {
					my ($token, $string) = @_;

					$string =~ s/^"//;
					$string =~ s/"$//;

					$string =~ s/\\"/"/g;

					return $string;
				},
		'ERROR',	'(?s:.*)',
				sub {
					my $line = $_[0]->lexer->line;
					my $file = $self->{'file_stack'}->[-1];

					die "$file:$line: syntax error: \"$_[1]\"\n";
				}
	);
	$lexer->from(\*$fh);
	$lexer->configure('Skip' => '\s+');
	push(@{$self->{'lexer_stack'}}, $lexer);

	$parser = Config::Objective::Parser->new();
	$parser->YYData->{'lexer'} = $lexer;
	$parser->YYData->{'config'} = $self;

	$parser->YYParse(yylex => \&_lexer,
#			 yydebug => 0x1F,
			 yyerror => \&_error);

	pop(@{$self->{'file_stack'}});
	pop(@{$self->{'lexer_stack'}});
	close($fh);

#	print "<== parse('$file')\n";

	return 1;
}


###############################################################################
###  allow direct access to object values
###############################################################################

sub AUTOLOAD
{
	my ($self) = @_;
	my ($method);

	$method = $AUTOLOAD;
	$method =~ s/.*:://;

	return 
		if ($method eq 'DESTROY');

#	return (overload::Overloaded($self->{'objs'}->{$method})
#		? $self->{'objs'}->{$method}
#		: $self->{'objs'}->{$method}->get());

	return $self->{'objs'}->{$method}->get();
}


###############################################################################
###  return a config object
###############################################################################

sub get_obj
{
	my ($self, $obj) = @_;

	return $self->{'objs'}->{$obj};
}


###############################################################################
###  get a list of config object names
###############################################################################

sub obj_names
{
	my ($self) = @_;

	return keys %{$self->{'objs'}};
}


###############################################################################
###  get a hash of object names and values
###############################################################################

sub get_hash
{
	my ($self) = @_;
	my ($href);

	$href = {};
	map { $href->{$_} = $self->$_; } $self->obj_names();

	return $href;
}


###############################################################################
###  cleanup and documentation
###############################################################################

1;

__END__

=head1 NAME

Config::Objective - Perl module for parsing object-oriented config files

=head1 SYNOPSIS

  use Config::Objective;
  use Config::Objective::String;
  use Config::Objective::List;

  my $conf = Config::Objective->new('filename',
  		{
			'var1' => Config::Objective::String->new(),
			'var2' => Config::Objective::List->new(),
			...
		},
		'include_dir'	=> '/usr/local/share/appname');

  print "var1 = \"" . $conf->var1 . "\"\n";

=head1 DESCRIPTION

The B<Config::Objective> module provides a mechanism for parsing
config files to manipulate configuration data.  Unlike most other
config file modules, which represent config data as simple variables,
B<Config::Objective> represents config data as perl objects.  This allows
for a much more flexible configuration language, since new classes can
be easily written to add methods to the config syntax.

The B<Config::Objective> class supports the following methods:

=over 4

=item new()

The constructor.  The first argument is the filename of the config file
to parse.  The second argument is a reference to a hash that maps names 
to configuration objects.

The remaining arguments are interpretted as a hash of attributes for
the object.  Currently, the only supported attribute is I<include_dir>,
which specifies the directory to search for include files (see L<File
Inclusion>).  If not specified, I<include_dir> defaults to ".".

=item I<object_name>

Once the constructor parses the config file, you can call the get()
method of any of the objects by using the object name as an autoloaded
method (see L<Recommended Methods>).

=item get_obj()

Returns a reference to the object of the specified object name.  The
object name is the first argument.

=item obj_names()

Returns a list of known object names.

=item get_hash()

Returns a hash where the keys are the known object names and the values
are the result of calling the get() method on the corresponding object.

=back

=head1 CONFIG FILE SYNTAX

The config file format supported by B<Config::Objective> is described
here.

=head2 Data Types

B<Config::Objective> supports three types of data: scalars, lists, and
hashes.  The syntax for these types is intentionally similar to their
perl equivalents.

=over 4

=item Scalars

A scalar is represented as a simple integer or string value.  If it is
composed only of letters, numbers, and the underscore character, it can
be written literally:

  foo
  all_word_characters
  123
  alpha_123_numeric
  4sure

However, if the value contains whitespace or other non-word characters,
it must be quoted:

  "telnet/tcp"
  "use quotes for whitespace"
  "quotes can be escaped like this \" inside quoted strings"
  "quoted
     strings
   can span
   multiple lines"

=item Lists

A list is represented as a sequence of comma-delimited values enclosed
by square brackets:

  [ this, is, a, list ]

Note that each value in a list can itself be a scalar, list, or hash:

  [ this, is, a, [ nested, list ] ]
  [ this, list, contains, a, { hash => value } ]

=item Hashes

A hash is represented as a sequence of zero or more comma-delimited
entries enclosed in curly braces:

  { this => 1, is => 2, a => 3, hash => 4 }

As in perl, each entry contains a key and a value.  However, unlike perl,
the value is optional:

  { this, is, a, hash, without, values }
  { this => hash, has => "some values", but, not, others }

When no value is specified for a given entry, its value is undefined.

Note that hash keys must always be scalars.  However, values may be
scalars, lists, or hashes:

  { "this is a" => [ list, within, a, hash ] }
  { "this is a" => { sub => hash } }

=back

=head2 Configuration Statements

Each statement in the config file results in calling a method on a
configuration object.  The syntax is:

  object[->method] [args];

In this syntax, "object" is the name of the object.  The object must
be created and passed to the B<Config::Objective> constructor, as
described above.

The "->method" portion is optional.  If specified, it indicates which
method should be called on the object.  If not specified, a method called
default() will be used.

The "args" portion is also optional.  It specifies one or more
comma-delimited arguments to pass to the method.  If multiple arguments
are provided, the entire argument list must be enclosed in parentheses.
Each argument can be a simple scalar, list, hash, or a complex, nested
list or hash structure, as described above.

So, putting this all together, here are some example configuration
statements:

  ### call default method with no arguments
  object;

  ### call a specific method, but still no args
  object->method;

  ### call default method, but specify a single scalar argument
  object scalar_arg;

  ### call default method, but specify a single list argument
  object [ this, is, a, single, list, argument ];

  ### call a specific method and specify a single hash argument
  object->method { this, is, a, single, hash, argument };

  ### call a specific method with multiple scalar args
  object->method(arg1, arg2, arg3);

  ### call a specific method with multiple args of different types
  object->method(scalar_arg, [ list, argument ], { hash => argument });

=head2 Conditional Evaluation

The config syntax also provides some rudementary support for conditional
evaluation.  A conditional directive is signalled by the use of a "%"
character at the beginning of a line (i.e., no leading whitespace).
There can be space between the "%" and the conditional directive,
however, which can improve readability when using nested conditional
blocks.

The conditional directives are I<%if>, I<%else>, I<%elif>, and I<%endif>.
They can be used to enclose other config statements, which are evaluated
or skipped based on whether the conditional expression evaluates to true.
For example:

  %if ( expression )
    ... other config directives ...
  %endif

The most basic I<expression> is simply a method call that returns
a true or false value.  The syntax for this is the same as a normal
config statement, except without the trailing semicolon:

  %if ( object[->method] [args] )

If no method is specified, the equals() method will be called by
default.

Multiple expressions can be combined using the "&&", "||", and
"!" operators.  Additional parentheses can also be used for grouping
within the expression.  For example:

  %if ( ( object1 foo && ! object2 bar ) || object3 baz )

=head2 File Inclusion

File inclusion is another type of conditional evaluation.  It allows you
to include another file in the config file that is currently being
parsed, similar to the C preprocessor's "#include" directive.  The
syntax is:

  %include "filename"

If the specified filename is not an absolute path, B<Config::Objective>
will look for it in the directory specified by the I<include_dir>
attribute when the B<Config::Objective> object was created.

Note that the I<%include> directive will be ignored within an I<%if>
block whose condition is false.  This means that you cannot start an
I<%if> block in one file, add a I<%include> directive, and provide the
I<%endif> directive in the included file.  All I<%if> blocks must be
fully contained within the same file.

=head2 Comments

Any text between a "#" character and the next newline is considered a
comment.  The "#" character loses this special meaning if it is enclosed
in a quoted string or immediately preceded by a "\".

=head1 CONFIGURATION OBJECTS

This section explains the details of how configuration objects are
used.

=head2 Recommended Methods

There are no strict requirements for how a class must be designed in
order to be used for a configuration object.  The following methods are
recommended in that they will be used by B<Config::Objective> in certain
circumstances, but they do not need to be present if they are
not actually going to be used.

=over 4

=item get()

Return the value encapsulated by the object.  This is used when you use
call the variable name as a method of the B<Config::Objective> object.
For example:

  print "var1 = '" . $conf->var1 . "'\n";

This will implicitly call the get() method of the object named I<var1>.

=item default()

This is the default method used when a configuration file references an
object with no method.

=item equals()

This is the default method used when a configuration file references an
object with no method as part of an expression.  (See L<"Conditional
Evaluation"> above.)

=back

=head2 Supplied Object Classes

B<Config::Objective> supplies several classes that can be used for
encapsulating common types of configuration data.

=over 4

=item B<Config::Objective::Boolean>

=item B<Config::Objective::Hash>

=item B<Config::Objective::Integer>

=item B<Config::Objective::List>

=item B<Config::Objective::String>

=item B<Config::Objective::Table>

=back

See the documentation for each of these classes for more information.

=head1 AUTHOR

Mark D. Roth E<lt>roth@uiuc.eduE<gt>

=head1 SEE ALSO

L<perl>.

=cut

