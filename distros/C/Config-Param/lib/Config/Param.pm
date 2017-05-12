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

package Config::Param;

use strict;

use Carp;
use 5.008;
# major.minor.bugfix, the latter two with 3 digits each
# or major.minor_alpha
our $VERSION = '3.002000';
$VERSION = eval $VERSION;
our %features = qw(array 1 hash 1);

our $verbose = 0; # overriding config

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

	# Parsing errors are noted at the place and result in program end in finalize(), normally.
	$pars->parse_args($args);
	$pars->use_config_files();
	$pars->apply_args();
	$pars->final_action();

	$_[0] = $pars->{errors} if $give_error;
	return $pars->{param};
}

# Now the meat.

# Codes for types of parameters. It's deliberate that simple scalars are false and others are true.
my $scalar = 0; # Undefined also counts as scalar.
my $array = 1;
my $hash = 2;
my @initval  = (undef, [], {});
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
# Looking for /./ first should work out for getting the full operator.
# This extension does not work for short parameters, though, as there
# -a/./4.4
# is already parsed to mean to divide the value of a by "./4.4". That's behaviour that
# we cannot change just like that, even if it rarely makes sense.
my $ops = '.+\-*\/';
my $sopex = '['.$ops.']?=|['.$ops.']';
my $lopex = '\/.\/['.$ops.']?=|['.$ops.']?='; 
# rudimentary name check; manily forbid spaces and "="
my $parname = '\w[\w'.$ops.']*\w';

my $noop = '[^+\-=.*\/]'; # no operator

# Regular expressions for parameter parsing.
# The two variants are crafted to yield matching back-references.
# -x -x=bla -xyz
our $shortex_strict = qr/^(([-+])($noop+|($noop)($sopex)(.*)))$/;
# -x -x=bla -xyz x x=bla xyz 
our $shortex_lazy   = qr/^(([-+]?)($noop+|($noop)($sopex)(.*)))$/;
# --long --long=bla
our $longex_strict  = qr/^(([-+]{2})($parname)(($lopex)(.*)|))$/;
# --long --long=bla -long=bla long=bla
our $longex_lazy    = qr/^(([-+]{0,2})($parname)()($lopex)(.*)|(--|\+\+)($parname))$/;

my %example = 
(
	 'lazy'   => '[-]s [-]xyz [-]s=value --long [-[-]]long=value - [files/stuff]'
	,'normal' => '-s -xyz -s=value --long --long=value [--] [files/stuff]'
);
my $lazyinfo = "The [ ] notation means that the enclosed - is optional, saving typing time for really lazy people. Note that \"xyz\" as well as \"-xyz\" mention three short options, opposed to the long option \"--long\". In trade for the shortage of \"-\", the separator for additional unnamed parameters is mandatory (supply as many \"-\" grouped together as you like;-).\n";

my @morehelp =
(
	 'You mention the parameters/switches you want to change in any order or even multiple times (they are processed in the oder given, later operations overriding/extending earlier settings.'."\n"
	,'An only mentioned short/long name (no "=value") means setting to 1, which is true in the logical sense. Also, prepending + instead of the usual - negates this, setting the value to 0 (false).'."\n"
	,'Specifying "-s" and "--long" is the same as "-s=1" and "--long=1", while "+s" and "++long" is the sames as "-s=0" and "--long=0".'."\n"
	,"\n"
	,'There are also different operators than just "=" available, notably ".=", "+=", "-=", "*=" and "/=" for concatenation / appending array/hash elements and scalar arithmetic operations on the value. Arrays are appended to via "array.=element", hash elements are set via "hash.=name=value". You can also set more array/hash elements by specifying a separator after the long parameter line like this for comma separation:'."\n"
	,"\t--array/,/=1,2,3  --hash/,/=name=val,name2=val2\n"
);

# check if long/short name is valid before use
sub valid_name
{
	my ($long, $short) = @_;
	return 
	(
		(not defined $short or $short eq '' or $short =~ /^$noop$/o)
		and defined $long
		and not $long =~ /=/
		and $long =~ /^$noop/o
		and $long =~ /$noop$/
		and $long =~ /\D/
	);
}

sub valid_type
{
	my $type = lc(ref $_[0]);
	return $typemap{$type}; # undefined if invalid
}

sub valid_def
{
	my $def = shift;
	$_[0] = valid_type($def->{value});
	return (valid_name($def->{long}, $def->{short}) and defined $_[0]);
}

sub hashdef
{
	my %h = (long=>shift, value=>shift, short=>shift, help=>shift);
	$h{short} = '' unless defined $h{short};
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

	return "'".(defined $def->{long} ? $def->{long} : '')."' definition is not good"
		unless valid_def($def);
	return "'$def->{long}' ".(defined $def->{short} ? "/ $def->{short}" : '')." name alrady taken"
		if($name_there->{$def->{long}} or $name_there->{$short});
	$name_there->{$def->{long}} = 1;
	$name_there->{$short} = 1 if $short ne '';

	return ''; # no problem
}

# check if whole definition array is proper,
# modifying the argument to sanitize to canonical form
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
	$self->{printconfig} = 0;
	my $hh = 'show the help message; 1: normal help, >1: more help; "par": help for paramter "par" only';
	$self->{extrahelp} = '
Additional fun with negative values, optionally followed by comma-separated list of parameter names:
-1: list par names, -2: list one line per name, -3: -2 without builtins, -10: dump values (Perl style), -11: dump values (lines), -100: print POD.';
	my $ih = 'Which configfile(s) to use (overriding automatic search in likely paths);'."\n".'special: just -I or --config causes printing a current config file to STDOUT';

	# Choosing kindof distributed storage of parmeter properties, for direct access.
	# These explicit entries serve as a quick overview.
	$self->{param} = { help=>0, config=>[] };      # values
	$self->{help}  = { help=>\$hh, config=>\$ih }; # help texts
	$self->{long}  = { h=>'help', I=>'config' };   # map short names to long
	$self->{short} = { help=>'h', config=>'I' };   # map long names to short
	$self->{type}  = { help=>$scalar, config=>$array }; # types
	$self->{length} = 6; # character count of longes parameter name (right now, 'config')

	$self->define({long=>'version', value=>0, short=>'', help=>\'print out the program version'})
		if(defined $self->{config}{version});

	# deprecated v2 API
	$self->INT_error("Update your program: ignorehelp is gone in favour of nofinals!", 1) if exists $self->{config}{ignorehelp};
	$self->INT_error("Update your program: eval option not supported anymore.", 1) if exists $self->{config}{eval};

	my $problem = sane_pardef($self->{config}, $pars);
	$self->INT_error("bad parameter specification: $problem", 1) if $problem;

	for my $def (@{$pars})
	{
		# definition failure here is an error in the module
		die "Config::Param: very unexpected failure to define a parameter.\n"
			unless($self->define($def));
	}

	$self->find_config_files();

	# Chain of config files being parsed, to be able to check for inclusion loops.
	$self->{parse_chain} = [];

	return $self;
}

sub define
{
	my $self = shift;
	my $pd = shift;

	$pd->{help} = \'' unless defined $pd->{help};
	$pd->{short} = '' unless defined $pd->{short};
	my $type; # valid_def sets that
	unless(valid_def($pd, $type))
	{
		$self->INT_error("Invalid definition for $pd->{long} / $pd->{short}");
		return 0;
	}
	unless(defined $self->{param}{$pd->{long}} or defined $self->{long}{$pd->{short}})
	{
		$self->{type}{$pd->{long}}  = $type;
		$self->INT_verb_msg("defining $pd->{long} / $pd->{short} of type $typename[$type]\n");
		# If the definition value is a reference, make a deep copy of it
		# instead of copying the reference. This keeps the definition
		# and default value unchanged, for reproducible multiple runs of
		# the parser.
		if(ref $pd->{value})
		{
			require Storable; # Only require it if there is really the need.
			$self->{param}{$pd->{long}} = Storable::dclone($pd->{value});
		}
		else
		{
			$self->{param}{$pd->{long}} = $pd->{value};
		}
		$self->{long}{$pd->{short}} = $pd->{long} if $pd->{short} ne '';
		$self->{short}{$pd->{long}} = $pd->{short};
		$self->{help}{$pd->{long}}  = ref $pd->{help} ? $pd->{help} : \$pd->{help};
		$self->{length}             = length($pd->{long}) if length($pd->{long}) > $self->{length};
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

# Step 1: parse command line
sub parse_args
{
	my $self = shift;
	my $args = shift;

	my $olderrors = @{$self->{errors}};
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
		elsif($begin =~ /$shorts/o)
		{
			my $sign = $2;
			$sign = '-' if $sign eq '';
			my $sname = $4;
			my $op = $5;
			my $val = (defined $6 ? $6 : '').$end;
			$self->INT_verb_msg("a (set of) short one(s)\n");
			unless(defined $op)
			{
				$sname = $3;
				$val = $sign =~ /^-/ ? 1 : 0;
				$op = '=';
				$self->INT_verb_msg("sname=$sname, default op =\n");
				if($sname eq 'I'){ $self->{printconfig} += 1; undef $op; }
			}
			if(defined $op)
			{
				$op .= '=' unless $op =~ /=$/;
				$self->INT_verb_msg("sname=$sname op=$op\n");
				my @names; # the list of real parameters
				# check for valid parameter names
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
								$self->{param}{help} = 1;
								$self->INT_error("unknown short parameter \"$s\" not in (".join(',', sort keys %{$self->{long}}).")");
							}
						}
					}
				}
				last unless @names; # end parsing if switches invalidated

				for my $n (@names)
				{
					$self->INT_verb_msg("param $n\n");
					if($op eq '='){ $self->{ops}{$n} = [ '=', $val ]; }
					else{ push(@{$self->{ops}{$n}}, $op, $val); }
				}
			}
			shift(@{$args});
		}
		elsif($begin =~ $longex)
		{
			#yeah, long option
			my $sign = defined $7 ? $7 : $2;
			$sign = '--' if $sign eq '';
			my $name = defined $8 ? $8 : $3;
			$self->INT_verb_msg("param $name\n");
			my $op = $5;
			my $val = (defined $6 ? $6 : '').$end;
			$self->INT_verb_msg("val $val\n");
			$self->INT_verb_msg("from $begin$end\n");
			# hack for operators, regex may swallow the . in .=
			unless($name =~ /$noop$/o)
			{
				$op = substr($name,-1,1).$op;
				$name = substr($name,0,length($name)-1);
			}
			unless(defined $op)
			{
				$val = $sign =~ /^-/ ? 1 : 0;
				$op = '=';
				if($name eq 'config'){ $self->{printconfig} += 1; undef $op; }
			}
			if(defined $op)
			{
				# If it does not exist yet, it might come into existence via config file.
				if(exists $self->{param}{$name} or $self->{config}{accept_unknown})
				{
					$op .= '=' unless $op =~ /=$/;
					if($op eq '='){ $self->{ops}{$name} = [ '=', $val ]; }
					else{ push(@{$self->{ops}{$name}}, $op, $val); }
				}
				else
				{
					if($self->{config}{fuzzy})
					{
						$self->INT_verb_msg("Unknown long option $name, assuming that this is data instead.\n");
						last;
					}
					else
					{
						unless($self->{config}{ignore_unknown} and $self->{config}{ignore_unknown} > 1)
						{
							$self->{param}{help} = 1; 
							$self->INT_error("Unknown long parameter \"$name\" not in (".join(',', sort keys %{$self->{param}}).")");
						}
					}
				}
			}
			shift(@{$args});
		}
		else
		{
			$self->INT_verb_msg("No parameter, end.\n");
			last;
		} #was no option... consider the switch part over
	}
	return (@{$self->{errors}} == $olderrors);
}

# Step 2: Read in configuration files.
sub use_config_files
{
	my $self = shift;
	# Do operations on config file parameter first.
	$self->INT_apply_ops('config');

	# Now parse config file(s).
	return $self->INT_parse_files();
}

# Step 3: Apply command line parameters.
# This is complicated by accept_unknown > 2.
# I need to wait until config files had the chance to define something properly.
sub apply_args
{
	my $self = shift;
	for my $key (keys %{$self->{ops}})
	{
		$self->define({long=>$key}) if(not exists $self->{param}{$key} and $self->{config}{accept_unknown} > 1);
		if(exists $self->{param}{$key})
		{
			$self->INT_apply_ops($key);
		}
		elsif(not $self->{config}{ignore_unknown})
		{
			$self->{param}{help} = 1; 
			$self->INT_error("Unknown long parameter \"$key\" not in (".join(',', sort keys %{$self->{param}}).")");
		}
	}
	return not @{$self->{errors}};
}

# Step 4: Take final action.
sub final_action
{
	my $self = shift;
	return if($self->{config}{nofinals});

	my $handle = $self->{config}{output};
	$handle = \*STDOUT unless defined $handle;

	#give the help (info text + option help) and exit when -h or --help was given
	if($self->{param}{help})
	{
		$self->help();
		if(@{$self->{errors}})
		{
			print STDERR "There have been errors in parameter parsing. You should seek help.\n";
		}
		exit(@{$self->{errors}} ? 1 : 0) unless $self->{config}{noexit};
	}
	elsif(defined $self->{config}{version} and $self->{param}{version})
	{
		print $handle "$self->{config}{program} $self->{config}{version}\n";
		exit(0) unless $self->{config}{noexit};
	}
	elsif($self->{printconfig})
	{
		$self->print_file($handle, ($self->{printconfig} > 1));
		exit(0) unless $self->{config}{noexit};
	}
}

# Helper functions...

# Produce a string showing the value of a parameter, for the help.
sub par_content
{
	my $self = shift;
	my $k = shift; # The parameter name.
	my $format = shift; # formatting choice
	if(not defined $format or $format eq 'dump')
	{
		if(eval { require Data::Dumper })
		{
			local $Data::Dumper::Terse = 1;
			local $Data::Dumper::Deepcopy = 1;
			local $Data::Dumper::Indent = shift;
			$Data::Dumper::Indent = 0 unless defined $Data::Dumper::Indent;
			local $Data::Dumper::Sortkeys = 1;
			local $Data::Dumper::Quotekeys = 0;
			return Data::Dumper->Dump([$self->{param}{$k}]);
		}
		else{ return "$self->{param}{$k}"; }
	}
	elsif($format eq 'lines')
	{
		return "\n" unless(defined $self->{param}{$k});
		if($self->{type}{$k} == $array)
		{
			return "" unless @{$self->{param}{$k}};
			return join("\n", @{$self->{param}{$k}})."\n";
		}
		elsif($self->{type}{$k} == $hash)
		{
			my $ret = '';
			for my $sk (sort keys %{$self->{param}{$k}})
			{
				$ret .= "$sk=$self->{param}{$k}{$sk}\n";
			}
			return $ret;
		}
		else{ return "$self->{param}{$k}\n"; }
	} else{ $self->INT_error("unknown par_content format: $format"); }
}

# Fill up with given symbol for pretty indent.
sub INT_indent_string
{
	my ($indent, $prefill) = @_;
	return ($indent > $prefill)
		? (($prefill and ($indent-$prefill>2)) ? '.' : ' ')x($indent - $prefill - 1).' '
		: '';
}

# simple formatting of some lines (breaking up with initial and subsequent indendation)
sub INT_wrap_print
{
	my ($handle, $itab, $stab, $length) = (shift, shift, shift, shift);
	return unless @_;
	# Wrap if given line length can possibly hold the input.
	if($length > length($itab) and $length > length($stab) and eval { require Text::Wrap })
	{
		local $Text::Wrap::columns = $length;
		local $Text::Wrap::unexpand = 0;
		print $handle Text::Wrap::wrap($itab, $stab, @_);
	}
	else # wrapping makes no sense
	{
		print $handle $itab.(shift @_);
		for(@_){ print $stab.$_; }
	}
}

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
			$usage = $2 if $2 ne '';
			shift(@desc);
			while(@desc and $desc[0] =~ /^\s*$/){ shift @desc; }

			# if the real deal follows on a later line
			if(not defined $usage and @desc)
			{
				$usage = shift @desc;
				$usage =~ s/^\s*//;
				$usage =~ s/\s*$//;
			}
		}
	}
	if(defined $prog)
	{
		print $handle "=head1 NAME\n\n$prog";
		print $handle " - $tagline" if defined $tagline;
		print $handle "\n\n";
	}
	if(defined $usage)
	{
		print $handle "\n=head1 SYNOPSIS\n\n";
		print "\t$_\n" for(split("\n", $usage));
	}
	if(@desc)
	{
		print $handle "\n=head1 DESCRIPTION\n\n";
		for(@desc){ print $handle escape_pod($_), "\n"; }
		print $handle "\n";
	}
	my $nprog = defined $prog ? $prog : 'some_program';

	print $handle "=head1 PARAMETERS\n\n";
	print $handle "These are the general rules for specifying parameters to this program:\n";
	print $handle "\n\t$nprog ";
	if($self->{config}{lazy})
	{
		print $handle escape_pod($example{lazy}),"\n\n";
		print $handle escape_pod($lazyinfo),"\n";
	}
	else
	{
		print $handle escape_pod($example{normal}),"\n\n";
	}
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

# Well, _the_ help.
sub help
{
	my $self = shift;
	my $handle = $self->{config}{output};
	$handle = \*STDOUT unless defined $handle;
	my $indent = $self->{length} + 4; # longest long name + ", s " (s being the short name)

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

	if($self->{param}{help} =~ /^(-\d+),?(.*)$/)
	{
		my $code = $1;
		my @keys = split(',', $2);

		if($code == -1)
		{ # param list, wrapped to screen
			INT_wrap_print($handle, '', '', $linewidth, "List of parameters:\n");
			INT_wrap_print($handle, '', '', $linewidth, join(' ', sort keys %{$self->{param}})."\n");
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
			print STDERR "\n\n";
		}
		return;
	}

	if($self->{param}{help} =~ /\D/)
	{
		my $k = $self->{param}{help};
		if(exists $self->{param}{$k})
		{
			print $handle "Parameter:\n\t$k".($self->{short}{$k} ne '' ? ", $self->{short}{$k}" : '')."\n";
			my $c = $self->par_content($k, 'dump', 1); $c =~s/\n/\n\t/g;
			print $handle "Value:\n\t$c\n";
			print $handle "Help:\n";
			INT_wrap_print($handle, "\t","\t", $linewidth, ${$self->{help}{$k}});
			INT_wrap_print($handle, "\t","\t", $linewidth, $self->{extrahelp})
				if $k eq 'help';
			print "\n";
		}
		else
		{
			print STDERR "Parameter $self->{param}{help} is not defined!\n";
		}
		return;
	}

	my $vst = (defined $self->{config}{version} ? "v$self->{config}{version} " : '');
	if(defined $self->{config}{tagline})
	{
		INT_wrap_print($handle, '', '', $linewidth, "\n$self->{config}{program} ${vst}- ",$self->{config}{tagline},"\n");
		INT_wrap_print($handle, '', '', $linewidth, "\n$self->{config}{copyright}\n")
			if defined $self->{config}{copyright};
		if(defined $self->{config}{usage})
		{
			print $handle "\nUsage:\n";
			INT_wrap_print($handle, "\t","\t", $linewidth, $self->{config}{usage}."\n");
		}
		INT_wrap_print($handle, '', '', $linewidth, "\n$self->{config}{info}\n")
			if defined $self->{config}->{info};
	}
	else
	{
		INT_wrap_print($handle, '', '', $linewidth, "\n$self->{config}{program} ${vst}- ".$self->{config}{info}."\n") if defined $self->{config}->{info};
		INT_wrap_print($handle, '', '', $linewidth, "\n$self->{config}{copyright}\n")
			if defined $self->{config}{copyright};
	}

	INT_wrap_print($handle, '', '', $linewidth, "\nGeneric parameter example (list of real parameters follows):\n\t$self->{config}{program} ");
	if($self->{config}{lazy})
	{
		print $example{lazy},"\n";
		if($self->{param}{help} > 1)
		{
			INT_wrap_print($handle, '', '', $linewidth, $lazyinfo);
		}
	}
	else
	{
		print $example{normal},"\n";
	}
	if($self->{param}{help} > 1)
	{
		INT_wrap_print($handle, '', '', $linewidth, "\n", @morehelp)
	}
	else
	{ # Don't waste so many lines by default.
		INT_wrap_print($handle, '', '', $linewidth
			, "Just mentioning -s equals -s=1 (true), while +s equals -s=0 (false).\n"
			, "Using separator \"--\" makes sure that parameter parsing stops.\n"
		)
	}
	INT_wrap_print($handle, '', '', $linewidth, "\n", "Recognized parameters:\n");
	my $preprint = "NAME, SHORT ";
	print $handle $preprint.INT_indent_string($indent, length($preprint))."VALUE [# DESCRIPTION]\n";
	my @hidden;
	for my $k ( sort keys %{$self->{param}} )
	{
		unless($self->{config}{hidenonshort} and $self->{short}{$k} eq '' and not ($k eq 'version' and defined $self->{config}{version}))
		{
			# long, s 
			my $prefix = $k;
			$prefix .= ", $self->{short}{$k}" if($self->{short}{$k} ne '');
			$prefix .= ' ';
			my $i = length($prefix);
			my $content = $self->par_content($k, 'dump', 0);
			my $stab = ' ' x $indent;
			my @help = split("\n", ${$self->{help}{$k}});
			push(@help, split("\n", $self->{extrahelp}))
				if($k eq 'help' and $self->{param}{help} > 1);
			$help[0] = $prefix.INT_indent_string($indent, $i).$content.($help[0] ne '' ? " # $help[0]" : '');
			for my $h (@help)
			{
				# First line needs no further initial indent.
				my $itab = $i ? '' : $stab;
				$i = 0;
				INT_wrap_print($handle, $itab, $stab, $linewidth, $h."\n");
			}
		}
		else{ push(@hidden, $k); }
	}
	if($self->{param}{help} > 1 and @hidden)
	{
		INT_wrap_print($handle, '', '', $linewidth, "\nThere ".($#hidden == 0 ? 'is one hidden parameter' : "are ".($#hidden+1)." hidden parameters")." intended for use in config files (but also settable via cmdline):\n");
		INT_wrap_print($handle, "\t", "\t", $linewidth, "@hidden\n");
		INT_wrap_print($handle, '', '', $linewidth, "\nRun me with just -I or --config to get a config file on stdout (the console) with the help info and current values.\n");
	}
	elsif(@hidden)
	{
		INT_wrap_print($handle, '', '', $linewidth, "\nHidden parameters: @hidden\n");
	}
	print $handle "\n";
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
	my $olderrors = @{$self->{errors}};
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
				next if ($_ =~ /^\s*#?\s*$lend$/o);

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
							$self->INT_apply_op($par, $op, $val);
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
						$self->INT_apply_op($mkey, $mop, $multiline);
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

	return (@{$self->{errors}} == $olderrors);
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

# The low-level worker for applying one parameter operation.
sub INT_apply_op
{
	my $self = shift; # (par, op, value)
	return unless exists $self->{param}{$_[0]};


	if($self->{type}{$_[0]} == $scalar)
	{
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
		elsif($_[1] =~ m:^/(.)/(.*)$:) # operator with specified array separator
		{
			my $sep = $1; # array separator
			my $op  = $2; # actual operator
			my @values = split($sep, $_[2]);
			if   ($op eq  '='){ @{$par} = @values; }
			elsif($op eq '.='){ push(@{$par}, @values); }
			else{ $bad = 1; }
		}
		else{ $bad = 1 }
		if($bad)
		{
			$self->INT_error("Operator '$_[1]' is invalid for array '$_[0]'!");
			$self->{param}{help} = 1;
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
			my @values = split($sep, $_[2]);
			# a sub just to avoid duplicating the name=value splitting and setting
			sub INT_push_hash
			{ my $par = shift; for (@_) {
				my ($k, $v) = split('=',$_,2);
				$par->{$k} = $v;
			}}
			if   ($op eq  '='){ %{$par} = (); INT_push_hash($par,@values); }
			elsif($op eq '.='){ INT_push_hash($par,@values); }
			else{ $bad = 1; }
		}
		else
		{
			# looking for key at begining (first line only)
			my ($key, $hval) = split('=', $_[2],2);
			if   ($_[1] eq  '='){ %{$par} = ( $key=>$hval ); }
			elsif($_[1] eq '.='){ $par->{$key} = $hval; }
			else{ $bad = 1 }
		}
		if($bad)
		{
			$self->INT_error("Operator '$_[1]' is invalid for hash '$_[0]'!");
			$self->{param}{help} = 1;
		}
	}
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
	my $fatal =  $_[1] ? 'FATAL ' : '';
	print STDERR "[Config::Param] ${fatal}Error: ", $_[0], "\n" unless $self->{config}{silenterr};
	push(@{$self->{errors}}, $_[0]);
	croak "Config::Param gives up because of $_[0]\n" if ($fatal and not $self->{config}{noexit});
	return 1;
}

1;

__END__


=head1 NAME

Config::Param - all you want to do with parameters for your program (or someone else's)

=head1 SYNOPSIS

Just use the module, define your parameters

	use Config::Param;

	# the definitions in flat array
	# remember: parameters help / h	and config / I are predefined!
	my @pardef =
	(
	   'parm1', $default1,  'a', 'help text for scalar 1'
	  ,'parm2', $default2,  'b', 'help text for scalar 2'
	  ,'parmA', \@defaultA, 'A', 'help text for array A'
	  ,'parmH', \@defaultH, 'H', 'help text for hash H'
	  ,'parmX', $defaultX,  '', 'help text for last one (scalar)'
	);

and call the parser,

	$parm_ref = Config::Param::get(@pardef);

	print "Value of parameter 'parm1': $parm_ref->{parm1}\n";
	print "Contents of array 'parmA': @{$parm_ref->{parmA}}\n";

possibly including some extra configuration,

	my %config =
	(
	  'info' => 'program info text',
	  'version' => '1.2.3'
	  # possibly more configuration key/value pairs
	);
	$parm_ref = Config::Param::get(\%config, @pardef);

or

	$parm_ref = Config::Param::get(\%config,\@pardef); 

or

	$parm_ref = Config::Param::get(\%config,\@pardef,\@cmdline_args); 

The most complicated call is this, making only sense when disabling final exit:

	$config{noexit} = 1; # or nofinals
	$parm_ref = Config::Param::get(\%config,\@pardef,\@cmdline_args, $errors); 

This will return a count of errors encountered (bad setup, bad command line args). With default configuration, the routine would not return on error, but end the program. Errors will be mentioned to STDERR in any case.

Finally, you can use a Config::Param object to do what Config::Param::get does:

	# equivalent to
	# $parm_ref = Config::Param::get(\%config,\@pardef);
	my $pars = Config::Param->new(\%config, \@pardef);
	$pars->parse_args(\@ARGV);
	$pars->use_config_files();
	$pars->apply_args();
	$pars->final_action();
	$parm_ref = $pars->{param};

=head1 DESCRIPTION

The basic task is to take some description of offered parameters and return a hash ref with values for these parameters, influenced by the command line and/or configuration files. The simple loop from many years ago now is about the most comprehensive solution for a program's param space that I am aware of, while still supporting the one-shot usage via a single function call and a flat description of parameters.

It handles command line parameters (somewhat flexible regarding the number of "-", but insisting on the equal sign in B<--name=value>), defining and handling standard parameters for generating helpful usage messages and  parses as well as generates configuration files.

=head2 command line parameter processing

Process command line options/switches/parameters/... , be it short or long style, supporting clustering of short options. Interprets B<--parm=value> / B<-p=value> with the obvious effect; sets option to 1 (which is true) when just B<--option> / B<-o> is given.
Also, though somewhat counterintuitive but sort of a standard already and logically following the idea that "-" is true, B<++option> / B<+o> will set the value to 0 (false).
The form "--parm value" is not supported as no simple bullet-proof generic way to do that came across my mind. There is the fundamental problem of deciding if we have a parameter value or some other command line data like a file name to process. Since this problem still persists with the "=" used in assignment when one considers a file with a name like "--i_look_like_an_option", which is perfectly possible, Param also looks out for "--" as a final delimiter for the named parameter part, which is also quite common behaviour. The command line arguments after "--" stay in the input array (usually @ARGV) and can be used by the calling program. The parsed parameters as well as the optional "--" are removed; so, if you want to retain your @ARGV, just provide a copy.

You can have scalars, hashes or arrays (references, of course) as values for your parameters. The hash/array type is chosen when you provide an (anonymous) hash/array reference as default value.

Hash values are set via prefixing a key with following "=" before the actual value:

	--hashpar=name=value

A nifty feature is the support of operators. Instead of B<--parm=value> you can do do B<--parm.=value>  to append something to the existing value. When B<-p> is the short form of B<--parm>, the same happens through B<-p.=value> or, saving one character, B<-p.value> (but I<not> B<--parm.value>, here the dot would be considered part of the parameter name).
So "B<--parm=a --parm.=b -p.c>" results in the value of B<parm> being "abc".

This is especially important for sanely working with hashes and arrays:

	--hashpar.=name=value --hashpar.=name2=value2
	--arraypar=value --arraypar.=value2

The plain "=" operator resets the whole array/hash! For arrays and hashes, there is another specialty: You can specify a single-character separator to split up the argument by enclosing it in forward slashes before the plain operator:

	--hashpar/,/=name=value,name2=value2 --hashpar/:/.=name3=value3:name4=value4
	--arraypar/,/=a,b,c --arraypar/:/.=d:e:f

This extension is only present for the syntax using long parameter names, where the
equal sign is mandatory. So be aware of

	-a/,/3,4

meaning to divide the value of a by ",/3,4" (which is nonsense, but valid syntax already without
the extension for array/hash separators). Even adding an equal sign would not change this.

There is no advanced parsing with quoting of separator characters --- that's why
you can choose an appropriate one so that simple splitting at occurences does the
right thing.

These plain operators are available:

=over 4

=item B<B<=>>

Direct assignment.

=item B<B<.=>> or short B<.>

String concatenation for scalar parameters, pushing values for array and hash parameters.

=item B<B<+=>> or short B<+>

Numeric addition to scalar value.

=item B<B<-=>> or short B<->

Numeric substraction to scalar value.

=item B<B<*=>> or short B<*>

Numeric multiplication of scalar value.

=item B<B</=>> or short B</>

Numeric division of scalar value.

=back

You can omit the B<=> for the short-form (one-letter) of parameters on the command line when using special operators, but not in the configuration file.
There it is needed for parser safety. The operators extend to the multiline value parsing in config files, though (see the section on config file syntax).

See the B<lazy> configuration switch for a modified command line syntax, saving you some typing of "-" chars.

=head2 automatic usage/version message creation

Based on the parameter definition Config::Param automatically prints the expected usage/help message when the (predefined!) B<--help> / B<-h> was given, with the info string in advance when defined, and exits the program. You can turn this behaviour off, of course. An example for the generated part of the help message:

	par_acceptor v1.0.0 - Param test program that accepts
	any parameter given

	Generic parameter example (list of real parameters
	follows):
	        par_acceptor -s -xyz -s=value --long --long=value [--] [files/stuff]
	Just mentioning -s equals -s=1 (true), while +s equals
	-s=0 (false).
	Using separator "--" makes sure that parameter parsing
	stops.

	Recognized parameters:
	NAME, SHORT   VALUE [# DESCRIPTION]
	ballaballa .. '0' # a parameter with meta data
	bla ......... ['1']
	blu ......... '42'
	config, I ... [] # Which configfile(s) to use
	              (overriding automatic search in likely
	              paths);
	              special: just -I or --config causes
	              printing a current config file to STDOUT
	help, h ..... 1 # show the help message; 1: normal
	              help, >1: more help; "par": help for
	              paramter "par" only
	includepar .. 'I got included, yeah!'
	version ..... 0 # print out the program version


Note: When printing to a terminal, Config::Param tries to determine the screen width and does a bit of formatting to help readability of the parameter table.

=head2 configuration file parsing

The module also introduces a simple but flexible configuration file facility. Configuration means simply setting the same parameters that are available to the command line.

The second and last predefined parameter called "config" (short: I) is for giving a file (or several ones, see below!) to process I<before> the command line options are applied (what the user typed is always the last word). If none is given, some guessing may take place to find an appropriate file (see below).
When just B<-I> or B<--config> is given (no B<=>!), then a file with the current configuration ist written to STDOUT and the program exits (unless B<ignorefinals> is set).
When you give the lonely B<-I> or B<--config> once, you'll get a explained config file with comments and meta info, when you give the option twice, you get a condensed file with only the raw settings and a small header telling for which program it is.

Config files are parsed before applying command line arguments, so that the latter can override settings.

=head2 configuration file creation

Well, of course the module will also create the configuration files it consumes, giving B<--conf> or B<-I> without further argument triggers writing of a configuration file to standard output and exit of program

=head3 Configuration file syntax

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

This will locate anotherconfigfile either via absolute path or relative to the currently parsed file. Search paths are B<not> used (this was documented erroneously before). Its settings are loaded in-place and parsing continues with the current file.  The file name starts with the first non-whitespace after B<=include> and continues until the end of line. No quoting. If the given name does not exist, the ending .conf is added and that one tried instead. The parsing aborts (croaks) if an inclusion loop is detected.

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

A text to print out before the parameter info when giving help.

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

hide parameters that don't have a short name in --help output (p.ex. multiline stuff that one doesn't want to see outside of config files)

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

The one-line reason for your program to exist. The motto, whatever. If not given, the first line of the info string is used. Please give either none or both of B<tagline> and B<usage>.

=item B<usage>

Usage string summing up basic calling of the program. If not present, the info string might get harvested for that, if it contains such:

	usage: program [parameters] some.conf [parameters] [param names]

or

	usage:
	  program [parameters] some.conf [parameters] [param names]

(with arbitrary number of empty lines in between). Please give either none or both of B<tagline> and B<usage>.

=back

=head1 MEMBERS

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

Parameter definitions are a plain array or an array of hashes/arrays:

	@params = (  'long1',0,'l','some parameter'
	            ,'long2',1,'L','another parameter' );
	@params = (  ['long1',0,'l','some parameter']
	            ,['long2',1] ); # omitted stuff empty/undef by default
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

You can mix hash and array refs with each other, but not with plain values. if the first element is no reference, Config::Param checks if the total count is a multiple of 4 to catch sloppyness on your side.

If it is ever decided to extend the definition of parameters for Config::Param, that extension will be possible via hash/array ref specifications.

It is possible to omit config hash and parameter definition and this can make sense if you intend to create the param space later on (p.ex. from a config file with meta data).

	$param = Config::Param->new(\%config);
	$param = Config::Param->new();
	# then do something to define parameters

=item B<define>

A method to define one single parameter:

	$param->define({long=>$longname, value=>$value, short=>$short, help=>$desc});

Here, the help can be a string or a reference to a string (a reference is stored, anyway).

=item B<find_config_files>

Use confdir and program to find possible config files (setting the the config parameter, it it is not set already).

	$param->find_config_files();

=item B<parse_args>

Parse given command line argument list, storing its settings in internal operator queue (step 1 of usual work).

	$param->parse_args(\@ARGV);

=item B<use_config_files>

Apply possible operations on config parameter and parse files indicated by that (step 2 of usual work).

	$param->use_config_files();

=item B<apply_args>

Apply the operations defined by the parsed argument list to the parameters (step 3 of usual work).

	$param->apply_args();

=item B<final_action>

Possibly execute final action as determined by parameter values or encountered errors, like printing help or a configuration file and exit (step 4 or usual work). Without something special to do, it just returns nothing.

	$param->final_action();

=item B<parse_file>

Parse given configuration file. Optional parameter (when true) triggers full usage of meta data to complete/override setup.
If the given file specification is no full absolute path, it is searched in usual places or in specified configuration directory (see confdir).
Note that versions before 3.001 replaced a "~" at the beginning with the home directory. While that may be convenient in certain moments where the shell does not do that itself, such is still is the shell's task and possibly causes confusion.

	$param->parse_file($file, $construct);

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

An array of collected error messages. You are free to empty it to indicate a fresh start.

=back

Members not documented here can not be relied upon for future releases.

=head1 SEE ALSO

This module evolved from a simple loop for command line argument processing, that I thought was quicker written than to search for an already existing module for that. While just using some Getopt I<may> have been a bit quicker, this wouldn't fully do what I want and what numerous scripts I have written rely on. It may fully do what I<you> want, though - so better check this before blaming me for wasting your time with installing Config::Param.

This being yet another entry in the Config/Getopt category, there are lots of alternative packages doing similar things (see http://search.cpan.org/modlist/Option_Parameter_Config_Processing). But when you limit your search to packages that do command line processing, parsing of config files and do handle standard behaviour like generating usage messages, the crowd is well reduced. You might want to check out L<App::Options|App::Options>, which has the same basic functionality, but of course different enough in the details as well as basic philosophy to let me justify the existence of this module, at least to myself.

There is also L<Getopt::Euclid>, which somewhat works like the inverse, generating your parameter space from verbose description (POD) instead of generating the latter from the Perl data structure you provide. In any case, it is not concerned with config files.

=head1 AUTHOR

Thomas Orgis <thomas@orgis.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2016, Thomas Orgis.

This module is free software; you
can redistribute it and/or modify it under the same terms
as Perl 5.10.0. For more details, see the full text of the
licenses in the directory LICENSES.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

=cut


