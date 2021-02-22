package Config::Parser;
use strict;
use warnings;
use parent 'Config::AST';
use Carp;
use Cwd qw(abs_path);
use Text::ParseWords;
use mro;

our $VERSION = "1.05";

sub new {
    my $class = shift;
    local %_ = @_;
    my $loaded = 0;

    my @parseargs;
    if (my $filename = delete $_{filename}) {
	push @parseargs, $filename;
	foreach my $k (qw(fh line)) {
	    if (my $v = delete $_{$k}) {
		push @parseargs, ($k, $v);
	    }
	}
    }

    my $self = $class->SUPER::new(%_);
    
    if (my $lex = delete $_{lexicon}) {
	$self->lexicon($lex);
    } else {
	$self->lexicon({ '*' => '*' });
	my @cl = grep { $_ ne __PACKAGE__ && $_->isa(__PACKAGE__) }
	          reverse @{mro::get_linear_isa($class)};
	my $dict;
	if (@cl) {
	    foreach my $c (@cl) {
	        if (my ($file, $line, $data) = $c->findsynt) {
		    my $d = $self->loadsynt($file, $line, $data);
		    if ($d) {
			$dict = { %{$dict // {}}, %$d }
		    }
		}
		last if $c eq $class;
	    }
	}
	$self->lexicon($dict) if $dict;
    }

    $self->init;
    if (@parseargs) {
	$self->parse(@parseargs);
	$self->commit or croak "configuration failed";
    }
    
    return $self;    
}

sub init {}
sub mangle {}

sub commit {
    my $self = shift;
    my $res = $self->SUPER::commit;
    $self->mangle if $res;
    return $res;
}

sub findsynt {
    my $class = shift;
    my $file = $class;
    $file =~ s{::}{/}g;
    $file .= '.pm';
    $file = abs_path($INC{$file})
	or croak "can't find module file for $class";
    local ($/, *FILE);
    open FILE, $file or croak "Can't open $file";
    my ($text, $data) = split /(?m)^__DATA__$/, <FILE>, 2;
    close FILE;
    return ($file, 1+($text =~ tr/\n//), $data) if $data;
    return ();
}

sub loadsynt {
    my ($self, $file, $line, $data) = @_;
    open(my $fh, '<', \$data)
	or croak "can't open filehandle for data string";
    $self->parse($file,
		 fh => $fh,
		 line => $line)
	or croak "Failed to parse template at $file:$line";
    close $fh;

    my @sections;
    my $lex = $self->as_hash(sub {
            my ($what, $name, $val) = @_;
	    $name = '*' if $name eq 'ANY';
	    if ($what eq 'section') {
		$val->{section} = {};
		push @sections, $val;
		($name, $val->{section});
	    } else {
		my @words = parse_line('\s+', 0, $val);
		my $ret = {};
		$val = shift @words;

		if ($val eq 'STRING') {
		    # nothing
		} elsif ($val eq 'NUMBER' || $val eq 'DECIMAL') {
		    $ret->{re} = '^\d+$';
		} elsif ($val eq 'OCTAL') {
		    $ret->{re} = '^[0-7]+$';
		} elsif ($val eq 'HEX') {
		    $ret->{re} = '^([0-9][A-Fa-f])+$';
		} elsif ($val =~ /^BOOL(EAN)?$/) {
		    $ret->{check} = \&check_bool;
		} else {
		    unshift @words, $val;
		}

		while (($val = $words[0])
		       && $val =~ /^:(?<kw>.+?)(?:\s*=\s*(?<val>.*))?$/) {
		    $ret->{$+{kw}} = $+{val} // 1;
		    shift @words;
		}
		if (@words) {
		    if ($ret->{array}) {
			$ret->{default} = [@words];
		    } else {
		        $ret->{default} = join(' ', @words);
		    }
		}
		($name, $ret);
	    }
      })->{section};
    # Process eventual __options__ keywords
    foreach my $s (@sections) {
	if (exists($s->{section}{__options__})) {
	    @{$s}{keys %{$s->{section}{__options__}}}
	               = values %{$s->{section}{__options__}};
	    delete $s->{section}{__options__};
	}
    }
    return $lex;
}

sub check_bool {
    my ($self, $valref, undef, $locus) = @_;
    my %bv = (
	yes => 1,
	no => 0,
	true => 1,
	false => 0,
	on => 1,
	off => 0,
	t => 1,
	nil => 0,
	1 => 1,
	0 => 0
    );
    
    if (exists($bv{$$valref})) {
	$$valref = $bv{$$valref};
	return 1;
    }
    $self->error("$$valref is not a valid boolean value", locus => $locus);
    return 0;
}

1;

=head1 NAME

Config::Parser - base class for configuration file parsers

=head1 DESCRIPTION

B<Config::Parser> provides a framework for writing configuration file
parsers.  It is an intermediate layer between the abstract syntax tree
(L<Config::AST>) and implementation of a parser for a particular
configuration file format.

It takes a I<define by example> approach.  That means that the implementer
creates a derived class that implements a parser on top of B<Config::Parser>.
Application writers write an example of configuration file in the B<__DATA__>
section of their application, which defines the statements that are allowed
in a valid configuration.  This example is then processed by the parser
implementation to create an instance of the parser, which is then used to
process the actual configuration file.

Let's illustrate this on a practical example.  Suppose you need a parser for
a simple configuration file, which consists of keyword/value pairs.  In each
pair, the keyword is separated from the value by an equals sign.  Pairs are
delimited by newlines.  Leading and trailing whitespace characters on a line
are ignored as well as are empty lines.  Comments begin with a hash sign and
end with a newline.

You create the class, say B<Config::Parser::KV>, inherited from
B<Config::Parser>.  The method B<parser> in this class implements the actual
parser.

Application writer decides what keywords are allowed in a valid configuration
file and what are their values and describes them in the B<__DATA__> section
of his program (normally in a class derived from B<Config::Parser::KV>, in
the same format as the actual configuration file.  For example:

  __DATA__
  basedir = STRING :mandatory
  mode = OCTAL
  size = NUMBER :array

This excerpt defines a configuration with three allowed statements.  Uppercase
values to the right of the equals sign are data types.  Values starting with
a colon are flags that define the semantics of the values.  This section
declares that three keywords are allowed.  The B<basedir> keyword takes
string as its argument and must be present in a valid configuration.  The
B<mode> expects octal number as its argument.  The B<size> keyword takes
a number.  Multiple B<size> statements are collapsed into an array.

To parse the actual configuration file, the programmer creates an instance
of the B<Config::Parse::KV> class, passing it the name of the file as its
argument:

  $cf = new Config::Parse::KV($filename);

This call first parses the B<__DATA__> section and builds validation rules,
then it parses the actual configuration from B<$filename>.  Finally, it
applies the validation rules to the created syntax tree.  If all rules pass,
the configuration is correct and the constructor returns a valid object.
Otherwise, it issues proper diagnostics and croaks.

Upon successful return, the B<$cf> object is used to obtain the actual
configuration values as needed.

Notice that syntax declarations in the B<__DATA__> section always follow the
actual configuration file format, that's why we call them I<definition by
example>.  For instance, the syntax definition for a configuration file in
Apache-like format would look like

  __DATA__
  <section ANY>
     basedir STRING :mandatory
     mode OCTAL
     size NUMBER :array
  </section>

=head1 CONSTRUCTOR

=head2 $cfg = new Config::Parser(%hash)

Creates a new parser object.  Keyword arguments are:

=over 4

=item B<filename>

Name of the file to parse.  If supplied, the constructor will call
the B<parse> and B<commit> methods automatically and will croak if
the latter returns false.  The B<parse> method is given B<filename>,
B<line> and B<fh> keyword-value pairs (if present) as its arguments.

If not supplied, the caller is supposed to call both methods later.

=item B<line>

Optional line where the configuration starts in B<filename>.  It is used to
keep track of statement location in the file for correct diagnostics.  If
not supplied, B<1> is assumed.

Valid only together with B<filename>.

=item B<fh>

File handle to read from.  If it is not supplied, new handle will be
created by using B<open> on the supplied filename.

Valid only together with B<filename>.

=item B<lexicon>

Dictionary of allowed configuration statements in the file.  You will not
need this parameter.  It is listed here for completeness sake.  Refer to
the L<Config::AST> constructor for details.

=back

=head1 USER HOOKS

These are the methods provided for implementers to do any implementation-
specific tasks.  Default implementations are empty placeholders.

=head2 $cfg->init

Called after creation of the base object, when parsing of the syntax
definition has finished.  Implementers can use it to do any
implementation-specific initialization.

=head2 $cfg->mangle

Called after successful parsing.  It can be used to modify the created
source tree.

=head1 PARSER METHODS

The following two methods are derived from L<Config::AST>.  They are
called internally by the constructor, if the file name is supplied.

=head2 $cfg->parse($filename, %opts)

Parses the configuration from B<$filename>.  Optional arguments are:

=over 4

=item B<fh>

File handle to read from.  If it is not supplied, new handle will be
created by using B<open> on the supplied filename.

=item B<line>

Line to start numbering of lines from.  It is used to keep track of
statement location in the file for correct diagnostics.  If not supplied,
B<1> is assumed.

=back

=head2 $cfg->commit

Finalizes the syntax tree.  Returns true on success, and false on errors.

=head1 SYNTAX DEFINITION

Syntax definition is a textual description of statements allowed in
a configuration file.  It is written in the format of the configuration
file itself and is parsed using the same object (derivative of
B<Config::Parser>) that will be used later to parse the actual configuration.

Syntax definitions are gathered from the B<__DATA__> blocks of 
subclasses of B<Config::Parser>.

In a syntax definition the value of each statement consists of optional
data type followed by zero or more options delimited with whitespace.

Valid data types are:

=over 4

=item B<STRING>

String value.

=item B<NUMBER> or B<DECIMAL>

Decimal number.

=item B<OCTAL>

Octal number.

=item B<HEX>

Hex number.

=item B<BOOL> or B<BOOLEAN>

Boolean value.  Allowed values are:
B<yes>, B<true>, B<on>, B<t>, B<1>, for C<true> and
B<no>, B<false>, B<off>, B<nil>, B<0>, for C<false>.

=back

If the data type is omitted, no checking is performed unless specified
otherwise by other options (see the B<:re> and B<:check> options below).

Options are special names prefixed with a colon.  Option names follow
the keywords from the L<Config::AST> keyword lexicon value.  An option 
can be followed by an equals sign and its value.  If an option is used
without arguments, the value B<1> is implied.

Any word not recognized as an option or its value starts the I<default
value>.

Available options are described below:

=over 4

=item B<:mandatory>

Marks the statement as a mandatory one.  If such a statement is missing from
the configuration file, the parser action depends on whether the default value
is supplied.  If it is, the statement will be inserted in the parse tree with
the default value.  Otherwise, a diagnostic message will be printed and the
constructor will return B<undef>.

=item B<:default>

Argument supplies the default value for this setting.

=item B<:array>

If the value is 1, declares that the statement is an array.  Multiple
occurrences of the statement will be accumulated. They can be retrieved as
a reference to an array when the parsing is finished.

=item B<:re = >I<string>

Defines a regular expression which the value must match in order to be
accepted.  This provides a more elaborate mechanism of checking than the
data types.  In fact, data types are converted to the appropriate B<:re>
options internally, for example B<OCTAL> becomes B<:re = "^[0-7]+$">.
If data type and B<:re> are used together, B<:re> takes precedence.

=item B<:select = >I<method>

Argument is the name of a method to call in order to decide
whether to apply this definition.  The method will be called as

  $cfg->{ \$method }($node, @path)

where $node is the B<Config::AST::Node::Value> object (use
B<$vref-E<gt>value>, to obtain the actual value), and B<@path> is its pathname.

=item B<:check = >I<method>

Argument is the name of a method which will be invoked after parsing the
statement in order to verify its value.  This provides the most flexible
way of verification (the other two being the B<:re> option and data type
declaration).  The method will be invoked as follows:

  $cfg->{ \$method }($valref, $prev_value, $locus)

where B<$valref> is a reference to the value, and B<$prev_value> is the
value of the previous instance of this setting.  The method must return
B<true>, if the value is OK for that setting.  In that case, it is allowed
to modify the value referenced by B<$valref>.  If the value is erroneous,
the method must issue an appropriate error message using B<$cfg-E<gt>error>,
and return 0.

=back

To specify options for a section, use the reserved keyword B<__options__>.
Its value is the list of options as described above.  After processing, the
keyword itself is removed from the lexicon.

=head1 OTHER METHODS

=head2 $cfg->check($valref, $prev, $locus)

This method implements syntax checking and translation for C<BOOLEAN> data
types.  If B<$$valref> is one of the valid boolean values (as described
above), it translates it to B<1> or B<0>, stores that value in B<$valref>,
and returns 1.  Otherwise, it emits error message using B<$cfg->error> and
returns 0.

=head1 SEE ALSO

L<Config::AST>(3).

=cut

    
