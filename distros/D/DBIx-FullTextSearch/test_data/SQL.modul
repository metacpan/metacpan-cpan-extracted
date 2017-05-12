
# ####################
# Parsing SQL commands

package XBase::SQL::Expr;
package XBase::SQL;

use strict;
use vars qw( $VERSION %COMMANDS );

$VERSION = '0.129';

# #################################
# Type conversions for create table
my %TYPES = ( 'char' => 'C', 'varchar' => 'C',
		'num' => 'N', 'numeric' => 'N', 'int' => 'N',
		'integer' => 'N', 'float' => 'F', 'boolean' => 'L',
		'blob' => 'M', 'memo' => 'M', 'date' => 'D',
		'time' => 'T', 'datetime' => 'T' );

# ##################
# Regexp definitions

%COMMANDS = (

# Top level SQL commands

	'COMMANDS' => 	'SELECT | INSERT | DELETE | UPDATE | CREATE | DROP',
	'SELECT' =>	'select ( SELECTALL | SELECTFIELDS ) from TABLE WHERE ?
							ORDERBY ?',
	'INSERT' =>	'insert into TABLE ( \( INSERTFIELDS \) ) ? values
						\( INSERTCONSTANTS \)',
	'DELETE' =>	'delete from TABLE WHERE ?',
	'UPDATE' =>	'update TABLE set SETCOLUMNS WHERE ?',
	'CREATE' =>	'create table TABLE \( COLUMNDEF ( , COLUMNDEF ) * \)',
	'DROP' =>	'drop table TABLE',

# table, field name, number, string

	'TABLE' =>	'\\S+',
	'FIELDNAME' =>	'[a-z_][a-z0-9_]*',
	'NUMBER' => q'-?\d*\.?\d+',
	'STRING' => q! \\" STRINGDBL \\" | \\' STRINGSGL \\' !,
	'STRINGDBL' => q' STRINGDBLPART ( \\\\. STRINGDBLPART ) * ',
	'STRINGSGL' => q' STRINGSGLPART ( \\\\. STRINGSGLPART ) * ',
	'STRINGDBLPART' => q' [^\\\\"]* ',
	'STRINGSGLPART' => q! [^\\\\']* !,

# select fields

	'SELECTFIELDS' =>	'SELECTFIELD ( , SELECTFIELD ) *',
	'SELECTFIELD' =>	'FIELDNAME',
	'SELECTALL' =>	q'\*',

# where clause

	'WHERE' =>	'where WHEREEXPR',
	'WHEREEXPR' =>	'BOOLEAN',

	'BOOLEAN' =>	q'\( BOOLEAN \) | RELATION ( ( AND | OR ) BOOLEAN ) *',
	'RELATION' =>   'EXPFIELDNAME ( is not ? null | LIKE CONSTANT_NOT_NULL | RELOP ARITHMETIC )',
	'EXPFIELDNAME' => 'FIELDNAME',
	'AND' =>	'and',
	'OR' =>		'or',
	'LIKE' =>	'not ? like',

	'RELOP' => [ qw{ == | = | <= | >= | <> | != | < | > } ],
	'ARITHMETIC' => [ qw{ \( ARITHMETIC \)
		| ( CONSTANT | EXPFIELDNAME ) ( ( \+ | \- | \* | \/ | \% ) ARITHMETIC ) ? } ],
	
	'CONSTANT' => ' CONSTANT_NOT_NULL | NULL ',
	'CONSTANT_NOT_NULL' => ' BINDPARAM | NUMBER | STRING ',
	'BINDPARAM' => q'\?',
	'NULL' => 'null',

	'ORDERBY' => 'order by ORDERFIELDNAME ( asc | ORDERDESC ) ?',
	'ORDERDESC' => 'desc',
	'ORDERFIELDNAME' => 'FIELDNAME',

# insert definitions

	'INSERTFIELDS' =>	'FIELDNAME ( , FIELDNAME ) *',
	'INSERTCONSTANTS' =>	'CONSTANT ( , CONSTANT ) *',

# update definitions

	'SETCOLUMNS' =>	'SETCOLUMN ( , SETCOLUMN ) *',
	'SETCOLUMN' =>	'FIELDNAME = ARITHMETIC',

# create definitions

	'COLUMNDEF' =>	'COLUMNKEY | COLUMNNAMETYPE ( not null ) ?',
	'COLUMNKEY' =>	'primary key \( FIELDNAME \)',
	'COLUMNNAMETYPE' =>	'FIELDNAME FIELDTYPE',
	'FIELDTYPE' =>	'TYPECHAR | TYPENUM | TYPEBOOLEAN | TYPEMEMO | TYPEDATE',
	
	'TYPECHAR' =>	' ( varchar | char ) ( \( TYPELENGTH \) ) ?',
	'TYPENUM' =>	'( num | numeric | float | int | integer ) ( \( TYPELENGTH ( , TYPEDEC ) ? \) ) ?',
	'TYPEDEC' =>	'\d+',

	'TYPELENGTH' =>	'\d+',
	'TYPEBOOLEAN' =>	'boolean | logical',
	'TYPEMEMO' =>	'memo | blob',
	'TYPEDATE' =>	'date | time | datetime',
	);

# #####################################
# "Expected" messages for various types
my %ERRORS = (
	'TABLE' => 'Table name',
	'RELATION' => 'Relation',
	'ARITHMETIC' => 'Arithmetic expression',
	'from' => 'From specification',
	'into' => 'Into specification',
	'values' => 'Values specification',
	'\\(' => 'Left paren',
	'\\)' => 'Right paren',
	'\\*' => 'Star',
	'\\"' => 'Double quote',
	"\\'" => 'Single quote',
	'STRING' => 'String',
	'SELECTFIELDS' => 'Columns to select',
	'FIELDTYPE' => 'Field type',
	);

# ########################################
# Simplifying conversions during the match
my %SIMPLIFY = (
	'STRINGDBL' => sub { join '', '"', get_strings(@_), '"'; },
	'STRINGSGL' => sub { join '', '\'', get_strings(@_), '\''; },
	'STRING' => sub { my $e = (get_strings(@_))[1];
			## $e =~ s/([\\'])/\\$1/g;
			"XBase::SQL::Expr->string($e)"; },
	'NUMBER' => sub { my $e = (get_strings(@_))[0];
				"XBase::SQL::Expr->number($e)"; },
	'EXPFIELDNAME' => sub { my $e = (get_strings(@_))[0];
				"XBase::SQL::Expr->field('$e', \$TABLE, \$VALUES)"; },
	'BINDPARAM' => 'XBase::SQL::Expr->string($BIND->[$startbind++])',
	'FIELDNAME' => sub { uc ((get_strings(@_))[0]); },
	'WHEREEXPR' => sub { join ' ', get_strings(@_); },
	'RELOP' => sub { my $e = (get_strings(@_))[0];
			if ($e eq '=') { $e = '=='; }
			elsif ($e eq '<>') { $e = '!=';} $e; },
	'TABLE' => sub { (get_strings(@_))[0]; },
	'ARITHMETIC' => sub { join ' ', get_strings(@_); },
	'RELATION' => sub { my @values = get_strings(@_);
		local $^W = 0;
		my $testnull = join ' ', @values[1 .. 3];
		if ($testnull =~ /^is (not )?null ?$/i)
			{ return "not $1 defined(($values[0])->value)"; }
		elsif ($values[1] =~ /^(not )?like$/i)
			{ return "$1(XBase::SQL::Expr->likematch($values[0], $values[2])) " }
		else { return join ' ', @values; }	},
	'NULL' => 'XBase::SQL::Expr->null()',
	'AND' =>	'and',
	'OR' =>		'or',
	'LIKE' =>	sub { join ' ', get_strings(@_); },
	);
#
#
my %STORE = (
	'SELECT' => sub { shift->{'command'} = 'select'; },
	'SELECTALL' => 'selectall',
	'SELECTFIELD' => 'fields',
	
	### 'SELECTFIELDS' => sub { my ($self, @fields) = @_;
	###	while (@fields) { push @{$self->{'fields'}}, shift @fields; shift @fields; }},

	'INSERT' => sub { shift->{'command'} = 'insert'; },
	'INSERTCONSTANTS' => sub { my $self = shift;
		my $fntext = 'sub { my ($TABLE, $BIND, $startbind) = @_; map { $_->value() } ' . join(' ', @_) . ' }';
		my $fn = eval $fntext;
		if ($@) { $self->{'inserterror'} = $@; }
		else { $self->{'insertfn'} = $fn; }
		},
	'INSERTFIELDS' => sub { my ($self, @fields) = @_;
		while (@fields) { push @{$self->{'fields'}}, shift @fields; shift @fields; }},

	'DELETE' => sub { shift->{'command'} = 'delete'; },

	'UPDATE' => sub { shift->{'command'} = 'update'; },
	
	'SETCOLUMNS' => sub { my $self = shift;
		my $list = '';
		while (@_)
			{
			push @{$self->{'fields'}}, shift @_;
			shift @_;
			$list .= shift(@_) . ', ';
			shift @_;
			}
		my $fntext = 'sub { my ($TABLE, $VALUES, $BIND, $startbind) = @_; map { $_->value() } ' . $list . ' }';
		my $fn = eval $fntext;
		if ($@) { $self->{'updateerror'} = $@; }
		else { $self->{'updatefn'} = $fn; }
		},


	'CREATE' => sub { shift->{'command'} = 'create'; },
	'COLUMNNAMETYPE' => sub { my $self = shift;
		push @{$self->{'createfields'}}, $_[0];
		push @{$self->{'createtypes'}}, $TYPES{lc $_[1]};
		push @{$self->{'createlengths'}}, $_[3];
		push @{$self->{'createdecimals'}}, $_[5]; },

	'DROP' => sub { shift->{'command'} = 'drop'; },
	
	'TABLE' => 'table',

	'WHEREEXPR' => sub { my ($self, $expr) = @_;
		### print STDERR "Evalling: $expr\n";
		my $fn = eval 'sub { my ($TABLE, $VALUES, $BIND, $startbind) = @_; ' . $expr . '; }';
		if ($@) { $self->{'whereerror'} = $@; }
		else { $self->{'wherefn'} = $fn; }
		},
	
	'FIELDNAME' => 'usedfields',
	'BINDPARAM' => sub { my $self = shift; $self->{'numofbinds'}++ },
	'where' => sub { my $self = shift;
		$self->{'bindsbeforewhere'} = $self->{'numofbinds'}; },
	
	'ORDERFIELDNAME' => 'orderfield',
	'ORDERDESC' => 'orderdesc',
	);

sub parse
	{
	my ($class, $string) = @_;
	my $self = bless {}, $class;

	### print STDERR "Parsing $string\n";
	# try to match the $string against $COMMANDS{'COMMANDS'}
	my ($srest, $error, $errstr, @result) = match($string, 'COMMANDS');
	$srest =~ s/^\s+//s;

	if ($srest ne '' and not $error)
		{ $error = 1; $errstr = 'Extra characters in SQL command'; }
	if ($error)
		{
		if (not defined $errstr) { $errstr = 'Error in SQL command'; }
		substr($srest, 40) = '...' if length $srest > 44;
		$self->{'errstr'} = "$errstr near `$srest'";
		}
	else
		{
		# take the results and store them to $self
		### use Data::Dumper; print STDERR Dumper @result;
		$self->store_results(\@result, \%STORE);
		if (defined $self->{'whereerror'})
			{ $self->{'errstr'} = "Some deeper problem: eval failed: $self->{'whereerror'}"; }
		### print STDERR Dumper $self;
		}
	$self;
	}
sub match
	{
	my $string = shift;
	my @regexps = @_;

	my $origstring = $string;

	my $title;

	if (@regexps == 1 and defined $COMMANDS{$regexps[0]})
		{
		$title = $regexps[0];
		my $c = $COMMANDS{$regexps[0]};
		@regexps = expand( ( ref $c ) ? @$c :
					grep { $_ ne '' } split /\s+/, $c);
		}

	my $modif;
	if (@regexps and $regexps[0] eq '?' or $regexps[0] eq '*')
		{ $modif = shift @regexps; }

	my @result;
	my $i = 0;
	while ($i < @regexps)
		{
		my $regexp = $regexps[$i];
		my ($error, $errstr, @r);
		if (ref $regexp)
			{ ($string, $error, $errstr, @r) = match($string, @$regexp); }
		elsif ($regexp eq '|')
			{ $i = $#regexps; next; }
		elsif (defined $COMMANDS{$regexp})
			{ ($string, $error, $errstr, @r) = match($string, $regexp); }
		elsif ($string =~ s/^\s*?($regexp)(?:$|\b|(?=\W))//si)
			{ @r = $1; }
		else
			{ $error = 1; }

		if (defined $error)
			{
			if ($origstring eq $string)
				{
				while ($i < @regexps)
					{ last if $regexps[$i] eq '|'; $i++; }
				next if $i < @regexps;
				last if defined $modif;
				}
	
			if (not defined $errstr)
				{
				if (defined $ERRORS{$regexp})
					{ $errstr = $ERRORS{$regexp}; }
				elsif (defined $title and defined $ERRORS{$title})
					{ $errstr = $ERRORS{$title}; }
				$errstr .= ' expected' if defined $errstr;
				}

			return ($string, 1, $errstr, @result);
			}
	
		if (ref $regexp)
			{ push @result, @r; }
		elsif (@r > 1)
			{ push @result, $regexp, [ @r ]; }
		else
			{ push @result, $regexp, $r[0]; }
		}
	continue
		{
		$i++;
		if (defined $modif and $modif eq '*' and $i >= @regexps)
			{ $origstring = $string; $i = 0; }
		}

	return ($string, undef, undef, @result);
	}

sub expand
	{
	my @result;
	my $i = 0;
	while ($i < @_)
		{
		my $t = $_[$i];
		if ($t eq '(')
			{
			$i++;
			my $begin = $i;
			my $nest = 1;
			while ($i < @_ and $nest)
				{
				my $t = $_[$i];
				if ($t eq '(') { $nest++; }
				elsif ($t eq ')') { $nest--; }
				$i++;
				}
			$i--;
			push @result, [ expand(@_[$begin .. $i - 1]) ];	
			}
		elsif ($t eq '?' or $t eq '*')
			{
			my $prev = pop @result;
			push @result, [ $t, ( ref $prev ? @$prev : $prev ) ];
			}
		else
			{ push @result, $t; }
		$i++;
		}
	@result;
	}
sub store_results
	{
	my ($self, $result) = @_;

	my $i = 0;
	while ($i < @$result)
		{
		my ($key, $match) = @{$result}[$i, $i + 1];
		my $stval = $STORE{$key};
		my $m = $SIMPLIFY{$key};

		if (ref $match)
			{ $self->store_results($match); }
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
		$i += 2;
		}
	}
#
#
sub get_strings
	{
	my @strings = @_;
	if (@strings == 1 and ref $strings[0])
		{ @strings = @{$strings[0]}; }
	my @result;	my $i = 1;
	while ($i < @strings)
		{
		if (ref $strings[$i])
			{ push @result, get_strings($strings[$i]); }
		else
			{ push @result, $strings[$i]; }
		$i += 2;
		}
	@result;
	}
sub print_result
	{
	my $result = shift;
	my @result = @$result;
	my @before = @_;
	my $i = 0;
	while ($i < @result)
		{
		my ($regexp, $string) = @result[$i, $i + 1];
		if (ref $string)
			{ print_result($string, @before, $regexp); }
		else
			{ print "$string:\t @before $regexp\n"; }
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
	'/'  => sub { my $a = ( $_[2] ? $_[0]->value / $_[1]->value
				: $_[1]->value / $_[0]->value );
			XBase::SQL::Expr->number($a); },
	'%'  => sub { my $a = ( $_[2] ? $_[0]->value % $_[1]->value
				: $_[1]->value % $_[0]->value );
			XBase::SQL::Expr->number($a); },
	'<'  => \&less,
	'<=' => \&lesseq,
	'>'  => sub { $_[1]->less(@_[0, 2]); },
	'>=' => sub { $_[1]->lesseq(@_[0, 2]); },
	'!=' => \&notequal,
	'<>' => \&notequal,
	'==' => sub { my $a = shift->notequal(@_); return ( $a ? 0 : 1); },
	'""' => sub { ref shift; },
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
#
# Function working on Expr objects
#
sub less
	{
	my ($self, $other, $reverse) = @_;
	my $answer;
	if (defined $self->{'string'} or defined $other->{'string'})
		{ $answer = ($self->value lt $other->value); }
	else
		{ $answer = ($self->value < $other->value); }
	return -$answer if $reverse;
	$answer;
	}
sub lesseq
	{
	my ($self, $other, $reverse) = @_;
	my $answer;
	if (defined $self->{'string'} or defined $other->{'string'})
		{ $answer = ($self->value le $other->value); }
	else
		{ $answer = ($self->value <= $other->value); }
	return -$answer if $reverse;
	$answer;
	}
sub notequal
	{
	my ($self, $other) = @_;
	local $^W = 0;
	if (defined $self->{'string'} or defined $other->{'string'})
		{ ($self->value ne $other->value); }
	else
		{ ($self->value != $other->value); }
	}

sub likematch
	{
	my $class = shift;
	my ($field, $string) = @_;

	my $regexp = $string->value;
	$regexp =~ s/(\\\\[%_]|.)/ ($1 eq '%') ? '.*' : ($1 eq '_') ? '.' : "\Q$1" /seg;
	$field->value =~ /^$regexp$/i;
	}

1;

