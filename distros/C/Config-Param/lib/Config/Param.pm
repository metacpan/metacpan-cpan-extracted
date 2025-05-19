# This has been a simple routine for command line and config file parsing.
# Now it deals with differing styles (grades of laziness) of command line parameters,
# has funky operators on them, and is a tool box to work with other program's config files.

# It also carries a badge with the inscript "NIH syndrome".
# On the backside, you can read "But still better than anything that came before!".

# current modus operandi:
# 1. parse command line args into temporary storage
# 2. parse config files (that may have been set on command line)
# 3. merge settings (overwrite config file settings)
# 4. finalize with help/error message

# TODO: I got sections now. A next step could be sub-commands, presented as sections
# in help output and also defined like/with those. Needs some namespacing, though.
# Maybe just sub-instances of Config::Param.

# TODO: I should restructure the the internal data. It's too many hashes now
# with the same key. Nested hash or better array with named indices (to avoid typos and
# less wasteful storage)?

# TODO: --config with append mode, by config option

package Config::Param;

use strict;
use warnings;

use Carp;
use 5.008;
# major.minor.bugfix, the latter two with 3 digits each
# or major.minor_alpha
our $VERSION = '4.000006';
$VERSION = eval $VERSION;
our %features = qw(array 1 hash 1);

our $verbose = 0; # overriding config

# parameter flags
our $count  = 1;
our $arg    = 2;
our $switch = 4;
our $append = 8;
our $nonempty = 16;

# using exit values from sysexists.h which make sense
# for configuration parsing
my $ex_usage  = 64;
my $ex_config = 78;
my $ex_software = 70;

use Sys::Hostname;
use FindBin qw($Bin);
use File::Spec;
use File::Basename;

# The official API for simple use:

# This is the procedural interface: Just call get() with your setup and get the pars.
sub get #(config, params)
{
	# Handling of the differing API variants
	# 1. just plain list of parameter definitions
	# 2. config hash first, then parameter definitions
	# 3. config hash, then array ref for definitions
	#   ... in that case, optional ref to argument array to parse
	my $config = ref $_[0] eq 'HASH' ? shift : {};
	my $pardef;
	my $args = \@ARGV;
	my $give_error;
	if(ref $_[0] eq 'ARRAY')
	{
		$pardef = shift;
		if(ref $_[0] eq 'ARRAY')
		{
			$args = shift;
			$give_error = 1;
		}
	}
	else{ $pardef = \@_; }

	my $pars = Config::Param->new($config, $pardef);
	# Aborting on bad specification. Not sensible to continue.
	# Match this with documentation in POD.
	my $bad = not (
		    $pars->good()
		and $pars->parse_args($args)
		and $pars->use_config_files()
		and $pars->apply_args()
		and $pars->INT_value_check()
	);
	$pars->final_action($bad);

	$_[0] = $pars->{errors} if $give_error;
	return $pars->{param};
}

# Now the meat.

# Codes for types of parameters. It's deliberate that simple scalars are false and others are true.
my $scalar = 0; # Undefined also counts as scalar.
my $array = 1;
my $hash = 2;
my @initval  = (undef, [], {});
#This needs to be changed. Also for a hash, --hash is equivalent to --hash=1, which
#results in 1=>undef, not truth=>1
my @trueval  = (1, [1], {truth=>1});
my @falseval = (0, [0], {truth=>0});
my @typename = ('scalar', 'array', 'hash');
my %typemap  = (''=>$scalar, scalar=>$scalar, array=>$array, hash=>$hash);

# A name is allowed to contain just about everything but "=", but shall not end with something that will be mistaken for an operator.
# The checks for valid names besides the generic regexes are stricter and should be employed in addition.

# Parser regex elements.
# Generally, it's optinal operators before "=" or just operators for short parameters.
# The addition with /./ is for choosing an arbitrary array separator for the value.
# Since long names are not allowed to end with an operator, using "/" that way is
# no additional restriction.
# Context is needed to decide for /,/ and // with special function for arrays and hashes.
# The grammar is not context-free anymore. Meh.
# Well, treating it this way: // is a special operator for long names,
# // is parsed as /=/, then interpreted accordingly for arrays as //.
my $ops = '.+\-*\/'; # There's also <<endtext as special thing in config file.
my $sopex = '['.$ops.']?=|['.$ops.']=?';
my $lopex = '\/.\/['.$ops.']?=|['.$ops.']?=|\/\/|\/.\/';
my $noop = '[^+\-=.*\/\s<>]'; # a non-whitespace character that is unspecial
my $parname = $noop.'[^\s=\/<>]*'.$noop;

# Regular expressions for parameter parsing.
# The two variants are crafted to yield matching back-references.
# -x -x=bla -xyz -xyz=bla
our $shortex_strict = qr/^(([-+])($noop+|($noop+)($sopex)(.*)))$/;
# -x -x=bla -xyz x x=bla xyz
our $shortex_lazy   = qr/^(([-+]?)($noop+|($noop)($sopex)(.*)))$/;
# -xbla with x possibly arg-requiring option and bla an argument
our $shortarg = qr/^[-+]($noop)($sopex|)(.+)$/;
# --long --long=bla
our $longex_strict  = qr/^(([-+]{2})($parname)(($lopex)(.*)|))$/;
# --long --long=bla -long=bla long=bla
our $longex_lazy    = qr/^(([-+]{0,2})($parname)()($lopex)(.*)|(--|\+\+)($parname))$/;

my %example = 
(
	 'lazy'   => '[-]s [-]xyz [-]s=value --long [-[-]]long=value - [files/stuff]'
	,'normal' => '-s -xyz -s=value --long --long=value [--] [files/stuff]'
);
my $lazyinfo = "The [ ] notation means that the enclosed - is optional, saving typing time for really lazy people. Note that \"xyz\" as well as \"-xyz\" mention three short options, opposed to the long option \"--long\". In trade for the shortage of \"-\", the separator for additional unnamed parameters is mandatory (supply as many \"-\" grouped together as you like;-).";

my @morehelp =
(
	 'You mention the options to change parameters in any order or even multiple times.'
,	' They are processed in the oder given, later operations overriding/extending earlier settings.'
,	' Using the separator "--" stops option parsing'."\n"
	,'An only mentioned short/long name (no "=value") means setting to 1, which is true in the logical sense. Also, prepending + instead of the usual - negates this, setting the value to 0 (false).'."\n"
	,'Specifying "-s" and "--long" is the same as "-s=1" and "--long=1", while "+s" and "++long" is the sames as "-s=0" and "--long=0".'."\n"
	,"\n"
	,'There are also different operators than just "=" available, notably ".=", "+=", "-=", "*=" and "/=" for concatenation / appending array/hash elements and scalar arithmetic operations on the value. Arrays are appended to via "array.=element", hash elements are set via "hash.=name=value". You can also set more array/hash elements by specifying a separator after the long parameter line like this for comma separation:'."\n\n"
	,"\t--array/,/=1,2,3  --hash/,/=name=val,name2=val2"
);

# check if long/short name is valid before use
sub valid_name
{
	my ($long, $short) = @_;
	return 
	(
		(not defined $short or $short eq '' or $short =~ /^$noop$/o)
		and defined $long
		and $long =~ /^$parname/o
	);
}

sub valid_type
{
	my $type = lc(ref $_[0]);
	return $typemap{$type}; # undefined if invalid
}

# A valid definition also means that the default value type
# must match a possibly specified type.
sub valid_def
{
	my $def = shift;
	$_[0] = (defined $def->{type} and not defined $def->{value})
	?	$def->{type}
	:	valid_type($def->{value});
	return
	(
		valid_name($def->{long}, $def->{short}) and defined $_[0]
		and ( not defined $def->{type} or ($def->{type} ne $_[0]) )
		and ( not defined $def->{regex} or ref $def->{regex} eq 'Regexp')
		and ( not defined $def->{call} or ref $def->{call} eq 'CODE' )
	);
}

sub hashdef
{
	my %h = (     long=>shift, value=>shift,  short=>shift
	,             help=>shift,   arg=>shift,  flags=>shift
	,         addflags=>shift, level=>shift
	,            regex=>shift,  call=>shift );
	$h{short} = '' unless defined $h{short};
	$h{flags} = 0  unless defined $h{flags};
	return \%h;
}

sub builtins
{
	my $config = shift;
	my %bldi = (help=>1, h=>1, I=>1, config=>1);
	$bldi{version} = 1 if(defined $config and defined $config->{version});
	return \%bldi;
}

# helper for below
sub INT_defchecker
{
	my $def = shift;
	my $name_there = shift;
	my $short = defined $def->{short} ? $def->{short} : '';

	return ''
		if defined $def->{section};
	return "'".(defined $def->{long} ? $def->{long} : '')."' definition is not good"
		unless valid_def($def);
	return "'$def->{long}' ".(defined $def->{short} ? "/ $def->{short}" : '')." name already taken"
		if($name_there->{$def->{long}} or $name_there->{$short});
	$name_there->{$def->{long}} = 1
		if defined $def->{long};
	$name_there->{$short} = 1 if $short ne '';

	return ''; # no problem
}

# check if whole definition array is proper,
# modifying the argument to sanitize to canonical form
# That form is an array of definition hashes.
sub sane_pardef
{
	my $config = shift;
	my $name_there = builtins($config);
	my $indef = $_[0];
	$_[0] = []; # If an error comes, nothing is sane.
	if(@{$indef})
	{
		if(ref $indef->[0] ne '')
		{
			# each element is a ref, check them all
			for my $d (@{$indef})
			{
				my $t = ref $d;
				return 'mix of array/hash and other stuff'
					if($t eq '');
				return 'strange refs, neither hash nor array'
					if($t ne 'ARRAY' and $t ne 'HASH');

				my $def = $t eq 'ARRAY' ? hashdef(@{$d}) : $d;
				my $problem = INT_defchecker($def, $name_there);
				$d = $def;
				return $problem if $problem;
			}
		}
		else
		{
			return 'plain member count not multiple of 4' if(@{$indef} % 4);

			my @spars = ();
			while(@{$indef})
			{
				my $sdef;
				my $def = hashdef(splice(@{$indef}, 0, 4));
				my $problem = INT_defchecker($def, $name_there);
				return $problem if $problem;
				push(@spars, $def);
			}
			$indef = \@spars;
		}
	}
	$_[0] = $indef; # only after full success
	return '';
}

sub escape_pod
{
	return undef unless defined $_[0];
	my @text = split("\n", shift, -1);
	for(@text)
	{
		next if m/^\s/; # indented stuff is verbatim
		s/^=(\w)/=Z<>$1/;
		s/([A-Z])</$1Z<></g;
	}
	return join("\n", @text);
}

# Following: The OO API for detailed work.

sub new # strictly (\%config, \@pardef)
{
	my $class = shift;
	my $self = {};
	bless $self, $class;

	$self->{config} = shift;
	$self->{config} = {} unless defined $self->{config};
	my $pars = shift;
	$pars = [] unless defined $pars;
	$self->{files} = [];
	$self->{errors} = [];

	$self->{config}{program} = basename($0) unless defined $self->{config}{program};
	$self->{config}{shortdefaults} = 1 unless exists $self->{config}{shortdefaults};
	$self->{printconfig} = 0;
	my $hh = 'Show the help message. Value 1..9: help level, par:'
	.	' help for paramter par (long name) only.';
	$self->{extrahelp} = 'Additional fun with negative values, optionally'
	.	' followed by comma-separated list of parameter names:'."\n"
	.	'-1: list par names, -2: list one line per name,'
	.	' -3: -2 without builtins, -10: dump values (Perl style),'
	.	' -11: dump values (lines), -100: print POD.';
	my $ih = 'Which configfile(s) to use (overriding automatic search'
	.	' in likely paths);'."\n"
	.	'special: just -I or --config causes printing a current config'
	.	' file to STDOUT';

	if($self->{config}{lazy} and $self->{config}{posixhelp})
	{
		$self->INT_error("POSIX-style help texts and lazy parameter syntax are incompatible.");
		$self->{config}{posixhelp} = 0;
	}
	# Put -- in front of long names in communication, in POSIX mode.
	$self->{longprefix} = $self->{config}{posixhelp} ? '--' : '';
	# Same for - and short names.
	$self->{shortprefix} = $self->{config}{posixhelp} ? '-' : '';
	# An array of sections, with {name=>foo, member=>[$long1, $long2, ...]}.
	# If I opted for 
	$self->{section} = [];
	# Start the default, nameless section. Maybe a name should be generated if there
	# are other sections.
	$self->define({ section=>'', level=>1, flags=>$self->{config}{flags}
	,	regex=>$self->{config}{regex}, call=>$self->{config}{call} });

	# Choosing kindof distributed storage of parmeter properties, for direct
	# access. With more and more properties, the count of global hashes
	# increases uncomfortably.
	$self->{param} = {}; # parameter values
	$self->{help}  = {}; # help texts
	$self->{long}  = {}; # map short to long names
	$self->{short} = {}; # map long to short names
	$self->{arg}   = {}; # argument name
	$self->{type}  = {}; # type code
	# store default values, for even more detailed documentation
	$self->{default} = {};  # default value
	$self->{level} = {};    # parameter level for help output
	$self->{length} = 0;    # max length of long names
	$self->{arglength} = 0; # max length of name=arg or name[=arg]
	# Chain of config files being parsed, to be able to check for inclusion loops.
	$self->{parse_chain} = [];
	# TODO set from config hash
	$self->define({ long=>'help',   short=>$self->{config}{shortdefaults} ? 'h' : '', value=>0
	,	help=>\$hh, flags=>0, regex=>qr/./ });
	$self->define(
	{
		long=>'config', short=>$self->{config}{shortdefaults} ? 'I' : '', value=>[]
	,	help=>\$ih, flags=>0, regex=>qr/./
	,	call=> sub
		{ # --config increments printconfig and does not add a config file.
			unless(defined $_[2])
			{
				$self->{printconfig} += 1;
				undef $_[0]; # Skip this operation.
			}
			return 0;
		}
	});
	$self->define({ long=>'version', value=>0, short=>''
	,	help=>\'print out the program version', arg=>''
	,	flags=>0, regex=>qr/./ })
		if(defined $self->{config}{version});

	# deprecated v2 API
	$self->INT_error("Update your program: ignorehelp is gone in favour of nofinals!")
		if exists $self->{config}{ignorehelp};
	$self->INT_error("Update your program: eval option not supported anymore.")
		if exists $self->{config}{eval};

	my $problem = sane_pardef($self->{config}, $pars);
	if($problem)
	{
		$self->INT_error("bad parameter specification: $problem");
	} else
	{
		my $di = 0;
		for my $def (@{$pars})
		{
			++$di;
			# definition failure here is an error in the module
			$self->INT_error("Very unexpected failure to evaluate parameter definition $di.")
				unless($self->define($def));
		}
		$self->find_config_files();
	}
	return $self;
}

sub good
{
	my $self = shift;
	return @{$self->{errors}} == 0;
}

# name[=arg] and variants
sub INT_namearg
{
	my $self = shift;
	my $name = shift;
	my $flags = $self->{flags}{$name};
	my $val= $self->{arg}{$name};
	$val = 'val' unless defined $val;
	return $flags & $arg
	?	$name.'='.$val # mandatory argument
	:	( $val eq ''
		?	$name      # silent optional argument
		:	$name.'[='.$val.']' ) # named optional argument
}

sub define
{
	my $self = shift;
	my $pd = shift;

	my $helpref = defined $pd->{help}
	?	( ref $pd->{help} ? $pd->{help} : \$pd->{help} )
	:	\"";
	# The section keyword defines a section instead of a parameter.
	if(exists $pd->{section})
	{
		# Silence runs with perl -W. Actually, I'm annoyed that 0+undef isn't
		# doing this already. Still doing 0+ to catch idle strings, which are
		# evildoing by the user program.
		my $flags = defined $pd->{flags} ? 0+$pd->{flags} : 0;
		my $level = defined $pd->{level} ? 0+$pd->{level} : 0;
		# The first section is the default one, any further sections mean
		# that you care about parameter order.
		$self->{config}{ordered} = 1
			if @{$self->{section}};
		push(@{$self->{section}}, { section=>$pd->{section}
		,	help=>$helpref, level=>$level
		,	minlevel=>10 # will be lowered when parameters are added to it
		,	flags=>$flags, regex=>$pd->{regex}, call=>$pd->{call} });
		return 1;
	}

	unless(@{$self->{section}})
	{
		$self->INT_error("Define the default section first!");
		return 1;
	}

	my $section = $self->{section}[$#{$self->{section}}];
	my $name = $pd->{long};

	$pd->{help} = \'' unless defined $pd->{help};
	$pd->{short} = '' unless defined $pd->{short};
	my $type; # valid_def sets that
	unless(valid_def($pd, $type))
	{
		$self->INT_error("Invalid definition for $name / $pd->{short}");
		return 0;
	}
	my $flags = defined $pd->{flags}
		?	$pd->{flags}
		:	$section->{flags};
	$flags |= $pd->{addflags}
		if defined $pd->{addflags};
	my $regex = defined $pd->{regex}
	?	$pd->{regex}
	:	$section->{regex};
	my $call  = defined $pd->{call}
	?	$pd->{call}
	:	$section->{call};
	if($flags & $switch and $flags & $arg)
	{
		$self->INT_error("Invalid flags (switch requiring argument) for $name / $pd->{short}");
		return 0;
	}
	unless(defined $self->{param}{$name} or defined $self->{long}{$pd->{short}})
	{
		$self->{type}{$name}  = $type;
		# If the definition value is a reference, make a deep copy of it
		# instead of copying the reference. This keeps the definition
		# and default value unchanged, for reproducible multiple runs of
		# the parser.
		if(ref $pd->{value})
		{
			require Storable; # Only require it if there is really the need.
			$self->{param}{$name}   = Storable::dclone($pd->{value});
			$self->{default}{$name} = Storable::dclone($pd->{value});
		}
		else
		{
			$self->{param}{$name} = $pd->{value};
			$self->{default}{$name} = $pd->{value};
		}
		$self->{long}{$pd->{short}} = $name
			if $pd->{short} ne '';
		$self->{short}{$name} = $pd->{short};
		$self->{help}{$name}  = $helpref;
		$self->{arg}{$name}   = $pd->{arg};
		my $lev = $self->{level}{$name} = 0+( defined $pd->{level}
		?	$pd->{level}
		:	$section->{level} );
		# Store the minimum level needed to display at least one section member.
		$section->{minlevel} = $lev
			if $lev < $section->{minlevel};
		$self->{flags}{$name} = $flags;
		$self->{arg}{$name} = ''
			if $self->{flags}{$name} & $switch;
		push(@{$section->{member}}, $name);
		$self->INT_verb_msg("define $name / $pd->{short} of type $typename[$type] flags $self->{flags}{$name}\n");
		# Call INT_namearg after settling flags!
		$self->{length}       = length($name)
			if length($name) > $self->{length};
		my $arglen = length($self->INT_namearg($name));
		$self->{arglength}    = $arglen
			if $arglen > $self->{arglength};
		$self->{regex}{$name} = $regex
			if defined $regex;
		$self->{call}{$name}  = $call
			if defined $call;
	}
	else
	{
		$self->INT_error("Tried to redefine an option ($pd->{long} / $pd->{short}! Programmer: please check this!");
		return 0;
	}
	return 1;
}

sub find_config_files
{
	my $self = shift;

	if(defined $self->{config}{file})
	{
		@{$self->{param}{config}} = ref $self->{config}{file} eq 'ARRAY'
			? @{$self->{config}{file}}
			: ($self->{config}{file});
	}
	#means: nofile[false,true], file[string], info, verbose[bool],  
	#config confusion
	# as long as I was told not to use a config file or it has been already given
	unless($self->{config}{nofile} or @{$self->{param}{config}})
	{
		# Default to reading program.conf and/or program.host.conf if found.
		my $pconf = $self->INT_find_config($self->{config}{program}.'.conf');
		my $hconf = $self->INT_find_config($self->{config}{program}.'.'.hostname().'.conf');
		my @l;
		push(@l, $pconf) if defined $pconf;
		push(@l, $hconf) if defined $hconf;
		# That list can be empty if none existing.
		$self->INT_verb_msg("possible config files: @l\n");
		# The last entry in the list has precedence.
		unless($self->{config}{multi})
		{
			@l = ($l[$#l]) if @l; # Only the last element, if any, prevails.
		}
		@{$self->{param}{config}} = @l;
	}
}

# Parse abcd to the list of corresponding long names.
sub INT_long_names
{
	my $self  = shift;
	my $sname = shift;
	my @names;
	for my $s (split(//,$sname))
	{
		if(defined (my $name = $self->{long}{$s}))
		{
			push(@names, $name);
		}
		else
		{
			if($self->{config}{fuzzy})
			{
				$self->INT_verb_msg("Unknown short option $s, assuming that this is data instead.\n");
				@names = ();
				last;
			}
			else
			{
				unless($self->{config}{ignore_unknown} and $self->{config}{ignore_unknown} > 1)
				{
					#$self->{param}{help} = 1;
					$self->INT_error("unknown short parameter \"$s\" not in (".join('', sort keys %{$self->{long}}).")");
				}
			}
		}
	}
	return \@names;
}

# Works directly on last arguments to avoid passing things back and forth.
sub INT_settle_op # (lastoption, sign, name, op, val, args)
{
	my $self = shift;
	my $lastoption = shift;
	my $sign = shift;
	my $name = shift;
	# op:$_[0] val:$_[1] args:$_[2]
	my $flags = $self->{flags}{$name};
	my $arrhash = defined $self->{type}{$name}
		and grep {$_==$self->{type}{$name}} ($array, $hash);

	# First settle a possibly enforced argument that has to follow.
	# Then call the custom callback that could change things

	if(defined $_[0] and $arrhash)
	{
		# -a/,/=bla and -a/,/bla are equivalent, as is -a/,/ bla
		if($_[0] eq '/' and $_[1] =~ m:(./)(=?)(.*):)
		{
			$_[0] .= $1.$2;
			$_[1] = ($3 eq '' and $2 eq '') ? undef : $3;
			$_[0] .= '='
				if($2 eq '' and defined $_[1]);
		}
		if($_[0] =~ m:^/./$: and $flags & $arg)
		{
			unless(@{$_[2]})
			{
				$self->INT_error( "Array/hash missing explicit argument: $self->{longprefix}$name"
				.	($self->{short}{$name} ne '' ? " ($self->{shortprefix}$self->{short}{$name})" : '') );
				return;
			}
			$_[0] .= '=';
			$_[1] = shift @{$_[2]};
		}
	} elsif(not defined $_[0] and $flags & $arg)
	{
		unless($lastoption and @{$_[2]})
		{
			$self->INT_error( "Parameter missing explicit argument: $self->{longprefix}$name"
			.	($self->{short}{$name} ne '' ? " ($self->{shortprefix}$self->{short}{$name})" : '') );
			return;
		}
		$_[0] = '=';
		$_[1] = shift @{$_[2]};
	}

	# Defined empty value with undefined operator is just confusing to the callback.
	undef $_[1]
		unless defined $_[0];

	# The callback that could modify things.

	if(defined $self->{call}{$name})
	{
		my $nname = $name;
		my $ret = $self->{call}{$name}->($nname, $sign, $_[0], $_[1]);
		if($ret or (not defined $nname or $nname ne $name))
		{
			$self->INT_error("Callback for $name returned an error: $ret")
				if $ret; # otherwise intentional drop
			undef $_[0];
			return;
		}
	}

	# Final translation of operator.

	unless(defined $_[0])
	{
		if($flags & $count)
		{
			($_[0], $_[1]) = $sign =~ /^-/ ? ('+=', 1) : ('=', 0);
		}
		else
		{
			$_[0] = '=';
			$_[1] = $sign =~ /^-/ ? 1 : 0;
		}
	}
	if($arrhash)
	{
		$_[0] =~ s:(^|[^\.])=$:$1.=:
			if $self->{flags}{$name} & $append;
	}
}

# Record a operator and operand for given parameter.
# It is not checked if the operation makes sense.
sub INT_add_op
{
	my $self = shift;
	my ($name, $op, $val) = (shift, shift, shift);
	$self->{ops}{$name} = []
		unless defined $self->{ops}{$name};
	return # undefined ops are intentionally dropped
		unless defined $op;
	$self->INT_verb_msg("name: $name op: $op (val: $val)\n");
	push(@{$self->{ops}{$name}}, ($op =~ /=$/ ? $op : $op.'='), $val);
}

# Step 1: parse command line
sub parse_args
{
	my $self = shift;
	my $args = shift;

	my $olderrs = @{$self->{errors}};
	$self->{ops} = {};
	$self->{printconfig} = 0;

	$self->{param}{help} = 1 if($self->{config}{gimme} and not @{$args}); #giving help when no arguments

	#regexes for option parsing
	my $shorts = $shortex_strict;
	my $longex = $longex_strict;
	my $separator = '^--$'; #exactly this string means "Stop the parsing!"

	if($self->{config}{lazy})
	{
		$shorts = $shortex_lazy;
		$longex = $longex_lazy;
		$separator = '^-+$'; # Lazy about separators, too ... Any number of consecutive "-".
	}

	# The argument parser, long/short parameter evaluation is similar, but separate.
	while(@{$args})
	{
		$self->INT_verb_msg("parsing $args->[0]\n");
		my $e = index($args->[0], "\n");
		my $begin;
		my $end = "";
		my $name;
		if($e >=0)
		{
			$begin = substr($args->[0],0,$e);
			$end   = substr($args->[0],$e);
		}
		else
		{
			$begin = $args->[0];
		}
		if($begin =~ /$separator/o)
		{
			$self->INT_verb_msg("separator\n");
			shift(@{$args});
			last;
		}
		elsif( $begin =~ $shortarg
			and defined ($name = $self->{long}{$1})
			and $self->{flags}{$name} & $arg )
		{
			$self->INT_verb_msg("short with value\n");
			my $op = $2 ne '' ? $2 : '=';
			my $val = $3.$end;
			shift @{$args};
			$self->INT_settle_op(1, '-', $name, $op, $val, $args);
			$self->INT_add_op($name, $op, $val);
		}
		elsif($begin =~ /$shorts/o)
		{
			my $sign = $2;
			$sign = '-' if $sign eq '';
			my $op = $5;
			my $sname = defined $op ? $4 : $3;
			my $val = (defined $6 ? $6 : '').$end;
			$self->INT_verb_msg("a (set of) short one(s)\n");
			# First settle which parameters are mentioned.
			# This returns an empty list if one invalid option is present.
			# Also, the case of a single argument-requiring short option leading
			# a value is handled by redefining the value and operator
			my $names = $self->INT_long_names($sname, $op, $val);
			last unless @{$names};
			shift @{$args}; # It is settled now that this is options.

			while(@{$names})
			{
				my $olderr = @{$self->{errors}};
				my $name = shift @{$names};
				my $lastoption = not @{$names};
				# Only the last one gets the specified operation.
				my $kop  = $lastoption ? $op  : undef;
				my $kval = $lastoption ? $val : undef;
				$self->INT_settle_op($lastoption, $sign, $name, $kop, $kval, $args);
				$self->INT_add_op($name, $kop, $kval)
					if(@{$self->{errors}} == $olderr);
			}
		}
		elsif($begin =~ $longex)
		{
			#yeah, long option
			my $olderr = @{$self->{errors}};
			my $sign = defined $7 ? $7 : $2;
			$sign = '--' if $sign eq '';
			my $name = defined $8 ? $8 : $3;
			$self->INT_verb_msg("param $name\n");
			my $op = $5;
			my $val = (defined $6 ? $6 : '').$end;
			unless(exists $self->{param}{$name} or $self->{config}{accept_unknown})
			{
				if($self->{config}{fuzzy})
				{
					$self->INT_verb_msg("Stopping option parsing at unkown one: $name");
					last;
				}
				else
				{
					unless($self->{config}{ignore_unknown} and $self->{config}{ignore_unknown} > 1)
					{
						$self->INT_error("Unknown parameter (long option): $name");
					}
				}
			}
			shift @{$args};
			# hack for operators, regex may swallow the . in .=
			unless($name =~ /$noop$/o)
			{
				$op = substr($name,-1,1).$op;
				$name = substr($name,0,length($name)-1);
			}
			# On any error, keep parsing for giving the user a full list of errors,
			# but do not process anything erroneous.
			$self->INT_settle_op(1, $sign, $name, $op, $val, $args)
				if(@{$self->{errors}} == $olderr);
			$self->INT_add_op($name, $op, $val)
				if(@{$self->{errors}} == $olderr);
		}
		else
		{
			$self->INT_verb_msg("No parameter, end.\n");
			last;
		} #was no option... consider the switch part over
	}
	$self->{bad_command_line} = not (@{$self->{errors}} == $olderrs)
		unless $self->{bad_command_line};
	return not $self->{bad_command_line};
}

# Step 2: Read in configuration files.
sub use_config_files
{
	my $self = shift;
	my $olderr = @{$self->{errors}};
	# Do operations on config file parameter first.
	$self->INT_apply_ops('config');
	my $newerr = @{$self->{errors}};
	if($olderr != $newerr)
	{
		$self->{bad_command_line} = 1;
		return 0;
	}
	# Now parse config file(s).
	return $self->INT_parse_files();
}

# Step 3: Apply command line parameters.
# This is complicated by accept_unknown > 2.
# I need to wait until config files had the chance to define something properly.
sub apply_args
{
	my $self = shift;
	my $olderrs = @{$self->{errors}};
	for my $key (keys %{$self->{ops}})
	{
		if( not exists $self->{param}{$key}
			and defined $self->{config}{accept_unknown}
			and $self->{config}{accept_unknown} > 1 )
		{
			$self->define({long=>$key});
		}
		if(exists $self->{param}{$key})
		{
			$self->INT_apply_ops($key);
		}
		elsif(not $self->{config}{ignore_unknown})
		{
			$self->INT_error("Unknown long parameter \"$self->{longprefix}$key\"");
		}
	}
	$self->{bad_command_line} = not (@{$self->{errors}} == $olderrs)
		unless $self->{bad_command_line};
	return not $self->{bad_command_line};
}

# Step 4: Take final action.
sub final_action
{
	my $self = shift;
	my $end = shift;
	return if($self->{config}{nofinals});

	my $handle = $self->{config}{output};
	$handle = \*STDOUT
		unless defined $handle;
	my $exitcode = @{$self->{errors}}
	?	( $self->{bad_command_line}
		?	$ex_usage
		:	($self->{bad_config_file} ? $ex_config : $ex_software)
		)
	:	0;

	if($end)
	{
		if(@{$self->{errors}})
		{
			$self->INT_error("There have been errors in parameter parsing. You should seek --help.");
		}
		exit($exitcode)
			unless $self->{config}{noexit};
		return;
	}

	#give the help (info text + option help) and exit when -h or --help was given
	if($self->{param}{help})
	{
		$self->help();
		exit($exitcode)
			unless $self->{config}{noexit};
	}
	elsif(defined $self->{config}{version} and $self->{param}{version})
	{
		print $handle "$self->{config}{program} $self->{config}{version}\n";
		exit($exitcode)
			unless $self->{config}{noexit};
	}
	elsif($self->{printconfig})
	{
		$self->print_file($handle, ($self->{printconfig} > 1));
		exit($exitcode) 
			unless $self->{config}{noexit};
	}
}

# Helper functions...

# Produce a string showing the value of a parameter, for the help.
sub par_content
{
	my $self = shift;
	my $k = shift; # The parameter name.
	my $format = shift; # formatting choice
	my $indent = shift; # indent value for dumper
	my $mk = shift; # value selector: 'param' or 'default', usually
	$mk = 'param'
		unless defined $mk;
	if(not defined $format or $format eq 'dump')
	{
		if(eval { require Data::Dumper })
		{
			no warnings 'once'; # triggers when embedding the module
			local $Data::Dumper::Terse = 1;
			local $Data::Dumper::Deepcopy = 1;
			local $Data::Dumper::Indent = $indent;
			$Data::Dumper::Indent = 0 unless defined $Data::Dumper::Indent;
			local $Data::Dumper::Sortkeys = 1;
			local $Data::Dumper::Quotekeys = 0;
			return Data::Dumper->Dump([$self->{$mk}{$k}]);
		}
		else{ return "$self->{$mk}{$k}"; }
	}
	elsif($format eq 'lines')
	{
		return "\n" unless(defined $self->{$mk}{$k});
		if($self->{type}{$k} == $array)
		{
			return "" unless @{$self->{$mk}{$k}};
			return join("\n", @{$self->{$mk}{$k}})."\n";
		}
		elsif($self->{type}{$k} == $hash)
		{
			my $ret = '';
			for my $sk (sort keys %{$self->{$mk}{$k}})
			{
				$ret .= "$sk=$self->{$mk}{$k}{$sk}\n";
			}
			return $ret;
		}
		else{ return "$self->{$mk}{$k}\n"; }
	} else{ $self->INT_error("unknown par_content format: $format"); }
}

# Fill up with given symbol for pretty indent.
sub INT_indent_string
{
	my ($indent, $prefill, $filler) = @_;
	$filler = '.'
		unless defined $filler;
	return ($indent > $prefill)
		? ( ($prefill and ($indent-$prefill>2)) ? $filler : ' ')
			x	($indent - $prefill - 1) . ' '
		: '';
}

# simple formatting of some lines (breaking up with initial and subsequent indendation)
sub INT_wrap_print
{
	my ($handle, $itab, $stab, $length) = (shift, shift, shift, shift);
	return unless @_;
	# Wrap if given line length can possibly hold the input.

	# Probably I will make this more efficient in future, probably also
	# dropping Text::Wrap instead of fighting it. Or use some POD formatting?
	my @paragraphs = split("\n", join("", @_), -1);
	# Drop trailing empty lines. We do not wrap what.
	while(@paragraphs and $paragraphs[$#paragraphs] eq '')
	{
		pop @paragraphs;
	}
	my $first = 1;
	print $handle $itab;
	print $handle "\n"
		unless @paragraphs;
	my $line = undef;
	my $llen = length($itab);
	my $slen = length($stab);
	my $can_wrap = $length > $llen && $length > $slen;
	while(@paragraphs)
	{
		my $p = shift(@paragraphs);
		# Try to handle command line/code blocks by not messing with them.
		if($p =~ /^\t/)
		{
			print $handle (defined $line ? $line : '')."\n"
				if $llen;
			print $handle $stab.$p."\n";
			$line = '';
			$llen = 0;
		}
		elsif($p eq '')
		{
			print $handle (defined $line ? $line : '')."\n";
			$line = '';
			$llen = 0;
		}
		elsif($can_wrap)
		{
			my @words = split(/\s+/, $p);
			while($llen>$slen or @words)
			{
				my $w = shift(@words);
				my $l = length($w);
				if(not $l or $l+$llen >= $length)
				{
					print $handle (defined $line ? $line : '')."\n";
					$llen = 0;
					$line = '';
					$first = 0;
				}
				if($l)
				{
					unless(defined $line)
					{
						$line = '';
					}
					elsif($llen)
					{
						$line .= ' ';
						$llen += 1;
					}
					else
					{
						$line = $stab;
						$llen = $slen;
					}
					$line .= $w;
					$llen += $l;
				}
			}
			$line = '';
			$llen = 0;
		}
		else # wrapping makes no sense
		{
			print $handle (defined $line ? $line : '').$p."\n";
			$line = '';
			$llen = 0;
		}
	}
}

# Produce wrapped text from POD.
sub INT_pod_print
{
	my ($handle, $length) = (shift, shift);
	require Pod::Text;
	my $pod = Pod::Text->new(width=>$length);
	$pod->output_fh($handle);
	$pod->parse_string_document($_[0]);
}

# Produce POD output from text.
sub print_pod
{
	my $self = shift;
	my $handle = $self->{config}{output};
	$handle = \*STDOUT unless defined $handle;

	my $prog = escape_pod($self->{config}{program});
	my $tagline = escape_pod($self->{config}{tagline});
	# usage line is unescaped
	my $usage = $self->{config}{usage};
	my @desc = (); # usage might come from here
	@desc = split("\n", $self->{config}{info}, -1)
		if(defined $self->{config}{info});

	$tagline = escape_pod(shift @desc)
		unless(defined $tagline or not defined $prog);

	while(@desc and $desc[0] =~ /^\s*$/){ shift @desc; }

	unless(defined $usage or not @desc)
	{
		if(lc($desc[0]) =~ /^\s*usage:\s*(.*\S?)\s*$/)
		{
			$usage = $1 if $1 ne '';
			shift(@desc);
			while(@desc and $desc[0] =~ /^\s*$/){ shift @desc; }

			# if the real deal follows on a later line
			if(not defined $usage and @desc)
			{
				$usage = shift @desc;
				$usage =~ s/^\s*//;
				$usage =~ s/\s*$//;
				while(@desc and $desc[0] =~ /^\s*$/){ shift @desc; }
			}
		}
	}
	if(defined $prog)
	{
		print $handle "\n=head1 NAME\n\n$prog";
		print $handle " - $tagline" if defined $tagline;
		print $handle "\n";
	}
	if(defined $usage)
	{
		print $handle "\n=head1 SYNOPSIS\n\n";
		print $handle "\t$_\n" for(split("\n", $usage));
	}
	if(@desc or defined $self->{config}{infopod})
	{
		print $handle "\n=head1 DESCRIPTION\n\n";
		if(defined $self->{config}{infopod})
		{
			print $handle $self->{config}{infopod};
		} else
		{
			for(@desc){ print $handle escape_pod($_), "\n"; }
		}
	}
	my $nprog = defined $prog ? $prog : 'some_program';

	print $handle "\n=head1 PARAMETERS\n\n";
	print $handle "These are the general rules for specifying parameters to this program:\n";
	print $handle "\n\t$nprog ";
	if($self->{config}{lazy})
	{
		print $handle escape_pod($example{lazy}),"\n\n";
		print $handle escape_pod($lazyinfo),"\n";
	}
	else
	{
		print $handle escape_pod($example{normal}),"\n";
	}
	print $handle "\n";
	for(@morehelp)
	{
		print $handle escape_pod($_);
	}
	print $handle "\n\nThe available parameters are these, default values (in Perl-compatible syntax) at the time of generating this document following the long/short names:\n";
	print $handle "\n=over 2\n";
	for my $k (sort keys %{$self->{param}})
	{
		print $handle "\n=item B<".escape_pod($k).">".
			($self->{short}{$k} ne '' ? ', B<'.escape_pod($self->{short}{$k}).'>' : '').
			" ($typename[$self->{type}{$k}])".
			"\n\n";
		my @content = $k eq 'help'
			? 0
			: split("\n", $self->par_content($k, 'dump', 1));
		print $handle "\t$_\n" for(@content);
		print $handle "\n".escape_pod(${$self->{help}{$k}})."\n";
		print $handle "\n".$self->{extrahelp}."\n" if($k eq 'help');
	}
	print $handle "\n=back\n";

	# closing with some simple sections
	my @podsections;
	# user-provided
	push(@podsections, @{$self->{config}{extrapod}})
		if(defined $self->{config}{extrapod});

	# standard
	for( ['BUGS','bugs'], ['AUTHOR', 'author'], ['LICENSE AND COPYRIGHT', 'copyright'] )
	{
		push(@podsections, {head=>$_->[0], body=>$self->{config}{$_->[1]}})
			if(defined $self->{config}{$_->[1]});
	}

	for my $ps (@podsections)
	{
		print $handle "\n=head1 $ps->{head}\n";
		print $handle "\n",$ps->{verbatim} ? $ps->{body} : escape_pod($ps->{body}),"\n";
	}

	print $handle "\n=cut\n";
}

sub _pm
{
	my $self  = shift;
	my $k     = shift;
	return ( ($self->{type}{$k} == $scalar
		and ( $self->{flags}{$k} & $switch
			or (defined $self->{arg}{$k} and $self->{arg}{$k} eq '') ))
		and ($self->{default}{$k}) ) ? '+' : '-';
}

# Well, _the_ help.
sub help
{
	my $self = shift;
	my $handle = $self->{config}{output};
	$handle = \*STDOUT unless defined $handle;
	my $indent = $self->{config}{posixhelp}
	?	$self->{arglength} + 7 # -s, --name[=arg] 
	:	$self->{length} + 4; # longest long name + ", s " (s being the short name)

	# Trying to format it fitting the screen to ease eye navigation in large parameter lists.
	my $linewidth = 0;
	if(defined $self->{config}{linewidth})
	{
		$linewidth = $self->{config}{linewidth};
	}
	elsif(eval { require Term::ReadKey })
	{
		# This can die on me! So run it in eval.
		my @s = eval { Term::ReadKey::GetTerminalSize(); };
		$linewidth = $s[0] if @s;
	}
	elsif(eval { require IPC::Run })
	{
		my ($in, $err);
		if(eval { IPC::Run::run([qw(tput cols)], \$in, \$linewidth, \$err) })
		{
			chomp($linewidth);
			$linewidth += 0; # ensure a number;
		}
	}
	my $prosewidth = $linewidth > 80 ? 80 : $linewidth;

	if($self->{param}{help} =~ /^(-\d+),?(.*)$/)
	{
		my $code = $1;
		my @keys = split(',', $2);
		my $badkeys;
		for(@keys)
		{
			unless(exists $self->{param}{$_})
			{
				++$badkeys;
				$self->INT_error("Parameter $_ is not defined!");
			}
		}
		return
			if $badkeys;

		if($code == -1)
		{ # param list, wrapped to screen
			INT_wrap_print( $handle, '', "\t", $linewidth, "List of parameters: "
			,	join(' ', sort keys %{$self->{param}}) );
		}
		elsif($code == -2)
		{ # param list, one one each line
			print $handle join("\n", sort keys %{$self->{param}})."\n";
		}
		elsif($code == -3)
		{ # param list, one one each line, without builtins
			my $builtin = builtins($self->{config});
			my @pars = sort grep {not $builtin->{$_}} keys %{$self->{param}};
			print $handle join("\n", @pars)."\n" if @pars;
		}
		elsif($code == -10)
		{ # dump values, suitable to eval to a big array
			my $first = 1;
			for(@keys)
			{
				if($first){ $first=0; }
				else{ print $handle ", "; }
				print $handle $self->par_content($_, 'dump', 1);
			}
		}
		elsif($code == -11)
		{ # line values
			for(@keys){ print $handle $self->par_content($_, 'lines'); }
		}
		elsif($code == -100)
		{
			$self->print_pod();
		}
		else
		{
			$self->INT_error("bogus help code $code");
			INT_wrap_print(\*STDERR, '', '', $linewidth, "\nHelp for help:\n", ${$self->{help}{help}});
			INT_wrap_print(\*STDERR, '','', $linewidth, $self->{extrahelp});
		}
		return;
	}

	# Anything with at least two characters could be a parameter name.
	if($self->{param}{help} =~ /../)
	{
		my $k = $self->{param}{help};
		if(exists $self->{param}{$k})
		{
			my $val   = $self->{arg}{$k};
			my $s     = $self->{short}{$k};
			my $type  = $self->{type}{$k};
			my $flags = $self->{flags}{$k};
			my $pm    = $self->_pm($k);
			$val = 'val' unless defined $val;
			print $handle $self->{config}{posixhelp}
			?	"Option:\n\t"
				.	($s ne '' ? "$pm$s, " : '')
				.	$pm.$pm.$k."\n"
			:	"Parameter:\n\t$k".($s ne '' ? ", $s" : '')."\n";
			my $c = $self->par_content($k, 'dump', 1);
			$c =~ s/\n$//;
			$c =~s/\n/\n\t/g;
			print $handle "\nValue:\n\t$c\n";
			my $dc = $self->par_content($k, 'dump', 1, 'default');
			$dc =~ s/\n$//;
			$dc =~s/\n/\n\t/g;
			print $handle "\nDefault value: "
			.	($c eq $dc ? "same" : "\n\t$dc")
			.	"\n";
			print $handle "\nSyntax notes:\n";
			my $notes = '';
			if($type eq $scalar)
			{
				my @switchcount;
				push(@switchcount, "switch")
					if($flags & $switch or not $flags & $count);
				push(@switchcount, "counter")
					if($flags & $count or not $flags & $switch);
				$notes .= $flags & $arg
					?	"This is a scalar parameter that requires an explicit"
						.	" argument value."
						.	" You can choose the canonical form --$k=$val or let"
						.	" the value follow like --$k $val"
						.	( $s ne ''
							?	" (short option only: both -$s $val and -$s$val are valid)"
							:	'' )
						.	'.'
					: $val ne ''
						?	"This is a scalar parameter with an optional argument"
							.	" value than can only be provided by attaching it"
							.	" with an equal sign or another operator,"
							.	" e.g. --$k=$val."
						:	"This is a parameter intended as a ".join(" or ", @switchcount)
							.	", providing an argument value is not required.";
				$notes .= " The value can be built"
						.	" in multiple steps via operators for appending (--$k.=) or"
						.	" arithmetic (--$k+= for addition, --$k-=, --$k*=, and --$k/= for"
						.	" subtraction, multiplication, and division)."
					unless $flags & $switch;
				$notes .= "\n\nThe above applies to the short -$s, too, with the"
						.	" addition that the equal sign can be dropped for"
						.	" two-character operators, like -$s+3."
					if(not $flags & $switch and $s ne '');
				$notes .= $flags & $count
					?	"\n\nEach appearance of --$k "
						.	($s ne '' ? "and -$s " : '')
						.	"increments the value by 1, while ++$k "
						.	($s ne '' ? "and +$s " : '')
						.	"set it to zero (false)."
					:	"\n\nJust --$k"
						.	($s ne '' ? " or -$s " : '')
						.	"sets the value to 1 (engages the switch), while ++$k"
						.	($s ne '' ? " or +$s " : '')
						.	"sets the value to 0 (disengages the switch)."
					unless($flags & $arg);
			} elsif(grep {$_ == $type} ($array, $hash))
			{
				$notes .= $type == $hash
				?	'This is a hash (name-value store) parameter. An option argument'
					.	' consists of <key>=<value> to'
					.	' store the actual value with for given key.'
				:	'This is an array parameter.';
				$notes .= ' Assigned values are appended even if the append operator .='
					.	' is not used explicitly.'
					if $flags & $append;
				$notes .= $flags & $arg
				?	' An explicit argument to the option is required.'
					.	" It is equivalent to specify --$k=$val or --$k $val."
					.	" A value is explcitly appended to the "
					.	"$typename[$type] via --$k.=$val."
				:	" An option argument can be given via --$k=$val or --$k.=$val to "
					.	" explicitly append to the $typename[$self->{type}{$k}].";
				$notes .= ' For this parameter, the appending operator .= is implicit.'
					if $flags & $append;
				$notes .= "\n\nThe above applies also to the short option -$s"
				.	($flags & $arg
					?	", with added possibility of directly attaching the argument via -$s$val."
					:	".")
					if $s ne '';
				$notes .= "\n\n";
				$notes .= "Multiple values can be provided with a single separator character"
				.	" that is specified between slashes, like --$k/,/=a,b,c.";
			} else
			{
				$notes .= 'I do not know what kind of parameter that is.'
			}
			$notes .= "\n\n"
				.	'Lazy option syntax is active: you can drop one or both of the'
				.	' leading \'--\', also the \'-\' of the short form. Beware: just'
				.	' -'.$k.' is a group of short options, while -'.$k.'=foo would be'
				.	' an assignment to '.$k.'.'
					if $self->{config}{lazy};
			INT_wrap_print( $handle, "\t", "\t", $prosewidth, $notes);
			print $handle "\nHelp:";
			if(${$self->{help}{$k}} ne '')
			{
				print $handle "\n";
				INT_wrap_print($handle, "\t","\t", $prosewidth, ${$self->{help}{$k}});
			} else
			{
				print $handle " none";
			}
			INT_wrap_print($handle, "\t","\t", $prosewidth, $self->{extrahelp})
				if $k eq 'help';
			print "\n";
		} else
		{
			$self->INT_error("Parameter $k is not defined!");
		}
		return;
	}

	if($self->{param}{help} =~ /\D/)
	{
		$self->INT_error("You specified an invalid help level (parameter name needs two characters minimum).");
		return;
	}

	my $vst = (defined $self->{config}{version} ? "v$self->{config}{version} " : '');
	if(defined $self->{config}{tagline})
	{
		INT_wrap_print($handle, '', '', $prosewidth, "\n$self->{config}{program} ${vst}- ",$self->{config}{tagline});
		if(defined $self->{config}{usage})
		{
			print $handle "\nUsage:\n";
			INT_wrap_print($handle, "\t","\t", $prosewidth, $self->{config}{usage});
		}
		if(defined $self->{config}{info})
		{
			INT_wrap_print($handle, '', '', $prosewidth, "\n".$self->{config}{info});
		} elsif(defined $self->{config}{infopod})
		{
			print {$handle} "\n";
			INT_pod_print($handle, $prosewidth, $self->{config}{infopod});
		}
		INT_wrap_print($handle, '', '', $prosewidth, "\n$self->{config}{copyright}")
			if defined $self->{config}{copyright};
	}
	else
	{
		if(defined $self->{config}{info})
		{
			INT_wrap_print($handle, '', '', $prosewidth, "\n$self->{config}{program} ${vst}- ".$self->{config}{info})
		} elsif(defined $self->{config}{infopod})
		{
			print {$handle} "\n$self->{config}{program} ${vst}\n";
			INT_pod_print($handle, $prosewidth, $self->{config}{infopod});
		}

		INT_wrap_print($handle, '', '', $prosewidth, "\n$self->{config}{copyright}")
			if defined $self->{config}{copyright};
	}

	my $level = 0+$self->{param}{help};
	my $tablehead = '';

	if($self->{config}{posixhelp})
	{
		INT_wrap_print( $handle, '', '', $prosewidth
			,	"\nShort options can be grouped and non-optional arguments"
			.	" can follow without equal sign. Force options end with '--'."
			.	" Switches on with -, off with +."
			.	" See --help=par for details on possible advanced syntax with option"
			.	" --par." );
	} else
	{
		my $preprint = "NAME, SHORT ";
		$indent = length($preprint)
			if length($preprint) > $indent;
		$tablehead = $preprint
		.	INT_indent_string($indent, length($preprint))."VALUE [# DESCRIPTION]\n";
		INT_wrap_print( $handle, '', '', $prosewidth
		,	"\nGeneric parameter example (list of real parameters follows):\n" );
		print $handle "\n";
		if($self->{config}{lazy})
		{
			print $handle "\t$self->{config}{program} $example{lazy}\n";
			if($level > 1)
			{
				INT_wrap_print($handle, '', '', $prosewidth, "\n", $lazyinfo);
			}
		}
		else
		{
			print $handle "\t$self->{config}{program} $example{normal}\n";
		}
		print $handle "\n";
		if($level > 1)
		{
			INT_wrap_print($handle, '', '', $prosewidth, @morehelp)
		} else
		{ # Don't waste so many lines by default.
			INT_wrap_print($handle, '', '', $prosewidth
				, "Just mentioning -s equals -s=1 (true), while +s equals -s=0 (false)."
				, " The separator \"--\" stops option parsing."
			)
		}
		INT_wrap_print($handle, '', '', $prosewidth, "\nRecognized parameters:");
	}
	my @hidden_nonshort;
	my @hidden_level;
	if($self->{config}{ordered})
	{
		foreach my $s (@{$self->{section}})
		{
			if($level >= $s->{minlevel})
			{
				INT_wrap_print( $handle, '', '', $prosewidth, "\n".$s->{section} )
					if($s->{section} ne '');
				INT_wrap_print( $handle, '', '', $prosewidth, ${$s->{help}} )
					if(${$s->{help}} ne '');
				print $handle "\n".$tablehead;
			}
			# Go through the parameters at least to count the hidden ones.
			for my $k (@{$s->{member}})
			{
				$self->INT_param_help( $handle, $k, $level, $prosewidth, $indent
				,	\@hidden_nonshort, \@hidden_level );
			}
		}
	} else
	{
		print $handle "\n".$tablehead;
		for my $k ( sort keys %{$self->{param}} )
		{
			$self->INT_param_help( $handle, $k, $level, $prosewidth, $indent
			,	\@hidden_nonshort, \@hidden_level );
		}
	}
	if(@hidden_nonshort)
	{
		print $handle "\n";
		if($level> 1)
		{
			INT_wrap_print( $handle, '', '', $prosewidth,
				"Hidden parameters intended primarily for config files:" );
			INT_wrap_print( $handle, "\t", "\t", $prosewidth, "@hidden_nonshort" );
		} else
		{
			INT_wrap_print( $handle, '', '', $prosewidth, 'There'
			.	( @hidden_nonshort == 1
				?	'is one hidden config file parameter'
				:	'are '.(0+@hidden_nonshort).' hidden config file parameters' ) );
		}
	}
	if(@hidden_level)
	{
		print $handle "\n";
		if($level > 1)
		{
			INT_wrap_print( $handle, '', "\t", $prosewidth
			,	"Parameters explained at higher help levels: @hidden_level" );
		} else
		{
			INT_wrap_print( $handle, '', '', $prosewidth, "There "
			.	( @hidden_level == 1
				?	'is one parameter'
				:	'are '.(0+@hidden_level).' parameters' )
			.	' explained at higher help levels.' );
		}
	}
	print $handle "\n";
}

sub INT_param_help
{
	my $self = shift;
	my ($handle, $k, $level, $linewidth, $indent, $hidden_nonshort, $hidden_level) = @_;

	# Reasons to hide from current printout.
	my $hide = 0;
	if( $self->{config}{hidenonshort} and $self->{short}{$k} eq ''
		and not ($k eq 'version' and defined $self->{config}{version}) )
	{
		++$hide;
		push(@{$hidden_nonshort}, $k);
	}
	if($level < $self->{level}{$k})
	{
		++$hide;
		push(@{$hidden_level}, $k);
	}
	return
		if $hide;

	if($self->{config}{posixhelp})
	{
		$self->INT_param_help_posix($handle, $k, $linewidth, $indent);
	} else
	{
		$self->INT_param_help_table($handle, $k, $linewidth, $indent);
	}
}

sub INT_param_help_table
{
	my $self = shift;
	my ($handle, $k, $linewidth, $indent) = @_;
	
	# This format will change, I presume.
	# This is the parameter syntax-agnostic print, where that
	# information is shown elsewhere. People are used to
	# -s, --long=<value>     Blablabla [default]
	# Let's go there.
	# long, s 
	my $prefix = $k;
	$prefix .= ", $self->{short}{$k}" if($self->{short}{$k} ne '');
	$prefix .= ' ';
	my $content = $self->par_content($k, 'dump', 0);
	my $stab = ' ' x $indent;
	my @help = split("\n", ${$self->{help}{$k}});
	push(@help, split("\n", $self->{extrahelp}))
		if( $k eq 'help' and $self->{param}{help} > 1
			and defined $self->{extrahelp} );
	$help[0] = $content.(@help and $help[0] ne '' ? " # $help[0]" : '');
	for(my $i=0; $i<@help; ++$i)
	{
		INT_wrap_print( $handle, ( $i==0
			?	$prefix.INT_indent_string($indent, length($prefix))
			:	$stab ) , $stab, $linewidth, $help[$i] );
	}
}

sub INT_param_help_posix
{
	my $self = shift;
	my ($handle, $k, $linewidth, $indent) = @_;
	my $stab = ' ' x $indent;
	my $prefix = '';
	my $pm = $self->_pm($k);
	$prefix = $self->{short}{$k} ne '' ? "$pm$self->{short}{$k}, " : '    ';
	$prefix .= $pm.$pm.$self->INT_namearg($k).' ';
	my @help = split("\n", ${$self->{help}{$k}});
	push(@help, split("\n", $self->{extrahelp}))
		if($k eq 'help' and $self->{param}{help} > 1);
	# Splitting the empty string does not give an array with one empty string,
	# but an empty array instead.
	push(@help, '')
		unless @help;
	$help[0] = 'disable: '.$help[0]
		if $pm eq '+';
	for(my $i=0; $i<@help; ++$i)
	{
		INT_wrap_print( $handle, ( $i==0
			?	$prefix.INT_indent_string($indent, length($prefix), ' ')
			:	$stab ) , $stab, $linewidth, $help[$i] );
	}
}

# Have to cover two use cases:
# 1. Have defined param space, just want values.
# 2. Want to construct param space from file.
# Parse configured config files.
sub INT_parse_files
{
	my $self = shift;
	my $construct = shift;

	for my $file (@{$self->{param}{config}})
	{
		return 0 unless $self->parse_file($file, $construct);
	}
	return 1;
}

# check if it's existing and not a directory
# _not_ explicitly checking for files as that would exclude things that otherwise would work as files just fine
sub INT_filelike
{
	return (-e $_[0] and not -d $_[0])
}

# Look for given config file name in configured directory or search for it in
# the list of likely places. Appending the ending .conf is also tried.
sub INT_find_config
{
	my $self = shift;
	my $name = shift;

	return $name if File::Spec->file_name_is_absolute($name);

	# Let's special-case the current working directory. Do not want to spell it
	# out for the directory search loop.
	# But yes, it is a bit of duplication with the .conf addition. Sorry.
	return $name if(INT_filelike($name));
	return "$name.conf" if(INT_filelike("$name.conf"));

	my $path;
	my @dirs;
	#determine directory to search config files in
	if(defined $self->{config}{confdir})
	{
		@dirs = ($self->{config}{confdir});
	}
	else
	{
		@dirs = (
		 File::Spec->catfile($ENV{HOME},'.'.$self->{config}{program})
		,File::Spec->catfile($Bin,'..','etc',$self->{config}{program})
		,File::Spec->catfile($Bin,'..','etc')
		,File::Spec->catfile($Bin,'etc')
		,$Bin
		,File::Spec->catfile($ENV{HOME},'.config',$self->{config}{program})
		,File::Spec->catfile($ENV{HOME},'.config')
		);
	}

	for my $d (@dirs)
	{
		my $f = File::Spec->catfile($d, $name);
		$f .= '.conf' unless INT_filelike($f);
		if(INT_filelike($f))
		{
			$path = $f;
			last;
		}
	}

	$self->INT_verb_msg("Found config: $path\n") if defined $path;
	return $path
}

# Parse one given file.
sub parse_file
{
	my $self = shift;

	my $confname = shift;
	my $construct = shift;

	my $lend = '(\012\015|\012|\015)';
	my $nlend = '[^\012\015]';
	my $olderrs = @{$self->{errors}};
	require IO::File;

	# TODO: Support loading multiple occurences in order.
	my $file = $self->INT_find_config($confname);
	my $cdat = new IO::File;
	if(not defined $file)
	{
		$self->INT_error("Couldn't find config file $confname!") unless $self->{config}{nocomplain};
	}
	elsif(grep {$_ eq $file} @{$self->{parse_chain}})
	{
		$self->INT_error("Trying to parse config file $file twice in one chain!");
	}
	elsif($cdat->open($file, '<'))
	{
		push(@{$self->{parse_chain}}, $file);
		push(@{$self->{files}}, $file);
		if(defined $self->{config}{binmode})
		{
			binmode($cdat, $self->{config}{binmode});
		}
		#do we need or want binmode for newlines?
		my $multiline = '';
		my $mcollect = 0;
		my $ender = '';
		my $mkey ='';
		my $mop = '';
		my %curpar;
		my $ln = 0;
		while(<$cdat>)
		{
			++$ln;
			unless($mcollect)
			{
				next if ($_ =~ /^\s*#/ or $_ =~ /^\s*#?\s*$lend$/o);

				if($_ =~ /^=($nlend+)$lend*$/o)
				{
					my $meta = $1;
					if($construct)
					{
						if($meta =~ /^param file\s*(\(([^)]*)\)|)\s*for\s*(.+)$/)
						{
							$self->{config}{program} = $3;
							$self->INT_verb_msg("This file is for $self->{config}{program}.\n");
							if(defined $2 and $2 =~ /^(.+)$/)
							{
								for my $s (split(',', $1))
								{
									$self->INT_verb_msg("Activating option $s.\n");
									$self->INT_error("$file:$ln: eval option not supported anymore.") if($s eq 'eval');
									$self->{config}{$s} = 1;
								}
							}
						}
						elsif($meta =~ /^version\s*(.+)$/)
						{
							$self->{config}{version} = $1;
						}
						elsif($meta =~ /^info\s(.*)$/)
						{
							$self->{config}{info} .= $1."\n"; #dos, unix... whatever...
						}
						elsif($meta =~ /^infopod\s(.*)$/)
						{
							$self->{config}{infopod} .= $1."\n"; #dos, unix... whatever...
						}
					}
					# Groping for parameter description in any case.
					if($meta =~ /^(long|key)\s*(\S*)(\s*short\s*(\S)|)(\s*type\s*(\S+)|)/)
					{
						%curpar = (long=>$2, short=>defined $4 ? $4 : '', help=>'');
						my $type = defined $6 ? $6 : '';
						if(exists $typemap{$type})
						{
							$curpar{value} = $initval[$typemap{$type}];
							$self->INT_verb_msg("switching to key $curpar{long} / $curpar{short}\n");
						}
						else{ $self->INT_error("$file:$ln: unknown type $type"); %curpar = (); }
					}
					elsif($meta =~ /^(help|desc)\s(.*)$/)
					{
						$curpar{help} .= $curpar{help} ne '' ? "\n" : "" . $2;
					}
					elsif($meta =~ /^include\s*(.+)$/)
					{
						my $incfile = $1;
						# Avoid endless looping by making this path explicit.
						# Search for config file vicious if you tell it to load ../config and that also contains ../config ...
						$self->INT_verb_msg("including $incfile\n");
						unless(File::Spec->file_name_is_absolute($incfile))
						{
							my $dir = dirname($file);
							$dir = File::Spec->rel2abs($dir);
							$incfile = File::Spec->catfile($dir, $incfile);
							$incfile .= '.conf'
								unless -e $incfile;
						}
						$self->parse_file($incfile, $construct);
					}
				}
				else
				{
					if($_ =~ /^\s*($parname)\s*($lopex)\s*($nlend*)$lend$/)
					{
						my ($par,$op,$val) = ($1,$2,$3);
						#remove trailing spaces
						$val =~ s/\s*$//;
						#remove quotes
						$val =~ s/^"(.*)"$/$1/;
						$self->INT_definery(\%curpar, $par, $construct);
						if(exists $self->{param}{$par})
						{
							$self->INT_verb_msg("Setting $par $op $val\n");
							$self->INT_apply_op($par, $op, $val, $file);
						}
						else
						{
							unless($self->{config}{ignore_unknown})
							{
								$self->{param}{help} = 1 if($self->{config}{nanny});
								$self->INT_error("$file:$ln: unknown parameter $par");
							}
						}
					}
					elsif($_ =~ /^\s*($parname)\s*$lend$/)
					{
						my $par = $1;
						$self->INT_definery(\%curpar, $par, $construct);
						if(exists $self->{param}{$par})
						{
							$self->INT_verb_msg("Setting $par so that it is true.\n");
							$self->{param}{$par} = $trueval[$self->{type}{$par}];
						}
						else
						{
							unless($self->{config}{ignore_unknown})
							{
								$self->{param}{help} = 1 if($self->{config}{nanny});
								$self->INT_error("$file:$ln: unknown parameter $par");
							}
						}
					}
					elsif($_ =~ /^\s*($parname)\s*([$ops]?)<<(.*)$/)
					{
						$ender = $3;
						$mop = $2 ne '' ? $2 : '=';
						$mkey = $1;
						$mcollect = 1;
						$mop .= '=' unless $mop =~ /=$/;
						$self->INT_verb_msg("Reading for $mkey...(till $ender)\n"); 
					}
				}
			}
			else
			{
				$self->INT_verb_msg("collect: $_");
				unless($_ =~ /^$ender$/)
				{
					s/(^|$nlend)$lend$/$1\n/o;
					$multiline .= $_;
				}
				else
				{
					$mcollect = 0;
					# remove last line end
					$multiline =~ s/(^|$nlend)$lend$/$1/o;
					$self->INT_definery(\%curpar, $mkey, $construct);
					if(exists $self->{param}{$mkey})
					{
						# apply the config file options first, with eval() when desired
						$self->INT_apply_op($mkey, $mop, $multiline, $file);
						$self->INT_verb_msg("set $mkey from $multiline\n");
					}
					else
					{
						unless($self->{config}{ignore_unknown})
						{
							if($self->{config}{nanny}){ $self->{param}{help} = 1; }
							$self->INT_error("$file:$ln: unknown parameter $mkey!");
						}
					}

					$multiline = '';
				}
			}
		}
		$cdat->close();
		$self->INT_verb_msg("... done parsing.\n");
		pop(@{$self->{parse_chain}});
	}
	else{ $self->INT_error("Couldn't open config file $file! ($!)") unless $self->{config}{nocomplain}; }

	if(@{$self->{errors}} == $olderrs)
	{
		return 1
	} else
	{
		$self->{bad_config_file} = 1;
		return 0;
	}
}

# Just helper for the above, not gerneral-purpose.

# Define a parameter in construction mode or when needed to accept something unknown.
sub INT_definery
{
	my ($self, $curpar, $par, $construct) = @_;
	if(
		defined $curpar->{long}
		and (
		$construct
		or
		(
			$self->{config}{accept_unknown}
			and not exists $self->{param}{$par}
			and $curpar->{long} eq $par
		))
	){ $self->define($curpar); }

	$self->define({long=>$par}) if(not exists $self->{param}{$par} and ($construct or $self->{config}{accept_unknown}));
	%{$curpar} = ();
}

# Print out a config file.
sub print_file
{
	my ($self, $handle, $bare) = @_;

	my @omit = ('config','help');
	push(@omit,'version') if defined $self->{config}{version};
	push(@omit, @{$self->{config}{notinfile}}) if defined $self->{config}{notinfile};
	unless($bare)
	{
		print $handle <<EOT;
# Configuration file for $self->{config}{program}
#
# Syntax:
# 
EOT
	print $handle <<EOT;
# 	name = value
# or
# 	name = "value"
#
# You can provide any number (including 0) of whitespaces before and after name and value. If you really want the whitespace in the value then use the second form and be happy;-)
EOT
	print $handle <<EOT;
# It is also possible to set multiline strings with
# name <<ENDSTRING
# ...
# ENDSTRING
#	
# (just like in Perl but omitting the ;)
# You can use .=, +=, /= and *= instead of = as operators for concatenation of strings or pushing to arrays/hashes, addition, substraction, division and multiplication, respectively.
# The same holds likewise for .<<, +<<, /<< and *<< .
#
# The short names are just provided as a reference; they're only working as real command line parameters, not in this file!
#
# The lines starting with "=" are needed for parsers of the file (other than $self->{config}{program} itself) and are informative to you, too.
# =param file (options) for program
# says for whom the file is and possibly some hints (options)
# =info INFO
# is the general program info (multiple lines, normally)
# =long NAME short S type TYPE
# says that now comes stuff for the parameter NAME and its short form is S. Data TYPE can be scalar, array or hash.
# =help SOME_TEXT
# gives a description for the parameter.
#
# If you don't like/need all this bloated text, the you can strip all "#", "=" - started and empty lines and the result will still be a valid configuration file for $self->{config}{program}.

EOT
	}
	print $handle '=param file ';
	my @opt = (); # There are no relevant options currently.
	print $handle '('.join(',',@opt).') ' if @opt;
	print $handle 'for '.$self->{config}{program}."\n";
	print $handle '=version '.$self->{config}{version}."\n" if defined $self->{config}{version}; 
	print $handle "\n";
	if(defined $self->{config}{info} and !$bare)
	{
		my @info = split("\n",$self->{config}{info});
		for(@info){ print $handle '=info '.$_."\n"; }
	}
	if(defined $self->{config}{infopod} and !$bare)
	{
		my @info = split("\n",$self->{config}{infopod});
		for(@info){ print $handle '=infopod '.$_."\n"; }
	}
	for my $k (sort keys %{$self->{param}})
	{
		unless(grep(/^$k$/, @omit))
		{
			#make line ending changeable...
			#or use proper system-independent line end
			#for now we just use \n - what may even work with active perl
			#
			unless($bare)
			{
				print $handle "\n=long $k"
					,$self->{short}{$k} ne '' ? " short $self->{short}{$k}" : ''
					," type $typename[$self->{type}{$k}]"
					,"\n";
				my @help = split("\n",${$self->{help}{$k}});
				for(@help)
				{
					print $handle "=help $_\n";
				}
			}
			my $values = $self->{type}{$k} ? $self->{param}{$k} : [ $self->{param}{$k} ];
			if($self->{type}{$k} == $hash)
			{
				my @vals;
				for my $k (sort keys %{$values})
				{
					push(@vals, $k.(defined $values->{$k} ? '='.$values->{$k} : ''));
				}
				$values = \@vals;
			}
			$values = [ undef ] unless defined $values;
			my $first = 1;
			print $handle "\n" unless $bare;
			for my $v (@{$values})
			{
				my $preop = $self->{type}{$k}
					? ( (not $first)
						? '.'
						: ( (@{$values} > 1) ? ' ' : '' ) )
					: '';
				if(defined $v)
				{
					if($v =~ /[\012\015]/)
					{
						my $end = 'EOT';
						my $num = '';
						$v =~ s/[\012\015]*\z/\n/g; # that line end business needs testing
						while($v =~ /(^|\n)$end$num(\n|$)/){ ++$num; }
						print $handle "$k $preop<<$end$num\n$v$end$num\n";
					}
					else{ print $handle "$k $preop= \"$v\"\n"; }
				}
				else{ print $handle "# $k is undefined\n"; }

				$first = 0;
			}
		}
	}
}

sub INT_push_hash
{
	my $self = shift;
	my $par = shift; for (@_)
	{
		my ($k, $v) = split('=',$_,2);
		if(defined $k)
		{
			$par->{$k} = $v;
		} else
		{
			$self->INT_error("Undefined key for hash $_[0]. Did you mean --$_[0]// to empty it?");
		}
	}
}

# The low-level worker for applying one parameter operation.
sub INT_apply_op
{
	my $self = shift; # (par, op, value, file||undef)

	return unless exists $self->{param}{$_[0]};

	if($self->{type}{$_[0]} == $scalar)
	{
		no warnings 'numeric';
		my $par = \$self->{param}{$_[0]}; # scalar ref
		if   ($_[1] eq  '='){ $$par  = $_[2]; }
		elsif($_[1] eq '.='){ $$par .= $_[2]; }
		elsif($_[1] eq '+='){ $$par += $_[2]; }
		elsif($_[1] eq '-='){ $$par -= $_[2]; }
		elsif($_[1] eq '*='){ $$par *= $_[2]; }
		elsif($_[1] eq '/='){ $$par /= $_[2]; }
		else{ $self->INT_error("Operator '$_[1]' on '$_[0]' is invalid."); $self->{param}{help} = 1; }
	}
	elsif($self->{type}{$_[0]} == $array)
	{
		my $par = $self->{param}{$_[0]}; # array ref
		my $bad;
		if   ($_[1] eq  '='){ @{$par} = ( $_[2] ); }
		elsif($_[1] eq '.='){ push(@{$par}, $_[2]); }
		elsif($_[1] eq  '//=' or ($_[1] eq '/=' and $_[2] eq '/')){ @{$par} = (); }
		elsif($_[1] =~ m:^/(.)/(.*)$:) # operator with specified array separator
		{
			my $sep = $1; # array separator
			my $op  = $2; # actual operator
			my @values = split(/\Q$sep\E/, $_[2]);
			if   ($op eq  '='){ @{$par} = @values; }
			elsif($op eq '.='){ push(@{$par}, @values); }
			else{ $bad = 1; }
		}
		else{ $bad = 1 }
		if($bad)
		{
			$self->INT_error("Operator '$_[1]' is invalid for array '$_[0]'!");
			#$self->{param}{help} = 1;
		}
	}
	elsif($self->{type}{$_[0]} == $hash)
	{
		my $par = $self->{param}{$_[0]}; # hash ref
		my $bad;

		if($_[1] =~ m:^/(.)/(.*)$:) # operator with specified array separator
		{
			my $sep = $1; # array separator
			my $op  = $2; # actual operator
			my @values = split(/\Q$sep\E/, $_[2]);
			# a sub just to avoid duplicating the name=value splitting and setting
			if   ($op eq  '='){ %{$par} = (); $self->INT_push_hash($par,@values); }
			elsif($op eq '.='){ $self->INT_push_hash($par,@values); }
			else{ $bad = 1; }
		}
		elsif($_[1] eq  '//=' or ($_[1] eq '/=' and $_[2] eq '/'))
		{
			%{$par} = ();
		} else
		{
			if   ($_[1] eq  '='){ %{$par} = (); $self->INT_push_hash($par,  $_[2]); }
			elsif($_[1] eq '.='){ $self->INT_push_hash($par, $_[2]); }
			else{ $bad = 1 }
		}
		if($bad)
		{
			$self->INT_error("Operator '$_[1]' is invalid for hash '$_[0]'!");
			$self->{param}{help} = 1;
		}
	}
}

sub INT_value_check
{
	my $self = shift;
	my $p = $self->{param};
	my $olderr = @{$self->{errors}};
	for my $k (keys %{$self->{regex}})
	{
		if($self->{type}{$k} == $scalar)
		{
			$self->INT_error("Value of $k does not match regex: $p->{$k}")
				unless $p->{$k} =~ $self->{regex}{$k};
		} elsif($self->{type}{$k} == $array)
		{
			for(my $i=0; $i<@{$p->{$k}}; ++$i)
			{
				$self->INT_error("Element $i of $k does not match regex: $p->{$k}[$i]")
					unless $p->{$k}[$i] =~ $self->{regex}{$k};
			}
		} elsif($self->{type}{$k} == $hash)
		{
			for my $n (sort keys %{$p->{$k}})
			{
				$self->INT_error("Element $n of $k does not match regex: $p->{$k}{$n}")
					unless $p->{$k}{$n} =~ $self->{regex}{$k};
			}
		}
	}
	for my $k (keys %{$p})
	{
		no warnings 'uninitialized';
		next
			unless ($self->{flags}{$k} & $nonempty);
		unless(
			( $self->{type}{$k} == $scalar and $p->{$k} ne '' ) or
			( $self->{type}{$k} == $array  and @{$p->{$k}}    ) or
			( $self->{type}{$k} == $hash   and %{$p->{$k}}    )
		){
			$self->INT_error("Parameter $k is empty but should not be.");
		}
	}
	return $olderr == @{$self->{errors}};
}

sub current_setup
{
	require Storable;
	my $self = shift;
	my $config = Storable::dclone($self->{config});
	my @pardef;
	my $bin = builtins($self->{config});
	for my $p (sort keys %{$self->{param}})
	{
		next if $bin->{$p};
		my $val = ref($self->{param}{$p}) ? Storable::dclone($self->{param}{$p}) : $self->{param}{$p};
		push(@pardef, $p, $val, $self->{short}{$p}, ${$self->{help}{$p}});
	}
	return ($config, \@pardef);
}


# Little hepler for modifying the parameters.
# Apply all collected operations to a specific parameter.
sub INT_apply_ops
{
	my $self = shift;
	my $key = shift;
	return unless defined $self->{ops}{$key};
	$self->INT_verb_msg("Param: applying (@{$self->{ops}{$key}}) to $key of type $self->{type}{$key}\n");
	while(@{$self->{ops}{$key}})
	{
		my $op  = shift(@{$self->{ops}{$key}});
		my $val = shift(@{$self->{ops}{$key}});
		$self->INT_apply_op($key, $op, $val);
	}
}

sub INT_verb_msg
{
	my $self = shift;
	return unless ($verbose or $self->{config}{verbose});
	print STDERR "[Config::Param] ", @_;
}

sub INT_error
{
	my $self = shift;
	print STDERR "$self->{config}{program}: [Config::Param] Error: "
	,	$_[0], "\n" unless $self->{config}{silenterr};
	push(@{$self->{errors}}, $_[0]);
	return 1;
}

1;

__END__

=head1 NAME

Config::Param - all you want to do with parameters for your program (or someone else's)

=head1 SYNOPSIS

Just use the module,

	use Config::Param;

define your parameters in the simplest form of a flat array, possibly
directly in the call to the parser,

	# the definitions in flat array
	# predefined by default: help / h and config / I
	my $parm_ref = Config::Param::get
	(
	   'parm1', $default1,  'a', 'help text for scalar 1'
	  ,'parm2', $default2,  'b', 'help text for scalar 2'
	  ,'parmA', \@defaultA, 'A', 'help text for array A'
	  ,'parmH', \%defaultH, 'H', 'help text for hash H'
	  ,'parmX', $defaultX,  '', 'help text for last one (scalar)'
	);

or go about this in a more structured way with extra tweaks.

	my $flags = $Config::Param:arg|$Config::Param:count;
	my @pardef =
	(
	  [ 'parm1', $default1,  'a', 'some scalar parameter' ]
	, [ 'parm2', $default2,  'b', 'a counted switch', $flags ]
	, { long=>'parmA', value=>[], short=>'A'
	  , help=>'help text for array A,', arg=>'element', flags=>$flags }
	, [ 'parmH', \@defaultH, 'H', 'help text for hash H', 'prop=val', $flags ]
	, [ 'parmX', $defaultX,  '', 'help text for last one (scalar)' ]
	);
	$parm_ref = Config::Param::get(\@pardef);

The result is a hash reference with the long parameter names as keys and
containing the values after processing the command line.

	print "Value of parameter 'parm1': $parm_ref->{parm1}\n";
	print "Contents of array 'parmA': ".( defined $parm_ref->{parmA}
	? join(",", @{$parm_ref->{parmA}})
	: "<undefined>" )."\n";

There could be some extra configuration.

	my %config =
	(
	  'info' => 'program info text'
	,  'version' => '1.2.3'
	,  'flags' => $Config::Param:count # default flags for all parameters
	   # possibly more
	);
	$parm_ref = Config::Param::get(\%config, \@pardef);

The command-line arguments to use instead of @ARGV can also be provided.

	$parm_ref = Config::Param::get(\%config,\@pardef,\@cmdline_args);

The most complicated call is this, making only sense when disabling final exit:

	$config{noexit} = 1; # or nofinals
	$parm_ref = Config::Param::get(\%config,\@pardef,\@cmdline_args, $errors);

This will return a count of errors encountered (bad setup, bad command line args). With default configuration, the routine would not return on error, but end the program. Errors will be mentioned to STDERR in any case.

Finally, you can use a Config::Param object to do what Config::Param::get does:

	# equivalent to
	# $parm_ref = Config::Param::get(\%config,\@pardef);
	my $pars = Config::Param->new(\%config, \@pardef);
	my $bad = not (
		    $pars->good()
		and $pars->parse_args(\@ARGV)
		and $pars->use_config_files()
		and $pars->apply_args()
	);
	$pars->final_action($bad);
	$parm_ref = $pars->{param};

=head1 DESCRIPTION

The basic task is to take some description of offered parameters and return a hash ref with values for these parameters, influenced by the command line and/or configuration files. The simple loop from many years ago now is about the most comprehensive solution for a program's param space that I am aware of, while still supporting the one-shot usage via a single function call and a flat description of parameters.

The module handles command line options to set program parameters, defining
and handling standard options for generating helpful usage messages, and
parses as well as generates configuration files. Furthermore, it can generate
program documentation in POD form, the other way round from other approaches that
use your written POD to generate parameter help.

The syntax for single-letter options follows the recommendations of
IEEE Std 1003.1-2017 (12. Utility Conventions), with

B<command> [I<options>] [--] [I<operands>]

indicating a generic command line. All parameters are required to have a long name,
which is used for GNU-style long options. A short name (classic POSIX-style)
is optional.

=head2 Option processing overview

This is a brief overview of ways to provide parameter values via command-line
options. See further below for details.

The letter B<p> stands for the short name of the parameter B<param>. When providing
values, a prefix of B<+> or B<++> works just as B<-> or B<-->.

=over 4

=item B<--param>, B<-p>

Identical to B<--param=1> unless counting for the scalar
parameter is enabled, when it is identical to B<--param+=1> instead.

=item B<++param>, B<+p>

Identical to B<--param=0>.

=item B<--param=>I<value>, B<-p=>I<value>

Set parameter value. If the parameter is an array or hash and accumulation
is enabled, this is identical to B<--param.=>I<value>.

=item B<--param> I<value>, B<-p> I<value>, B<-p>I<value>

Alternative syntax equivalent to B<--param=>I<value>
without equal sign or even whitespace
to set the parameter value where a value is mandatory. The last
form only works if the value does not conflict with operator
syntax (beginning with B<.>, B<+>, B<->, B<*>, or B</>) and does not
start with an equal sign itself.

=item B<-abc>, B<-abc=>I<value>, B<-abc> I<value>

Equivalent to B<-a -b -c>, B<-a -b -c=>I<value>, and B<-a -b -c> I<value>,
respectively. The last one only works if B<-c> (and only c)
requires an argument.

=item B<--param.=>I<value>, B<-p.[=]>I<value>

Append the given value to the current content of the parameter. For arrays,
this appends another entry. For hashes, the value shall be a name-value pair
to update the hash.

=item B<--param><B<+>|B<->|B<*>|B</>>B<=>I<value>, B<-p><B<+>|B<->|B<*>|B</>>[B<=>]I<value>

Perform arithmetic operations on the current scalar parameter value. Examples that all
add 3 to the current value:

	--param+=3 -p+=3 -p+3

Arithmetic is not supported for array and hash parameters. The operators are
B<+> for addition, B<-> for subtraction, B<*> for multiplication, B</> for
division. 

=item B<--param/,/=>I<a>B<,>I<b>B<,>I<c>,
      B<--param/,/> I<a>B<,>I<b>B<,>I<c>,
      B<-p/,/>[B<=>]I<a>B<,>I<b>B<,>I<c>,
      B<-p/,/> I<a>B<,>I<b>B<,>I<c>

Set array parameter to comma-separated list (any single-character
separator may be chosen). An argument has to follow, so an equal sign
or, for the short option, even any separation is optional.

=item B<--param/,/=>I<a=1>B<,>I<b=2>,
      B<--param/,/> I<a=1>B<,>I<b=2>,
      B<-p/,/>[B<=>]I<a=1>B<,>I<b=2>,
      B<-p/,/> I<a=1>B<,>I<b=2>,

Set hash parameter to comma-separated name-value pairs (any single-character
separator besides the equal sign may be chosen). An argument has to follow,
so an equal sign or, for the short option, even any separation is optional.

=item B<--param//>, B<-p//>

Set the array or hash parameter to the empty list/hash. This is different from
assigning an empty string, which would create one entry defined by that empty
string instead.

=back

Some of the above variants are not supported with the lazy configuration option
for reducing the amount of hyphens to type.

=head2 Basic option syntax and scalar parameters

This module processes command line options to set program parameters,
be it short or long style, supporting clustering of short options. Every
parameter has to be given a long option name, while a short
(single-letter) one is optional. By default, the form B<--param=>I<value> or
B<-p=>I<value> sets an explicit value. Omitting the B<=>I<value> part
causes the value 1 (true) being assigned -- or added if the flag
B<$Config::Param::count> is in effect.

A parameter can be marked to require an explicit argument using the flag
B<$Config::Param::arg>. Then, the forms B<--param >I<value> and B<-p >I<value> as
well as B<-p>I<value> also are valid syntax, but the forms B<--param>
and B<-p> without following value are invalid. If there is no separation
to the value, the value itself must not begin with any of B<=>,
B<.>, B<+>, B<->, B<*>, and B</>.

Also, though somewhat counterintuitive but existing practice and 
logically following the idea that "-" is true, B<++param> / B<+p>
will set the value to 0 (false). If you specify a value, it does not
matter if "-" or "+" is used in front of the name.

The values are stored from the strings of the argument list and interpreted
by Perl when you access them. There is no distinction bettwen strings and
numbers; those are just scalar values. If you enable switch accumulation,
integer arithmetic takes place for counting
the number of times the parameter (switch, short or long form)
was given: B<-p -parm -p> will
be equivalent to B<--param=3> if the value was previously unset or zero.
The form B<+p> will always reset the value to zero.

There is the fundamental problem of deciding if we have a parameter value or
some other command-line data like a file name to process.
Since this problem still persists with the "=" used in assignment when one
considers a file with a name like "--i_look_like_an_option", Config::Param
also looks out for B<--> as a final delimiter for the named parameter part,
which is also quite common behaviour.

The command line arguments after "--" stay in the input array (usually @ARGV)
and can be used by the calling program. The parsed parameters as well as the
optional "--" are removed; so, if you want to retain your @ARGV, just provide
a copy.

There is a configuration option that reduces the amount of "-" you need to
type, see "lazy" below. It may make sense if your program exclusively
takes named parameters with values and does not expect anything else, but
it complicates usage by enlarging the variations of syntax.

=head2 Arrays and hashes

You can also have hashes or arrays as values for your parameters.
The hash/array type is chosen when you
provide an (anonymous) hash/array reference as value in the definition.

You can set a whole array by specifying a separator character between
forward slashes:

	--array/,/=a,b

This results in the strings "a" and "b" being stored as elements. You can choose
any character as separator, even the forward slash itself.

You can also use the concatenation operator B<.=> to append elements,
the form

	--array=a --array.=b

being equivalent to the above. Furthermore, if accumulation is enabled
(B<$Config::Param::append>), the concatenation operator is implicit,
so another way would be

	--array=a --array=b

and finally, if the flag (B<$Config::Param::arg> is active, the equal sign
can be omitted, to have

	--array a --array b

result in the same, also for the short names. Without that flag, --array
would instead set or append the value 1.

In any setting, you can empty an array or hash using B<--array//> or	B<-a//>.

Hash values are set via prefixing a key with following "=" before the actual value:

	--hash=name=value

This sets the whole hash to the single name-value set, or appends such a set
if B<$Config::Param::append> is active. To set multiple values in one go, the
same logic as for arrays applies:

	--hash/,/=foo=a,bar=b
	--hash=foo=a --hash.=bar=b

If the equal sign is omitted, only a key specified, a hash entry with an undefined
value is created. This is the only direct way to actally pass the value B<undef> via
the commandline. This is different from B<--hash=key=>, which adds the empty string
as value.

A change for fringe cases arised in version 4 of the library: In the past, omitting
any argument (just B<--hash> or B<++hash>) would result in the value 1 or 0
being stored for the key 'truth'. Now, the behaviour is consistent so that
B<--hash> does create a hash entry with key 1 and undefined value, like
B<--hash=1> does.

The same logic as for arrays applies regarding B<$Config::Param::arg> and
B<$Config::Param::append>. Likewise, hash is also cleared usign B<--hash//> or
B<-H//>.

=head2 Operators

Apart from simple assignment, the parser offers some basic operators to work
on command-line arguments or configuration file entries in succession.

Instead of B<--param=value> you can do do B<--param.=>I<value> to append
something to the existing value. When B<-p> is the short form of B<--param>,
the same happens through B<-p.=>I<value> or, saving one character, B<-p.>I<value>.
The long form needs the full operator, as the dot could be part of a parameter
name. So

	--param=a --param.=b -p.c

results in the value of B<parm> being 'abc'.

This is especially important for sanely working with hashes and arrays
without B<$Config::Param::append>, where the append operator adds new
entries instead of re-setting the whole data structure to the given
value. The append operator is also the only operator defined for
arrays and hashes. It can be combined with the element splitting,

	--array/:/=a:b --array/-/.=c-d -a/,/.=e,f

resulting in a, b, c, d, e, and f being stored in the array.

There is no advanced parsing with quoting of separator characters --- that's why
you can choose an appropriate one so that simple splitting at occurences does the
right thing.

The full non-assignment operator consists of an operator character and the
equal sign, but the latter can be dropped for the short option form. Apart
from concatenation, there are basic arithmetic operators.
These plain operators are available:

=over 4

=item B<=>I<value>

Direct assignment.

=item B<.=>I<value> or short B<.>I<value>

String concatenation for scalar parameters, pushing values for array and hash parameters.

=item B<+=>I<value> or short B<+>I<value>

Addition to scalar value.

=item B<-=>I<value> or short B<->I<value>

Substraction from scalar value.

=item B<*=>I<value> or short B<*>I<value>

Multiplication of scalar value.

=item B</=>I<value> or short B</>I<value>

Division of scalar value.

=back

You can omit the B<=> for the short-form (one-letter) of parameters on the command
line when using the extra operators, but not in the configuration file.
There it is needed for parser safety. The operators extend to the multiline value
parsing in config files, though (see the section on config file syntax).

See the B<lazy> configuration switch for a modified command line syntax,
saving you some typing of "-" chars.

=head2 Automatic usage/version message creation

Based on the parameter definition Config::Param automatically prints the expected usage/help message when the (predefined!) B<--help> / B<-h> was given, with the info string in advance when defined, and exits the program. You can turn this behaviour off, of course. An example for the generated part of the help message:

	simple v0.0.1 - just a quick hack to demonstrate Config::Paramm
	
	usage:
		examples/simple [parameters] whatever
	
	We have this long info string just to show that Config::Param picks
	the tagline and usage info from it. This is not mandatory.
	
	Generic parameter example (list of real parameters follows):
		simple -s -xyz -s=value --long --long=value [--] [files/stuff]
	
	Just mentioning -s equals -s=1 (true), while +s equals -s=0 (false).
	The separator "--" stops option parsing.
	
	Recognized parameters:
	
	NAME, SHORT VALUE [# DESCRIPTION]
	config, I   [] # Which configfile(s) to use (overriding automatic
	            search in likely paths);
	            special: just -I or --config causes printing a current
	            config file to STDOUT
	help, h ... 1 # Show the help message. Value 1..9: help level, par:
	            help for paramter par (long name) only.
	meter ..... 'I got value but no help text, neither short name.'
	para, p ... 0 # A parameter.
	version ... 0 # print out the program version

Note: When printing to a terminal, Config::Param tries to determine the screen width and does a bit of formatting to help readability of the parameter table.

With the B<posixhelp> option, it looks more traditional:

	simple v0.0.1 - just a quick hack to demonstrate Config::Param
	
	usage:
		examples/simple [parameters] whatever
	
	We have this long info string just to show that Config::Param picks
	the tagline and usage info from it. This is not mandatory.
	
	Short options can be grouped and non-optional arguments can follow
	without equal sign. Force options end with '--'. Switches on with -,
	off with +. See --help=par for details on possible advanced syntax
	with option --par.
	
	-I, --config[=val] Which configfile(s) to use (overriding automatic
	                   search in likely paths);
	                   special: just -I or --config causes printing a
	                   current config file to STDOUT
	-h, --help[=val]   Show the help message. Value 1..9: help level, par:
	                   help for paramter par (long name) only.
	    --meter[=val]  
	-p, --para[=val]   A parameter.
	    --version      print out the program version

This mode makes most sense when you also use parameter flags to augment
the definitions, forcing mandatory arguments, marking parameters as
switches and counters. If you start to really polish the usage of
your program, you might want to consider going down that route
for feel more like a good old program with hand-crafted option parsing.

=head3 help parameter values

The B<help> parameter interprets given values is specific
ways, to squeeze out more functionality of that precious
predefined name.

=over 4

=item B<1>

Standard compact help, option overview.

=item I<name>

Print out verbose help for the parameter with the given long option name.

=item B<2>

More elaborate help including some extra lines about
parameter syntax.

=item B<3> to B<9>

Higher levels to allow selections of parameters of increasing obscurity
(see the level property in a parameter definition).

=item B<-1>

List parameter names, comma-separated in a possibly wrapped line.

=item B<-2>

List parameter names, one on each line.

=item B<-3>

List parametter names without the built-ins, one on each line.

=item B<-10[,]>I<name>B<[,>I<name> ...B<]>

Dump values of the provided parameters in a way suitable for evaluation in Perl,
as a comma-separated list.

=item B<-11[,]>I<name>B<[,>I<name> ...B<]>

Dump values in a line-oriented format.

=item B<-100>

Print the usage documentation as POD, perhaps to pass to pod2man for creating
a man page.

=back


=head2 Configuration file parsing

The module also introduces a simple but flexible configuration file facility. Configuration means simply setting the same parameters that are available to the command line.

The second and last predefined parameter called "config" (short: I) is for giving a file (or several ones, see below!) to process I<before> the command line options are applied (what the user typed is always the last word). If none is given, some guessing may take place to find an appropriate file (see below).
When just B<-I> or B<--config> is given (no B<=>!), then a file with the current configuration ist written to STDOUT and the program exits (unless B<ignorefinals> is set).
When you give the lonely B<-I> or B<--config> once, you'll get a explained config file with comments and meta info, when you give the option twice, you get a condensed file with only the raw settings and a small header telling for which program it is.

Config files are parsed before applying command line arguments, so that the latter can override settings.

=head2 Configuration file creation

Well, of course the module will also create the configuration files it consumes.
Specifying B<--conf> or B<-I> (or your different chosen names) without option
argument trigers writing of a configuration file to standard output and exit of the program. 
This is a trick available only to this special parameter

=head2 Configuration file syntax

The syntax of the configuration files is based on simple name and value pairs, similar to INI files (no sections, though you can use dots in parameter names to mimick them). In a configuration file, only the long name of a parameter is used:

	mode = "something"

sets the parameter mode to the value B<something>. Actually, 

	mode = something

would do the same. The whitespace around the operator (here: =) and before the line break is ignored.
You want to use (double) quotes when defining a value that begins or ends with whitespace:

	mode = " something spacy "

Consequently, you have to use quotes around the value if it starts with a quote character:

	mode = ""something with a quote"

The stuff between the first " and the last " will be used as value (you do not need to quote your quotes individually).
If you want your strings to contain multiple lines (or just a single actual newline character), you can use this, which should look familiar from Perl:

	mode <<EOT
	a line
	another line
	bla
	EOT

You can replace the EOT with anything you like... even nothing - then, the next empty line marks the end.
Only rule is that the end marker should not appear in the multiline value itself (alone on a line). Please note that this not being actual Perl syntax, there are no semicolons here.

Also, the last line end before the end marker is stripped, so if you want it included, add an empty line:

	mode <<EOT
	a line

	EOT


You can also use the funny operators introduced for command line parameters by
replacing the B<=> with B<.=>, B<+=>, B<-=>, B</=>, B<*=> as you like.
That works for the B<<<EOT> multiline construct, too, just make it B<.<<EOT> for appending and likewise B<+<<EOT>, B<-<<EOT> , B</<<EOT>, B<*<<EOT> for the other operations.

Also, just mentioning the parameter name sets it to a true value, like simple mentioning on command line.
And that is actually one reason for not just using another markup or serialization format for configuration files: The specification in the file follows the same concepts you have on the command line (esp. regarding operator use). It is the same language, although with some slight deviation, like the here document and string quoting, which is matter of the shell in the case of command lines.

Comments in the config file start with "#" and are supposed to be on lines on their own (otherwise, they will get parsed as part of a parameter value). Special tokens for the parser (see see parse_file method, with the optional parameter) start with "=", the important one is inclusion of other config files:

	=include anotherconfigfile[.conf]

This will locate anotherconfigfile either via absolute path or relative
to the currently parsed file. Search paths are B<not> used (this was
documented erroneously before). Its settings are loaded in-place and
parsing continues with the current file.  The file name starts with the
first non-whitespace after B<=include> and continues until the end of
line. No quoting.  If the given name does not exist, the ending .conf
is added and that one tried instead. The parsing aborts and raises an
error if an inclusion loop is detected.

There are more tokens in a fully annotated output of config files. Example:

	# I skipped  block of comments explaining the config file syntax.
	=param file for par_acceptor
	=version 1.0.0

	=info Param test program that accepts any parameter given

	=long ballaballa type scalar
	=help a parameter with meta data

	ballaballa = "0"

Only the last line in this example is relevant to the program itself (named "par_acceptor" here). The rest is auxilliary information for outsiders.

One last note: If a parameter value is undefined, no assignment is written to the config file. So a config file can never intentionally set a value to undefined state. You can start out with B<undef> values, but as soon as the parameter got set one time to something else, it won't go back B<undef>.

=head2 The config keys

Note that the hash ref you give to the constructor is taken over by the object; if you want to preserver the original hash, you have to make a copy yourself. It is the same with parameter definitions as array ref; consumed by initialization.

=over 4

=item B<info> (some text)

A text to print out before the parameter info when giving help, also
used for the DESCRIPTION section in POD output if B<infopod> is not
defined.

=item B<infopod> (some POD-formatted text)

Same as info, but used verbatim in POD output, and used to format
help message printout if the former is not present. Be careful with fancy
encodings. It is assumed that the terminal can handle whatever is given
here, which should be UTF-8 nowadays, but you might want to stick to ASCII.
This applies to any texts handled by this module, though.

=item B<program>

name of the program/package, used in search for config file and for output of config files/messages; default is basename($0)

=item B<version>

Version string for your program; this activates the definition of a B<--version> switch to print it.

=item B<verbose> (0 / 1)

When not 0, be verbose about the work being done. There may be different verbosity levels in the future, but for now value 4 is no different from 1. You can set $Config::Param::verbose to the same effect, globally.

=item B<multi> (0 / 1)

If activated, potentially parses all located default config files in a row instead of choosing one (currently this is about generic and host config file; might get extended to system global vs. $HOME).

=item B<confdir> (directory path)

Define a directory for searching of config files, overriding the internal defaults of looking at various likely places (in order), with "bin" being the directory the program resides in, "~" the user home directory:

=over 4

=item ~/.programname

=item bin/../etc/programname

=item bin/../etc

=item bin/etc

=item bin

=item ~/.config/programname

=item ~/.config

The contents and ordering of that list carry over behaviour in earlier versions of Config::Param, where the first existing directory in that list got used as single source for config files. During addition of the .config/ variants for version 3.001, this got changed to search the whole list (plus current working directory) for each requested file.
This should provide reasonable compatibility to existing setups and a flexible way forward to enhance the ability to find config files.
Note that you can always skip all that automatic fuss by specifying full paths to the desired config files. This just offers some convenience at the expense of predictability in case of conflicting config files of the same name at different locations.
TODO: A future release may offer to override this list and tell Config::Param to locate multiple occurences of one config file name and load them in order. In that case, you probably want to change the order to look in global directories first, then in the users's home for specific settings overriding global defaults.

=back

Explicitly given files without absolute path are always searched in the current working directory first.

=item B<file> (single file name/path or array ref of those)

Define the default config file (s), overriding the internal default of confdir/programname.conf or (being more powerful if existing) confdir/programname.hostname.conf .
The .conf suffix will be added if needed.
A word on the hostname: This is a possibility to use one configuration directory for several hosts (p.ex. mounted over NFS). 

B<BEWARE:> Every smartness has its catch - when you do a `myprogram -I=my -I > my.conf` the newly created (and empty) file my.conf in the currect directoy is found and used as config file for reading, resulting in the program defaults being written regardless of what another existing my.conf would say!

=item B<nofile> (0 / 1)

Prevent automatic parsing of configuration files.

=item B<gimme> (0 / 1)

Give help end exit if no command line arguments are there.

=item B<lazy> (0 / 1)

Switch to the "lazy" syntax that allows omitting the "-" and "--" in -p and --parameter (same with "+" and "++") most of the times but absolutely requires the separation of other stuff with /-+/ (read this as PERL regex;-).

=item B<nofinals> (0 / 1)

Do not take final action on certain switches (help, version, config file printing). Normally (with nofinals == 0), Param would exit your program on processing these.

=item B<noexit> (0 / 1)

Do final actions, but do not exit on those. Also prevents dying in constructor (and by extension, the get routine). You are supposed to check the error list.

=item B<notinfile> (listref)

list with parameters (long names) not to include in config file printing, help and config are always left out as they make no sense in files (config might make sense, but there is =include to handle that).

=item B<nanny> (0 / 1)

give parameter help and exit() when encountering unknown parameters in config files; otherwise just complain - this is disabled by nofinals.

=item B<fuzzy> (0 / 1)

handle --non-existing-parameter by simply stopping parsing there (treat it as first file or such to be handled by your program), otherwise complain and dump help info + exit.

=item B<nocomplain> (0 / 1)

do not complain about missing config file or the like

=item B<hidenonshort>

Hide parameters that don't have a short name in the overview
(p.ex. multiline stuff that one doesn't want to see outside of config files)

=item B<ordered>

Print out parameters in definition order; otherwise sorted.
This is implied once you define sections.

=item B<binmode> (undef / :utf8 / :latin1 / ...)

Set the binmode (text encoding) for parsed files.

=item B<ignore_unkown>

Do not complain on unknown parameters, just swallow silently. The actual value is important: 1 == only ignore unknowns in config files, 2 == also ignore unknowns on command line (overridden by the fuzzy operation).

=item B<accept_unkown>

Silently add parameters (long names only) to the party as scalars when encountering corresponding settings. Similar to ignore_unknown, the value 1 means adding from config files only, value 2 also adds from command line (overruled by the fuzzy operation).

This also activates partial usage of parameter meta data in the config file if it appears before the actual assignment. In that case, you can even add non-scalar parameters externally.

=item B<output>

Specify a handle to print help messages and config files to instead of STDOUT.

=item B<linewidth>

Set a line width for paragraph formatting (otherwise terminal is queried).

=item B<silenterr>

Integer for preventing printout of errors. You can prevent other printery by not enabling verbose mode and preventing finals or setting output to some sink.

=item B<author>

Set some text to print when information about the author is expected.

=item B<copyright>

Copyright and license info.

=item B<tagline>

The one-line reason for your program thttp://thomas.orgis.org/scripterei/download/Config-Param-3.002000.tar.gzo exist. The motto, whatever. If not given, the first line of the info string is used. Please give either none or both of B<tagline> and B<usage>.

=item B<usage>

Usage string summing up basic calling of the program. If not present, the info string might get harvested for that, if it contains such:

	usage: program [parameters] some.conf [parameters] [param names]

or

	usage:
	  program [parameters] some.conf [parameters] [param names]

(with arbitrary number of empty lines in between). Please give either none or both of B<tagline> and B<usage>.

=item B<posixhelp>

Generate usage text more like those of classic POSIX tools, not using a
table of parameters, rather options and option arguments. This is incompatible
with the lazy parameter parsing, as the usage hints would be too confusing
or just inaccurate regarding actual syntax.




=item B<shortdefaults>

Define this to a false value to prevent B<-h> and B<-I> being predefined as
short names for B<--help> and B<--config>. Available since version 4.
This frees some namespace, but still enforces the long names being available for
help output and config file parsing. Users should be able to rely on that.

=item B<flags>

Default flags for parameter definitions in the implicit default section.
See L</PARAMETER DEFINITON> for possible values.

=item B<regex>

Default regex for parameter definitions in the implicit default section.
See L</PARAMETER DEFINITON>.

=item B<call>

Default callback for parameter definitions in the implicit default section.
See L</PARAMETER DEFINITON>. This can be useful for tracing command line
usage with a generic function. This call will also be applied to the
default parameters defined by the library.

=back

=head2 PARAMETER DEFINITION

Parameter definitions are provided as plain array or an array of hashes/arrays:

	# plain flat list of long name, default value, short name, help text
	@pardef = (  'long1',0,'l','some parameter'
	            ,'long2',1,'L','another parameter' );
	# list of lists
	@pardef = (  ['long1',0,'l','some parameter']
	            ,['long2',1] ); # omitted stuff empty/undef by default
	# list of hashes and/or lists
	@pardef =
	(
		{
			 long=>'long1'
			,value=>0,
			,short=>'l'
			,help=>'some parameter'
		}
		, ['long2',1,'L','another parameter']
	);

If the first element is no reference, Config::Param checks if the total count
is a multiple of 4 to catch sloppyness on your side. These are possible
keys for the hash definition:

=over 4

=item B<long>

The long paramter name. This is required.
It must not contain '=', commas or any whitespace and begin and end with a
non-operator character. Also, it needs to be at least two
characters long.

=item B<value>

The default value. The parameter starts with this value and and operations
from the command line or config files apply on top, most notably
simple replacement with another value.
This can be a scalar (including undef) or a (anonymous) reference to
an array or hash, which also defines the type of the parameter.
No other type of reference, please.

Note that the contents the array/hash reference points to are deep-copied
to avoid modifying the parameter definition and have consistent results
on re-runs of the parser.

=item B<short>

The short name, the classic POSIX option. This needs to be a single
character that is not part of an operator.

=item B<help>

The help text that describes this parameter and its usage.

=item B<arg>

Name of argument to use in help output. The default would be
'value'. If this is the empty string, no argument is mentioned
in the help output. This fits classic switches that only know
on and off, or possibly a count. An alternative for that is to add
the flag B<$Config::Param::switch>.

=item B<flags>

A set of flags specific to this parameter. See below.
A section definition can provide a default.

=item B<addflags>

Flags to set on top (only in hash definition).

=item B<level>

A help level for this parameter to appear in the generated usage text.
You can hide an excessive amount of options from simple B<--help>
output by specifying a level above 1. They are only listed at/above
B<--help=>I<level>.

=item B<regex>

A regex a value needs to match. This has to be a parsed regex object,
not a plain string, so use something like

	regex=>qr/^\d+$/

to enforce unsigned integers. The check is applied per-element for
arrays and hashes (values only, not keys) at the end, after applying
operators. If the check fails, it is treated like a parameter parsing
error, normally ending your program.

A section definition can provide a default.

=item B<call>

A subroutine reference to call for validation or any processing you
would like after parsing a parameter from the command line, but before
settling operations. This means you get see B<--foo> and decide if this
should be translated to B<--foo.=42> instead of treating it as B<--foo=1>.
Any fancy operation may apply. You could just count things.

This is intended for interactive gimmics and not triggered during parsing
of configuration files. A forced argument gives you an implicit B<=>
operator, even if that might be translated to the append operator after
the call due to the parameter flags.

A prototype would be

	sub param_call # (name, sign, op, value)
	{
		print STDERR "Operation on $_[0].\n".
		print STDERR "You want to apply operation $_[2] to parameter $_[0].\n"
			if defined $_[2];
		print STDERR "The fresh value for $_[0]: $_[3]\n"
			if defined $_[3];
		return 0
			unless $_[0] =~ /^num/;
		$_[3] += 0; # force numeric nature
		return 1
			if $_[3] % 2; # Only even numbers!
		return 0; # all good
	}

The sign is either B<-> or B<+> relating to B<--foo> or B<++foo> usage. You can
modify this as well as operator and value. The operation and value could be
undefined if not provided by the user, but you can set them. Once the operator
is defined, a value must be set, too, and the sign does not matter
anymore. You can actually decide to set the value to undefined, a state that
normally cannot be restored after a parameter has been set in the usual way.

If the call returns non-zero, this is treated as an error in parameter handling
and the program ends unless you disabled that in your call to the library.
If you modify the name, or just undefine it, the setting will be dropped as if
the user did not specify anything.

A section definition can provide a default callback.

=back

An array definition contains four or more of the values for the above
hash keys in the documented order.

So, an elaborate definition may look like

	{
			 long     => 'friend'
			,value    => 'myself'
			,short    => 'f'
			,help     => 'name of a friend'
			,arg      => 'name'
			,flags    => $Config::Param::arg
			,addflags => 0
			,level    => 3
			,regex    => qr/[a-zA-Z]/
			,call     => sub { ... }
	}

or

	['friend', 'myself', 'f', 'name of a friend', 'name', $Config::Param::arg
	,	0, 3, qr/[a-zA-Z]/, sub { ... } ]

for brevity.

A set of flags modifies the parsing behaviour. They can be set globally as a
default, with each parameter definition possibly overriding those.
The parameter flags value is built by binary OR of these, so

	$Config::Param::arg|$Config::Param::append

means this parameter requires and argument and that is implicitly appended
to the current contents of the hash or array.

These are the possible flags:

=over 4

=item B<$Config::Param::count>

Turn B<-p> without option argument into B<-p+=1>, to effectively count the
number of times a switch was specified. This only has effect for scalar
parameters.

=item B<$Config::Param::arg>

Require an explicit argument. This allows the user to drop the equal sign between
option and value in favour of providing the value as following word on the command
line. For the short name, this even allows dropping any separator, like in

	-Wl,-R/foo/bar

to assign (or append, for an array) the value 'l,-R/foo/bar' to the parameter with the
short name 'W'.

=item B<$Config::param::switch>

Mark this scalar parameter as a switch that knows on and off, maybe counted.
This is the same as specifying an empty argument name. The option will still
accept an optional argument, but it will not be advertised.

=item B<$Config::Param::append>

Turn an assignment into appending to the array or hash. This even enables the extreme
case of storing a sequence of ones and zeros using

	-a +aa -a +a -aaa

to encode the binary sequence 10010111. More traditionally, the combination
with B<$Config::Param::arg> enables storing multple option arguments from

	-a hello -a world

into the array ('hello', 'world') without funky operator syntax.
This has no effect for scalar parameters.

=item B<$Config::Param::nonempty>

Triggers a error if the parameter does not contain some non-empty value
after parsing. This means something different than the empty string
or just undefined for scalars
and at least one element being present for arrays and hashes. The array or
hash element itself can still be empty.

If you also want to ensure some non-whitespace or actually non-empty
array or hash elements, use a regex check in addition.

=back

=head3 Sections

To structure the help output, you can also include hashes that do not
define a parameter, but a section of them instead. This structures the
printout for many parameters and gives you the chance to add some more prose
like that. Examples of section definitions:

	{ section=>'input' }

	{ section=>'some knobs', help=>'Tune -u -u --up!'
	, level=>2, flags=$Config::Param::count }

The help text is formatted to fit on the screen, so no fancy formatting besides
paragraphs is supposed to be present from your side.

The presence of section definitions also triggers printout of parameters in the
order you defined them. The optional level makes the section printout
only apppear at and above the given help level.


=head2 MEMBERS

The simple procedural interface consists of mainly one function, but also some:

=over 4

=item B<get>

	$parm_ref = Config::Param::get(\%config,\@pardef,\@cmdline_args, $errors);
	$parm_ref = Config::Param::get(@pardef);

This basically returns a hashref with parsed parameter values, from different variants of input (see SYNOPSIS). You can also fetch a reference to the error string array, which only makes sense when disabling final actions, which would happen normally (the function not returning at all).

=item B<valid_name>

	be_happy() if Config::Param::valid_name($long, $short);

Purely syntactical check for valid parameter names (letters, not (too many) funky symbols).

=item B<valid_type>

	be_happy() if Config::Param::valid_type($value);

This does not mean that Config::Param will do the correct thing with your complex cross-blessed data structure; just that it I<thinks> that it can, and will work with it as parameter intialization.

=item B<valid_def>

	be_happy() if Config::Param::valid_def(\%single_pardef);

Checks if a single parameter definition given as hash is formally correct (name and type). If you hand in a second argument, the type code is stored there.

=item B<hashdef>

	$parhash = Config::Param::hashdef(@def_array);

=item B<builtins>

	$builtin_names = Config::Param::builtins(\%config);
	print "$name is used as long or short" if $builtin_names->{$name};

As it is an error to try and define a parmameter that conflicts with predfined long/short names, this returns a hash for easy checking if something is used already (depending on %config).

=item B<sane_pardef>

	$problem = Config::Param::sane_pardef(\%config,\@pardef);
	die "bad parameter specification: $problem\n" if $problem;

This checks the parameter definition for issues (noted in $problem string) and brings it into the preferred form for internal consumption. Returns empty string if no problem encountered. The provided config is supposed to be identical to the one used later.

Using this function, you can prevent Config::Param::get() or Config::Param->new() from blowing up (using die()) on bad parameter specifications. If you do not take that extra care, it is assumed that blowing up is what you want on errors.

=item B<escape_pod>

Little function that takes a string and returns it with potential POD directives neutralized.

=back

The module also offers a class to work with. Most class members return 1 (true) on success, 0 on failure, also incrementing the error counter. That class has the following interesting members:

=over 4

=item B<new>

The constructor that normally wants this usage:

	$param = Config::Param->new(\%config, \@pardef);

It is possible to omit config hash and parameter definition and this can make sense if you intend to create the param space later on (p.ex. from a config file with meta data).

	$param = Config::Param->new(\%config);
or
	$param = Config::Param->new();
	# then do something to define parameters

=item B<define>

A method to define one single parameter:

	$param->define({long=>$longname, value=>$value, short=>$short, help=>$desc});

Here, the help can be a string or a reference to a string (a reference is stored, anyway).

=item B<good>

Return true if no errors are recorded (from bad definitions or command line arguments,
for example). If using instances of the class explicitly, you should make sure
you check this method before actually working with any resulting parmeter values.
Library versions before 4 aborted the program using die() or croak() on setup issues,
but now such errors are recorded for you to act on. Just dying deep in some library
is not polite.

=item B<find_config_files>

Use confdir and program to find possible config files (setting the the config parameter, it it is not set already).

	$param->find_config_files();

=item B<parse_args>

Parse given command line argument list, storing its settings in internal operator queue (step 1 of usual work).

	$param->parse_args(\@ARGV);

Returns true if no error occured during this or an earlier call to parse_args()
or apply_agrgs().

=item B<use_config_files>

Apply possible operations on config parameter and parse files indicated by that (step 2 of usual work).

	$param->use_config_files();

Returns true if no new error occured.

=item B<apply_args>

Apply the operations defined by the parsed argument list to the parameters (step 3 of usual work).

	$param->apply_args();

Returns true if no command line parsing error occured, meaning no error during this or earlier
calls to apply_args() or parse_args(). This changed subtly in version 4. Before that, it
returned if no errors occured at all, also from config files.
As it is and was no good idea to call this when errors occured before, this change should not
matter much, but makes the return value more consistent.

=item B<final_action>

Possibly execute final action as determined by parameter values or encountered errors,
like printing help or a configuration file and exit (step 4 or usual work). Without something
special to do, it just returns nothing. It also does nothing if nofinals is set and only
exists the program if noexit is unset.

	$param->final_action();

If called with a true value as argument,

	$para->final_action(1);

it only checks the internal error count, producing a final error message
if that is non-zero, and exists unless noexit is set. Other final actions are
not taking place. Since version 4, the non-zero exit values are
64 (EX_USAGE) to indicate errros in command-line syntax or parameter
semantics, 78 (EX_CONFIG) to indicate specific config-file syntax issues, or
70 (EX_SOFTWARE) for errors in my or your code (usage of the library). This
follows the conventions of sysexits.h.

=item B<parse_file>

Parse given configuration file. Optional parameter (when true) triggers full usage of meta data to complete/override setup.
If the given file specification is no full absolute path, it is searched in usual places or in specified configuration directory (see confdir).
Note that versions before 3.001 replaced a "~" at the beginning with the home directory. While that may be convenient in certain moments where the shell does not do that itself, such is still is the shell's task and possibly causes confusion.

	$param->parse_file($file, $construct);

This returns true if no new error occured.

=item B<print_file>

Print config file to given handle. Optional parameter gives a level of bareness, stripping meta info.

	$param->print_file(\*STDOUT, $bare);

=item B<current_setup>

Return configuration hash and parameter definition array that corresponds to the current state (copies that can be destroyed at will).

	($config, $pardef) = $param->current_setup();
	$param_copy = Config::Param->new($config, $pardef);

=item B<par_content>

	# dump in perl-parseable format, with some pretty indent
	$string = $param->par_content($name, 'dump', 2);
	# lines without other quoting
	$string = $param->par_content($name, 'lines');

Return a string representing the content to given parameter key, with optional choice of format. Default is 'dump' with indent 0. Other choice is 'lines' for putting the value on a line or multiple lines, in case of arrays/hashes (newlines in values just happen, too, undef values result in empty lines, empty arrays/hashes in nothing at all).
The third parameter chooses the indent style (see L<Data::Dumper>).

=item B<print_pod>

Print POD to configured output. This utilizes the parameter space plus the meta data you provided in the config hash, including the possible extra sections. Writing the documentation by hand would suck, wouldn't it? Never forget a parameter in the man page again!

=back

There are some member variables that are of interest (messing with those can have consequences, of course):

=over 4

=item B<param>

This is the internal parameter hash. If using the object interface, that is how you can actually access your configuration.

=item B<help>

	$par_description = ${$param->{help}{$name}};

=item B<short>

	$par_short = $param->{short}{$name}

=item B<long>

	$par_short = $param->{long}{$shortname}

=item B<files>

An array of files that have been parsed. You are free to reset that to be empty before loading a configuration file explicitly. After parsing, you have the list of all files that have been included (the intially given one plus files that have been included from there on).

=item B<errors>

An array of collected error messages. You are free to empty it to indicate a fresh start,
but make sure not to ignore errors created during parameter definition. Before version 4,
the library aborted the process when something went wrong in this stage. This was changed
to only end your program in an expected way during a call to final_action().

=back

Members not documented here can not be relied upon for future releases.

=head1 SEE ALSO

This module evolved from a simple loop for command line argument processing, that I thought was quicker written than to search for an already existing module for that. While just using some Getopt I<may> have been a bit quicker, this wouldn't fully do what I want and what numerous scripts I have written rely on. It may fully do what I<you> want, though - so better check this before blaming me for wasting your time with installing Config::Param.

This being yet another entry in the Config/Getopt category, there are lots of alternative packages doing similar things (see http://search.cpan.org/modlist/Option_Parameter_Config_Processing). But when you limit your search to packages that do command line processing, parsing of config files and do handle standard behaviour like generating usage messages, the crowd is well reduced. You might want to check out L<App::Options|App::Options>, which has the same basic functionality, but of course different enough in the details as well as basic philosophy to let me justify the existence of this module, at least to myself.

There is also L<Getopt::Euclid>, which somewhat works like the inverse, generating your parameter space from verbose description (POD) instead of generating the latter from the Perl data structure you provide. In any case, it is not concerned with config files.

=head1 AUTHOR

Thomas Orgis <thomas@orgis.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2022, Thomas Orgis.

This module is free software; you
can redistribute it and/or modify it under the same terms
as Perl 5.10.0. For more details, see the full text of the
licenses in the directory LICENSES.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

=cut


