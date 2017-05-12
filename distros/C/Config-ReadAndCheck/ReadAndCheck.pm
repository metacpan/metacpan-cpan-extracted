package Config::ReadAndCheck;

use strict;

#$^W++;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
);

%EXPORT_TAGS = ('print' => [qw(PrintList)],
               );

foreach (keys(%EXPORT_TAGS))
        { push(@{$EXPORT_TAGS{'all'}}, @{$EXPORT_TAGS{$_}}); };

$EXPORT_TAGS{'all'}
	and @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
);

$VERSION = '0.04';

use Carp;
use IO::File;
use Tie::IxHash;

my $CheckLoop = undef;
$CheckLoop = sub
	{
	my ($Params, $Dupes, $Path) = @_;
	if (!($Dupes && $Path))
		{
		$Dupes = {};
		$Path  = 'root'
		};
	my $Name = undef;
	foreach $Name (keys(%{$Params}))
		{
		if ($Params->{$Name}->{'SubSection'})
			{
			if (exists($Dupes->{$Params->{$Name}->{'SubSection'}}))
				{
				$@ = "SubSection loop found: \"$Path\->$Name\"";
				return 1;
				};
			$Dupes->{$Params->{$Name}->{'SubSection'}}++;
			if (&{$CheckLoop}($Params->{$Name}->{'SubSection'}, $Dupes, "$Path\->$Name"))
				{ return 1; };
			delete($Dupes->{$Params->{$Name}->{'SubSection'}});
			};
		};
	return 0;
	};

my $CheckParams = undef;
$CheckParams = sub
	{
	my ($Params, $Path) = @_;

	my $NewParams = undef;
	tie(%{$NewParams}, 'Tie::IxHash');

	($Path) or $Path = 'root';

	my $SimpleProcess = sub() { return ($1, $2); };

	my $Name = undef;
	foreach $Name (keys(%{$Params}))
		{
		if (ref($Params->{$Name}) ne 'HASH')
			{
			$@ = "\"$Path\->$Name\" have to be a 'HASH' reference!";
			#if($^W) { Carp::carp $@; };
			return;
			};

		if (!defined($Params->{$Name}->{'Pattern'}))
			{
			$@ = "\"$Path\->$Name\->{'Pattern'}\" have to be defined!";
			#if($^W) { Carp::carp $@; };
			return;
			};

		$NewParams->{$Name}->{'Pattern'} = $Params->{$Name}->{'Pattern'};

		$NewParams->{$Name}->{'Type'} = $Params->{$Name}->{'Type'}
			or $NewParams->{$Name}->{'Type'} = 'UNIQ';
		$NewParams->{$Name}->{'Type'} = uc($NewParams->{$Name}->{'Type'});

		if (!(($NewParams->{$Name}->{'Type'} eq 'UNIQ')     ||
		      ($NewParams->{$Name}->{'Type'} eq 'LIST')     ||
		      ($NewParams->{$Name}->{'Type'} eq 'UNIQLIST') ||
		      ($NewParams->{$Name}->{'Type'} eq 'IGNORE')))
			{
			$@ = "$Path\->$Name\->{'Type'} have to be 'UNIQ', or 'LIST', or 'UNIQLIST', or 'IGNORE'!";
			#if($^W) { Carp::carp $@; };
			return;
			};

		$NewParams->{$Name}->{'Process'} = $Params->{$Name}->{'Process'}
			or $NewParams->{$Name}->{'Process'} = $SimpleProcess;

		if (ref($NewParams->{$Name}->{'Process'}) ne 'CODE')
			{
			$@ = "$Path\->$Name\->{'Process'} have to be a 'CODE' reference!";
			#if($^W) { Carp::carp $@; };
			return;
			};

		(!exists($Params->{$Name}->{'Default'}))
			or $NewParams->{$Name}->{'Default'} = $Params->{$Name}->{'Default'};

		defined($Params->{$Name}->{'SubSection'})
			or next;

		if (ref($Params->{$Name}->{'SubSection'}) ne 'HASH')
			{
			$@ = "$Path\->$Name\->{'SubSection'} have to be reference to 'HASH'!";
			#if($^W) { Carp::carp $@; };
			return;
			};

		$NewParams->{$Name}->{'SubSection'} = &{$CheckParams}($Params->{$Name}->{'SubSection'}, "$Path\->$Name")
			or return;
		};
	return $NewParams;
	};

sub new($%)
	{
	my ($class, %Config) = @_;

	(!&{$CheckLoop}($Config{'Params'}))
		or return;

	my $self = {};

	$self->{'CaseSens'} = $Config{'CaseSens'};

	$self->{'Params'} = &{$CheckParams}($Config{'Params'})
		or return;

	Reset($self);

	return bless $self => $class;
	};

sub Result($)
	{
	my ($self) = @_;
	my %Result = ();
	tie(%Result, 'Tie::IxHash', %{$self->{'Result'}});
	return (wantarray ? %Result : \%Result);
	};

sub Reset($)
	{
	my ($self) = @_;
        tie(%{$self->{'Result'}}, 'Tie::IxHash');
	$self->{'SecStack'} = [];
	unshift(@{$self->{'SecStack'}}, {'Params' => $self->{'Params'},'Result' => $self->{'Result'}});
	};

sub Params($)
	{
	my ($self) = @_;
	my $Params = &{$CheckParams}($self->{'Params'});
	return (wantarray ? %{$Params} : $Params);
	};

my $ParseLine = sub($$)
	{
	my ($self, $Str, $Params) = @_;

	my $Name = undef;

	#print "###########################\n".PrintList($Params, 'p: ', '  ');

	foreach $Name (keys(%{$Params}))
		{
		my $Pattern = $Params->{$Name}->{'Pattern'};

		my ($P1, $P2);
		($self->{'CaseSens'} ? $Str =~ m/\A$Pattern\Z/ : $Str =~ m/\A$Pattern\Z/i)
			or next;
		$@ = '';
		if (!(($P1, $P2) = &{$Params->{$Name}->{'Process'}}()))
			{
			length($@)
				or $@ = "Invalid value(s) in '$Name' definition";
			#if($^W) { Carp::carp $@; };
			return;
			};
		return ($Name, $P1, $P2);
		};

	$@ = "Unrecognized string";
	#if($^W) { Carp::carp $@; };
	return;
	};

my $CheckRequired = undef;
$CheckRequired = sub
	{
	my ($Params, $Result, $Path) = @_;

	defined($Path)
		or $Path = 'root';

	my $Key = undef;
	foreach $Key (keys(%{$Params}))
		{
		($Params->{$Key}->{'Type'} ne 'IGNORE')
			or next;
		if (!exists($Result->{$Key}))
			{
			if (!exists($Params->{$Key}->{'Default'}))
				{
				$@ = "Required parameter $Path\->$Key is not defined";
				#if($^W) { Carp::carp $@; };
				return;
				};

			if    ($Params->{$Key}->{'Type'} eq 'LIST')
				{
				if (ref($Params->{$Key}->{'Default'}) ne 'ARRAY')
					{
					$@ = "$Path\->$Key\->{'Default'} have to be an 'ARRAY' reference";
					#if($^W) { Carp::carp $@; };
					return;
					};
				@{$Result->{$Key}} = @{$Params->{$Key}->{'Default'}};
				}
			elsif ($Params->{$Key}->{'Type'} eq 'UNIQLIST')
				{
				if (ref($Params->{$Key}->{'Default'}) ne 'HASH')
					{
					$@ = "$Path\->$Key\->{'Default'} have to be a 'HASH' reference";
					#if($^W) { Carp::carp $@; };
					return;
					};
				tie(%{$Result->{$Key}}, 'Tie::IxHash', %{$Params->{$Key}->{'Default'}});
				}
			else
				{ $Result->{$Key} = $Params->{$Key}->{'Default'}; };
			};
		if ($Params->{$Key}->{'SubSection'})
			{
			#print "$Path\->$Key\->{'SubSection'}\n";
			my @SubResults = ();

			if    ($Params->{$Key}->{'Type'} eq 'UNIQ')
				{ $SubResults[0] = $Result->{$Key}; }
			elsif ($Params->{$Key}->{'Type'} eq 'LIST')
				{ @SubResults = @{$Result->{$Key}}; }
			elsif ($Params->{$Key}->{'Type'} eq 'UNIQLIST')
				{ @SubResults = values(%{$Result->{$Key}}); };

			my $SubResult = undef;
			foreach $SubResult (@SubResults)
				{
				if (ref($SubResult) ne 'HASH')
					{
					$@ = "Value of parameter $Path\->$Key have to be a 'HASH' reference because of 'SubSection' defined for it";
					#if($^W) { Carp::carp $@; };
					return;
					};
				&{$CheckRequired}($Params->{$Key}->{'SubSection'}, $SubResult, "$Path\->$Key")
					or return;
				};
			};
		};

	return (wantarray ? %{$Result} : $Result);
	};

sub CheckRequired($)
	{
	my ($self);
	($self) = @_;

	my %Result = ();
	tie(%Result, 'Tie::IxHash');
	%Result = &{$CheckRequired}($self->{'Params'}, $self->{'Result'})
		or return;
	return (wantarray ? %Result : \%Result);
	};

my $ParseGetline = sub($$)
	{
	my ($self, $GetLine) = @_;

	my $Line = 0;
	my $Str = undef;
	while ($Str = &{$GetLine}())
		{
		$Line++;
		$Str =~ s/\n//g;

		if (!ParseIncremental($self, $Str))
			{
			$@ = "$@, line $Line: \"$Str\"";
			#if($^W) { Carp::carp $@; };
			return;
			};
		defined($self->{'SecStack'}->[0])
			or last;
		};

	if ($self->{'Params'}->{'EndOfSection'} &&
	    $self->{'SecStack'}->[0])
		{
		$@ = "Input dry up before 'EndOfSection' reached";
		return;
		};

	CheckRequired($self)
		or return;

	return (wantarray ? %{$self->{'Result'}} : $self->{'Result'});
	};

sub Parse($$)
	{
	my ($self, $Input) = @_;
	my $GetLine  = undef;
	my $RunIndex = 0;
	if    (!ref($Input))
		{
		my @tmpArray = split('\n', $Input);
		$Input = \@tmpArray;
		$GetLine = sub{return $Input->[$RunIndex++]};
		}
	elsif (ref($Input) eq 'CODE')
		{
		$GetLine = $Input;
		}
	elsif (ref($Input) eq 'ARRAY')
		{
		$GetLine = sub{return $Input->[$RunIndex++]};
		}
	else
		{
		$@ = "Can not use reference to ".ref($Input)." as an input source";
		return;
		};

	my %Result = ();
	tie(%Result, 'Tie::IxHash');
	%Result = &{$ParseGetline}($self, $GetLine)
		or return;

	return (wantarray ? %Result : \%Result);
	};

sub ParseFile($$)
	{
	my ($self, $FileName) = @_;

	my $File = IO::File->new("< $FileName");
	if (!$File)
		{
		$@ = "Can not open file \"$FileName\" for read";
		return;
		};

	my %Result = ();
	tie(%Result, 'Tie::IxHash');
	%Result = &{$ParseGetline}($self, sub{return $File->getline()})
		or return;

	$File->close();

	return (wantarray ? %Result : \%Result);
	};

my $UnshiftSubSecIfNecessary = sub
	{
	my ($self, $Params, $Result) = @_;

	if (!tied(%{$Result}))
		{
		tie(%{$Result}, 'Tie::IxHash', %{$Result});
		$_[2] = $Result;
		};

	unshift(@{$self->{'SecStack'}}, {'Params' => $Params, 'Result' => $Result});

	return $Params;
	};

sub ParseIncremental($$)
	{
	my ($self, $Str) = @_;

	my ($Name, $P1, $P2);

	my $Params = undef;
	while($Params = $self->{'SecStack'}->[0]->{'Params'})
		{
		(!(($Name, $P1, $P2) = &{$ParseLine}($self, $Str, $Params)))
			or last;

		(!defined($Params->{'EndOfSection'}))
			or return;

		shift(@{$self->{'SecStack'}})
		};

	defined($Name)
		or return;

	#print "$Name, $P1, $P2\n";

	my $Type   = $Params->{$Name}->{'Type'};
	my $Result = $self->{'SecStack'}->[0]->{'Result'};

	if    ($Type eq 'UNIQ')
		{
		if (exists($Result->{$Name}))
			{
			$@ = "Duplicate '$Name' definition";
			#if($^W) { Carp::carp $@; };
			return;
			};

		$Result->{$Name} = $P1;

		if (defined($Params->{$Name}->{'SubSection'}))
			{
			if (defined($Result->{$Name}) && (ref($Result->{$Name}) ne 'HASH'))
				{
				print $Result->{$Name}.', '.ref($Result->{$Name})."\n";
				$@ = "{'$Name'}->{'Process'} have to return refrence to 'HASH' because of {'$Name'}->{'SubSection'} property is defined";
				return;
				}
			else
				{
				&{$UnshiftSubSecIfNecessary}($self, $Params->{$Name}->{'SubSection'}, $Result->{$Name});
				};

			};
		}
	elsif ($Type eq 'LIST')
		{
		(ref($Result->{$Name}) eq 'ARRAY')
			or $Result->{$Name} = [];

		push(@{$Result->{$Name}}, $P1);

		if (defined($Params->{$Name}->{'SubSection'}))
			{
			if (defined($Result->{$Name}->[$#{$Result->{$Name}}]) &&
			    (ref($Result->{$Name}->[$#{$Result->{$Name}}]) ne 'HASH'))
				{
				print $Result->{$Name}->[$#{$Result->{$Name}}].', '.ref($Result->{$Name}->[$#{$Result->{$Name}}])."\n";
				$@ = "{'$Name'}->{'Process'} have to return refrence to 'HASH' because of {'$Name'}->{'SubSection'} property is defined";
				return;
				}
			else
				{
				&{$UnshiftSubSecIfNecessary}($self, $Params->{$Name}->{'SubSection'}, $Result->{$Name}->[$#{$Result->{$Name}}]);
				};

			};
		}
	elsif ($Type eq 'UNIQLIST')
		{
		#print "$Name'->'$P1': \"$Result->{$Name}->{$P1}\"\n";
		if (ref($Result->{$Name}) ne 'HASH')
			{
			$Result->{$Name} = undef;
			tie(%{$Result->{$Name}}, 'Tie::IxHash');
			};

		if (!defined($P1))
			{
			$@ = "{'$Name'}->{'Process'} have to return defined value as a first element of the list";
			return;
			};

		if (exists($Result->{$Name}->{$P1}))
			{
			$@ = "Duplicate '$Name'->'$P1' definition";
			$@ .= ", the value is \"$Result->{$Name}->{$P1}\"";
			#if($^W) { Carp::carp $@; };
			return;
			};

		$Result->{$Name}->{$P1} = $P2;

		if (defined($Params->{$Name}->{'SubSection'}))
			{
			if (defined($Result->{$Name}->{$P1}) && (ref($Result->{$Name}->{$P1}) ne 'HASH'))
				{
				$@ = "{'$Name'}->{'Process'} have to return refrence to 'HASH' because of {'$Name'}->{'SubSection'} property is defined";
				return;
				}
			else
				{
				&{$UnshiftSubSecIfNecessary}($self, $Params->{$Name}->{'SubSection'}, $Result->{$Name}->{$P1});
				};

			};
		};

	($Name ne 'EndOfSection')
		or shift(@{$self->{'SecStack'}});

	return $Name;
	};


my $SafeStr = sub($)
	{
	my ($Str) = shift
		or return '!UNDEF!';
	$Str =~ s{ ([\x00-\x1f\xff]) } { sprintf("\\x%2.2X", ord($1)) }gsex;
	return $Str;
	};

sub PrintList
	{
	my ($List, $Pref, $Shift) = @_;

	if    (!(ref($List) eq 'ARRAY' || (ref($List) eq 'HASH')))
		{
		$@ = "First parameter have to be ARRAY or HASH reference!";
		if ($^W) { Carp::carp("$@\n"); };
		return;
		};

	my $Res = '';

	my $RunIndex = 0;
	my $Name = undef;
	foreach $Name ((ref($List) eq 'ARRAY') ? @{$List} : keys(%{$List}))
		{
		my $Key = (ref($List) eq 'ARRAY') ? "[$RunIndex]" : "'$Name'";
		my $Val = (ref($List) eq 'ARRAY') ? $Name      : $List->{$Name};
		my $Dlm = (ref($List) eq 'ARRAY') ? '= '       : '=>';
		if    (ref($Val) eq 'ARRAY')
			{ $Res .= sprintf("%s%s array\n%s",  $Pref, &{$SafeStr}($Key), PrintList($Val, $Pref.$Shift, $Shift)); }
		elsif (ref($Val) eq 'HASH')
			{ $Res .= sprintf("%s%s hash\n%s",   $Pref, &{$SafeStr}($Key), PrintList($Val, $Pref.$Shift, $Shift)); }
		else
			{ $Res .= sprintf("%s%s\t%s %s\n",   $Pref, &{$SafeStr}($Key), $Dlm, (defined($Val) ? '"'.&{$SafeStr}($Val).'"' : 'undef')); }
		$RunIndex++;
		};

	return $Res;
	};

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Config::ReadAndCheck - Perl module for parsing generic config files
conforms to predefined line-by-line-based format.

I<Version 0.03>

=head1 SYNOPSIS

  # This code could be used for parsing
  # the windows-style INI files.

  use strict;
  use Config::ReadAndCheck;

  my $FileName = shift or die "Usage: $0 <FileName>\n";

  my %ParsINI = ();

  # The lines started from ';' or '#' and empty lines will be ignored
  $ParsINI{'Comment'}   = {'Pattern' => '(?:\s*(?:(?:[\;\#]).*)*)',
                           'Type'    => 'ignore',
                          };

  # Sections have to have a '[SectionName]' form.
  # SectionName cannot be empty
  # SectionName has to be unique
  # The first line which is not a parameter definition is end of the section
  # Comments are allowed inside of the section (!)
  # At least one section has to be defined because of lack of 'Default' definition
  $ParsINI{'Section'}   = {'Pattern' => '\s*\[(.+)\]'.$ParsINI{'Comment'}->{'Pattern'},
                           'Type'    => 'UniqList',
                           'SubSection' => {'Params'  => {}, # Defined latter
                                            'Comment' => $ParsINI{'Comment'},
                                           },
                          };

  # Parameters have to have a 'ParamName=Value' form.
  # All leading o trailing spaces are ignored.
  # All spaces around the '=' sign are ignored
  # ParamName can not contain '=' sign and can not be empty
  # ParamName has to be unique in the section
  # The default 'Process' function is used.
  # Empty (no parameters) sections are allowed by the 'Default' definition
  $ParsINI{'Section'}->{'SubSection'}->{'Params'} =
          {'Pattern' => '\s*([^\=]+)\s*=\s*([^\s](?:.*[^\s])?)'.$ParsINI{'Comment'}->{'Pattern'},
           'Type'    => 'UniqList',
           'Default' => {},
          };

  # Create the parser object.
  # '%ParsINI' will be automaticaly checked for consistency
  my $Parser = Config::ReadAndCheck->new('Params' => \%ParsINI)
  	or die "Can not create the parser: $@\n";

  # Parse the INI file. Parsing is case-insensitive by default
  my $Result = $Parser->ParseFile($FileName)
  	or die "Error parsing file \"$FileName\": $@";

  # The I<C<$Result>> will be a reference to the hash with the followin structure:
  # 
  #   {'SectionName1' => {'ParamName1' => 'Value1',
  #                       'ParamName2' => 'Value2',
  #                       ...
  #                      },
  #    'SectionName2' => {'ParamName1' => 'Value1',
  #                       'ParamName2' => 'Value2',
  #                       ...
  #                      },
  #    ...
  #   }
  
  print Config::ReadAndCheck::PrintList($Result, '', "\t");

=head1 DESCRIPTION

This module provides a way to easily create a parser for your own file format
and check the parsed values on the fly.

=head1 The C<Config::ReadAndCheck> methods

=over 4

=item C<new(%Config)>

Returns a reference to the C<Config::ReadAndCheck> object.
C<%Config> is a hash containing configuration parameters.

Configuration parameters are:

=over 8

=item C<CaseSens>

Optional parameter. If value is 'true' the input line identification will be case-sensitive.
Default action is case-insensitive.

=item C<Params>

The value has to be the reference to the L<section definition hash>.

=over 12

=item Section definition

The structure is:

  my $Params = {'ParamName1' => $ParamDefinition1,
                'ParamName2' => $ParamDefinition2,
                ...
                'EndOfSection' => $ParamDefinition3,
               };

The I<C<'ParamName1'>>, I<C<'ParamName2'>> are the names of parameters.

The I<C<$ParamDefinition1>>, I<C<$ParamDefinition2>> are the reference
to the L<parameter definition hash>.

I<C<'EndOfSection'>> is a reserved parameter name (see I<C<'SubSection'>>).

Each parameter will be represented in the result hash as a value with key the same as parameter name.
The type of the value depends on C<'Type'> field in the parameter definition (see below).

=item Parameter definition hash

The structure is:

  my $ParamDefinition = {'Pattern' => 'The pattern string',
                         'Process' => $ProcessSubroutine,
                         'Default' => 'Value',
                         'Type'    => $ParamType,
                         'SubSection'   => $RefToSection,
                        };

=over 16

=item I<C<'Pattern'>>

The perl regexp is used to identify the input line
as a relative to this parameter. The I<C<'\A'>> escape sequence will be added
to the beginning of the pattern and I<C<'\Z'>> will be added to the end automatically.
I<C<'\n'>> symbols will be striped out from the line before evaluation.
The evaluation will be done case sensitive or insensitive
according to the 'CaseSens' parameter of the C<new()> method.


=item I<C<'Process'>>

The reference to your very own parameter check and preparation
subroutine. This subroutine which is called without parameters.
I<C<$1>>, I<C<$2>> and so on will be set according to your pattern.
I<C<Process>> subroutine has to return one or two elements list.
Number and type of elements depends on
C<$ParamDefinition-E<gt>{'Type'}> and C<$ParamDefinition-E<gt>{'SubSection'}>.

Empty list means the 'line did not pass the check'.
In this case I<C<Process>> subroutine can pass the error message to the parser:
just set the I<C<$@>> variable.

If C<$ParamDefinition-E<gt>{'Process'}> is not defined
the simple I<C<sub{return ($1,$2);}>> subroutine will be used.

I<C<Process>> subroutine can pass the error

=item I<C<'Default'>>

The default value for this parameter.
The type of this property depends on C<'Type'> and C<'SubSection'>.
If C<$ParamDefinition-E<gt>{'Default'}> does not exist the parameter is treated as 'required'
(see C<CheckRequired()>).

=item I<C<'Type'>>

The type of the parameter.
Can be I<C<'UNIQ'>>, or I<C<'UNIQLIST'>>, or I<C<'LIST'>>, or I<C<'IGNORE'>>.

=over 20

=item I<C<UNIQ>>

Only one line corresponding to the pattern has to be presented in the input.

The C<UNIQ> value will be represented as single value in the result hash.
This will be a first value in the list returned by the process subroutine.

=item I<C<UNIQLIST>>

Multiple lines corresponding to the pattern can be presented in the input.
The process subroutine for this type has to return a list of two values.

The C<UNIQLIST> parameter will be represented in the result hash as a reference to hash.
The first value returned by process subroutine will be used as a hash key
and the second will be a value. So, the first value returned by the process subroutine
has to be uniq for each line corresponded to the pattern.

=item I<C<LIST>>

Multiple lines corresponding to the pattern can be presented in the input.

The C<LIST> parameter will be represented in the result hash as a reference to array.
The first value returned by the process subroutine will be pushed to this array
for each line corresponded to the pattern. So, nothing unique at all.

=item I<C<IGNORE>>

Multiple lines corresponding to the pattern can be presented in the input.
All them will not be presented in the result hash.

=back

=item Z<>

I<Type name is case-insensitive>

=item C<'SubSection'>

The reference to the L<section definition>.

If C<'SubSection'> is defined, the C<'Process'> subroutine has to return
the reference to the hash, even empty as a first list element for types I<C<UNOQ>> and I<C<LIST>>,
and as a second element for type I<C<UNIQLIST>>.

The parameter with C<'SubSection'> defined will be represented
in the result hash as a reference to hash.

The parameters defined in the C<'SubSection'> will be represented
in this hash with their own names.

The level of recursion is not limited but loops are prohibited.

If C<'SubSection'> is defined, the line corresponding to I<C<'Pattern'>> will be treated
as a first line of the enclosed section.

The line corresponding to the I<C<'EndOfSection'>> parameter of the enclosed section
will be treated as a last line in the subsection.
The next line will be verified by the parameters of the parent section.

If no I<C<'EndOfSection'>> parameter is defined in the subsection,
the first line which does not correcpond to any of the subsection parameters
will be treated as an end of subsection.
Also, this line will be passed for the verification to the parent section.

Note: the root section also can have a I<C<'EndOfSection'>> parameter.
It will be treated as an 'EOF'.

=back

=back

The C<new()> method returns a reference to the C<Config::ReadAndCheck> object or 'undef' value.

=back

=item C<Result()>

Returns a copy of current result of parsing as a hash or reference to hash in scalar context.

=item C<Reset()>

Remove all the data relative to previous parsing from the memory and make
the parser ready for next parsing. Returns 'undef'.

=item C<Params()>

Returns a copy of 'Params' hash currently in use or reference to hash in scalar context.

=item C<Parse(ARRAYREF)>

C<$Array> is a reference to array of strings to be parsed.

Then reach the EOF or I<C<'EndOfSection'>> C<ParseArray()> calls
the C<CheckRequired()> function
to check if all required parameters were defined.

=item C<ParseFile($FileName)>

C<$FileName> is the name of file to be parsed.

Then reach the EOF or I<C<'EndOfSection'>> C<Parse()> calls
the C<CheckRequired()> function
to check if all required parameters were defined.

=item C<Parse(CODEREF)>

C<CODEREF> is a reference to the subroutine, which returns the next string.

C<&{CODEREF}()> will be called without any parameters and have to return a string.
It have to return an I<C<undef>> value as an 'EOF' indication.

=item C<Parse($String)>

C<$String> is just string.
The tokens I<C<(.*\n)>> will be extracted from this string and parsed one by one.

=item C<ParseIncremental($Str)>

C<$Str> is a string to be parsed. C<ParseIncremental()> returns a name of the parameter
which is C<$Str> correspond to or I<undef> if string is unrecognised.

B<I<C<$@>>> will contain an error message.

=item C<CheckRequired()>

C<CheckRequired()> checks whether all the parameters which 
do not have a I<C<'Default'>> value provided exist in the C<$Result> hash.
It stops on the first one which does not and returns a I<false> value. I<C<$@>> variable
contains a string I<"Required parameter PARAMETER_NAME is not defined">.

If no 'problematic' parameters are found C<CheckRequired()> returns a I<true> value.

In addition to this check, C<CheckRequired()> sets all undefined parameters
to their I<C<'Default'>> value.

=item C<PrintList($List, $Prefix, $Shift)>

C<$List> is a hash or array reference.
C<$Prefix> is a prefix substring.
C<$Shift> is a 'shift' substring (see below).

C<PrintList()> produces a string which contains a human readable representation of a hash or array.

It is descending to the any hash or array references in the list.
Embedded records are shifted for the one or more (according to level of embedment)
C<$Shift> substrings.

All records preceded by the C<$Prefix> substring.

For example

  my @Tst = ('p 0.0',
             'p 0.1',
             {'p 1.0' => 'here',
              'p 1.1' => 'here too',
              'p 1.2' => ['p 2.0',
                          'p 2.1']},
             'p 0.3');
  print PrintList(\@Tst, '>', "\t");

will print

  >[0]    =  "p 0.0"
  >[1]    =  "p 0.1"
  >[2] hash
  >       'p 1.1' => "here too"
  >       'p 1.2' array
  >               [0]     =  "p 2.0"
  >               [1]     =  "p 2.1"
  >       'p 1.0' => "here"
  >[3]    =  "p 0.3"

=back

All methods including C<new()> returns an 'undef' value in case of error.
The B<I<C<$@>>> variable will contain an error explanation.

=head2 EXPORT

None by default.

=over 4

=item C<:print>

C<PrintList()>

=back

=head1 AUTHOR

Daniel Podolsky, E<lt>tpaba@cpan.orgE<gt>

=head1 SEE ALSO

L<Tie::IxHash>.

=cut
