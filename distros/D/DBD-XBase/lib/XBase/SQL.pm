
# ####################
# Parsing SQL commands

package XBase::SQL::Expr;
package XBase::SQL;

use strict;
use vars qw( $VERSION %COMMANDS );

$VERSION = '1.06';

# #################################
# Type conversions for create table
my %TYPES = ( 'char' => 'C', 'varchar' => 'C',
		'num' => 'N', 'numeric' => 'N', 'int' => 'N', 'decimal' => 'N',
		'integer' => 'N', 'float' => 'F', 'boolean' => 'L',
		'blob' => 'M', 'memo' => 'M', 'date' => 'D',
		'time' => 'T', 'datetime' => 'T',
		'money' => 'Y' );

# ##################
# Regexp definitions

%COMMANDS = (

# Top level SQL commands

	'COMMANDS' => 	' ( SELECT | INSERT | DELETE | UPDATE | CREATE | DROP ) [\\s|;]* ',
	'SELECT' =>	'select ( SELECTALL | SELECTFIELDS ) from TABLE WHERE ?
							ORDERBY ?',
	'INSERT' =>	'insert into TABLE ( \( INSERTFIELDS \) ) ? values
						\( INSERTCONSTANTS \)',
	'DELETE' =>	'delete from TABLE WHERE ?',
	'UPDATE' =>	'update TABLE set SETCOLUMNS WHERE ?',
	'CREATE' =>	'create table TABLE \( COLUMNDEF ( , COLUMNDEF ) * \)',
	'DROP' =>	'drop table TABLE',

# select fields

	'SELECTFIELDS' =>	'SELECTFIELD ( , SELECTFIELD ) *',
	'SELECTFIELD' =>	'SELECTEXPFIELD ( as ? FIELDNAMENOTFROM SELECTFIELDNAME ) ? ',
	'SELECTALL' =>	q'\*',
	'SELECTEXPFIELD' =>	'ARITHMETIC',
	'FIELDNAMENOTFROM' =>	'(?!from)(?=\w)|(?=from\s+from\b)',
	'SELECTFIELDNAME' =>	'STRING | [a-z_][a-z0-9_]*',

# insert definitions

	'INSERTFIELDS' =>	'INSERTFIELDNAME ( , INSERTFIELDNAME ) *',
	'INSERTFIELDNAME' =>	'FIELDNAME',
	'INSERTCONSTANTS' =>	'CONSTANT ( , CONSTANT ) *',

# update definitions

	'SETCOLUMNS' =>	'SETCOLUMN ( , SETCOLUMN ) *',
	'SETCOLUMN' =>	'UPDATEFIELDNAME = UPDATEARITHMETIC',
	'UPDATEFIELDNAME' => 'FIELDNAME',
	'UPDATEARITHMETIC' => 'ARITHMETIC',

# create definitions

	'COLUMNDEF' =>	'COLUMNKEY | COLUMNNAMETYPE ( not null ) ?',
	'COLUMNKEY' =>	'primary key \( FIELDNAME \)',
	'COLUMNNAMETYPE' =>	'FIELDNAME FIELDTYPE',
	'FIELDTYPE' =>	'TYPECHAR | TYPENUM | TYPEBOOLEAN | TYPEMEMO | TYPEDATE | money ',
	
	'TYPECHAR' =>	' ( varchar | char ) ( \( TYPELENGTH \) ) ?',
	'TYPENUM' =>	'( num | numeric | decimal | float | int | integer ) ( \( TYPELENGTH ( , TYPEDEC ) ? \) ) ?',
	'TYPEDEC' =>	'\d+',

	'TYPELENGTH' =>	'\d+',
	'TYPEBOOLEAN' =>	'boolean | logical',
	'TYPEMEMO' =>	'memo | blob',
	'TYPEDATE' =>	'date | time | datetime',

# table, field name, number, string

	'TABLE' =>	'[^\s\(]+',
	'FIELDNAME' =>	'[a-z_][a-z0-9_.]*',
	'NUMBER' => q'-?\d*\.?\d+',
	'STRING' => q! \\" STRINGDBL \\" | \\' STRINGSGL \\' !,
	'STRINGDBL' => q' STRINGDBLPART ( \\\\. STRINGDBLPART ) * ',
	'STRINGSGL' => q' STRINGSGLPART ( \\\\. STRINGSGLPART ) * ',
	'STRINGDBLPART' => q' [^\\\\"]* ',
	'STRINGSGLPART' => q! [^\\\\']* !,

# where clause

	'WHERE' =>	'where WHEREEXPR',
	'WHEREEXPR' =>	'BOOLEAN',

	'BOOLEAN' =>	q'not BOOLEAN | ( \( BOOLEAN \) | RELATION ) ( ( AND | OR ) BOOLEAN ) *',
	'RELATION' =>   'ARITHMETIC ( is not ? null | LIKE CONSTANT_NOT_NULL | RELOP ARITHMETIC )',
	'AND' =>	'and',
	'OR' =>		'or',
	
	'RELOP' => [ qw{ == | = | <= | >= | <> | != | < | > } ],
	'LIKE' =>	'not ? like',

	'ARITHMETIC' => [ qw{ ( \( ARITHMETIC \)
		| CONSTANT | FUNCTION | EXPFIELDNAME )
		( ( \+ | \- | \* | \/ | \% | CONCATENATION ) ARITHMETIC ) ? } ],
	'EXPFIELDNAME' => 'FIELDNAME',
	'CONCATENATION' =>	'\|\|',


	'CONSTANT' => ' CONSTANT_NOT_NULL | NULL ',
	'CONSTANT_NOT_NULL' => ' BINDPARAM | NUMBER | STRING ',
	'BINDPARAM' => q'\? | : [a-z0-9]* ',
	'NULL' => 'null',

	'ARITHMETICLIST' => 	' ARITHMETIC ( , ARITHMETICLIST ) * ',
	'FUNCTION' =>	' FUNCTION1 | FUNCTION23 | FUNCTIONANY ',
	'FUNCTION1' =>	' ( length | trim | ltrim | rtrim ) \( ARITHMETIC \) ',
	'FUNCTION23' =>	' ( substr | substring ) \( ARITHMETIC , ARITHMETIC ( , ARITHMETIC ) ? \) ',
	'FUNCTIONANY' =>	' concat \( ARITHMETICLIST \) ',

	'ORDERBY' => 'order by ORDERFIELDNAME ORDERDESC ?
				( , ORDERFIELDNAME ORDERDESC ? ) *',
	'ORDERDESC' => 'asc | desc',
	'ORDERFIELDNAME' => 'FIELDNAME',
	);

# #####################################
# "Expected" messages for various types
my %ERRORS = (
	'COMMANDS' => 'Unknown SQL command',
	'TABLE' => 'Table name expected',
	'RELATION' => 'Relation expected',
	'ARITHMETIC' => 'Arithmetic expression expected',
	'from' => 'From specification expected',
	'into' => 'Into specification expected',
	'values' => 'Values specification expected',
	'\\(' => 'Left paren expected',
	'\\)' => 'Right paren expected',
	'\\*' => 'Star expected',
	'\\"' => 'Double quote expected',
	"\\'" => 'Single quote expected',
	'STRING' => 'String expected',
	'SELECTFIELDS' => 'Columns to select expected',
	'FIELDTYPE' => 'Field type expected',
	);


# #########
# Callbacks to be called after everything is nicely matched
my %STORE = (
	'SELECT' => sub { shift->{'command'} = 'select'; },
	'SELECTALL' => sub {
		my $self = shift;
		$self->{'selectall'} = '*';
		$self->{'selectfn'} = sub { my ($TABLE, $VALUES, $BIND) = @_; map { XBase::SQL::Expr->field($_, $TABLE, $VALUES)->value } $TABLE->field_names; };
		undef;
		},
	'SELECTEXPFIELD' => 'fields',
	'SELECTFIELDS' => sub {
		my $self = shift;
		my $select_fn = 'sub { my ($TABLE, $VALUES, $BIND) = @_; map { $_->value } (' . join(', ', @{$self->{'fields'}} ) . ')}';
		### print "Selectfn: $select_fn\n";
		my $fn = eval $select_fn;
		if ($@) { $self->{'selecterror'} = $@; }
		else { $self->{'selectfn'} = $fn; }
		$self->{'selectfieldscount'} = scalar(@{$self->{'fields'}});
		undef;
		},
	'SELECTFIELDNAME' => sub {
		my $self = shift;
		my $fieldnum = @{$self->{'fields'}} - 1;
		my $name = (get_strings(@_))[0];
		$self->{'selectnames'}[$fieldnum] = $name;
		undef;
		},
	
	'INSERT' => sub { shift->{'command'} = 'insert'; },
	'INSERTFIELDNAME' =>	'insertfields',
	'INSERTCONSTANTS' => sub { my $self = shift;
		my $insert_fn = 'sub { my ($TABLE, $BIND) = @_; map {
		$_->value() } ' . join(' ', get_strings(@_)) . ' }';
		my $fn = eval $insert_fn;
		### print STDERR "Evalling insert_fn: $insert_fn\n";
		if ($@) { $self->{'inserterror'} = $@; }
		else { $self->{'insertfn'} = $fn; }
		undef;
		},
	'INSERTFIELDS' => sub { my ($self, @fields) = @_;
		while (@fields) { push @{$self->{'fields'}}, shift @fields; shift @fields; }},

	'DELETE' => sub { shift->{'command'} = 'delete'; },

	'UPDATE' => sub { shift->{'command'} = 'update'; },
	'UPDATEFIELDNAME' => 'updatefields',
	'UPDATEARITHMETIC' => 'updateexprs',
	'SETCOLUMNS' => sub { my $self = shift;
		my $list = join ', ', @{$self->{'updateexprs'}};;
		my $update_fn = 'sub { my ($TABLE, $VALUES, $BIND) = @_; map { $_->value() } (' . $list . ') }';
		my $fn = eval $update_fn;
		### print STDERR "Evalling update_fn: $update_fn\n";
		if ($@) { $self->{'updateerror'} = $@; }
		else { $self->{'updatefn'} = $fn; }
		undef;
		},


	'CREATE' => sub { shift->{'command'} = 'create'; },
	'COLUMNNAMETYPE' => sub { my $self = shift;
		my @results = get_strings(@_);
		push @{$self->{'createfields'}}, $results[0];
		push @{$self->{'createtypes'}}, $TYPES{lc $results[1]};
		push @{$self->{'createlengths'}}, $results[3];
		push @{$self->{'createdecimals'}}, $results[5]; },

	'DROP' => sub { shift->{'command'} = 'drop'; },
	
	'TABLE' => sub {
		my $self = shift;
		my $table = (get_strings(@_))[0];
		push @{$self->{'table'}}, $table;
		$table;
		},

	
	'FIELDNAME' => sub {
		my $self = shift;
		my $field = uc ((get_strings(@_))[0]);
		$field =~ s/^.*\.//;
		push @{$self->{'usedfields'}}, $field;
		$field;
		},
	'EXPFIELDNAME' => sub {
		my $self = shift;
		my $e = (get_strings(@_))[0];
		"XBase::SQL::Expr->field('$e', \$TABLE, \$VALUES)";
		},

	'BINDPARAM' => sub {
		my $self = shift;
		my $string = join '', get_strings(@_);
	
		my $bindcount = keys %{$self->{'binds'}};
		$bindcount = 0 unless defined $bindcount;
		
		if ($string eq '?') {
			$string = ':p'.($bindcount+1);
			}
		$self->{'binds_order'}[$bindcount] = $string
				unless exists $self->{'binds'}{$string};

		$self->{'binds'}{$string}++;
		"XBase::SQL::Expr->string(\$BIND->{'$string'})";
		},

	'FUNCTION' => sub {
		my $self = shift;
		my @params = get_strings(@_);
		my $fn = uc shift @params;
		"XBase::SQL::Expr->function('$fn', \$TABLE, \$VALUES, @params)";
		},

	'ORDERFIELDNAME' => 'orderfields',
	'ORDERDESC' => 'orderdescs',
	
	'STRINGDBL' => sub {
		my $self = shift;
		join '', '"', get_strings(@_), '"';
		},
	'STRINGSGL' => sub {
		my $self = shift;
		join '', '\'', get_strings(@_), '\'';
		},
	'STRING' => sub {
		shift;
		my $e = (get_strings(@_))[1];
		"XBase::SQL::Expr->string($e)";
		},
	'NUMBER' => sub {
		shift;
		my $e = (get_strings(@_))[0];
		"XBase::SQL::Expr->number($e)";
		},
	'NULL' => sub { 'XBase::SQL::Expr->null()' },
	'AND' => sub { 'and' },
	'OR' =>	sub { 'or' },
	'LIKE' =>	sub { shift; join ' ', get_strings(@_); },
	'CONCATENATION' =>	sub { ' . ' },




	'WHEREEXPR' => sub { my $self = shift;
		my $expr = join ' ', get_strings(@_);
		### print STDERR "Evalling: $expr\n";
		### use Data::Dumper;
		my $fn = eval '
			sub { 
			### print Dumper @_;
			my ($TABLE, $VALUES, $BIND) = @_; ' . $expr . '; }';
		if ($@) { $self->{'whereerror'} = $@; }
		else { $self->{'wherefn'} = $fn; }
		'';
		},



	'RELOP' => sub { shift; my $e = (get_strings(@_))[0];
			if ($e eq '=') { $e = '=='; }
			elsif ($e eq '<>') { $e = '!=';} $e; },
	'ARITHMETIC' => sub { shift; join ' ', get_strings(@_); },
	'RELATION' => sub { shift; my @values = get_strings(@_);
		local $^W = 0;
		my $testnull = join ' ', @values[1 .. 3];
		if ($testnull =~ /^is (not )?null ?$/i)
			{ return "not $1 defined(($values[0])->value)"; }
		elsif ($values[1] =~ /^(not )?like$/i)
			{ return "$1(XBase::SQL::Expr->likematch($values[0], $values[2])) " }
		else { return join ' ', @values; }	},

	);

sub find_verbatim_select_names {
	my ($self, @result) = @_;
	my $i = 0;
	while ($i < @result) {
		if ($result[$i] eq 'SELECTEXPFIELD') {
			my @out = $self->get_verbatim_select_names(@result[$i, $i + 1]);
			push @{$self->{'selectnames'}}, uc join '', @out;
		}
		elsif (ref $result[$i + 1] eq 'ARRAY') {
			$self->find_verbatim_select_names(@{$result[$i + 1]});
		}
		$i += 2;
	}
}
sub get_verbatim_select_names {
	my ($self, @result) = @_;
	my $i = 1;
	my @out = ();
	while ($i < @result) {
		if (ref $result[$i] eq 'ARRAY') {
			push @out, $self->get_verbatim_select_names(@{$result[$i]});
		} else {
			push @out, $result[$i];
		}
		$i += 2;
	}
	@out;
}

#######

# Parse is called with a string -- the whole SQL query. It should
# return the object with all properties filled, or errstr upon error

# First, we call match. Then, after we know that the match was
# successfull, we call store_results
sub parse {
	$^W = 0;
	my ($class, $string) = @_;
	my $self = bless {}, $class;

	# try to match the $string against $COMMANDS{'COMMANDS'}
	# that's the top level starting point
	my ($srest, $error, $errstr, @result) = match($string, 'COMMANDS');

	# after the parse, nothing should have left from the $string
	# if it does, it's some rubbish
	if ($srest ne '' and not $error) {
		$error = 1;
		$errstr = 'Extra characters in SQL command';
	}
	
	# we want to have meaningfull error messages. if it heasn't
	# been specified so far, let's just say Error	
	if ($error) {
		if (not defined $errstr) {
			$errstr = 'Error in SQL command';
		}

		# and only show the relevant part of the SQL string
		substr($srest, 40) = '...' if length $srest > 44;
		if ($srest ne '') {
			$self->{'errstr'} = "$errstr near `$srest'";
		} else {
			$self->{'errstr'} = "$errstr at the end of query";
		}
	} else {
		# take the results and store them to $self

		$self->find_verbatim_select_names(@result);
		$self->store_results(\@result, \%STORE);
		if (defined $self->{'whereerror'}) {
			$self->{'errstr'} = "Some deeper problem: eval failed: $self->{'whereerror'}";
		}
		### use Data::Dumper; print STDERR "Parsed $string to\n", Dumper $self if $ENV{'SQL_DUMPER'};
	}
	$self;
}

##########

# Function match is called with a string and a list of regular
# expressions we need to match
sub match {
	my $string = shift;
	my @regexps = @_;

	# we save the starting string, for case when we need to backtrack
	my $origstring = $string;

	# the title is the name of the goal (bigger entity) we now try
	# to match; it's mainly used to find correct error message
	my $title;

	if (@regexps == 1 and defined $COMMANDS{$regexps[0]}) {
		$title = $regexps[0];
		my $c = $COMMANDS{$regexps[0]};

		# if we are to match a thing in %COMMANDS, let's expand it
		@regexps = expand( ( ref $c ) ? @$c :
					grep { $_ ne '' } split /\s+/, $c);
	}

	# as the first element of the @regexp list, we might have got
	# modifiers -- ? or * -- we will use them in cse of non-match
	my $modif;
	if (@regexps and $regexps[0] eq '?' or $regexps[0] eq '*') {
		$modif = shift @regexps;
	}

	# let's walk through the @regexp list and see
	my @result;
	my $i = 0;
	while ($i < @regexps) {
		my $regexp = $regexps[$i];
		my ($error, $errstr, @r);

		# if it's an array, call match recursivelly
		if (ref $regexp) {
			($string, $error, $errstr, @r) = match($string, @$regexp);
		}
		# if it's a thing in COMMANDS, call match recursivelly
		elsif (defined $COMMANDS{$regexp}) {
			($string, $error, $errstr, @r) = match($string, $regexp);
		}
		
		# if we've found |, it means that one alternative matched
		# fine and we can leave the loop -- we use next to go
		# through continue
		elsif ($regexp eq '|') {
			$i = $#regexps; next;
		}

		# otherwise do a regexp match
		elsif ($string =~ s/^\s*?($regexp)(?:$|\b|(?=\W))//si) {
			@r = $1;
		}
	
		# and yet otherwise we have a problem
		else {
			$error = 1;
		}

		# if we have a problem
		if (defined $error) {
			# if nothing has matched yet, try to find next
			# alternative
			if ($origstring eq $string) {
				while ($i < @regexps) {
					last if $regexps[$i] eq '|'; $i++;
				}
				next if $i < @regexps;
				last if defined $modif;
			}

			# if we got here, we haven't found any alternative
			# and no modifier was specified for this list
			# so just form the errstr and return with shame
			if (not defined $errstr) {
				if (defined $ERRORS{$regexp}) {
					$errstr = $ERRORS{$regexp};
				} elsif (defined $title and defined $ERRORS{$title}) {
					$errstr = $ERRORS{$title};
				}
			}

			return ($string, 1, $errstr, @result);
		}

		# add result to @result
		if (ref $regexp) {
			push @result, @r;
		} elsif (@r > 1) {
			push @result, $regexp, [ @r ];
		} else {
			push @result, $regexp, $r[0];
		}
	}
	continue {
		$i++;
		# if we hve *, let's try another round
		if (defined $modif and $modif eq '*' and $i >= @regexps) {
			$origstring = $string; $i = 0;
		}
	}

	return ($string, undef, undef, @result);
}

sub expand {
	my @result;
	my $i = 0;
	while ($i < @_) {
		my $t = $_[$i];
		if ($t eq '(') {
			$i++;
			my $begin = $i;
			my $nest = 1;
			while ($i < @_ and $nest) {
				my $t = $_[$i];
				if ($t eq '(') { $nest++; }
				elsif ($t eq ')') { $nest--; }
				$i++;
			}
			$i--;
			push @result, [ expand(@_[$begin .. $i - 1]) ];	
		} elsif ($t eq '?' or $t eq '*') {
			my $prev = pop @result;
			push @result, [ $t, ( ref $prev ? @$prev : $prev ) ];
		} else {
			push @result, $t;
		}
		$i++;
	}
	@result;
}
#
# We run this method on the XBase::SQL object, with the tree structure
# in the $result arrayref
sub store_results {
	my ($self, $result) = @_;

	my $i = 0;
	
	# Walk through the list
	while ($i < @$result) {
		# get the key and the value matched for the key
		my ($key, $match) = @{$result}[$i, $i + 1];

		# if there is some structure below, process it
		if (ref $match) {
			$self->store_results($match);
		}

		# see what are we supposed to do for this key
		my $store_value = $STORE{$key};

		if (defined $store_value) {
			if (ref $store_value eq 'CODE') {
				my @out = &{$store_value}($self, (ref $match ? @$match : $match));
				if (@out == 1) {
					$result->[$i+1] = $out[0];
				} else {
					$result->[$i+1] = [ @out ];
				}
			} else {
				push @{$self->{$store_value}}, get_strings($match);
			}
		}

=comment

		if (defined $m)
			{
			my @result = (( ref $m eq 'CODE' ) ? &{$m}( ref $match ? @$match : $match) : $m);
			if (@result == 1)
				{ $match = $result[0]; }
			else
				{ $match = [ @result ]; }
			$result->[$i + 1] = $match;	
			}

		if (defined $stval)
			{
			my @result;
			if (ref $match) { @result = get_strings($match); }
			else { @result = $match; }
			if (ref $stval eq 'CODE')
				{ &{$stval}($self, @result); }
			else
				{ push @{$self->{$stval}}, @result; }
			}

=cut

		$i += 2;
	}
}
#
#
sub get_strings {
	my @strings = @_;
	if (@strings == 1 and ref $strings[0]) {
		@strings = @{$strings[0]};
	}
	my @result;
	my $i = 1;
	while ($i < @strings) {
		if (ref $strings[$i]) {
			push @result, get_strings($strings[$i]);
		} else {
			push @result, $strings[$i];
		}
		$i += 2;
	}
	@result;
}
sub print_result {
	my $result = shift;
	my @result = @$result;
	my @before = @_;
	my $i = 0;
	while ($i < @result) {
		my ($regexp, $string) = @result[$i, $i + 1];
		if (ref $string) {
			print_result($string, @before, $regexp);
		} else {
			print "$string:\t @before $regexp\n";
		}
		$i += 2;
	}
}


# #######################################
# Implementing methods in SQL expressions

package XBase::SQL::Expr;

use strict;

use overload
	'+'  => sub { XBase::SQL::Expr->number($_[0]->value + $_[1]->value); },
	'-'  => sub { my $a = $_[0]->value - $_[1]->value; $a = -$a if $_[2];
			XBase::SQL::Expr->number($a); },
	'/'  => sub { my $a = ( $_[2] ? $_[1]->value / $_[0]->value
				: $_[0]->value / $_[1]->value );
			XBase::SQL::Expr->number($a); },
	'%'  => sub { my $a = ( $_[2] ? $_[1]->value % $_[0]->value
				: $_[0]->value % $_[1]->value );
			XBase::SQL::Expr->number($a); },
	'<'  => \&less,
	'<=' => \&lesseq,
	'>'  => sub { $_[1]->less(@_[0, 2]); },
	'>=' => sub { $_[1]->lesseq(@_[0, 2]); },
	'!=' => \&notequal,
	'<>' => \&notequal,
	'==' => sub { my $a = shift->notequal(@_); return ( $a ? 0 : 1); },
	'""' => sub { ref shift; },
	'.' => sub { XBase::SQL::Expr->string($_[0]->value . $_[1]->value); },
	'*'  => sub { XBase::SQL::Expr->number($_[0]->value * $_[1]->value);},
	'!'  => sub { not $_[0]->value },
	;

sub new { bless {}, shift; }
sub value { shift->{'value'}; }

sub field {
	my ($class, $field, $table, $values) = @_;
	my $self = $class->new;
	$self->{'field'} = $field;
	$self->{'value'} = $values->{$field};

	my $type = $table->field_type($field);
	if ($type eq 'N')	{ $self->{'number'} = 1; }
	else			{ $self->{'string'} = 1; }
	$self;
}
sub string {
	my $self = shift->new;
	$self->{'value'} = shift;
	$self->{'string'} = 1;
	$self;
}
sub number {
	my $self = shift->new;
	$self->{'value'} = shift;
	$self->{'number'} = 1;
	$self;
}
sub null {
	my $self = shift->new;
	$self->{'value'} = undef;
	$self;
}
sub other {
	my $class = shift;
	my $other = shift;
	$other;
}
sub function {
	my ($class, $function, $table, $values, @params) = @_;
	my $self = $class->new;
	$self->{'string'} = 1;
	if ($function eq 'LENGTH') {
		$self->{'value'} = length($params[0]->value);
		delete $self->{'string'};
		$self->{'number'} = 1;
	} elsif ($function eq 'TRIM') {
		($self->{'value'} = $params[0]->value) =~ s/^\s+|\s+$//g;
	} elsif ($function eq 'LTRIM') {
		($self->{'value'} = $params[0]->value) =~ s/^\s+//;
	} elsif ($function eq 'RTRIM') {
		($self->{'value'} = $params[0]->value) =~ s/\s+$//;
	} elsif ($function eq 'CONCAT') {
		$self->{'value'} = join '', map { $_->value } @params;
	} elsif ($function eq 'SUBSTR' or $function eq 'SUBSTRING') {
		my ($string, $start, $length) = map { $_->value } @params;
		if ($start == 0) { $start = 1; }
		$self->{'value'} = substr($string, $start - 1, $length);
	}
	$self;
}

1;
#
# Function working on Expr objects
#
sub less {
	my ($self, $other, $reverse) = @_;
	my $answer;
	if (defined $self->{'string'} or defined $other->{'string'}) {
		$answer = ($self->value lt $other->value);
	} else {
		$answer = ($self->value < $other->value);
	}
	return -$answer if $reverse;
	$answer;
}
sub lesseq {
	my ($self, $other, $reverse) = @_;
	my $answer;
	if (defined $self->{'string'} or defined $other->{'string'}) {
		$answer = ($self->value le $other->value);
	} else {
		$answer = ($self->value <= $other->value);
	}
	return -$answer if $reverse;
	$answer;
}
sub notequal {
	my ($self, $other) = @_;
	local $^W = 0;
	if (defined $self->{'string'} or defined $other->{'string'}) {
		($self->value ne $other->value);
	} else {
		($self->value != $other->value);
	}
}

sub likematch {
	my $class = shift;
	my ($field, $string) = @_;

	my $regexp = $string->value;
	$regexp =~ s/(\\\\[%_]|.)/ ($1 eq '%') ? '.*' : ($1 eq '_') ? '.' : "\Q$1" /seg;
	$field->value =~ /^$regexp$/si;
}

1;

