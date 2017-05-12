#! /usr/bin/env perl

=head1 NAME

Config::Nested - parse a configuration file consiging of nested blocks and sections.

=head1 SYNOPSIS

use Config::Nested;
use Data::Dumper;

my $c = new Config::Nested(
    section => [qw( location animal)],
    boolean => [qw( happy hungry alive)],
    variable => [qw( sex name colour ) ],
    array => 'breed exercise owner',
    hash => 'path',
);

$c->parseFile($ARGV[0]) || die "failed to parse!\n";

my @list = $c->section('animal');
print Dumper(\@list;

=head1 DESCRIPTION

Config::Nested is a configuration file parser based on brace delimited
blocks and named sections. Section, variable and boolean names are
predefined.

The result are configuration section hash objects corresponding to the
declared sections in the configuration string/file. Each hash contains
all the configuration information that is in scope at the end of its
block. The hash objects also contain an element '+' that is an array of
(section-name, value) pairs tracking which sections contain the current
configuration.

Array and hash variables accumumlate values as they proceed into deeper
and deeper blocks. When the block ends, arrays and hashes revert back to
their original value in the outer block.

The format is similar (but not idenical) to the ISC named or ISC dhcpd
configuration files. It is also similar to the configuration supported
by the perl module Config::Scoped except that sections can be nested and
arrays do not have to be enclosed by []. Consequently the syntax is
simpler and the data structures are less complicated.

=head1 CONFIG FILE FORMAT

	config: <statements>
	statements: section, block, assignemnts, lists
	section: <section> <value> [{ statements }]?
	block: { statements }
	hash: <hash-name> <value> <value>
	array: <array-name> <values>
	assignments: <variable> [=|+=|.=]? <value>
	boolean: [*!]?<boolean-variable>

The section, array, variable and booleans names are all specified prior
to parsing the configuration file.

Comments start with a # and continue to the end of the line.

The scope of each object is the enclosing block, section or file.

Each variable name must be unique when declared for the configuration.
However unique abbreviations are allowed within the configuration.

=head1 EXAMPLE CONFIG FILE

Suppose 'location' and 'animal' are decalred as sections; 'owner',
'name' and 'sex' as scalars; and 'path' as an array. Consider the
following configuration:

    owner George
    path step1
    location home {
        animal fish 
        {
            name Fred
            sex male
        }

        animal dog
        {
            name Fido
	    sex  female
    	    path step2
        }
    }

This data would create 1 location configuration hash and 2 animal
configuration hashes; each contains all the configuration information
that is in scope at the end of it's block.

In particular, the last animal configuration hash looks like:

  {
    '+'        => [ [ 'location', 'home' ], [ 'animal', 'dog' ] ],
    'age'      => '',
    'animal'   => 'dog',
    'location' => 'home',
    'name'     => 'Fido',
    'owner'    => 'George',
    'path'     => ['step1', 'step2' ],
    'sex'      => 'female'
   }

=head1 EXPORTS

Nothing.

=head1 FUNCTIONS

=cut


#####################################################################################

# Config::Nested
#
#			Anthony Fletcher 1st Jan 2007
#

package Config::Nested;

$VERSION = '2.0.1';

use 5;
use warnings;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
use vars qw($PARSER);

# Standard modules.
use Data::Dumper;
use Storable qw(dclone);
use Carp;
use Text::Abbrev;

# Non-standard modules.
use Parse::RecDescent;
use Config::Nested::Section;

# The RecDescent parser
$PARSER = undef;

# module configuration
$Data::Dumper::Sortkeys = 1;

my @categories = qw(section boolean variable array hash);

=pod

=head2 $parser = B<Config::Nested-E<gt>new( options )>

=head2 B<$parser-E<gt>configure( options )>

Construct a new Config::Nested object; arguments can be listed as I<key =E<gt> value> pairs.
The keys are

=over 4

=item section

The allowed section names. In the configuration file, each section name is followed by a value.

=item array

The allowed array names. In the configuration file, each array name is
followed by a space separated list of values. The default is the empty array.

=item hash

The allowed hash names. In the configuration file, each hash name is
followed by a space separated pair of values. The first value is the key
and the seconds its valuse in the hash. The default is the empty array.

=item boolean

The allowed boolean names. In the configuration file, each boolean
appears as just the work (set to 1), preceded by ! (set to 0) or *
(set to 1). The default is 0 (false).

==item variable

The allowed variable names. In the configuration file, each variable can
be followed by a single value or by the operations = (assign), +=
(increment) or .= (append) and a single value. The default is the empty string ''.

=back

The data in a configuration hash can be accessed via the declared name
(i.e. $obj->{name}).
Booleans take the value 0 or 1, declared arrays are Perl arrays,
sections and variables are just scalers.
Every name is present in the hash even if it has not been defined.

=cut

# Create a new object
sub new
{
	# Create an object.
	my $this = shift;
	my $class = ref($this) || $this;
	my $self = { };
	bless $self, $class;

	# Initialise
	$self->initialise();

	croak "Odd number of arguments" if @_ % 2;

	# Load args into $self.
	unless ($self->configure(@_))
	{
		croak "$class: initialisation failed!";
		return undef;
	}

	#use Data::Dumper; warn Dumper(\$self);

	$self;
}

# Configure object
sub configure
{
	my $this = shift;
	croak "Odd number of arguments" if @_ % 2;
	my %arg = @_;
	
	for my $k (@categories)
	{
		next unless exists $arg{$k};

		if (ref $arg{$k} eq '')
		{
			$this->{conf}->{$k} = [ split(/\s+/, $arg{$k}) ];
		}
		elsif (ref $arg{$k} eq 'ARRAY')
		{
			$this->{conf}->{$k} = $arg{$k};
		}
		else
		{
			croak "Unrecognised value for $k";
		}

		delete $arg{$k};
	}

	if (keys %arg)
	{
		croak "Unrecognised categories '", join("', '", keys %arg), "'\n";
	}

	$this->reset;

	#print Dumper($this);

	$this;
}

=pod

=head2 B<$parser-E<gt>initialise()>

Clear all the keywords from the parser.

=cut

# Initialise object
sub initialise
{
	my $this = shift;

	for my $k (@categories)
	{
		$this->{conf}->{$k} = [];
	}

	$this->reset;

	$this;
}

=pod

=head2 $conf = B<$parser-E<gt>autoConfigure($conf)>

Configure the parser from the configuration string, $conf. Lines that start
with an @ are special and are removed before returning the resulting string.

Lines of the form

=over 4

=item * 

@section <sections>
  
=item *

@array <array names>

=item *

@boolean <booleans>

=item *

@variable <variables>

=back

all cause the corresponding configuration action for the parser.

Lines of the form

=over 4

=item *

@defaults <variables>

=back

are fed to the parser as configuration strings and act to set defaults.

=cut

sub autoConfigure
{
	my ($this, $conf) = @_;

	while ($conf =~ s/^\@\s*(\S+)\s+(.*)$//m)
	{
		#print "@ -- $1 -- $2\n";

		my $category = $1;
		my $line = $2;

		if ($category ne 'defaults')
		{
			$this->configure($category => $line ) || croak "Unable to configure.\n";
		}
		else
		{
			$this->parse($line) || croak "Parsing defaults failed\n";
		}
	}

	#print Dumper($this);

	$conf;
}

=pod

=head2 B<$parser-E<gt>reset()>

Clear all the parsed data from the parser.

=cut

# Reset parser
sub reset
{
	my $this = shift;

	for my $s (@{$this->{conf}->{section}})
	{
		$this->{section}->{$s} = [];
	}
	$this->{stack} = [];

	#print "reset=", Dumper($this);
	$this;
}

=pod

=head2 B<$parser-E<gt>sections()>

Return the allowed section names.

=cut

sub sections
{
	return @{$_[0]->{conf}->{section}};
}

=pod

=head2 B<$parser-E<gt>section("section")>

Return the current array of parsed sections.

=cut

# section
sub section
{
	my ($this, $section) = @_;

	#print Dumper($this);

	unless (exists $this->{section}->{$section})
	{
		croak "No such section as '$section'";
		return undef;
	}

	@{$this->{section}->{$section}};
}

####################################################################
sub debug { }
sub debugOn
{
	# debugging.
	no warnings;

	@_ = __PACKAGE__ unless @_;

	for my $pack (@_)
	{
		#eval 'sub debug { print STDERR "debug ", @_; }';

		my $pack ||= 'main';
		eval "sub $pack" . '::debug {
			my ($package, $filename, $line,
				   $subroutine, $hasargs, $wantargs) 
					= caller(1);
			$filename = (caller(0))[1];
			$line = (caller(0))[2];
			$subroutine = "" unless defined($subroutine);
			#print STDERR "($filename:$line) ";
			print STDERR "$subroutine: ";
			if (@_)	{print STDERR @_; }
			else	{print "Debug $filename line $line.\n";}
		}';
		eval "sub $pack" . '::debug "debug on";';
	}
}

####################################################
sub array
{
	#debug Dumper(\@_), "\n";

	my ($obj, $field) = @_;
	exists $obj->{$field} ? @{$obj->{$field}} : ();
}

# return the final item in an array.
sub final { $_[$#_]; }

sub boolean
{
	my ($obj, $field) = @_;

	#print Dumper \@_, "\n";

	return 0 unless (exists($obj->{"*$field"}));
	return $obj->{"*$field"};
}

####################### Configuration File Parsing ############################
{

# static variables.
#our @obj;

our %section;
our %boolean;
our %variable;
our %array;
our %hash;

our %percent;

our %abbreviation;
our $THIS;

=pod

=head2 B<$parser-E<gt>parse( string )>

=head2 B<$parser-E<gt>parseFile( file )>

These parse the configuration string and files respectively.

=cut

sub parseFile
{
	my ($this, $file) = @_;

	# remember
	$this->{file} = $file;

	# read file.
	local ($/) = undef;
	local (*CONFIG);
	open (CONFIG, $file) || die "Cannot read $file ($!).\n";
	my $conf = (<CONFIG>);
	close CONFIG;

	$this->parse($conf);
}

sub parse
{
	my ($this, $conf) = @_;

	# Load the keywords
	%section	= map {$_ => 1} @{$this->{conf}->{section}};
	%boolean	= map {$_ => 2} @{$this->{conf}->{boolean}};
	%variable	= map {$_ => 3} @{$this->{conf}->{variable}};
	%array		= map {$_ => 4} @{$this->{conf}->{array}};
	%hash		= map {$_ => 5} @{$this->{conf}->{hash}};
	$THIS		= $this;

	# make a list of abbreviations.
	#%abbreviation = abbrev (@{$this->{conf}->{section}}, @{$this->{conf}->{boolean}}, @{$this->{conf}->{variable}}, @{$this->{conf}->{array}});

	my @keywords = ();
	for my $k (@categories)
	{
		push @keywords, @{$this->{conf}->{$k}};
	}
	%abbreviation = abbrev (@keywords);

	#print Dumper(\%abbreviation); exit;

	# initialise
	#@obj = ();	# stack.

	# Load the first object.
	unless (@{$this->{stack}})
	{
		# Create a configuration section object.
		my $first = new Config::Nested::Section (
			'+' => [],
		);

		# Add the members - cheating but works.
		for my $k ( @{$this->{conf}->{array}}) { $first->{$k} = []; }
		for my $k ( @{$this->{conf}->{hash}}) { $first->{$k} = {}; }
		for my $k ( @{$this->{conf}->{section}}) { $first->{$k} = ''; }
		for my $k ( @{$this->{conf}->{variable}}) { $first->{$k} = ''; }
		for my $k ( @{$this->{conf}->{boolean}}) { $first->{$k} = 0; }

		#warn "first=", Dumper($first);

		push @{$this->{stack}}, $first;
	}
	#&stack();

	# The configuration file grammar.
	 # This grammar started life as Config::Scoped but it didn't
	 # quite have the structure I needed.
#$::RD_HINT = 1;
#$::RD_ERRORS   =1;     # unless undefined, report fatal errors
#$::RD_WARN      =1;    # unless undefined, also report non-fatal problems
#$::RD_TRACE =1;        # if defined, also trace parsers' behaviour
#$::RD_AUTOSTUB     # if defined, generates "stubs" for undefined rules
#$::RD_AUTOACTION   # if defined, appends specified action to productions

	
	# Set the defaults directly.
	#$parser->program("
	#") || die "Error parsing defaults!\n";

	# remove any comments.
	$conf =~ s/#.*$//mg;
	$conf =~ s/^@.*$//mg;

	# Set up PARSER if needed.
	$PARSER = mkParser() unless $PARSER;

	# Parse the configuration file.
	$PARSER->program($conf) || return undef;

	#print "==========================\n", Dumper(\%todo); exit;
	#print "==========================\n", Dumper(\@obj);
	#print "====== Stack =============\n", Dumper($THIS->{stack}), "===========================\n\n";
	#exit;

	1;
}

sub mkParser
{
	my $grammar = q{

	program: 
	          <skip: qr{[^\S\n]*}x> statement(s) eofile
		   { $item[2] }

	statement: eol
	statement: section
	statement: boolean 

	statement: append
	statement: add
	statement: assign

	statement: hash
	statement: array
	statement: block
	statement: <error: Unknown command near "$text". Ignored.>

	block_start:
		'{'
		{ &Config::Nested::stack(); 1; }

	block:
		block_start statement(s) '}'
		{ &Config::Nested::unstack('block'); 1; }

	# This skip is important to allow sections to have blocks that
	# start on the next line.
	section_start: sectionname value <skip: '\s*'> '{'
		{
			# canonalise
			my $v = $item[1];

		  	&Config::Nested::stack();

			# array
			#push @{$Config::Nested::THIS->{stack}->[0]->{$v}}, $item[2];
			# scaler
			$Config::Nested::THIS->{stack}->[0]->{$v} = $item[2];

			# path
			push @{$Config::Nested::THIS->{stack}->[0]->{'+'}}, [ $v, $item[2] ];

			# Return the section name.
			$return = $v;

			1;
		}

	section:
		section_start statement(s?) '}'
		{
			#use Data::Dumper;
			#print '%arg=', Dumper(\%arg);
			#print '@arg=', Dumper(\@arg);
			#print '%item=', Dumper(\%item);
			#print '@item=', Dumper(\@item);

			&Config::Nested::save ($Config::Nested::THIS, $item[1], $Config::Nested::THIS->{stack}->[0]);

		  	&Config::Nested::unstack('section');
		}

	section: sectionname value
		{
			# canonalise
			my $v = $item[1];

			# Stack, update, save and unstack
		  	&Config::Nested::stack("section-eol $v");

			# Push this onto the section name array
			#push (@{$Config::Nested::obj[0]->{$v}}, $item[2]);
			# array
			#push @{$Config::Nested::THIS->{stack}->[0]->{$v}}, $item[2];
			# scaler
			$Config::Nested::THIS->{stack}->[0]->{$v} = $item[2];

			# path
			push @{$Config::Nested::THIS->{stack}->[0]->{'+'}}, [ $v, $item[2] ];

			# Save the obj.....
			&Config::Nested::save ($Config::Nested::THIS, $v, $Config::Nested::THIS->{stack}->[0]);

			# and unstack it.
		  	&Config::Nested::unstack('section-eol');

			1;
		}

	array:
		arrayname value(s?) eol
		{
			push (@{$Config::Nested::THIS->{stack}->[0]->{$item[1]}}, @{$item[2]});

			#&Config::Nested::debug "list '$return' found\n";

			1;
		}

	hash:
		hashname value value
		{
			$Config::Nested::THIS->{stack}->[0]->{$item[1]}->{$item[2]} = $item[3];

			1;
		}

	assign: 
		variable '=' value 
		{ $Config::Nested::THIS->{stack}->[0]->{$item[1]} =  $item[3]; 1; }

	assign: 
		variable value
		{ $Config::Nested::THIS->{stack}->[0]->{$item[1]} =  $item[2]; 1; }
		

	append: 
		variable '.=' value
		{ $Config::Nested::THIS->{stack}->[0]->{$item[1]} .=  $item[3]; 1; }
	add: 
		variable '+=' value
		{ $Config::Nested::THIS->{stack}->[0]->{$item[1]} +=  $item[3]; 1; }

	boolean:	'*' bool	{ $Config::Nested::THIS->{stack}->[0]->{"$item[2]"} = 1; 1; }
	boolean:	'!' bool	{ $Config::Nested::THIS->{stack}->[0]->{"$item[2]"} = 0; 1; }
	boolean:	bool		{ $Config::Nested::THIS->{stack}->[0]->{"$item[1]"} = 1; 1; }


	bool: keyword
		{
			return undef unless (exists($Config::Nested::boolean{$item[1]}));
			$return = $item[1];
			1;
		}

	sectionname: keyword
		{
			return undef unless (exists($Config::Nested::section{$item[1]}));
			$return = $item[1];
			1;
		}

	variable: keyword
		{
			return undef unless (exists($Config::Nested::variable{$item[1]}));
			$return = $item[1];
			1;
		}

	hashname: keyword
		{
			return undef unless (exists($Config::Nested::hash{$item[1]}));
			$return = $item[1];
			1;
		}

	arrayname: keyword
		{
			return undef unless (exists($Config::Nested::array{$item[1]}));
			$return = $item[1];
			1;
		}

	keyword: /\w+/
		{
			# Is it a legal keyword? Canonicalise
			my $kw = ($item[1]);
			return undef unless exists $Config::Nested::abbreviation{$kw};
			$return = $Config::Nested::abbreviation{$kw};

			1;
		}

	value:
		  /"([^"]*)"/ { $return = &Config::Nested::expand($1); 1; } |
		  /'([^']*)'/ { $return = $1; 1; } |
		  /[^\s;{}]+/ { $return = &Config::Nested::expand($item[1]); 1; }

	eol:
		';' | /\n+/

	eofile:
		/^\Z/
		{
			# unstack the final object.
		  	#Config::Nested::unstack('eof');
			1;
		}
	};

	# Load the grammar.
	my $parser = new Parse::RecDescent( $grammar ) || die "Bad grammar\n";
	#print Dumper($parser); exit;

	$parser;
}


# Takes a Config::Nested object, a section type and an array of config
# hashes and stores them in the onject.
sub save
{
	debug "Save: '", join("', '", @_), "'\n";

	my ($this) = shift;
	my ($section) = shift;

	push @{$this->{'section'}->{$section}}, @_;
	#print ref($this), ' ', Dumper ($this);
}

sub unstack
{
	my $label = join(' ', @_);

	my %obj = %{$THIS->{stack}->[0]};
	debug "\n------unstack $label-------\n", Dumper(\%obj), "\n\n";

	# forget the nested values.
	shift(@{$THIS->{stack}});
}

sub stack
{
	my $label = join(' ', @_);

	# duplicate the current values and put on the stack.
	# NB: we need a deep copy.
	#my $obj = dclone(\%{$obj[0]});
	my $obj = dclone(\%{$THIS->{stack}->[0]});

	unshift(@{$THIS->{stack}}, $obj);

	debug "\n------stack $label-------\n", Dumper(\$obj), "\n\n";
}

sub percent
{
	#print "expand ", join(', ', @_), "\n";

	local ($_);
	for (@_)
	{
		debug "in: $_\t";
		s/%(\w+)/exists($percent{$1}) ? $percent{$1} : ''/ge;
		debug "out: $_\n";
	}

	@_;
}

sub expand
{
	#print "expand ", join(', ', @_), "\n";
	local ($_) = @_;
	s/\$(\w+)/&_expand($1)/ge;

	$_;
}

sub _expand
{
	#print "_expand ", join(', ', @_), "\n";
	return $::obj[0]->{$_[0]} if (exists $::obj[0]->{$_[0]});
	return $ENV{$_[0]} if (exists $ENV{$_[0]});
	'';
}


}

=pod

=head1 SEE ALSO

Parse::RecDescent, Config::Scoped.

=cut

1;

