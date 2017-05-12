package DMTF::CIM::MOF;

use warnings;
use strict;
use Storable;
use DMTF::CIM;
use Carp;
use version;
our $VERSION = qv('0.05');
use Exporter qw ( import );


# Module implementation here
sub valid_MOF_integer
{
	my $value=shift;
	# Binary
	if($value =~ /^[-+]?1[01]*[bB]$/) {
		return 2;
	}
	# Octal
	elsif($value =~ /^[-+]?0[0-7]*$/) {
		return 8;
	}
	# Decimal
	elsif($value =~ /^[-+]?[1-9][0-9]*$/) {
		return 10;
	}
	# Hex
	elsif($value =~ /^[-+]?0[Xx][0-9a-fA-F]*$/) {
		return 16;
	}
	# Unknown
	elsif($value =~ /^[-+]?$/) {
		return 1;
	}
	return 0;
}

sub parse_MOF_integer
{
	my $value=shift;

	# Decimal
	if($value =~ /^[-+]?[1-9][0-9]*$/) {
		$value += 0;
	}
	else {
		# Binary
		if($value =~ /^([-+]?)(1[01]*)[bB]$/) {
			$value = "0b$2";
		}
		# Octal
		elsif($value =~ /^([-+]?)(0[0-7]*)$/) {
			$value = $2;
		}
		elsif($value =~ /^([-+]?)(0[Xx][0-9a-fA-F]*)$/) {
			$value=$2;
		}
		$value=oct($value);
		$value=0-$value if($1 eq '-');
	}
	return $value;
}

sub setdefaults
{
	my $scope=shift;
	my $qualifier=shift;

	foreach my $key (keys %$scope) {
		if(!defined $scope->{$key}{qualifiers}{lc($qualifier->{name})}) {
			$scope->{$key}{qualifiers}{lc($qualifier->{name})} = {type=>$qualifier->{type}};
			if(defined $qualifier->{array}) {
				$scope->{$key}{qualifiers}{lc($qualifier->{name})}{array}=$qualifier->{array};
			}
		}
		if(defined $qualifier->{value}) {
			if(ref($qualifier->{value}) eq '') {
				$scope->{$key}{qualifiers}{lc($qualifier->{name})}{value}=$qualifier->{value};
			}
			else {
				$scope->{$key}{qualifiers}{lc($qualifier->{name})}{value}=Storable::dclone($qualifier->{value});
			}
		}
	}
}

sub derive
{
	my $target=shift;
	my $super=shift;
	my $qualifiers=shift;

	# First, Deal with qualifiers...
	my $targetscope;
	if(defined $target->{qualifiers}{association} && $target->{qualifiers}{association}{value} eq 'true') {
		$targetscope='association';
	}
	elsif(defined $target->{qualifiers}{indication} && $target->{qualifiers}{indication}{value} eq 'true') {
		$targetscope='indication';
	}
	else {
		$targetscope='class';
	}
	foreach my $qualifier (keys %$qualifiers) {
		if(defined $qualifiers->{$qualifier}{scope}{$targetscope} || defined $qualifiers->{$qualifier}{scope}{all}) {
			if(!defined $target->{qualifiers}{$qualifier}) {
				$target->{qualifiers}{$qualifier} = {type=>$qualifiers->{$qualifier}{type}};
				if(defined $qualifiers->{$qualifier}{array}) {
					$target->{qualifiers}{$qualifier}{array}=$qualifiers->{$qualifier}{array};
				}
			}
			if(!defined $target->{qualifiers}{$qualifier}{value}) {
				if(defined $super->{qualifiers}{$qualifier}{value}) {
					if(ref($super->{qualifiers}{$qualifier}{value}) eq '') {
						$target->{qualifiers}{$qualifier}{value}=$super->{qualifiers}{$qualifier}{value};
					}
					else {
						$target->{qualifiers}{$qualifier}{value}=Storable::dclone($super->{qualifiers}{$qualifier}{value});
					}
				}
				elsif(defined $qualifiers->{$qualifier}{value}) {
					if(ref($qualifiers->{$qualifier}{value}) eq '') {
						$target->{qualifiers}{$qualifier}{value}=$qualifiers->{$qualifier}{value};
					}
					else {
						$target->{qualifiers}{$qualifier}{value}=Storable::dclone($qualifiers->{$qualifier}{value});
					}
				}
			}
		}
	}

	# Now copy properties, methods, and references
	$target->{properties}=Storable::dclone($super->{properties}) if defined $super->{properties};
	$target->{methods}=Storable::dclone($super->{methods}) if defined $super->{methods};
	$target->{references}=Storable::dclone($super->{references}) if defined $super->{references};
	# Now set any qualifiers that do not propogate to their default value...
	foreach my $qualifier (keys %$qualifiers) {
		if(defined $qualifiers->{$qualifier}{flavor}{restricted}) {
			if(defined $qualifiers->{$qualifier}{scope}{property} || defined $qualifiers->{$qualifier}{scope}{all}) {
				setdefaults($target->{properties}, $qualifiers->{$qualifier});
			}
			if(defined $qualifiers->{$qualifier}{scope}{reference} || defined $qualifiers->{$qualifier}{scope}{all}) {
				setdefaults($target->{references}, $qualifiers->{$qualifier});
			}
			if(defined $qualifiers->{$qualifier}{scope}{method} || defined $qualifiers->{$qualifier}{scope}{all}) {
				setdefaults($target->{methods}, $qualifiers->{$qualifier});
			}
			if(defined $qualifiers->{$qualifier}{scope}{parameter} || defined $qualifiers->{$qualifier}{scope}{all}) {
				foreach my $method (keys %{$target->{methods}}) {
					setdefaults($target->{methods}{$method}{parameters}, $qualifiers->{$qualifier});
				}
			}
		}
	}
	
	# Finally, set superclass
	$target->{superclass}=$super->{name};
}

sub fill_qualifiers
{
	my $target=shift;
	my $scope=shift;
	my $qualifiers=shift;

	foreach my $qualifier (keys %$qualifiers) {
		if(defined $qualifiers->{$qualifier}{scope}{$scope} || defined $qualifiers->{$qualifier}{scope}{all}) {
			if(!defined $target->{$qualifier}) {
				$target->{$qualifier} = {type=>$qualifiers->{$qualifier}{type}};
				$target->{$qualifier}{array}=$qualifiers->{$qualifier}{array} if(defined $qualifiers->{$qualifier}{array});
				if(defined $qualifiers->{$qualifier}{value}) {
					if(ref($qualifiers->{$qualifier}{value}) eq '') {
						$target->{$qualifier}{value}=$qualifiers->{$qualifier}{value};
					}
					else {
						$target->{$qualifier}{value}=Storable::dclone($qualifiers->{$qualifier}{value}) if(defined $qualifiers->{$qualifier}{value});
					}
				}
			}
		}
	}
}

sub value_parser_state
{
	my $type=shift;

	return 'INTEGER' if($type eq 'uint8');
	return 'INTEGER' if($type eq 'uint16');
	return 'INTEGER' if($type eq 'uint32');
	return 'INTEGER' if($type eq 'uint64');
	return 'INTEGER' if($type eq 'sint8');
	return 'INTEGER' if($type eq 'sint16');
	return 'INTEGER' if($type eq 'sint32');
	return 'INTEGER' if($type eq 'sint64');
	return 'REAL' if($type eq 'real32');
	return 'REAL' if($type eq 'real64');
	return 'PARSE_STRING' if($type eq 'string');
	return 'CHAR' if($type eq 'char16');
	return 'BOOLEAN' if($type eq 'boolean');
	return 'DATETIME' if($type eq 'datetime');
	return '';
}

sub parse_MOF
{
	my $fname=shift;
	my $old=shift;
	my $line='';
	my @handles;
	my @filenames;
	my @linenums;
	my @linepos;
	my $state='SKIP_WHITESPACE';
	my @state_stack=('OPEN');
	my %production;
	my %qualifiers;
	my %classes;
	my %instances;
	my %associations;
	my %indications;
	my $token='';		# Used to capture tokens
	my %string;			# Used to capture strings
	my $identifier='';	# Target of the IDENTIFIER state
	my $value;			# Target of the INTEGER, REAL, PARSE_STRING, CHAR, BOOLEAN, and DATETIME states
	my $type;			# Temporary storage for type until other details (such as name and property/method/reference) is known
	my $array;			# Temporary storage for the array subscript to a type
	my $method='';		# Temorary storage of current method name
	my $basepath=$fname;
	$basepath =~ s|([/\\])[^/\\]*$|$1|;
	my %dataTypes = (uint8=>'',sint8=>'',uint16=>'',sint16=>'',uint32=>'',sint32=>'',uint64=>'',sint64=>'',real32=>'',real64=>'',char16=>'',string=>'',boolean=>'',datetime=>'');
	my %scopetypes = (class=>'', association=>'', indication=>'', qualifier=>'', property=>'', reference=>'', method=>'', parameter=>'', any=>'');
	my %flavortypes = (enableoverride=>'', disableoverride=>'', restricted=>'', tosubclass=>'', translatable=>'');
	my %declarationtypes = (association=>'', indication=>'');
	my %qualifierlist;
	my $char16;

	$old=$old->{DATA} if(defined $old->{DATA});
	if(defined $old) {
		%classes=%{$old->{classes}} if(ref($old->{classes}) eq 'HASH');
		%associations=%{$old->{associations}} if(ref($old->{associations}) eq 'HASH');
		%indications=%{$old->{indications}} if(ref($old->{indications}) eq 'HASH');
		%qualifiers=%{$old->{qualifiers}} if(ref($old->{qualifiers}) eq 'HASH');
		%instances=%{$old->{instances}} if(ref($old->{instances}) eq 'HASH');
	}
	$filenames[$#filenames+1] = $fname;
	open($handles[$#handles+1], "<", $filenames[$#filenames]);
	$linenums[$#handles]=0;
line:while($#handles >= 0) {
		my $handle=$handles[$#handles];
		while (my $line = <$handle>) {
			last if(!defined $line);
			$linenums[$#handles]++;
			$linepos[$#handles]=0;
			while($linepos[$#handles] < length($line)) {
				my $char=substr($line, $linepos[$#handles]++, 1);
				if($state eq 'OPEN') {
					if($char eq '#') {
						$state = 'PRAGMA_START';
						$token=$char;
						next;
					}
					elsif($char eq '[') {
						# Can be a class or instance declaration
						%production=();
						push @state_stack, $state;
						push @state_stack, 'SKIP_WHITESPACE';
						push @state_stack, 'CLASS_QUALIFIER_LIST_END';
						push @state_stack, 'QUALIFIER_LIST';
						$identifier='';
						$state='IDENTIFIER';
						next;
					}
					elsif(lc($char) eq 'q') {
						%production=();
						push @state_stack, $state;
						push @state_stack, 'SKIP_WHITESPACE';
						$state = 'QUALIFIER_START';
						$token=$char;
						next;
					}
					elsif(lc($char) eq 'i') {
						%production=();
						push @state_stack, $state;
						push @state_stack, 'SKIP_WHITESPACE';
						$state = 'INSTANCE_START';
						$token=$char;
						next;
					}
					elsif(lc($char) eq 'c') {
						%production=();
						push @state_stack, $state;
						push @state_stack, 'SKIP_WHITESPACE';
						$state = 'CLASS_START';
						$token=$char;
						next;
					}
				}
				
				#####################
				## Comment Parsing ##
				#####################
				elsif($state eq 'ONE_SLASH') {
					if($char eq '/') {
						$state = 'LINE_COMMENT';
						next;
					}
					elsif($char eq '*') {
						$state = 'BLOCK_COMMENT';
						next;
					}
				}
				elsif($state eq 'LINE_COMMENT') {
					if($char eq "\n" || $char eq "\r") {
						$state = pop @state_stack;
						$linepos[$#handles]--;
					}
					next;
				}
				elsif($state eq 'BLOCK_COMMENT') {
					if($char eq '*') {
						$state = 'BLOCK_COMMENT_END';
					}
					next;
				}
				elsif($state eq 'BLOCK_COMMENT_END') {
					if($char eq '/') {
						$state = pop @state_stack;
					}
					else {
						$state = 'BLOCK_COMMENT';
					}
					next;
				}
				
				####################
				## Generic Parses ##
				####################
				elsif($state eq 'PARSE_STRING') {
					if(!defined $string{quotes}) {
						%string=(quotes=>0, escape=>0, hval=>0, hex=>'', value=>'');
					}
					if(!$string{quotes}) {
						if($char eq '"') {
							$string{quotes}=1;
							next;
						}
						elsif($char eq '/') {
							push @state_stack, $state;
							$state = 'ONE_SLASH';
							next;
						}
						elsif($char =~ /\s/s) {
							next;
						}
						else {
							$linepos[$#handles]--;
							$state = pop @state_stack;
							$value=$string{value};
							next;
						}
					}
					else {
						if($string{escape}) {
							if($char eq 'b') {
								$string{value} .= "\b";
								$string{escape}=0;
								next;
							}
							elsif($char eq 't') {
								$string{value} .= "\t";
								$string{escape}=0;
								next;
							}
							elsif($char eq 'n') {
								$string{value} .= "\n";
								$string{escape}=0;
								next;
							}
							elsif($char eq 'f') {
								$string{value} .= "\f";
								$string{escape}=0;
								next;
							}
							elsif($char eq 'r') {
								$string{value} .= "\r";
								$string{escape}=0;
								next;
							}
							elsif($char eq '"') {
								$string{value} .= '"';
								$string{escape}=0;
								next;
							}
							elsif($char eq "'") {
								$string{value} .= "'";
								$string{escape}=0;
								next;
							}
							elsif($char eq '\\') {
								$string{value} .= '\\';
								$string{escape}=0;
								next;
							}
							elsif(lc($char) eq 'x') {
								$string{escape}=0;
								$string{hval}=1;
								$string{hex}='';
								next;
							}
						}
						elsif($string{hval}) {
							if($char =~ /[A-Fa-f0-9]/) {
								$string{hex} .= $char;
								if(length($string{hex})==4) {
									$string{value} .= ord(hex($string{hex}));
									$string{hval}=0;
								}
								next;
							}
							else {
								$string{value} .= ord(hex($string{hex}));
								$string{hval}=0;
								next;
							}
						}
						else {
							if($char eq '\\') {
								$string{escape}=1;
								next;
							}	
							elsif($char eq '"') {
								$string{quotes}=0;
								next;
							}
							$string{value} .= $char;
							next;
						}
					}
				}
				elsif($state eq 'IDENTIFIER') {
					if (length($identifier) == 0) {
						if($char =~ /\s/s) {
							next;
						}
						elsif($char =~ /[A-Za-z_]/) {
							$identifier .= $char;
							next;
						}
					}
					else {
						if($char =~ /[A-Za-z0-9_]/) {
							$identifier .= $char;
							next;
						}
						elsif($char =~ /\s/s) {
							$state = 'SKIP_WHITESPACE';
							next;
						}
						else {
							$state = pop @state_stack;
							$linepos[$#handles]--;
							next;
						}
					}
				}
				elsif($state eq 'SKIP_WHITESPACE') {
					if($char =~ /\s/s) {
						next;
					}
					elsif($char eq '/') {
						push @state_stack, $state;
						$state='ONE_SLASH';
						next;
					}
					else {
						$state = pop @state_stack;
						$linepos[$#handles]--;
						next;
					}
				}
				elsif($state eq 'DATETIME') {
					$value ='';
					$linepos[$#handles]--;
					push @state_stack, 'DATETIME_PARSE';
					$state='PARSE_STRING';
					next;
				}
				elsif($state eq 'DATETIME_PARSE') {
					#TODO Parse date/time types.
					$linepos[$#handles]--;
					$state=pop @state_stack;
					next;
				}
				elsif($state eq 'BOOLEAN') {
					$value .= $char;
					if(lc($value) eq 'true') {
						$state = pop @state_stack;
						next;
					}
					elsif(lc($value) eq 'false') {
						# TODO: Should this be logically false?
						$state = pop @state_stack;
						next;
					}
					elsif(substr("true", 0, length($value)) eq lc($value)) {
						next;
					}
					elsif(substr("false", 0, length($value)) eq lc($value)) {
						next;
					}
				}
				elsif($state eq 'NULL') {
					$value .= $char;
					if(lc($value) eq 'null') {
						$value=undef;
						$state = pop @state_stack;
						next;
					}
					elsif(substr("null", 0, length($value)) eq lc($value)) {
						next;
					}
				}
				elsif($state eq 'CHECK_NULL') {
					$linepos[$#handles]--;
					if($char eq 'n') {
						pop @state_stack;
						$state = 'NULL';
						next;
					}
					else {
						$state = pop @state_stack;
						next;
					}
				}
				elsif($state eq 'INTEGER') {
					my $oldvalue=$value;
					my $oldvalid=valid_MOF_integer($value);
					$value .= $char;
					my $valid=valid_MOF_integer($value);
					if($valid) {
						next;
					}
					if($oldvalid > 1) {
						$linepos[$#handles]--;
						# TODO Check range.
						$value=parse_MOF_integer($oldvalue);
						$state = pop @state_stack;
						next;
					}
				}
				elsif($state eq 'SEMICOLON_TERMINATER') {
					if($char eq ';') {
						$state = 'SKIP_WHITESPACE';
						next;
					}
				}
				elsif($state eq 'QUALIFIER_LIST') {
					if(defined $declarationtypes{lc($identifier)} || defined $qualifiers{lc($identifier)}) {
						$qualifierlist{lc($identifier)}{type}=$qualifiers{lc($identifier)}{type};
						$qualifierlist{lc($identifier)}{array}=$qualifiers{lc($identifier)}{array} if(defined $qualifiers{lc($identifier)}{array});
						if($qualifierlist{lc($identifier)}{type} eq 'boolean') {
							$qualifierlist{lc($identifier)}{value}='true';
						}
						elsif(defined $qualifierlist{lc($identifier)}{array}) {
							$qualifierlist{lc($identifier)}{value}=[];
						}
						if($char eq ',') {
							push @state_stack, 'QUALIFIER_LIST';
							$identifier='';
							$state='IDENTIFIER';
							next;
						}
						elsif($char eq '(') {
							# Parse value
							push @state_stack, 'QUALIFIER_LIST_VALUE_DONE';
							push @state_stack, 'SKIP_WHITESPACE';

							my $newstate=value_parser_state($qualifiers{lc($identifier)}{type});
							if($newstate eq '') {
								pop @state_stack;
							}
							else {
								%string=();
								$value='';
								push @state_stack, $newstate;
								push @state_stack, 'CHECK_NULL';
								$state = 'SKIP_WHITESPACE';
								next;
							}
						}
						elsif($char eq '{') {
							push @state_stack, 'QUALIFIER_ARRAY_VALUE_DONE';
							push @state_stack, 'SKIP_WHITESPACE';
							
							my $newstate=value_parser_state($qualifiers{lc($identifier)}{type});
							if($newstate eq '') {
								pop @state_stack;
							}
							else {
								%string=();
								$value='';
								push @state_stack, $newstate;
								push @state_stack, 'CHECK_NULL';
								$state = 'SKIP_WHITESPACE';
								next;
							}
						}
						elsif($char eq ']') {
							$token='';
							$identifier='';
							$state='SKIP_WHITESPACE';
							next;
						}
					}
					else {
						# Implicitly defined qualifier
						$qualifierlist{lc($identifier)}{value}=$qualifiers{lc($identifier)}{value};
						$qualifierlist{lc($identifier)}{type}='string';
						if($char eq ',') {
							push @state_stack, 'QUALIFIER_LIST';
							$identifier='';
							$state='IDENTIFIER';
							next;
						}
						elsif($char eq '(') {
							# Parse value
							push @state_stack, 'QUALIFIER_LIST_VALUE_DONE';
							push @state_stack, 'SKIP_WHITESPACE';
							
							%string=();
							push @state_stack, 'PARSE_STRING';
							push @state_stack, 'CHECK_NULL';
							$state = 'SKIP_WHITESPACE';
							next;
						}
						elsif($char eq ':') {
							# TODO: (deprecated) implicit qualifier flavours
						}
						print "Qualifier/Declaration $identifier is unknown!\n";
					}
				}
				elsif($state eq 'QUALIFIER_ARRAY_VALUE_DONE') {
					push @{$qualifierlist{lc($identifier)}{value}}, $value;
					$value = '';
					if($char eq ',') {
						push @state_stack, 'QUALIFIER_ARRAY_VALUE_DONE';
						push @state_stack, 'SKIP_WHITESPACE';
						
						my $newstate=value_parser_state($qualifiers{lc($identifier)}{type});
						if($newstate eq '') {
							pop @state_stack;
						}
						else {
							%string=();
							$value='';
							push @state_stack, $newstate;
							push @state_stack, 'CHECK_NULL';
							$state = 'SKIP_WHITESPACE';
							next;
						}
					}
					elsif($char eq '}') {
						push @state_stack, 'QUALIFIER_LIST_AFTER_VALUE_DONE';
						$state='SKIP_WHITESPACE';
						next;
					}
				}
				elsif($state eq 'QUALIFIER_LIST_VALUE_DONE') {
					if($char eq ')') {
						$qualifierlist{lc($identifier)}{value}=$value;
						$value='';
						push @state_stack, 'QUALIFIER_LIST_AFTER_VALUE_DONE';
						$state='SKIP_WHITESPACE';
						next;
					}
				}
				elsif($state eq 'QUALIFIER_LIST_AFTER_VALUE_DONE') {
					if($char eq ',') {
						push @state_stack, 'QUALIFIER_LIST';
						$identifier='';
						$state='IDENTIFIER';
						next;
					}
					elsif($char eq ']') {
						$token='';
						$identifier='';
						$state='SKIP_WHITESPACE';
						next;
					}
					elsif($char eq ':') {
						# TODO (Deprecated) implicit qualifier flavours.
					}
				}

				###########################################
				## Class/Instance/Association/Indication ##
				###########################################
				elsif($state eq 'CLASS_QUALIFIER_LIST_END') {
					# TODO: Validate the scope and flavor of qualifiers.
					$production{qualifiers}={%qualifierlist};
					$linepos[$#handles]--;
					$state = 'INSTANCE_OR_CLASS';
					next;
				}
				elsif($state eq 'INSTANCE_OR_CLASS') {
					$token .= $char;
					if(lc($token) eq 'instance') {
						$state = 'INSTANCE_OF';
						next;
					}
					elsif(lc($token) eq 'class') {
						$identifier='';
						push @state_stack, 'CLASS_NAME';
						$state = 'IDENTIFIER';
						next;
					}
					elsif(substr("instance", 0, length($token)) eq lc($token)) {
						next;
					}
					elsif(substr("class", 0, length($token)) eq lc($token)) {
						next;
					}
				}

				##########################################
				## Class/Association/Indication Parsing ##
				##########################################
				elsif($state eq 'CLASS_START') {
					$token .= $char;
					if(lc($token) eq 'class') {
						$token='';
						$identifier='';
						push @state_stack, 'CLASS_NAME';
						$state = 'IDENTIFIER';
						next;
					}
					elsif(substr("class", 0, length($token)) eq lc($token)) {
						next;
					}
				}
				elsif($state eq 'CLASS_NAME') {
					$linepos[$#handles]--;
					if(!defined $classes{lc($identifier)} && !defined $associations{lc($identifier)} && !defined $indications{lc($identifier)}) {
						if($identifier =~ /^[A-Za-z][A-Za-z0-9]*_[A-Za-z_][A-Za-z0-9_]*$/) {
							$production{name}=$identifier;
							push @state_stack, 'CLASS_SUPERCLASS';
							$state='SKIP_WHITESPACE';
							next;
						}
						else {
							print "Invalid class name $identifier\n";
						}
					}
					else {
						print "Redefinition of $identifier!\n";
					}
				}
				elsif($state eq 'CLASS_SUPERCLASS') {
					if($char eq ':') {
						push @state_stack, 'CLASS_SUPERCLASS_NAME';
						$identifier='';
						$state='IDENTIFIER';
						next;
					}
					elsif($char eq '{') {
						$linepos[$#handles]--;
						$state = 'CLASS_FEATURE';
						if(defined $qualifierlist{association} && $qualifierlist{association}{value} eq 'true') {
							fill_qualifiers($production{qualifiers}, 'association', \%qualifiers);
						}
						elsif(defined $qualifierlist{indication} && $qualifierlist{indication}{value} eq 'true') {
							fill_qualifiers($production{qualifiers}, 'indication', \%qualifiers);
						}
						else {
							fill_qualifiers($production{qualifiers}, 'class', \%qualifiers);
						}
						next;
					}
				}
				elsif($state eq 'CLASS_SUPERCLASS_NAME') {
					if(defined $classes{lc($identifier)}) {
						derive(\%production, $classes{lc($identifier)}, \%qualifiers);
						$linepos[$#handles]--;
						push @state_stack, 'CLASS_FEATURE';
						$state='SKIP_WHITESPACE';
						next;
					}
					elsif(defined $associations{lc($identifier)}) {
						derive(\%production, $associations{lc($identifier)}, \%qualifiers);
						$linepos[$#handles]--;
						push @state_stack, 'CLASS_FEATURE';
						$state='SKIP_WHITESPACE';
						next;
					}
					elsif(defined $indications{lc($identifier)}) {
						derive(\%production, $indications{lc($identifier)}, \%qualifiers);
						$linepos[$#handles]--;
						push @state_stack, 'CLASS_FEATURE';
						$state='SKIP_WHITESPACE';
						next;
					}
					else {
						print "Superclass $identifier not defined\n";
					}
				}
				elsif($state eq 'CLASS_FEATURE') {
					if($char eq '{') {
						push @state_stack, 'CLASS_FEATURE_LIST';
						$state='SKIP_WHITESPACE';
						next;
					}
				}
				elsif($state eq 'CLASS_FEATURE_LIST') {
					%qualifierlist=();
					if($char eq '[') {
						push @state_stack, $state;
						push @state_stack, 'CLASS_FEATURE_QUALIFIER_LIST_END';
						push @state_stack, 'QUALIFIER_LIST';
						$identifier='';
						$state='IDENTIFIER';
						next;
					}
					elsif($char eq '}') {
						if(defined $production{qualifiers}{association} && $production{qualifiers}{association}{value} eq 'true') {
							$associations{lc($production{name})}={%production};
						}
						elsif(defined $production{qualifiers}{indication} && $production{qualifiers}{indication}{value} eq 'true') {
							$indications{lc($production{name})}={%production};
						}
						else {
							$classes{lc($production{name})}={%production};
						}
						push @state_stack, 'SEMICOLON_TERMINATER';
						$state='SKIP_WHITESPACE';
						next;
					}
					else {
						$linepos[$#handles]--;
						push @state_stack, 'CLASS_FEATURE_TYPE';
						$state='IDENTIFIER';
						next;
					}
				}
				elsif($state eq 'CLASS_FEATURE_QUALIFIER_LIST_END') {
					# TODO: Validate the scope and flavor of qualifiers.
					$linepos[$#handles]--;
					push @state_stack, 'CLASS_FEATURE_TYPE';
					$state='IDENTIFIER';
					next;
				}
				elsif($state eq 'CLASS_FEATURE_TYPE') {
					if(defined $dataTypes{lc($identifier)}) {
						$type = lc($identifier);
						$identifier='';
						$linepos[$#handles]--;
						push @state_stack, 'CLASS_FEATURE_NAME';
						$state='IDENTIFIER';
						next;
					}
					elsif(defined $classes{lc($identifier)} || defined $associations{lc($identifier)} || defined $indications{lc($identifier)}) {
						if(defined $production{qualifiers}{association} && $production{qualifiers}{association}{value} eq 'true') {
							$type = lc($identifier);
							$identifier='';
							$linepos[$#handles]--;
							$state = 'CLASS_REFERENCE';
							next;
						}
					}
					else {
						print "Unhandled type $identifier\n";
					}
				}
				elsif($state eq 'CLASS_REFERENCE') {
					$token .= $char;
					if(lc($token) eq 'ref') {
						$token = '';
						push @state_stack, 'CLASS_REFERENCE_NAME';
						$identifier='';
						$state='IDENTIFIER';
						next;
					}
					elsif(substr("ref", 0, length($token)) eq lc($token)) {
						next;
					}
				}
				elsif($state eq 'CLASS_REFERENCE_NAME') {
					$linepos[$#handles]--;
					$production{references}{lc($identifier)}{type}=$type;
					$production{references}{lc($identifier)}{is_ref}='true';
					fill_qualifiers(\%qualifierlist, 'reference', \%qualifiers);
					$production{references}{lc($identifier)}{qualifiers}={%qualifierlist};
					$production{references}{lc($identifier)}{name}=$identifier;
					%qualifierlist=();
					push @state_stack, 'SEMICOLON_TERMINATER';
					$state = 'SKIP_WHITESPACE';
					# TODO: Handle default value
					next;
				}
				elsif($state eq 'CLASS_FEATURE_NAME') {
					if($char eq '[') {
						fill_qualifiers(\%qualifierlist, 'property', \%qualifiers);
						$production{properties}{lc($identifier)}{qualifiers}={%qualifierlist};
						%qualifierlist=();
						$production{properties}{lc($identifier)}{type}=$type;
						$production{properties}{lc($identifier)}{array}='';
						$production{properties}{lc($identifier)}{name}=$identifier;
						push @state_stack, 'CLASS_PROPERTY_NAME_ARRAY';
						$state='SKIP_WHITESPACE';
						next;
					}
					elsif($char eq '=') {
						$production{properties}{lc($identifier)}{type}=$type;
						fill_qualifiers(\%qualifierlist, 'property', \%qualifiers);
						$production{properties}{lc($identifier)}{qualifiers}={%qualifierlist};
						$production{properties}{lc($identifier)}{name}=$identifier;
						%qualifierlist=();
						$linepos[$#handles]--;
						$state = 'CLASS_PROPERTY_DEFAULT';
						next;
					}
					elsif($char eq '(') {
						#Method...
						fill_qualifiers(\%qualifierlist, 'method', \%qualifiers);
						$production{methods}{lc($identifier)}{qualifiers}={%qualifierlist};
						%qualifierlist=();
						$production{methods}{lc($identifier)}{type}=$type;
						$production{methods}{lc($identifier)}{name}=$identifier;
						$method=lc($identifier);
						$identifier='';
						push @state_stack, 'CLASS_PARAMETER_LIST';
						$state = 'SKIP_WHITESPACE';
						next;
					}
					elsif($char eq ';') {
						$linepos[$#handles]--;
						fill_qualifiers(\%qualifierlist, 'property', \%qualifiers);
						$production{properties}{lc($identifier)}{qualifiers}={%qualifierlist};
						%qualifierlist=();
						$production{properties}{lc($identifier)}{type}=$type;
						$production{properties}{lc($identifier)}{name}=$identifier;
						$state = 'SEMICOLON_TERMINATER';
						next;
					}
				}
				elsif($state eq 'CLASS_PARAMETER_LIST') {
					if($char eq '[') {
						%qualifierlist=();
						push @state_stack, 'CLASS_PARAMETER_QUALIFIER_LIST_END';
						push @state_stack, 'QUALIFIER_LIST';
						$identifier='';
						$state='IDENTIFIER';
						next;
					}
					elsif($char eq ')') {
						push @state_stack, 'SEMICOLON_TERMINATER';
						$state='SKIP_WHITESPACE';
						next;
					}
					else {
						$linepos[$#handles]--;
						push @state_stack, 'CLASS_PARAMETER_TYPE';
						$identifier='';
						$state='IDENTIFIER';
						next;
					}
				}
				elsif($state eq 'CLASS_PARAMETER_QUALIFIER_LIST_END') {
					# TODO: Validate the scope and flavor of qualifiers.
					$linepos[$#handles]--;
					push @state_stack, 'CLASS_PARAMETER_TYPE';
					$state='IDENTIFIER';
					next;
				}
				elsif($state eq 'CLASS_PARAMETER_TYPE') {
					if(defined $dataTypes{lc($identifier)}) {
						$type = lc($identifier);
						$identifier='';
						$linepos[$#handles]--;
						push @state_stack, 'CLASS_PARAMETER_NAME';
						$state='IDENTIFIER';
						next;
					}
					elsif(defined $classes{lc($identifier)} || defined $associations{lc($identifier)} || defined $indications{lc($identifier)}) {
						$type = lc($identifier);
						$identifier='';
						$linepos[$#handles]--;
						$state = 'PARAMETER_REFERENCE';
						next;
					}
				}
				elsif($state eq 'CLASS_PARAMETER_NAME') {
					$production{methods}{$method}{parameters}{lc($identifier)}{type}=$type;
					$production{methods}{$method}{parameters}{lc($identifier)}{name}=$identifier;
					fill_qualifiers(\%qualifierlist, 'parameter', \%qualifiers);
					$production{methods}{$method}{parameters}{lc($identifier)}{qualifiers}={%qualifierlist};
					if($char eq '[') {
						$token='';
						$production{methods}{$method}{parameters}{lc($identifier)}{array}='';
						$state = 'PARAMETER_NAME_ARRAY';
						next;
					}
					elsif($char eq ',') {
						push @state_stack, 'CLASS_PARAMETER_LIST';
						$state = 'SKIP_WHITESPACE';
						next;
					}
					elsif($char eq ')') {
						push @state_stack, 'SEMICOLON_TERMINATER';
						$state = 'SKIP_WHITESPACE';
						next;
					}
				}
				elsif($state eq 'PARAMETER_REFERENCE') {
					$token .= $char;
					if(lc($token) eq 'ref') {
						$token = '';
						push @state_stack, 'PARAMETER_REFERENCE_NAME';
						$identifier='';
						$state='IDENTIFIER';
						next;
					}
					elsif(substr("ref", 0, length($token)) eq lc($token)) {
						next;
					}
				}
				elsif($state eq 'PARAMETER_REFERENCE_NAME') {
					$production{methods}{$method}{parameters}{lc($identifier)}{type}='ref';
					fill_qualifiers(\%qualifierlist, 'parameter', \%qualifiers);
					$production{methods}{$method}{parameters}{lc($identifier)}{qualifiers}={%qualifierlist};
					$production{methods}{$method}{parameters}{lc($identifier)}{name}=$identifier;
					if($char eq '[') {
						$token='';
						$production{methods}{$method}{parameters}{lc($identifier)}{array}='';
						$state = 'PARAMETER_NAME_ARRAY';
						next;
					}
					elsif($char eq ',') {
						push @state_stack, 'CLASS_PARAMETER_LIST';
						$state = 'SKIP_WHITESPACE';
						next;
					}
					elsif($char eq ')') {
						push @state_stack, 'SEMICOLON_TERMINATER';
						$state = 'SKIP_WHITESPACE';
						next;
					}
				}
				elsif($state eq 'PARAMETER_NAME_ARRAY') {
					if($char =~ /[0-9]/) {
						$production{properties}{lc($identifier)}{array} .= $char;
						next;
					}
					elsif($char eq ']') {
						push @state_stack, 'PARAMETER_NAME_ARRAY_DONE';
						$state='SKIP_WHITESPACE';
						next;
					}
				}
				elsif($state eq 'PARAMETER_NAME_ARRAY_DONE') {
					if($char eq ',') {
						push @state_stack, 'CLASS_PARAMETER_LIST';
						$state = 'SKIP_WHITESPACE';
						next;
					}
					elsif($char eq ')') {
						push @state_stack, 'SEMICOLON_TERMINATER';
						$state = 'SKIP_WHITESPACE';
						next;
					}
				}
				elsif($state eq 'CLASS_PROPERTY_NAME_ARRAY') {
					if($char =~ /[0-9]/) {
						$production{properties}{lc($identifier)}{array} .= $char;
						next;
					}
					elsif($char eq ']') {
						push @state_stack, 'CLASS_PROPERTY_DEFAULT';
						$state='SKIP_WHITESPACE';
						next;
					}
				}
				elsif($state eq 'CLASS_PROPERTY_DEFAULT') {
					if($char eq '=') {
						push @state_stack, 'CLASS_PROPERTY_DEFAULT_VALUE';
						$state = 'SKIP_WHITESPACE';
						next;
					}
					elsif($char eq ';') {
						$linepos[$#handles]--;
						$state = 'SEMICOLON_TERMINATER';
						next;
					}
				}
				elsif($state eq 'CLASS_PROPERTY_DEFAULT_VALUE') {
					if(defined $production{properties}{lc($identifier)}{array}) {
						if($char eq '{') {
							push @state_stack, 'CLASS_PROPERTY_DEFAULT_ARRAY_VALUE_DONE';
							push @state_stack, 'SKIP_WHITESPACE';
							
							my $newstate=value_parser_state($production{properties}{lc($identifier)}{type});
							if($newstate eq '') {
								pop @state_stack;
							}
							else {
								$value='';
								%string=();
								push @state_stack, $newstate;
								push @state_stack, 'CHECK_NULL';
								$state = 'SKIP_WHITESPACE';
								next;
							}
						}
					}
					else {
						# Parse value
						$linepos[$#handles]--;
						push @state_stack, 'CLASS_PROPERTY_DEFAULT_VALUE_DONE';
						push @state_stack, 'SKIP_WHITESPACE';
						
						my $newstate=value_parser_state($production{properties}{lc($identifier)}{type});
						if($newstate eq '') {
							pop @state_stack;
						}
						else {
							$value='';
							%string=();
							push @state_stack, $newstate;
							push @state_stack, 'CHECK_NULL';
							$state = 'SKIP_WHITESPACE';
							next;
						}
					}
				}
				elsif($state eq 'CLASS_PROPERTY_DEFAULT_ARRAY_VALUE_DONE') {
					push @{$production{properties}{lc($identifier)}{default}}, $value;
					$value = '';
					if($char eq ',') {
						push @state_stack, 'CLASS_PROPERTY_DEFAULT_ARRAY_VALUE_DONE';
						push @state_stack, 'SKIP_WHITESPACE';
						
						my $newstate=value_parser_state($production{properties}{lc($identifier)}{type});
						if($newstate eq '') {
							pop @state_stack;
						}
						else {
							$value='';
							%string=();
							push @state_stack, $newstate;
							push @state_stack, 'CHECK_NULL';
							$state = 'SKIP_WHITESPACE';
							next;
						}
					}
					elsif($char eq '}') {
						push @state_stack, 'SEMICOLON_TERMINATER';
						$state = 'SKIP_WHITESPACE';
						next;
					}
				}
				elsif($state eq 'CLASS_PROPERTY_DEFAULT_VALUE_DONE') {
					$production{properties}{lc($identifier)}{default}=$value;
					$linepos[$#handles]--;
					push @state_stack, 'SEMICOLON_TERMINATER';
					$state = 'SKIP_WHITESPACE';
					next;
				}

				####################
				## Pragma Parsing ##
				####################
				elsif($state eq 'PRAGMA_START') {
					$token .= $char;
					if(lc($token) eq '#pragma') {
						%production=(type=>'#pragma');
						$token = '';
						push @state_stack, 'PRAGMA_NAME';
						$identifier='';
						$state='IDENTIFIER';
						next;
					}
					elsif(substr("#pragma", 0, length($token)) eq lc($token)) {
						next;
					}
				}
				elsif($state eq 'PRAGMA_NAME') {
					if($char eq '(') {
						$production{name}=$identifier;
						$identifier='';
						push @state_stack, 'PRAGMA_PARAMETER';
						%string=();
						$state = 'PARSE_STRING';
						next;
					}
				}
				elsif($state eq 'PRAGMA_PARAMETER') {
					if($char =~ /\s/s) {
						next;
					}
					elsif($char eq ')') {
						$production{parameter} = $string{value};
						%string=();
						push @state_stack,'OPEN';
						$state = 'SKIP_WHITESPACE';
						if(lc($production{name}) eq 'include') {
							$filenames[$#filenames+1] = $basepath.$production{parameter};
							if(open($handles[$#handles+1], "<", $filenames[$#filenames])) {
								$linenums[$#handles]=0;
								next line;
							}
							pop @filenames;
							pop @handles;
							print "Error opening file $basepath$production{parameter}!\n";
						}
						else {
							next;
						}
					}
				}
				
				#######################
				## Qualifier Parsing ##
				#######################
				elsif($state eq 'QUALIFIER_START') {
					$token .= $char;
					if(lc($token) eq 'qualifier') {
						$token = '';
						push @state_stack, 'QUALIFIER_NAME';
						$identifier='';
						$state='IDENTIFIER';
						next;
					}
					elsif(substr("qualifier", 0, length($token)) eq lc($token)) {
						next;
					}
				}
				elsif($state eq 'QUALIFIER_NAME') {
					if($char eq ':') {
						$production{name}=$identifier;
						$identifier='';
						push @state_stack, 'QUALIFIER_TYPE';
						$state='IDENTIFIER';
						next;
					}
				}
				elsif($state eq 'QUALIFIER_TYPE') {
					if(defined $dataTypes{lc($identifier)}) {
						$production{type}=lc($identifier);
						$identifier='';
						if($char eq '[') {
							push @state_stack, 'QUALIFIER_ARRAY';
							$state='SKIP_WHITESPACE';
							next;
						}
						elsif($char eq '=') {
							$state = 'QUALIFIER_DEFAULT_VALUE';
							$linepos[$#handles]--;
							next;
						}
						elsif($char eq ',') {
							if($production{type} eq 'boolean') {
								$production{value}='true';
							}
							elsif(defined $production{array}) {
								$production{value}=[];
							}
							$state = 'QUALIFIER_SCOPE';
							$linepos[$#handles]--;
							next;
						}
					}
				}
				elsif($state eq 'QUALIFIER_ARRAY') {
					if($char eq ']') {
						$production{array}='';
						push @state_stack, 'QUALIFIER_DEFAULT_VALUE';
						$state='SKIP_WHITESPACE';
						next;
					}
					elsif($char =~ /[1-9]/) {
						$token=$char;
						$state='QUALIFIER_ARRAY_VALUE';
						next;
					}
				}
				elsif($state eq 'QUALIFIER_ARRAY_VALUE') {
					if($char =~ /[0-9]/) {
						$token .= $char;
						next;
					}
					elsif($char eq ']') {
						$production{array}=$token+0;
						$token='';
						push @state_stack, 'QUALIFIER_DEFAULT_VALUE';
						$state='SKIP_WHITESPACE';
						next;
					}
				}
				elsif($state eq 'QUALIFIER_DEFAULT_VALUE') {
					if($char eq '=') {
						push @state_stack, 'QUALIFIER_DEFAULT_VALUE_SPEC';
						$state='SKIP_WHITESPACE';
						next;
					}
					elsif($char eq ',') {
						if($production{type} eq 'boolean') {
							$production{value}='true';
						}
						elsif(defined $production{array}) {
							$production{value}=[];
						}
						$state = 'QUALIFIER_SCOPE';
						$linepos[$#handles]--;
						next;
					}
				}
				elsif($state eq 'QUALIFIER_DEFAULT_VALUE_SPEC') {
					$value='';
					$linepos[$#handles]--;
					if(defined $production{array}) {
						# TODO - Parse arrays...
					}
					else {
						push @state_stack, 'QUALIFIER_DEFAULT_VALUE_DONE';
						
						if($char eq 'n') {
							$state='NULL';
							next;
						}
						else {
							my $newstate = value_parser_state($production{type});
							if($newstate eq '') {
								pop @state_stack;
							}
							else {
								$value='';
								%string=();
								push @state_stack, $newstate;
								$state = 'SKIP_WHITESPACE';
								next;
							}
						}
					}
				}
				elsif($state eq 'QUALIFIER_DEFAULT_VALUE_DONE') {
					$linepos[$#handles]--;
					$production{value}=$value;
					$value='';
					push @state_stack, 'QUALIFIER_SCOPE';
					$state='SKIP_WHITESPACE';
					next;
				}
				elsif($state eq 'QUALIFIER_SCOPE') {
					if($char eq ',') {
						push @state_stack, 'QUALIFIER_SCOPE_IDENTIFIER';
						$state='SKIP_WHITESPACE';
						$token='';
						next;
					}
				}
				elsif($state eq 'QUALIFIER_SCOPE_IDENTIFIER') {
					$token .= $char;
					if(lc($token) eq 'scope') {
						$token = '';
						push @state_stack, 'QUALIFIER_SCOPE_LIST_START';
						$state='SKIP_WHITESPACE';
						next;
					}
					elsif(substr("scope", 0, length($token)) eq lc($token)) {
						next;
					}
				}
				elsif($state eq 'QUALIFIER_SCOPE_LIST_START') {
					if($char eq '(') {
						push @state_stack, 'QUALIFIER_SCOPE_LIST';
						$identifier='';
						$state='IDENTIFIER';
						next;
					}
				}
				elsif($state eq 'QUALIFIER_SCOPE_LIST') {
					if(defined $scopetypes{lc($identifier)}) {
						$production{scope}{lc($identifier)}=1;
						if($char eq ',') {
							push @state_stack, 'QUALIFIER_SCOPE_LIST';
							$identifier='';
							$state='IDENTIFIER';
							next;
						}
						elsif($char eq ')') {
							push @state_stack, 'QUALIFIER_FLAVOR';
							$identifier='';
							$state='SKIP_WHITESPACE';
							next;
						}
					}
				}
				elsif($state eq 'QUALIFIER_FLAVOR') {
					if($char eq ',') {
						push @state_stack, 'QUALIFIER_FLAVOR_IDENTIFIER';
						$state='SKIP_WHITESPACE';
						$token='';
						next;
					}
					elsif($char eq ';') {
						$qualifiers{lc($production{name})}={%production};
						$state = pop @state_stack;
						next;
					}
				}
				elsif($state eq 'QUALIFIER_FLAVOR_IDENTIFIER') {
					$token .= $char;
					if(lc($token) eq 'flavor') {
						$token = '';
						push @state_stack, 'QUALIFIER_FLAVOR_LIST_START';
						$state='SKIP_WHITESPACE';
						next;
					}
					elsif(substr("flavor", 0, length($token)) eq lc($token)) {
						next;
					}
				}
				elsif($state eq 'QUALIFIER_FLAVOR_LIST_START') {
					if($char eq '(') {
						push @state_stack, 'QUALIFIER_FLAVOR_LIST';
						$identifier='';
						$state='IDENTIFIER';
						next;
					}
				}
				elsif($state eq 'QUALIFIER_FLAVOR_LIST') {
					if(defined $flavortypes{lc($identifier)}) {
						$production{flavor}{lc($identifier)}=1;
						if($char eq ',') {
							push @state_stack, 'QUALIFIER_FLAVOR_LIST';
							$identifier='';
							$state='IDENTIFIER';
							next;
						}
						elsif($char eq ')') {
							$qualifiers{lc($production{name})}={%production};
							push @state_stack, 'SEMICOLON_TERMINATER';
							$identifier='';
							$state='SKIP_WHITESPACE';
							next;
						}
					}
				}
				else {
					print "Unhandled state $state\n";
					next;
				}
				
				carp "Error in $state (",join("->",@state_stack),") at char '$char' in $filenames[$#filenames] line $linenums[$#handles]\n";
				$line =~ s/\t/ /g;
				carp sprintf("%s\n%*s^\n", $line, $linepos[$#handles]-1, '');
				return;
			}
		}
		close(pop @handles);
		pop @filenames;
		pop @linenums;
		pop @linepos;
	}

	return {classes=>{%classes}, associations=>{%associations}, indications=>{%indications}, qualifiers=>{%qualifiers}, instances=>{%instances}};
}

1; # Magic true value required at end of module
__END__

=head1 NAME

DMTF::CIM::MOF - Compiles a MOF file


=head1 VERSION

This document describes DMTF::CIM::MOF version 0.05


=head1 SYNOPSIS

    use DMTF::CIM::MOF(parse_MOF);

    my $model=parse_MOF("/path/to/cim_schema_2.31.0.mof");


=head1 DESCRIPTION

This module creates an in-memory copy of a CIM object model from a set of
MOF files and returns it.

The module is really for use with L<DMTF::CIM> objects.


=head1 INTERFACE 

=over

=item C<< parse_MOF( path_to_schema, old_schema ); >>

This function will parse the MOF file located at path_to_schema and
return a model object.

=back

=head1 DIAGNOSTICS

=over

=item C<< Error in STATE (STATE->STACK) at char 'X' in filenae line X >>

This indicates a parsing error at the specified location.  The state stack
refers to the internal state machine and is unlikely to be useful to most
users.

=back


=head1 CONFIGURATION AND ENVIRONMENT

DMTF::CIM::MOF requires no configuration files or environment variables.


=head1 DEPENDENCIES

    Storable  (standard module)


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

The class referenced when a reference type is declared must have already been
parsed.

Please report any bugs or feature requests to
C<bug-dmtf-cim-mof@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Stephen James Hurd  C<< <shurd@broadcom.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Broadcom Corporation C<< <shurd@broadcom.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
