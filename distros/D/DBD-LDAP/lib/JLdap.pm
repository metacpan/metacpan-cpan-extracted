#!/usr/bin/perl

package JLdap;

require 5.002;

use Net::LDAP::Entry;
no warnings qw (uninitialized);

#use Fcntl; 

##++
##  Global Variables. Declare lock constants manually, instead of 
##  importing them from Fcntl.
##
use vars qw ($VERSION);
##--

$JLdap::VERSION = '0.24';

#my $NUMERICTYPES = '^(NUMBER|FLOAT|DOUBLE|INT|INTEGER|NUM)$';       #20000224
#my $STRINGTYPES = '^(VARCHAR|CHAR|VARCHAR|DATE|LONG|BLOB|MEMO)$';

##++
##  Public Methods and Constructor
##--

sub new
{
    my $class = shift;
    my $self;

    $self = {
                commands     => 'select|update|delete|alter|insert|create|drop|primary_key_info',
                column       => '[A-Za-z0-9\~\x80-\xFF][\w\x80-\xFF]+',
		_select      => '[\w\x80-\xFF\*,\s\~]+',
		path         => '[\w\x80-\xFF\-\/\.\:\~\\\\]+',
		table        => '',
		timestamp    => 0,
		fields       => {},
		use_fields   => '',
		key_fields   => '',
		order        => [],
		types        => {},
		lengths      => {},
		scales       => {},
		defaults     => {},
		records      => [],
		errors       => {},
		lasterror    => 0,     #JWT:  ADDED FOR ERROR-CONTROL
		lastmsg      => '',
		CaseTableNames  => 0,    #JWT:  19990991 TABLE-NAME CASE-SENSITIVITY?
		LongTruncOk  => 0,     #JWT: 19991104: ERROR OR NOT IF TRUNCATION.
		RaiseError   => 0,     #JWT: 20000114: ADDED DBI RAISEERROR HANDLING.
		silent       => 0,
		ldap_dbh			 => 0,
		ldap_sizelimit => 0,    #JWT: LIMIT #RECORDS FETCHED, IF SET.
		ldap_timelimit => 0,    #JWT: LIMIT #RECORDS FETCHED, IF SET.
		ldap_deref => 0,    #JWT: LIMIT #RECORDS FETCHED, IF SET.
		ldap_typesonly => 0,
		ldap_callback => 0,
		ldap_scope => 0,
		ldap_inseparator => '|',
		ldap_outseparator => '|',
		ldap_firstonly => 0,
		ldap_nullsearchvalue => ' ',  #ADDED 20040330 TO FOR BACKWARD COMPATABILITY.
		ldap_appendbase2ins => 0,     #ADDED 20060719 FOR BACKWARD COMPAT. - 0.08+ NO LONGER APPENDS BASE TO ALWAYSINSERT PER REQUEST.
		dirty			 => 0,     #JWT: 20000229: PREVENT NEEDLESS RECOMMITS.
		tindx => 0                    #REPLACES GLOBAL VARIABLE.
	    };

    bless $self, $class;

	 for (my $i=0;$i<scalar(@_);$i+=2)   #ADDED: 20040330 TO ALLOW SETTING ATTRIBUTES IN INITIALIZATION!
	 {
	 	$self->{$_[$i]} = $_[$i+1];
	 }

    $self->initialize;
    return $self;
}
sub initialize
{
	my $self = shift;

	$self->define_errors;
}

sub sql
{
	my ($self, $csr, $query) = @_;

	my ($command, $status, $base, $fields);
#print STDERR "-sql1($command,$status,$base,$fields)";
	return wantarray ? () : -514  unless ($query);
	$self->{lasterror} = 0;
	$self->{lastmsg} = '';
	$query   =~ s/\n/ /gso;
	$query   =~ s/^\s*(.*?)\s*$/$1/;
	$query = 'select tables'  if ($query =~ /^show\s+tables$/i);
	$query = 'select tables'  if ($query =~ /^select\s+TABLE_NAME\s+from\s+USER_TABLES$/i);  #ORACLE-COMPATABILITY.
	$command = '';

	if ($query =~ /^($self->{commands})/io)
	{
		$command = $1;
		$command =~ tr/A-Z/a-z/;    #ADDED 19991202!
		$status  = $self->$command ($csr, $query);
		if (!defined($status))      #NEXT 5 ADDED PER PATCH REQUEST 20091101:
		{
			$self->display_error(-599);
			return wantarray ? () : -599;
		}
		elsif (ref ($status) eq 'ARRAY')   #SELECT RETURNED OK (LIST OF RECORDS).
		{
			return wantarray ? @$status : $status;
		}
		else
		{
			if ($status < 0)
			{             #SQL RETURNED AN ERROR!
#print STDERR "-sql6 status=$status=\n";
				$self->display_error ($status);
				#return ($status);
				return wantarray ? () : $status;
			}
			else
			{                        #SQL RETURNED OK.
#print STDERR "-sql7 status=$status= at=$@= cash=$_= bang=$!= query=$?=\n";
				return wantarray ? ($status) : $status;
			}
		}
	}
	else
	{
		return wantarray ? () : -514;
	}
}

sub select
{
	my ($self, $csr, $query) = @_;

	my (@ordercols) = ();
	$regex = $self->{_select};
	$path  = $self->{path};
	my (@rtnvals) = ();

	my $distinct;
	$distinct = 1  if ($query =~ s/select\s+distinct(\s+\w|\s*\(|\s+\*)/select $1/i);
	my ($dbh) = $csr->FETCH('ldap_dbh');
	my ($tablehash);

	if ($query =~ /^select tables$/io)
	{
		$tablehash = $dbh->FETCH('ldap_tablenames');
		$self->{use_fields} = 'TABLE_NAME';  #ADDED 20000224 FOR DBI!
		$values_or_error = [];
		for ($i=0;$i<=$#{$tablehash};$i++)
		{
			push (@$values_or_error,[$tablehash->[$i]]);
		}
		unshift (@$values_or_error, ($#{$tablehash}+1));
		return $values_or_error;
	}
	elsif ($query =~ /^select\s+                         # Keyword
			($regex)\s+                       # Columns
			from\s+                           # 'from'
			($path)(.*)$/iox)
	{           
		($attbs, $table, $extra) = ($1, $2, $3);

		$table =~ tr/A-Z/a-z/  unless ($self->{CaseTableNames});  #JWT:TABLE-NAMES ARE NOW CASE-INSENSITIVE!
		$self->{file} = $table;
		if ($extra =~ s/([\s|\)]+)order\s+by\s*(.*)/$1/i)
		{
			$orderclause = $2;
			@ordercols = split(/,/,$orderclause);
			$descorder = ($ordercols[$#ordercols] =~ s/(\w+\W+)desc(?:end|ending)?$/$1/i);  #MODIFIED 20000721 TO ALLOW "desc|descend|descending"!
			for $i (0..$#ordercols)
			{
				$ordercols[$i] =~ s/\s//igo;   #CASE-INSENSITIVITY ADDED NEXT 2: 20050416 PER PATCH BY jmorano
				$ordercols[$i] =~ s/[\(\)]+//igo;
			}
		}
		$tablehash = $dbh->FETCH('ldap_tables');
		return (-524)  unless ($tablehash->{$table});

		my ($base, $objfilter, $dnattbs, $allattbs, $alwaysinsert) = split(/\:/o ,$tablehash->{$table});
		$attbs = $allattbs  if ($allattbs && $attbs =~ s/\*//o);
		$attbs =~ s/\s//go;
		$attbs =~ tr/A-Z/a-z/;
		@{$self->{order}} = split(/,/o, $attbs)  unless ($attbs eq '*');
		my $fieldnamehash = ();
		my $attbcnt = 0;
		foreach my $i (@{$self->{order}})
		{
			$fieldnamehash{$i} = $attbcnt++;
		}
		my ($ldap) = $csr->FETCH('ldap_ldap');
		$objfilter ||= 'objectclass=*';
		$objfilter = "($objfilter)"  unless ($objfilter =~ /^\(/o);
#print "<BR>-where=$extra=\n";
		if ($extra =~ /^\s+where\s*(.+)$/io)
		{
			$filter = $self->parse_expression($1);
			$filter = '('.$filter.')'  unless ($filter =~ /^\(/o);
			$filter = "(&$objfilter$filter)";
		}
		else
		{
			$filter = $objfilter;
		}
#print "<BR>-filter =$filter=\n";
		my $data;
		my (@searchops) = (
				'base' => $base,
				'filter' => $filter,
				'attrs' => [split(/\,/o, $attbs)]
		);
		foreach my $i (qw(ldap_sizelimit ldap_timelimit deref typesonly 
		callback))
		{
			$j = $i;
			$j =~ s/^ldap_//o;
			push (@searchops, ($j, $self->{$i}))  if ($self->{$i});
		}
		push (@searchops, ('scope', ($self->{ldap_scope} || 'one')));
#print "--- ATTBS =$attbs=\n";
#print "--- SEARCH OPS =".join('|',@searchops)."=\n";
		$data = $ldap->search(@searchops) 
				or return($self->ldap_error($@,"Search failed to return object: filter=$filter (".$data->error().")"));
#print "--- data=$data=\n";
		my ($j) = 0;
		my (@varlist) = ();
		while (my $entry = $data->shift_entry())
		{
			$dn = $entry->dn();
			next  unless ($dn =~ /$base$/i);   #CASE-INSENSITIVITY ADDED NEXT 2: 20050416 PER PATCH BY jmorano
			@attributes = $entry->attributes;
			unless ($attbcnt)
			{
				$attbs = join(',',@attributes);
				$attbcnt = 0;
				@{$self->{order}} = @attributes;
				foreach my $i (@{$self->{order}})
				{
					$fieldnamehash{$i} = $attbcnt++;
				}
			}
			$varlist[$j] = [];
			for (my $i=0;$i<$attbcnt;$i++)
			{
				$varlist[$j][$i] = '';
			}
			$i = 0;
			foreach my $attr (@{$self->{order}})
			{
#				$valuesref = $entry->get($attr);   #CHGD. TO NEXT PER PATCH REQUEST 20091101:
				$valuesref = $entry->get_value($attr, asref => 1);
				if ($self->{ldap_firstonly} && $self->{ldap_firstonly} <= scalar (@{$valuesref}))
				{
					#$varlist[$j][$fieldnamehash{$attr}] = join($self->{ldap_outseparator}, $valuesref->[0]); #CHGD. 20010829 TO NEXT.
					$varlist[$j][$fieldnamehash{$attr}] = join($self->{ldap_outseparator}, @{$valuesref}[0..($self->{ldap_firstonly}-1)]);
				}
				else
				{
					$varlist[$j][$fieldnamehash{$attr}] = join($self->{ldap_outseparator}, @$valuesref) || '';
				}
				unless ($valuesref[0])
				{
					$varlist[$j][$fieldnamehash{dn}] = $dn  if ($attr eq 'dn');
				}
				$i++;
			}
			++$j;
		}
		$self->{use_fields} = $attbs;
		if ($distinct)   #THIS MAKES "DISTINCT" WORK.
		{
			my (%disthash);
			for (my $i=0;$i<=$#varlist;$i++)
			{
				++$disthash{join("\x02",@{$varlist[$i]})};
			}
			@varlist = ();
			foreach my $i (keys(%disthash))
			{
				push (@varlist, [split(/\x02/o, $i, -1)]);
			}
		}
		if ($#ordercols >= 0)   #SORT 'EM!
		{
			my @SV;
			for (my $i=0;$i<=$#varlist;$i++)
			{
				$SV[$i] = '';
				foreach my $j (@ordercols)
				{
					$SV[$i] .= $varlist[$i][$fieldnamehash{$j}] . "\x01";
				}
			}
			@sortvector = &sort_elements(\@SV);
			@sortvector = reverse(@sortvector)  if ($descorder);
			@SV = ();
			while (@sortvector)
			{
				push (@SV, $varlist[shift(@sortvector)]);
			}
			@varlist = @SV;
			@SV = ();
		}
		return [($#attributes+1), @varlist];
	}
	else     #INVALID SELECT STATEMENT!
	{
		return (-503);
	}
}

sub sort_elements
{
	my (@elements, $line, @sortlist, @sortedlist, $j, $t, $argcnt, $linedata, 
			$vectorid, @sortvector);

	my ($lo) = 0;
	my ($hi) = 0;
	$lo = shift  unless (ref($_[0]));
	$hi = shift  unless (ref($_[0]));

	if ($lo || $hi)
	{
		for ($j=0;$j<=$#{$_[0]};$j++)
		{
			$sortvector[$j] = $j;
		}
	}
	$hi ||= $#{$_[0]};
	$argcnt = scalar(@_);
	for (my $i=$lo;$i<=$hi;$i++)
	{
		$line = $_[0][$i];
		for ($j=1;$j<$argcnt;$j++)
		{
			$line .= "\x02" . $_[$j][$i];
		}
		$line .= "\x04".$i;
		push (@sortlist, $line);
	}

	@sortedlist = sort @sortlist;
	$i = $lo;
	foreach $line (@sortedlist)
	{
		($linedata,$vectorid) = split(/\x04/o, $line);
		(@elements) = split(/\x02/o, $linedata);
		$t = $#elements  unless $t;
		for ($j=$t;$j>=1;$j--)
		{
			#push (@{$_[$j]}, $elements[$j]);
			${$_[$j]}[$i] = $elements[$j];
		}
		$sortvector[$i] = $vectorid;
		$elements[0] =~ s/\s+//go;
		${$_[0]}[$i] = $elements[$j];
		++$i;
	}
	return @sortvector;
}

sub ldap_error
{
	my ($self,$errcode,$errmsg,$warn) = @_;

	$err = $errcode || -1;
	$errdetails = $errmsg;
	$err = -1 * $err  if ($err > 0);
	return ($err)  unless (defined($warn) && $warn);

#	print "Content-type: text/html\nWindow-target: _parent", "\n\n"  
#			if (defined($warn) && $warn == 1);

	return ($self->display_error($errcode));
}

sub display_error
{	
	my ($self, $error) = @_;

	$other = $@ || $! || 'None';

	print STDERR <<Error_Message  unless ($self->{silent});

Oops! The following error occurred when processing your request:

    $self->{errors}->{$error} ($errdetails)

Here's some more information to help you:

	file:  $self->{file}
    $other

Error_Message

#JWT:  ADDED FOR ERROR-CONTROL.

	$self->{lasterror} = $error;
	$self->{lastmsg} = "$error:" . $self->{errors}->{$error};
	$self->{lastmsg} .= '('.$errdetails.')'  if ($errdetails);  #20000114

	$errdetails = '';   #20000114
	die $self->{lastmsg}  if ($self->{RaiseError});  #20000114.

    #return (1);
	return ($error);
}

sub commit
{
	my ($self) = @_;
	my ($status) = 1;
	my ($dbh) = $self->FETCH('ldap_dbh');
	my ($autocommit) = $dbh->FETCH('AutoCommit');

	$status = $dbh->commit()  unless ($autocommit);

	$self->{dirty} = 0  if ($status > 0);
	return undef  if ($status <= 0);   #ADDED 20000103
	return $status;
}

##++
##  Private Methods
##--

sub define_errors
{
	my $self = shift;
	my $errors;

	$errors = {};

	$errors->{'-501'} = 'Could not open specified database.';
	$errors->{'-502'} = 'Specified column(s) not found.';
	$errors->{'-503'} = 'Incorrect format in [select] statement.';
	$errors->{'-504'} = 'Incorrect format in [update] statement.';
	$errors->{'-505'} = 'Incorrect format in [delete] statement.';
	$errors->{'-506'} = 'Incorrect format in [add/drop column] statement.';
	$errors->{'-507'} = 'Incorrect format in [alter table] statement.';
	$errors->{'-508'} = 'Incorrect format in [insert] command.';
	$errors->{'-509'} = 'The no. of columns does not match no. of values.';
	$errors->{'-510'} = 'A severe error! Check your query carefully.';
	$errors->{'-511'} = 'Cannot write the database to output file.';
	$errors->{'-512'} = 'Unmatched quote in expression.';
	$errors->{'-513'} = 'Need to open the database first!';
	$errors->{'-514'} = 'Please specify a valid query.';
#    $errors->{'-515'} = 'Cannot get lock on database file.';
#    $errors->{'-516'} = 'Cannot delete temp. lock file.';
	$errors->{'-517'} = "Built-in function failed ($@).";
	$errors->{'-518'} = "Unique Key Constraint violated.";  #JWT.
	$errors->{'-519'} = "Field would have to be truncated.";  #JWT.
	$errors->{'-520'} = "Can not create existing table (drop first!).";  #20000225 JWT.
	$errors->{'-521'} = "Can not change datatype on non-empty table.";  #20000323 JWT.
	$errors->{'-522'} = "Can not decrease field-size on non-empty table.";  #20000323 JWT.
	$errors->{'-523'} = "Update Failed to commit changes.";  #20000323 JWT.
	$errors->{'-524'} = "No such table.";  #20000323 JWT.
	$errors->{'-599'} = 'General error.';

	$self->{errors} = $errors;

	return (1);
}

sub parse_expression
{
	my ($self, $s) = @_;

	$s =~ s/\s+$//o;     #STRIP OFF LEADING AND TRAILING WHITESPACE.
	$s =~ s/^\s+//o;
	return unless ($s);


	my $relop = '(?:<|=|>|<=|>=|!=|like|not\s+like|is\s+not|is)';
	my %boolopsym = ('and' => '&', 'or' => '|');

	my $indx = 0;

	my @P = ();
	my @T3 = ();            #PROTECTS MULTI-WAY RELOP EXPRESSIONS, IE. (A AND B AND C)
	my $t3indx = 0;
	@T = ();
	my @QS = ();

	$s=~s|\\\'|\x04|go;      #PROTECT "\'" IN QUOTES.
	$s=~s|\\\"|\x02|go;      #PROTECT "\"" IN QUOTES.

	#THIS NEXT LOOP STRIPS OUT AND SAVES ALL QUOTED STRING LITERALS 
	#TO PREVENT THEM FROM INTERFEARING WITH OTHER REGICES, IE. DON'T 
	#WANT OPERATORS IN STRINGS TO BE TREATED AS OPERATORS!

	$indx++ while ($s =~ s/([\'\"])([^\1]*?)\1/
			$QS[$indx] = $2; "\$QS\[$indx]"/e);

	for (my $i=0;$i<=$#QS;$i++)   #ESCAPE LDAP SPECIAL-CHARACTERS.
	{
		$QS[$i] =~ s/\\x([\da-fA-F][\da-fA-F])/\x05$1/g;   #PROTECT PERL HEX TO LDAP HEX (\X## => \##).
		#$QS[$i] =~ s/([\*\(\)\+\\\<\>])/\\$1/g;  #CHGD. TO NEXT. 20020409!
		$QS[$i] =~ s/([\*\(\)\\])/"\\".unpack('H2',$1)/eg;
		#$QS[$i] =~ s/\\x(\d\d)/\\$1/g;   #CONVERT PERL HEX TO LDAP HEX (\X## => \##).
		$QS[$i] =~ s/\x05([\da-fA-F][\da-fA-F])/\\$1/go;   #CONVERT PERL HEX TO LDAP HEX (\X## => \##).
	}
#print STDERR "-parse_expression: QS list=".join('|',@QS)."=   SSSS=$s=\n";
	$indx = 0;	

	#I TRIED TO ALLOWING ATTRIBUTES TO BE COMPARED W/OTHER ATTRIBUTES, BUT 
	#(20020409), BUT APPARENTLY LDAP ONLY ALLOWS STRING CONSTANTS ON RHS OF OPERATORS!

#	$indx++ while ($s =~ s/(\w+)\s*($relop)\s*(\$QS\[\d*\]|\w+)/  #THIS WAS TRIED TO COMPARE ATTRIBUTES WITH ATTRIBUTES, BUT APPARENTLY DOESN'T WORK IN LDAP!
	$indx++ while ($s =~ s/(\w+)\s*($relop)\s*(\$QS\[\d*\])/
			my ($one, $two, $three) = ($1, $2, $3);
			my ($regex) = 0;
			my ($opr) = $two;
			#CONVERT "NOT LIKE" AND "IS NOT" TO "!( = ).

			if ($two =~ m!(?:not\s+like|is\s+not)!io)
			{
				$two = '=';
				$regex = 2;
			}
			elsif ($two =~ m!(?:like|is)!io)  #CONVERT "LIKE" AND "IS" TO "=".
			{
				$two = '=';
				$regex = 1;
			}
			$P[$indx] = $one.$two.$three;   #SAVE EXPRESSION.
		
			#CONVERT SQL WILDCARDS INTO LDAP WILDCARDS IN OPERAND.
		
			my ($qsindx);
			if ($three =~ m!\$QS\[(\d+)\]!)
			{
				$qsindx = $1;
				if ($regex > 0)
				{
					if ($opr !~ m!is!io)
					{
						$QS[$qsindx] =~ s!\%!\*!go;     #FIX WILDCARD.  NOTE - NO FIX FOR "_"!
					}
				}
				$QS[$qsindx] = $self->{ldap_nullsearchvalue}  unless (length($QS[$qsindx]));
			}
			$P[$indx] = "!($P[$indx])"  if ($regex == 2 || $opr eq '!=' || ($opr eq '=' && !length($QS[$qsindx])));  #INVERT EXPRESSION IF "NOT"!
			$P[$indx] =~ s!\!\=!\=!o;   #AFTER INVERSION, FIX "!=" (NOT VALID IN LDAP!)
			"\$P\[$indx]";
	/ei);    #CASE-INSENSITIVITY ADDED NEXT 2: 20050416 PER PATCH BY jmorano
	$self->{tindx} = 0;
	$s = &parseParins($self, $s);

	for (my $i=0;$i<=$#T;$i++)
	{
#		1 while ($T[$i] =~ s/(.+?)\s*\band\b\s*(.+)/\&\($1\)\($2\)/i);
		1 while ($T[$i] =~ s/([^\(\)]+)\s*\band\b\s*([^\(\)]+)(?:and|or)?/\&\($1\)\($2\)/i);
		1 while ($T[$i] =~ s/([^\(\)]+)\s*\bor\b\s*([^\(\)]+)(?:and|or)?/\|\($1\)\($2\)/i);
	}
	$s =~ s/AND/and/igo;
	$s =~ s/OR/or/igo;
#	1 while ($s =~ s/(.+?)\s*\band\b\s*(.+)/\(\&\($1\)\($2\)\)/i);   #CASE-INSENSITIVITY ADDED NEXT 2: 20050416 PER PATCH BY jmorano
	1 while ($s =~ s/([^\(\)]+)\s*\band\b\s*([^\(\)]+)(?:and|or)?/\&\($1\)\($2\)/i);   #CASE-INSENSITIVITY ADDED NEXT 2: 20050416 PER PATCH BY jmorano
	1 while ($s =~ s/([^\(\)]+)\s*\bor\b\s*([^\(\)]+)(?:and|or)?/\|\($1\)\($2\)/i);   #CASE-INSENSITIVITY ADDED NEXT 2: 20050416 PER PATCH BY jmorano
	1 while ($s =~ s/\bnot\b\s*([^\s\)]+)?/\!\($1\)/);
	1 while ($s =~ s/\$T\[(\d+)\]/$T[$1]/g);
	$s =~ s/(\w+)\s+is\s+not\s+null?/$1\=\*/gi;
	$s =~ s/(\w+)\s+is\s+null?/\!\($1\=\*\)/gi;

	#CONVERT SQL WILDCARDS TO PERL REGICES.

	1 while ($s =~ s/\$P\[(\d+)\]/$P[$1]/g);
	$s =~ s/ +//go;
	1 while ($s =~ s/\$QS\[(\d+)\]/$QS[$1]/g);
	$s =~ s/\x04/\'/go;    #UNPROTECT AND UNESCAPE QUOTES WITHIN QUOTES.
	$s = '(' . $s . ')'  unless ($s =~ /^\(/o);
	return $s;
}

sub parseParins
{
	my $self = shift;
	my $s = shift;

	$self->{tindx}++ while ($s =~ s/\(([^\(\)]+)\)/
			$T[$self->{tindx}] = &parseParins($self, $1); "\$T\[$self->{tindx}]"
	/e);
	return $s;
}

sub rollback
{
	my ($self) = @_;

	my ($status) = 1;
	my ($dbh) = $self->FETCH('ldap_dbh');
	my ($autocommit) = $dbh->FETCH('AutoCommit');

	$status = $dbh->rollback()  unless ($autocommit);

	$self->{dirty} = 0  if ($status > 0);
	return $status;
}

sub update
{
	my ($self, $csr, $query) = @_;
	my ($i, $path, $regex, $table, $extra, @attblist, $filter, $all_columns);
	my $status = 0;
	my ($psuedocols) = "CURVAL|NEXTVAL|ROWNUM";
#print STDERR "-update10 sql=$query=\n";
    ##++
    ##  Hack to allow parenthesis to be escaped!
    ##--

	$query =~ s/\\([()])/sprintf ("%%\0%d: ", ord ($1))/ge;
	$path  =  $self->{path};
	$regex =  $self->{column};

	if ($query =~ /^update\s+($path)\s+set\s+(.+)$/i)
	{
		($table, $extra) = ($1, $2);
#print STDERR "-update20: table=$table= extra=$extra=\n";
		#ADDED IF-STMT 20010418 TO CATCH 
		#PARENTHESIZED SET-CLAUSES (ILLEGAL IN ORACLE & CAUSE WIERD PARSING ERRORS!)

		if ($extra =~ /^\(.+\)\s*where/io)
		{
			$errdetails = 'parenthesis around SET clause?';
			return (-504);
		}
		$table =~ tr/A-Z/a-z/  unless ($self->{CaseTableNames});  #JWT:TABLE-NAMES ARE NOW CASE-INSENSITIVE!
		$self->{file} = $table;

		my ($dbh) = $csr->FETCH('ldap_dbh');
		my ($ldap) = $csr->FETCH('ldap_ldap');
		my ($tablehash) = $dbh->FETCH('ldap_tables');
		return (-524)  unless ($tablehash->{$table});
		my ($base, $objfilter, $dnattbs, $allattbs, $alwaysinsert) = split(/\:/,$tablehash->{$table});

		$all_columns = {};

		$extra =~ s/\\\\/\x02/go;         #PROTECT "\\"
		#1$extra =~ s/\'\'/\x03\x03/go;    #PROTECT '', AND \'.
		$extra =~ s/\\\'/\x03/go;    #PROTECT '', AND \'.

		$extra =~ s/^\s+//o;  #STRIP OFF SURROUNDING SPACES.
		$extra =~ s/\s+$//o;

		#NOW TEMPORARILY PROTECT COMMAS WITHIN (), IE. FN(ARG1,ARG2).

		$column = $self->{column};
		$extra =~ s/($column\s*\=\s*)\'(.*?)\'(,|$)/
				my ($one,$two,$three) = ($1,$2,$3);
				$two =~ s|\,|\x05|go;
				$two =~ s|\(|\x06|go;
				$two =~ s|\)|\x07|go;
				$one."'".$two."'".$three;
		/eg;

		1 while ($extra =~ s/\(([^\(\)]*)\)/
				my ($args) = $1;
				$args =~ s|\,|\x05|go;
				"\x06$args\x07";
		/eg);
		@expns = split(',',$extra);
#print STDERR "-update50: extra=$extra= expns=".join('|',@expns)."=\n";
		for ($i=0;$i<=$#expns;$i++)  #PROTECT "WHERE" IN QUOTED VALUES.
		{
			$expns[$i] =~ s/\x05/\,/go;
			$expns[$i] =~ s/\x06/\(/go;
			$expns[$i] =~ s/\x07/\)/go;
			$expns[$i] =~ s/\=\s*'([^']*?)where([^']*?)'/\='$1\x05$2'/gi;
			$expns[$i] =~ s/\'(.*?)\'/my ($j)=$1; 
					$j=~s|where|\x05|gio; 
					"'$j'"
			/eg;
		}
		$extra = $expns[$#expns];    #EXTRACT WHERE-CLAUSE, IF ANY.
		$filter = ($extra =~ s/(.*)where(.+)$/where$1/i) ? $2 : '';
		$filter =~ s/\s+//o;
		$expns[$#expns] =~ s/\s*where(.+)$//io;   #20000108 REP. PREV. LINE 2FIX BUG IF LAST COLUMN CONTAINS SINGLE QUOTES.
		$column = $self->{column};
		$objfilter ||= 'objectclass=*';
		$objfilter = "($objfilter)"  unless ($objfilter =~ /^\(/o);
		if ($filter)
		{
#print STDERR "--update: BEF parse_expn: filter=$filter=\n";
			$filter = $self->parse_expression ($filter);
#print STDERR "--update: AFT parse_expn: filter=$filter= objfilter=$objfilter=\n";
			$filter = '('.$filter.')'  unless ($filter =~ /^\(/o);
			$filter = "(&$objfilter$filter)";
		}
		else
		{
			$filter = "$objfilter";
		}
	$filter =~ s/\x03/\\\'/go;    #UNPROTECT '', AND \'.  #NEXT 2 ADDED 20091101:
	$filter =~ s/\x02/\\\\/go;    #UNPROTECT "\\".
#		$alwaysinsert .= ',' . $base;   #CHGD TO NEXT 200780719 PER REQUEST.
		$alwaysinsert .= ',' . $base  if ($self->{ldap_appendbase2ins});
		$alwaysinsert =~ s/\\\\/\x02/go;   #PROTECT "\\"
		$alwaysinsert =~ s/\\\,/\x03/go;   #PROTECT "\,"
		$alwaysinsert =~ s/\\\=/\x04/go;   #PROTECT "\="
		my ($i1, $col, $vals, $j, @l);
		for ($i=0;$i<=$#expns;$i++)  #EXTRACT FIELD NAMES AND 
	                             #VALUES FROM EACH EXPRESSION.
		{
			$expns[$i] =~ s/\x03/\\\'/go;    #UNPROTECT '', AND \'.
			$expns[$i] =~ s/\x02/\\\\/go;    #UNPROTECT "\\".
			$expns[$i] =~ s!\s*($column)\s*=\s*(.+)$!
					my ($var) = $1;
					my ($val) = $2;
		
					$val = &pscolfn($self,$val)  if ($val =~ "$column\.$psuedocols");
					$var =~ tr/A-Z/a-z/;
					$val =~ s|%\0(\d+): |pack("C",$1)|ge;
					$val =~ s/^\'//o;             #NEXT 2 ADDED 20010530 TO STRIP EXCESS QUOTES.
					$val =~ s/([^\\\'])\'$/$1/;
					$val =~ s/\'$//o;
					$all_columns->{$var} = $val;
					@_ = split(/\,\s*/o, $alwaysinsert);
					while (@_)
					{
						($col, $vals) = split(/\=/o, shift);
						next  unless ($col eq $var);
						$vals =~ s/\x04/\\\=/go;       #UNPROTECT "\="
						$vals =~ s/\x03/\\\,/go;       #UNPROTECT "\,"
						$vals =~ s/\x02/\\\\/go;       #UNPROTECT "\\"
						@l = split(/\Q$self->{ldap_inseparator}\E/, $vals);
VALUE:							for (my $j=0;$j<=$#l;$j++)
						{
							next  if ($all_columns->{$var} =~ /\b$l[$j]\b/);
							$all_columns->{$var} .= $self->{ldap_inseparator} 
									if ($all_columns->{$var});
							$all_columns->{$var} .= $l[$j];
						}
					}
					$all_columns->{$var} =~ s/\x02/\\\\/go;
#					$all_columns->{$var} =~ s/\x03/\'/go;   #20091030: REPL. W.NEXT LINE TO KEEP ESCAPE SLASH "\" - RETAIN ORIG. COMMENT:
					$all_columns->{$var} =~ s/\x03/\\\'/go;   #20000108 REPL. PREV. LINE - NO NEED TO DOUBLE QUOTES (WE ESCAPE THEM) - THIS AIN'T ORACLE.
			!e;
		}

		delete $all_columns->{dn};   #DO NOT ALLOW DN TO BE CHANGED DIRECTLY!
#foreach my $xxx (sort keys %{$all_columns}) { print STDERR "---data($xxx)=".$all_columns->{$xxx}."=\n"; };
		my ($data);
		my (@searchops) = (
				'base' => $base,
				'filter' => $filter,
				);
		foreach my $i (qw(ldap_sizelimit ldap_timelimit deref typesonly 
		callback))
		{
			$j = $i;
			$j =~ s/^ldap_//o;
			push (@searchops, ($j, $self->{$i}))  if ($self->{$i});
		}
		push (@searchops, ('scope', ($self->{ldap_scope} || 'one')));
#print STDERR "-update: filter=$filter= searchops=".join('|',@searchops)."=\n";
		$data = $ldap->search(@searchops) 
				or return($self->ldap_error($@,"Search failed to return object: filter=$filter (".$data->error().")"));
#print STDERR "-update:  got thru search; data=$data=\n";
		my (@varlist) = ();
		$dbh = $csr->FETCH('ldap_dbh');
		my ($autocommit) = $dbh->FETCH('AutoCommit');
		my ($commitqueue) = $dbh->FETCH('ldap_commitqueue')  unless ($autocommit);
		my (@dnattbs) = split(/\,/o, $dnattbs);
		my ($changedn);
#print STDERR "-update:  going into loop!\n";
		while (my $entry = $data->shift_entry())
		{
#print STDERR "----update: in loop entry=$entry=\n";
			$dn = $entry->dn();
			$dn =~ s/\\/\x02/go;     #PROTECT "\";
			$dn =~ s/\\\,/\x03/go;   #PROTECT "\,";
			$changedn = 0;
I:			foreach my $i (@dnattbs)
			{
				foreach my $j (keys %$all_columns)
				{
					if ($i eq $j)
					{
						$dn =~ s/(\b$i\=)([^\,]+)/$1$all_columns->{$j}/;
						$changedn = 1;
						next I;
					}
				}
			}
			$dn =~ s/(?:\,\s*)$base$//;
			$dn =~ s/\x03/\\\,/go;     #UNPROTECT "\,";
			$dn =~ s/\x02/\\/go;     #UNPROTECT "\";
			foreach my $i (keys %$all_columns)
			{
				$all_columns->{$i} =~ s/(?:\\|\')\'/\'/go;   #1UNESCAPE QUOTES IN VALUES.
				@_ = split(/\Q$self->{ldap_inseparator}\E/, $all_columns->{$i});
				if (!@_)
				{
					push (@attblist, ($i, ''));
				}
				elsif (@_ == 1)
				{
					push (@attblist, ($i, shift));
				}
				else
				{
					push (@attblist, ($i, [@_]));
				}
			}
			$r1 = $entry->replace(@attblist);
#print STDERR "-update: r1=$r1= attblist=".join('|',@attblist)."=\n";
			if ($r1 > 0)
			{
				if ($autocommit)
				{
					$r2 = $entry->update($ldap);   #COMMIT!!!
					if ($r2->is_error)
					{
						$errdetails = $r2->code . ': ' . $r2->error;
						return (-523);
					}
					if ($changedn)
					{
						$r2 = $ldap->moddn($entry, newrdn => $dn);
						if ($r2->is_error)
						{
							$errdetails = "Could not change dn - " 
									. $r2->code . ': ' . $r2->error . '!';
							return (-523);
						}
					}
				}
				else
				{
					push (@{$commitqueue}, (\$entry, \$ldap));
					push (@{$commitqueue}, "dn=$dn")  if ($changedn);
				}
				++$status;
			}
			else
			{
			#return($self->ldap_error($@,"Search failed to return object: filter=$filter (".$data->error().")"));
				$errdetails = $data->code . ': ' . $data->error;
				return (-523);
			}
		}
		return ($status);
	}
	else
	{
		return (-504);
	}
}

sub delete 
{
	my ($self, $csr, $query) = @_;
	my ($path, $table, $filter, $wherepart);
	my $status = 0;

	$path = $self->{path};
	if ($query =~ /^delete\s+from\s+($path)(?:\s+where\s+(.+))?$/io)
	{
		$table     = $1;
		$wherepart = $2;
		$table =~ tr/A-Z/a-z/  unless ($self->{CaseTableNames});  #JWT:TABLE-NAMES ARE NOW CASE-INSENSITIVE!
		$self->{file} = $table;

		my ($dbh) = $csr->FETCH('ldap_dbh');
		my ($ldap) = $csr->FETCH('ldap_ldap');
		my ($tablehash) = $dbh->FETCH('ldap_tables');
		return (-524)  unless ($tablehash->{$table});
		my ($base, $objfilter, $dnattbs, $allattbs, $alwaysinsert) = split(/\:/,$tablehash->{$table});
		$objfilter ||= 'objectclass=*';
		$objfilter = "($objfilter)"  unless ($objfilter =~ /^\(/o);
		if ($wherepart =~ /\S/o)
		{
			$filter = $self->parse_expression ($wherepart);
			$filter = '('.$filter.')'  unless ($filter =~ /^\(/o);
			$filter = "(&$objfilter$filter)";
		}
		else
		{
			$filter = "$objfilter";
		}
		$filter = '('.$filter.')'  unless ($filter =~ /^\(/o);

		$data = $ldap->search(
				base   => $base,
				filter => $filter,
		) or return ($self->ldap_error($@,"Search failed to return object: filter=$filter (".$data->error().")"));
		my ($j) = 0;
		my (@varlist) = ();
		$dbh = $csr->FETCH('ldap_dbh');
		my ($autocommit) = $dbh->FETCH('AutoCommit');
		my ($commitqueue) = $dbh->FETCH('ldap_commitqueue')  unless ($autocommit);
		while (my $entry = $data->shift_entry())
		{
			$dn = $entry->dn();
			next  unless ($dn =~ /$base$/i);   #CASE-INSENSITIVITY ADDED NEXT 2: 20050416 PER PATCH BY jmorano
			$r1 = $entry->delete();
			if ($autocommit)
			{
				$r2 = $entry->update($ldap);   #COMMIT!!!
				if ($r2->is_error)
				{
					$errdetails = $r2->code . ': ' . $r2->error;
					return (-523);
				}
			}
			else
			{
				push (@{$commitqueue}, (\$entry, \$ldap));
			}
			++$status;
		}

		return $status;
	}
	else
	{
		return (-505);
	}
}

sub primary_key_info
{
	my ($self, $csr, $query) = @_;
	my $table = $query;
	$table =~ s/^.*\s+(\w+)$/$1/;
	$table =~ tr/A-Z/a-z/  unless ($self->{CaseTableNames});  #JWT:TABLE-NAMES ARE NOW CASE-INSENSITIVE!
	$self->{file} = $table;
	my ($dbh) = $csr->FETCH('ldap_dbh');
	my $tablehash = $dbh->FETCH('ldap_tables');
	return -524  unless ($tablehash->{$table});

	undef %{ $self->{types} };
	undef %{ $self->{lengths} };
	$self->{use_fields} = 'CAT,SCHEMA,TABLE_NAME,PRIMARY_KEY';
	$self->{order} = [ 'CAT', 'SCHEMA', 'TABLE_NAME', 'PRIMARY_KEY' ];
	$self->{fields}->{CAT} = 1;
	$self->{fields}->{SCHEMA} = 1;
	$self->{fields}->{TABLE_NAME} = 1;
	$self->{fields}->{PRIMARY_KEY} = 1;
	undef @{ $self->{records} };
	my (@keyfields) = split(/\,\s*/o, $self->{key_fields});  #JWT: PREVENT DUP. KEYS.
	${$self->{types}}{CAT} = 'VARCHAR';
	${$self->{types}}{SCHEMA} = 'VARCHAR';
	${$self->{types}}{TABLE_NAME} = 'VARCHAR';
	${$self->{types}}{PRIMARY_KEY} = 'VARCHAR';
	${$self->{lengths}}{CAT} = 50;
	${$self->{lengths}}{SCHEMA} = 50;
	${$self->{lengths}}{TABLE_NAME} = 50;
	${$self->{lengths}}{PRIMARY_KEY} = 50;
	${$self->{defaults}}{CAT} = undef;
	${$self->{defaults}}{SCHEMA} = undef;
	${$self->{defaults}}{TABLE_NAME} = undef;
	${$self->{defaults}}{PRIMARY_KEY} = undef;
	${$self->{scales}}{PRIMARY_KEY} = 50;
	${$self->{scales}}{PRIMARY_KEY} = 50;
	${$self->{scales}}{PRIMARY_KEY} = 50;
	${$self->{scales}}{PRIMARY_KEY} = 50;
	my $results;
	my $keycnt = scalar(@keyfields);
	while (@keyfields)
	{
		push (@{$results}, [0, 0, $table, shift(@keyfields)]);
	}
	unshift (@$results, $keycnt);
	return $results;
}

sub alter    #SQL COMMAND NOT IMPLEMENTED.
{
	$@ = 'SQL "alter" command is not (yet) implemented!';
	return 0;
}

sub insert
{
	#my ($self, $query) = @_;
	my ($self, $csr, $query) = @_;
	my ($i, $path, $table, $columns, $values, $status);

	$path = $self->{path};
	if ($query =~ /^insert\s+into\s+    # Keyword
			($path)\s*                  # Table
			(?:\((.+?)\)\s*)?           # Keys
	values\s*                           # 'values'
			\((.+)\)$/ixo)
	{   #JWT: MAKE COLUMN LIST OPTIONAL!

		($table, $columns, $values) = ($1, $2, $3);
		my ($dbh) = $csr->FETCH('ldap_dbh');
		my ($tablehash) = $dbh->FETCH('ldap_tables');
		$table =~ tr/A-Z/a-z/  unless ($self->{CaseTableNames});  #JWT:TABLE-NAMES ARE NOW CASE-INSENSITIVE!
		$self->{file} = $table;
		return (-524)  unless ($tablehash->{$table});
		my ($base, $objfilter, $dnattbs, $allattbs, $alwaysinsert) = split(/\:/,$tablehash->{$table});
		$columns =~ s/\s//go;
		$columns ||= $allattbs;
		$columns = join(',', @{ $self->{order} })  unless ($columns =~ /\S/o);  #JWT

		unless ($columns =~ /\S/o)
		{
			return ($self->display_error (-509));
		}
		$values =~ s/\\\\/\x02/go;         #PROTECT "\\"
		$values =~ s/\\\'/\x03/go;    #PROTECT '', AND \'.

		$values =~ s/\'(.*?)\'/
				my ($j)=$1; 
				$j=~s|,|\x04|go;         #PROTECT "," IN QUOTES.
				"'$j'"
		/eg;
		@values = split(/,/o, $values);
		$values = '';
		for $i (0..$#values)
		{
			$values[$i] =~ s/^\s+//o;      #STRIP LEADING & TRAILING SPACES.
			$values[$i] =~ s/\s+$//o;
			$values[$i] =~ s/\x03/\'/go;   #RESTORE PROTECTED SINGLE QUOTES HERE.
			$values[$i] =~ s/\x02/\\/go;   #RESTORE PROTECTED SLATS HERE.
			$values[$i] =~ s/\x04/,/go;    #RESTORE PROTECTED COMMAS HERE.
		}
		chop($values);

		$status = $self->insert_data ($csr, $base, $dnattbs, $alwaysinsert, $columns, @values);

		return $status;
	}
	else
	{
		return (-508);
	}
}

sub insert_data
{
	my ($self, $csr, $base, $dnattbs, $alwaysinsert, $column_string, @values) = @_;
	my (@columns, @attblist, $loop, $column, $j, $k);
	$column_string =~ tr/A-Z/a-z/;
	$dnattbs =~ tr/A-Z/a-z/;
	@columns = split (/\,/o, $column_string);

	if ($#columns = $#values)
	{
		my $dn = '';
		my @t = split(/,/o, $dnattbs);
		while (@t)
		{
			$j = shift (@t);
J1:			for (my $i=0;$i<=$#columns;$i++)
			{
				if ($columns[$i] eq $j)
				{
					$dn .= $columns[$i] . '=';
					if ($values[$i] =~ /\Q$self->{ldap_inseparator}\E/)
					{
						$dn .= (split(/\Q$self->{ldap_inseparator}\E/,$values[$i]))[0];
					}
					else
					{
						$dn .= $values[$i];
					}
					$dn .= ', ';
					last J1;
				}
			}
		}
		$dn =~ s/\'//go;
		$dn .= $base;
		for (my $i=0;$i<=$#columns;$i++)
		{
			@l = split(/\Q$self->{ldap_inseparator}\E/,$values[$i]);
			while (@l)
			{
				$j = shift(@l);
				$j =~ s/^\'//o;
				$j =~ s/([^\\\'])\'$/$1/;
				unless (!length($j) || $j eq "'" || $columns[$i] eq 'dn')
				{
					$j = "'"  if ($j eq "''");
					push (@attblist, $columns[$i]);
					push (@attblist, $j);
				}
			}
		}
#		$alwaysinsert .= ',' . $base;   #CHGD TO NEXT 200780719 PER REQUEST.
		$alwaysinsert .= ',' . $base  if ($self->{ldap_appendbase2ins});
		my ($i1, $found, $col, $vals, $j);
		@_ = split(/\,\s*/o, $alwaysinsert);
		while (@_)
		{
			($col, $vals) = split(/\=/o, shift);
			@l = split(/\Q$self->{ldap_inseparator}\E/, $vals);
VALUE:				for (my $i=0;$i<=$#l;$i++)
			{
				for ($j=0;$j<=$#attblist;$j+=2)
				{
					if ($attblist[$j] eq $col)
					{
						next VALUE  if ($attblist[$j+1] eq $l[$i]);
					}
				}
				push (@attblist, $col);
				push (@attblist, $l[$i]);
			}
		}
		my ($ldap) = $csr->FETCH('ldap_ldap');

		my $entry = Net::LDAP::Entry->new;
		$entry->dn($dn);

		my $result = $entry->add(@attblist);
		$_ = $entry->dn();

		my ($dbh) = $csr->FETCH('ldap_dbh');
		my ($autocommit) = $dbh->FETCH('AutoCommit');
		if ($autocommit)
		{
			$r2 = $entry->update($ldap);   #COMMIT!!!
			if ($r2->is_error)
			{
				$errdetails = $r2->code . ': ' . $r2->error;
				return (-523);
			}
		}
		else
		{
			my ($commitqueue) = $dbh->FETCH('ldap_commitqueue');
			push (@{$commitqueue}, (\$entry, \$ldap));
		}

		return (1);
	}
	else
	{
		$errdetails = "$#columns != $#values";   #20000114
		return (-509);
	}
}						    

sub create    #SQL COMMAND NOT IMPLEMENTED.
{
	$@ = 'SQL "create" command is not (yet) implemented!';
	return 0;
}

sub drop    #SQL COMMAND NOT IMPLEMENTED.
{
	$@ = 'SQL "drop" command is not (yet) implemented!';
	return 0;
}

sub pscolfn
{
	my ($self,$id) = @_;
	return $id  unless ($id =~ /CURVAL|NEXTVAL|ROWNUM/);
	my ($value) = '';
	my ($seq_file,$col) = split(/\./o, $id);
	$seq_file = $self->get_path_info($seq_file) . '.seq';

	$seq_file =~ tr/A-Z/a-z/  unless ($self->{CaseTableNames});  #JWT:TABLE-NAMES ARE NOW CASE-INSENSITIVE!
	open (FILE, "<$seq_file") || return (-511);
	$x = <FILE>;
	#chomp($x);
	$x =~ s/\s+$//o;   #20000113
	($incval, $startval) = split(/\,/o, $x);
	close (FILE);
	if ($id =~ /NEXTVAL/o)
	{
		open (FILE, ">$seq_file") || return (-511);
		$incval += ($startval || 1);
		print FILE "$incval,$startval\n";
		close (FILE);
	}
	$value = $incval;
	return $value;
}

sub SYSTIME
{
	return time;
}

sub NUM
{
	return shift;
}

sub NULL
{
	return '';
}

1;
