package CmdArguments;

use strict;

use vars qw($VERSION);

$VERSION = '1.00';

=head1 NAME

CmdArguments - Module to process arguments passed on command line

=head1 SYNOPSIS

    # program name args.pl
    use CmdArguments;

    my $var1 = 10;          # initialize variable
    my $var2 = 0;           # with default values.
    my @var3 = ( 1, 2, 3);  # well, if you like to.
    my @var4;               # but, not necessary

    my $parse_ref = [
                     [ "arg1", \$var1 ], # argTypeScalar is assumed
                     [ "arg2", \$var2,
                       {TYPE => argTypeSwitch}], # explicit argTypeSwitch
                     [ "arg3", \@var3 ], # argTypeArray assumed
                     [ "arg4", \@var4,
                       {UNIQUE => 1}], # argTypeArray assumed
                    ];

    CmdArguments::parse(@ARGV, $parse_ref);

    print "var1 = $var1\n";
    print "var2 = $var2\n";
    print "var3 = @var3\n";
    print "var4 = @var4\n";

    exit 0;

test command ...

    args.pl -arg1 23 -arg2 -arg3 2 4 3 2 5 -arg4 2 4 3 2 4

should generate following output...

    var1 = 23
    var2 = 1
    var3 = 2 4 3 2 5
    var4 = 2 4 3

=head1 DESCRIPTION

This module provides some handy functions to process
command line options.

When this module is included it introduces following
constants in the calling program namespace...

    argTypeScalar = 0
    argTypeArray  = 1
    argTypeSwitch = 2

=cut

sub BEGIN {
    use constant argTypeScalar => 0;
    use constant argTypeArray  => 1;
    use constant argTypeSwitch => 2;
    use constant argTypeHash   => 3;

    my $pkg = caller;
    no strict 'refs';
    *{"${pkg}::argTypeScalar"} = sub () { argTypeScalar };
    *{"${pkg}::argTypeArray"}  = sub () { argTypeArray };
    *{"${pkg}::argTypeSwitch"} = sub () { argTypeSwitch };
    *{"${pkg}::argTypeHash"}   = sub () { argTypeHash };
}

=over 1

=item B<CmdArguments::parse>

Simplest way to use this program is to call B<parse> (static function).

Calling syntax is...

I<parse(L<@arguments|@arguments>, L<$array_ref|$array_ref>,
I<L<$text_or_func1|$text_or_func1>>, I<L<$text_or_func2|$text_or_func2>>)>

=over 2

=item I<@arguments>

array of command line arguments. So, @ARGV could be passed instead.

=item I<$array_ref>

reference to an array containing information about how to
parse data in @arguments.

basic structure of $array_ref is...

$array_ref = [ I<$array_ref_for_individual_tag>, ...];

$array_ref_for_individual_tag = [I<L<$option_tag|$option_tag>>
, I<L<$ref_of_variable|$ref_of_variable>>,
I<L<$hash_ref|$hash_ref>>]; # $hash_ref is optional

=over 3

=item I<$hash_ref>

reference to a hash containing supplementary information about $option_tag

  $hash_ref = {
    TYPE   => argType..., # argTypeSwitch
                          # argTypeArray or argTypeScalar

    UNIQUE => 1,          # 1 or 0

    USAGE  => "help information", # try giving -h or -help
                                  # on command line

    FUNC   => sub { eval $_[0] }
  };

=over 4

=item TYPE

this specifies what kind of variable reference is passed in
$ref_of_variable. If TYPE is argTypeScalar or argTypeSwitch
it assumes reference to a scalar. If TYPE is argTypeArray it
assumes reference to an array.

if TYPE tag is not provided then ...

1. I<argTypeScalar> is assumed if $ref_of_variable is a scalar reference

2. I<argTypeArray> is assumed if $ref_of_variable is an array reference

=over 5

=item What is argType...?

=over 6

=item argTypeSwitch

on command line you can not provide value for an option.

=item argTypeScalar

on command line you must provide one and only one value

=item argTypeArray

on command line you can provide zero or more values

=back 6

=back 5

=item UNIQUE

this tag is applicable for option type I<argTypeArray> only.
it can be 0 or 1. 1 means make unique array. So, if an
option is defined as UNIQUE then on command line if you
give say 2 3 4 5 3 4 6 7 then array will hold 2 3 4 5 6 7.
If it was not unique then it will hold 2 3 4 5 3 4 6 7.

=item FUNC

Holds a reference to a function. Function should take
a scalar argument and return a scalar if option is
argTypeScalar and return an array if option is
argTypeArray. This is not used for option type argTypeSwitch.

Example: if option type is an argTypeArray. and function is
defined like

FUNC => sub { eval $_[0] }

and if on the command line something like 1..3 or 1,2,3
is passed then it will generate an array having values 1 2 3.

=back 4

=item I<$ref_of_variable>

Can pass reference of a scalar or an array variable
depending on what require from command line.

=item I<$option_tag>

It is the name of the option tag. if option tag is I<opt> then
on command line you have to specify option like I<-opt>.

=back 3

=item $text_or_func1

=item $text_or_func2

pass text or reference to a function. If function is passed
it should return text or should itself print message on
STDERR. Try experimenting by passing -h or -help in the argument.
$text_or_func1 is printed after the help text is printed and
$text_or_func1 is used before printing helptext.

=back 2

=back 1

=cut

sub parse (\@@) {
    my ($arg_ref, $process, $postusage, $preusage) = @_;

    use constant argTagField  => 0;
    use constant argVarField  => 1;
    use constant argHashField => 2;

    my %functions = (argTypeScalar+0 => "argScalar",
		     argTypeArray+0  => "argArray",
		     argTypeHash+0  => "argHash",
		     argTypeSwitch+0 => "argSwitch");

    my $args = CmdArguments->beginArg(@$arg_ref);
    foreach my $argsyntax (@$process) {
	my $typehash = (defined $argsyntax->[argHashField]
			? $argsyntax->[argHashField] : {});

	my $tag     = $argsyntax->[argTagField];
	my $var     = $argsyntax->[argVarField];
	my $type    = _value($typehash->{TYPE});
	my $sub     = _value($typehash->{FUNC});
	my $unique  = _value($typehash->{UNIQUE});
	my $usage   = _value($typehash->{USAGE});
	my $dispOpt = _value($typehash->{DISPOPTION});
	my $params  = _value($typehash->{PARAMS});

	unless (defined $type) {
	    $type = argTypeScalar if ref($var) eq 'SCALAR';
	    $type = argTypeArray  if ref($var) eq 'ARRAY';
	    $type = argTypeHash   if ref($var) eq 'HASH';
	    unless (defined $type) {
		die "ERROR: option ($tag) - variable should be a reference\n";
	    }
	}

	my @arguments = ($tag => $var, usage => $usage,
			 dispOption => $dispOpt,
			 func => $sub, unique => $unique, params => $params);

	if (exists $functions{$type}) {
	    my $function = $functions{$type};
	    $args->$function(@arguments);
	} else {
	    die "Please check type ($type)\n";
	}
    }

    my @return = ();
    if (wantarray) {
	@return = $args->endArg;
    } else {
	$args->endArg;
    }
    $args->usage($preusage, $postusage);
    return @return;
}

# Start Argument processing
# usage: my $arg = CmdArguments->beginArg(@ARGV);
sub beginArg {
    my ($class, @argv) = @_;

    my $self = {};
    bless $self, $class;

    # trap the arguments
    $self->{ARGS} = @argv ? [@argv] : \@ARGV;
    # usage string in case of help or error
    $self->{USAGE} = "";
    # required for generating variable names
    $self->{_TMPNUM} = 0;

    # trap the original accumulator;
    $self->{_ACCUMULATOR} = $^A;

    # temporay variable
    # to store help status
    my $tmpHelpVar = 0;
    $self->{_HELPSAT} = \$tmpHelpVar;

    # hash where reference user supplied
    # variables are stored
    $self->{_VARIABLES} = {};
    # hash where user defined functions are stored
    $self->{_FUNCTIONS} = {};

    # used in case wrong option is given
    $self->{_UNKNOWN_OPTIONS} = [];

    # begin generating main loop
    $self->{LOOP_STRING} = <<'BEGINARG';
    while (@{$self->{ARGS}}) {
        $_ = shift @{$self->{ARGS}};
BEGINARG

    return $self;
}

# process scalar argument
# usage: $arg->argScalar(option => \$scalar_variable,
#                        usage => "description",
#                        func => sub { return $_[0] });
sub argScalar {
    my $self   = shift;

    # get user supplied argument and variable (where
    # value is to be stored) and other options
    my ($arg, $variable, %options) = _makeOptions(@_);

    # store user supplied function and variable
    my ($varName, $funName) = $self->_getVarAndFuncName($variable,
							$options{func}
							|| undef);
    # generate code to handle scalar option
    $self->{LOOP_STRING} .= <<OPRIONARG;
        \/^-($arg)\$\/ && ( do { my \$value = shift(\@{\$self->{ARGS}});
                               \${\$self->{_VARIABLES}{$varName}}
                                  = \$self->{_FUNCTIONS}{$funName}->(\$value);
                          }, next
                        );
OPRIONARG

    # make usage
    $self->_makeUsage($arg, %options);
}

# process switch argument
# passed variable will be turned on or off
# usage: $arg->argScalar(option => \$switch_variable,
#                        usage => "description");
sub argSwitch {
    my $self = shift;

    # get user supplied argument and variable (where
    # value is to be stored) and other options
    my ($arg, $variable, %options) = _makeOptions(@_);

    # store user supplied function and variable
    my ($varName, $funName) = $self->_getVarAndFuncName($variable,
							$options{func}
							|| undef);

    # generate code to handle switch option
    $self->{LOOP_STRING} .= <<OPRIONARG;
        \/^-($arg)\$\/ && ( \${\$self->{_VARIABLES}{$varName}}
                          = \!\${\$self->{_VARIABLES}{$varName}}+0 , next);
OPRIONARG

    # make usage
    $self->_makeUsage($arg, %options);
}

# process array argument
# usage: $arg->argArray(option => \@array_variable,
#                       usage => "description",
#                       unique => 1,
#                       func => sub { return @_ });
sub argArray {
    my $self = shift;

    # get user supplied argument and variable (where
    # value is to be stored) and other options
    my ($arg, $variable, %options) = _makeOptions(@_);

    # uniqe list required (default: yes)
    my $unique = exists $options{unique} ? ($options{unique} || 0) : 1;

    # store user supplied function and variable
    my ($varName, $funName) = $self->_getVarAndFuncName($variable,
							$options{func}
							|| undef);
    my $param = $options{params};
    $param = 'undef' unless defined $param;
    $self->{_PARAMS}{$varName} = $param;

    # generate code to handle array option
    $self->{LOOP_STRING} .= <<OPRIONARG;
        \/^-($arg)\$\/ &&
             (do { my \%tmp = map { (\$_, 1)
                              } \@{\$self->{_VARIABLES}{$varName}};
                   while (\@{\$self->{ARGS}} and \$self->{ARGS}[0] !~ /^-/) {
                          my \$value = shift \@{\$self->{ARGS}};
                          my \@values
                              = \$self->{_FUNCTIONS}
                                 {$funName}->(\$value,
                                              \$self->{_PARAMS}{$varName});
                          if ($unique) {
                              \@values = grep { my \$stat = exists \$tmp{\$_};
                                                \$stat ||= 0;
                                                \$tmp{\$_} = 1 unless \$stat;
                                                !\$stat
                                         } \@values;
                          }
                          push(\@{\$self->{_VARIABLES}{$varName}}, \@values)
                            if \@values;
                   }}, next
             );
OPRIONARG

    # make usage
    $self->_makeUsage($arg, %options);
}

# process hash argument
# usage: $arg->argHash(option => \%hash_variable,
#                      usage => "description",
#                      func => sub { ... });
sub argHash {
    my $self = shift;

    # get user supplied argument and variable (where
    # value is to be stored) and other options
    my ($arg, $variable, %options) = _makeOptions(@_);

    # uniqe list required (default: yes)
    my $unique = exists $options{unique} ? ($options{unique} || 0) : 1;

    # store user supplied function and variable
    my ($varName, $funName) = $self->_getVarAndFuncName($variable,
							$options{func}
							|| undef);
    my $param = $options{params};
    $param = 'undef' unless defined $param;
    $self->{_PARAMS}{$varName} = $param;

    # generate code to handle hash option
    $self->{LOOP_STRING} .= <<OPRIONARG;
        \/^-($arg)\$\/ &&
             (do { while (\@{\$self->{ARGS}} and \$self->{ARGS}[0] !~ /^-/) {
                          my \$value = shift \@{\$self->{ARGS}};
                          my \$values
                              = \$self->{_FUNCTIONS}
                                 {$funName}->(\$value,
                                              \$self->{_PARAMS}{$varName});
			  my \$ref = ref(\$values);
			  unless (\$ref) {
			      \$self->{_VARIABLES}{$varName}{\$values} = 1;
			  } elsif ( \$ref eq 'HASH') {
			      foreach my \$key (keys \%\$values) {
				  \$self->{_VARIABLES}{$varName}{\$key}
				    = \$values->{\$key};
			      }
			  }
                   }}, next
             );
OPRIONARG

    # make usage
    $self->_makeUsage($arg, %options);
}

# finish the main loop
# usage: $arg->endArg;
sub endArg {
    my $self = shift;

    # generate code to provide help
    $self->argSwitch("h|help" => $self->{_HELPSAT},
		     usage => <<HELP, dispOption => "      ");
show this help.
HELP

    my @return = ();


    my $wantarray = wantarray || 0;

    # end the main loop
    # and push unhandled options
    $self->{LOOP_STRING} .= <<ENDLOOP;
        if (\$wantarray && \$_ !~ /^-/) {
            push \@return, \$_;
        } else {
            push \@{\$self->{_UNKNOWN_OPTIONS}}, \$_;
        }
    }
ENDLOOP

    # run the main loop
    eval "$self->{LOOP_STRING}";
    if ($@) {
	print STDERR "OPS: $@ \n";
	my @array = split "\n", $self->{LOOP_STRING};
	my $i = 1;
	print STDERR map { sprintf("%3d: %s\n", $i++, $_) } @array;
	exit 1;
    }

    # reset format accumulator
    $^A = $self->{_ACCUMULATOR};

    return @return;
}

# display usage if require
# usage: $arg->usage($pre, $post);
# $pre: string or function reference
# $post: string or function reference
# NOTE: if not used help will not be generated
sub usage {
    my ($self, $pre, $pst) = @_;

    # generate string for unknown options
    my $unknown_options = (@{$self->{_UNKNOWN_OPTIONS}}
			   ? "(@{$self->{_UNKNOWN_OPTIONS}})" : "");
    $unknown_options = "$0: Unknown options $unknown_options\n"
      if $unknown_options;

    # handle error or simply help...
    if (${$self->{_HELPSAT}} || $unknown_options) {
	my $prefunc = ref($pre) eq 'CODE' ? $pre : sub { $pre || "" };
	my $pstfunc = ref($pst) eq 'CODE' ? $pst : sub { $pst || "" };

	print STDERR $unknown_options;
	print STDERR &$prefunc || "";
	print STDERR $self->{USAGE};
	print STDERR &$pstfunc || "";
        $unknown_options ? exit 100 : exit 0;
    }
}

# core code for formatting help
sub _makeUsage {
    my ($self, $option, %desc) = @_;

    my $description = $desc{usage} || "not ready yet!.";
    my $opts = $desc{dispOption} || "opts";

    my $olen = length($option.$opts) + 2;
    my $format = '@>>>>>>>>>>>>>>>>>>: ';
    if ($olen > 19) {
	$format = '@' . '>' x $olen . "\n" . " " x 19 . ": ";
    }

    my $len = 60;
    my $dformat = '^' . '<' x $len . '~';
    my $dlen = length($description);
    my $line = int($dlen / $len);

    $line += 2;
    $format .= join "\n" . " " x 21, map {$dformat} 1..$line;
    my $str = '$^A = ""; formline($format, "-" . $option . '
      . '" $opts ", ' . ('$description, ' x $line) . '  ); $^A;';
    $str = eval $str;
    chomp($str);
    $str .= "\n";
    $self->{USAGE} .= $str;
}

sub _getVariableName {
    my $self = shift;

    return "VAR_" . (++$self->{_TMPNUM});
}

sub _makeOptions {
    my $option   = shift;
    my $variable = shift;
    return ($option, $variable, @_);
}

sub _getVarAndFuncName {
    my ($self, $variable, $function) = @_;

    my $varName = $self->_getVariableName;
    $self->{_VARIABLES}{$varName} = $variable;
    my $funName = $self->_getVariableName;
    $self->{_FUNCTIONS}{$funName} = sub { $_[0] };
    if ($function) {
	if (ref($function) eq 'CODE') {
	    $self->{_FUNCTIONS}{$funName} = $function;
	} else {
	    die "ERROR: func should be a reference to a function\n";
	}
    }

    return ($varName, $funName);
}

sub _value {
    my $val = shift;
    return defined $val ? $val : undef;
}

=head1 AUTHOR

Navneet Kumar, E<lt>F<navneet_k@hotmail.com>E<gt>

=cut

1;
