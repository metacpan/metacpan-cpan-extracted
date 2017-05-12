use Exporter;
use strict;

# I've rewritten this from scratch, but I still think this is a bit
# dirty.  As it is now, I'm mixing perl, HTML, HTML::Template-code
# ... and even the kludgy parameters to DBIx::Recordset and
# DBIx::CGITables.  Sort of ironically as that was what I was trying
# to avoid in the first place.  I suggest either some kind of template
# system for making the templates ... or maybe this can be done in an
# object-oriented way.

# I've splitted this one in two parts - first one part for reading DD
# code and/or stored metadata from a file, then a part for writing
# templates and the parameter file.

# It's going to make two templates, one for viewing/updating a single
# item/object/database row (a pre-filled form) alternatively an empty
# form (for searching), and one for viewing a listing.  In addition
# it's going to create a parameter file for DBIx::CGITables /
# DBIx::Recordset.

# The %metadata hash contains all metadata - with redundancy for quick
# & easy lookups.  The format of %metadata is:

# All parameters to be written directly to the parameter file:
# $metadata{'!params'}=[ "$key=$value", ...]
# $metadata{$database}->{'!params'}
# $metadata{$database}->{$tablename}->{'!params'}

# Column metadata:
# $metadata{$database}->{$table}->{$column}->{$key}=$value;

# Where $key=$value can be:

# input=textarea|textbox|select[ db.t.name]|hidden
# output
# list_output
# input_max=$size
# input_size=$size (defaults to max or 4 for numeric or 10 for date 
#                   or 19 for timestamp or 30 for textbox)
# input_html_options=$opts
# references="$database.$table.$column"
# referenced_by="$database.$table.$column"
# title=1
# primkey=1
# substring_searchable=1
# startstring_searchable=1

# Table metadata (mostly redundant)
# $metadata{$database}->{$table}->{$key}=$value;

# Where $key=$value can be:

# !order=[$key1, $key2, ...]
# !foreign_keys={$foreign_key=>"$referenced_db.$referenced_table.$referenced_column", ...}
# !referenced_keys={$referenced_key=>"$referencing_db.$referencing_table.$foreign_key", ...}
# !title=$title_key
# !primkey=$primary_key

use vars qw |
    @EXPORT @ISA $output_dir $param_dir $new_search_button $head
    $form_head $list_head $tail $form_tail $list_tail $usertable
    %metadata|;


@ISA=qw(Exporter);
@EXPORT=qw(make);

# The template files will be put into $output_dir, defaulting to ".".
$output_dir=".";

# The parameter file will be put into $param_dir, defaulting to ".".
$param_dir=".";

# The table where users can be found
$usertable="defaultdb.personell";

# The $new_search_button is how to represent a "get a fresh search form-button".
$new_search_button='
<form method="post"> <!-- Better to use get when debugging -->
<TMPL_IF NAME="!UserName">
<input type="hidden" name="!UserName" value="<TMPL_VAR NAME="!UserName">">
</TMPL_IF>
<TMPL_IF NAME="!Password">
<input type="hidden" name="!Password" value="<TMPL_VAR NAME="!Password">">
</TMPL_IF>
<input type="hidden" name="!SearchForm" value="1">
<input type="submit" value="Blank form">
</form>
';

# Head is how the head of the templates should look.  Eventually there
# should also be a title in the header, but I haven't figured out any
# smart way to do it yet.

$head='
<head>
<title><TMPL_VAR name="!Table"></title>
</head>
<body>
<h1><TMPL_VAR name="!Table"></h1>'. $new_search_button;

# Oposite of head:
$tail='</body></html>
';

$list_head="$head
           <table>";
$list_tail="</TMPL_LOOP></table>
              $tail";

# Form_head is the start of the form that is used when
# viewing/updating/adding one object/row/item.
$form_head='
<form method="post">
<TMPL_LOOP default>
';



# Form_tail is the tail of the form

$form_tail='
</TMPL_LOOP>
<TMPL_IF name="?count">
<input type=submit name="=update" value="Update"><br>
<TMPL_ELSE>
<input type=submit name="=search" value="Search"><br>
<input type=submit name="=add=" value="add"><br>
</TMPL_IF>
Login: <input name="!UserName" value="<TMPL_VAR name="!UserName">"><br>
Password: <input name="password" name="!Password" value="<TMPL_VAR name="!Password">"><br>
';



sub make {
    fetch_params(shift || $ENV{'DBI_DSN'} || undef);
    write_templates();
#    store_params();
}



sub fetch_params {
    warn "This is under development.  Foreign keys and a lot of other features are not supported yet.";

    # I'll use those variables when playing around with the sqldd:

    my $dsn=shift;
    
    push @{$metadata{'!params'}}, "!DataSource=$dsn"
	if (defined $dsn);
    

    my ($tablename, $schema_name, $in_table);

    # Reading the input file

    while (<>) {

	# Chop away doublequotes - we probably don't need them,
	# and mysql doesn't have them anyway:
	s/\"//g;

	# Leading and trailing whitespace is hardly relevant
	s/^\s*//;
	s/\s*$//;

	if (/^(\#|--)(\s*)END$/) {
	    # End of sql dd
	    last;
	}

	elsif (/^\s*\#(.*)Database: (\w+)/) {
	    # Mysql hides the schema name in the comments
	    $schema_name=$2;
	} 

	elsif (/^(\s*(\);(\s*))?)$/ || /^(-- |\#|\;)/) {
	    # Probably nothing interessting.
	}

	elsif (/^use (\w+)\;$/) {
	    $schema_name=$1;
	}

	elsif (/^create(\s*)table/i) {
	    # New table
	    $_=$';
	    /^(\s*)(\w+)(\.(\w+))?/ || die "syntax error in inputs?" ;
	    $tablename=$4 ? $4 : $2;
	    $schema_name=$4 ? $2 : $schema_name;
	}

	elsif (/^(\w+)(\s*)(int|varchar|blob|char|date|timestamp|time)/i) {
	    # (probably) a normal variable
	    my ($key, $type)=($1, $3);
	    my $length=($type =~ /^int/i) ? 4 : ($type =~ /timestamp/i) ? 19 : undef;
	    $metadata{$schema_name}->{$tablename}->{$key}->{input_size}=$length;
	    $metadata{$schema_name}->{$tablename}->{$1}->{'list_output'}=1;
	    $metadata{$schema_name}->{$tablename}->{$key}->{input}=
		($type =~ /(LONG(\s*)VARCHAR)|(blob)/i) ? 'textarea' : 'textbox';
	}

	elsif (/^PRIMARY KEY \((\w+)\)/i) {
	    $metadata{$schema_name}->{$tablename}->{$1}->{'!primkey'}=1;
	    $metadata{$schema_name}->{$tablename}->{$1}->{'output'}=1;
	    $metadata{$schema_name}->{$tablename}->{$1}->{'input'}='hidden';
	    $metadata{$schema_name}->{$tablename}->{'!primkey'}=$1;
	    push @{$metadata{$schema_name}->{$tablename}->{'!params'}}, "!PrimKey=$1";
	}

	else {
	    warn "Unknown input";
	}
    }

} # end of sub fetch_params
















sub write_templates {

    my $multiadd_feature=0; # Stubbed

    for my $schema_name (keys %metadata) {
	next if $schema_name =~ /^\!/;

	for my $tablename (keys %{$metadata{$schema_name}}) {
	    next if $tablename =~ /^\!/;

	    my $list_row="<TMPL_LOOP default><tr><td>";
	    
	    # Open the files:
	    open (PARAMF, ">$param_dir/$schema_name.$tablename.param.dbt") || die;
	    open (FOUNDMORE, ">$output_dir/$schema_name.$tablename.found_more.dbt")|| die;
	    open (SINGLE, ">$output_dir/$schema_name.$tablename.dbt")|| die;
	    open (MULTIADD, ">$output_dir/$schema_name.$tablename.multiadd.dbt") || die
		if ($multiadd_feature);
		
		# Print headers:
		print PARAMF qq|\
!Table=$tablename
%? \$max=100
!IgnoreEmpty=2
!ContentType=text/html
%RGV PreserveCase=1
%T die_on_bad_params=0
|;
	    print PARAMF join ("\n", @{$metadata{'!params'}}, "\n")
		if exists $metadata{'!params'};
	    print PARAMF join ("\n", @{$metadata{$schema_name}->{'!params'}}, "\n")
		if exists $metadata{$schema_name}->{'!params'};
	    print PARAMF join ("\n", 
			       @{$metadata{$schema_name}->{$tablename}->{'!params'}}, "\n")
		if exists $metadata{$schema_name}->{$tablename}->{'!params'};

	    print SINGLE $head;

	    # For MultiAdd:
#	    print SINGLE "<TMPL_IF AddSelectCount>You added 
#                  <TMPL_VAR AddSelectcount> combinations..</TMPL_IF>";

	    print SINGLE $form_head;
	    
	    print FOUNDMORE $list_head;
	    if (my $primkey=$metadata{$schema_name}->{$tablename}->{'!primkey'}) {
		$list_row.=qq|<a href="$schema_name.$tablename.dbt?$primkey=<TMPL_VAR $primkey>"><TMPL_VAR $primkey></a>|;
		print FOUNDMORE "<th>$primkey</th>";
	    }
		
#	    # the multiadd-feature is not supported yet.  This is from my earlier system.
#	    print MULTIADD $head, $form_head, q|
#		    <input type="hidden" name="skip" value="1">
#			<input type="hidden" name="commit" value="addselect">
#			    |
#				if ($multiadd_feature);


	    for my $column (keys %{$metadata{$schema_name}->{$tablename}}) {
		next if $column =~ /^\!/;

		my $inputopts="";
	    
		my $input =$metadata{$schema_name}->{$tablename}->{$column}->{input};
		my $output=$metadata{$schema_name}->{$tablename}->{$column}->{output};
		my $list_output=$metadata{$schema_name}->{$tablename}->{$column}->{list_output};

		if ($input eq 'textbox') {
		    # input_size and input_max
		    if (my $length=$metadata{$schema_name}->{$tablename}->{$column}->{input_size}) {
			$inputopts.="size=\"$length\"";
			if (my $max=$metadata{$schema_name}->{$tablename}->{$column}->{input_max}) {
			    $inputopts .= " maxlength=\"$length\"";
			}
		    }
		    print SINGLE "$column: <input name=\"$column\" value=\"<TMPL_VAR $column>\" $inputopts><br>\n";
		}
	    
		elsif ($input eq 'textarea') {
		    print SINGLE "$column:<br><textarea name=\"$column\" rows=10 cols=60 wrap=soft><TMPL_VAR $column></textarea><br>\n";
		}

		elsif ($input eq 'hidden') {
		    print SINGLE "<TMPL_IF $column><input type=\"hidden\" name=\"$column\" value=\"<TMPL_VAR $column>\"></TMPL_IF>";
		}

		# OnUpdate - Postponed, not supported by Recordset as for now
		if (0 && $column =~ /^(LAST)?(UPDATED|CREATED)(TIMESTAMP?)$/i) {
		    print PARAMF "(...)\\$column=now()\n";
		    print SINGLE "\\$column: (...)<br>\n";
		}
		
		# same with this one
		elsif (0 && $column =~ /(CREATED|ADDED|UPDATED)BY/i) {
		    
		    my $au=($1 =~ /^ADDED$/i) ? 'add' : 'update';
		    
		    print PARAMF 
			"_$au\_$column\_Function_Substitute=(select personellid from personell where login='\$user')\n";
		    next;
		}
	    
		if ($list_output) {
		    print FOUNDMORE "<th>$column</th>\n";
		    $list_row.="<td><TMPL_VAR $column></td>";
		}

		if ($output) {
		    print SINGLE "<TMPL_IF $column>$column: <TMPL_VAR $column><br></TMPL_IF>\n";
		}
		
	    }

	    # Let's finish and close those templates
	    print FOUNDMORE "\n",$list_row,"</tr>\n", $list_tail, $tail;
	    close (FOUNDMORE);
	    print SINGLE $form_tail;
	    # Handle references: stub!
	    print SINGLE $tail;
	    print MULTIADD qq|
		</table><INPUT type="submit" value="MultiAdd!"></form>
		    |, $tail if ($multiadd_feature);
	    close (SINGLE);
	    close (PARAMF);
	    close (MULTIADD)
		if ($multiadd_feature);
	}
    }
} # End of the write_templates sub


__END__


=head1 NAME

DBIx::CGITables::MakeTemplates - creates templates for CGITables.

=head1 SYNOPSIS

  cd /path/to/webserver/document_root/wherever/the/templates/should/be

  mysqldump -d mydatabase > /tmp/schema.dd
  echo '-- END' >> /tmp/schema.dd
  vi /tmp/schema.dd
  perl -MDBIx::CGITables::MakeTemplates -e 'make "dbi:mysql:test:localhost"'< /tmp/schema.dd

=head1 DESCRIPTION

This is under construction, there might be code stubs, some of the
announced features might be missing, and if you're more unlucky it
might not work at all.  Feedback will probably speed up my work on
this.

This module takes its input from a set of data definitions (SQL
`create table' statements), and generates templates and parameter
files for the tables.  The data definition file should be edited
slightly before running MakeTemplates.

The most important thing about the hand-editing is to deal with the
foreign keys.  Mysql doesn't have them at all, so they will eventually
have to be manually added.  If there is a "Foreign key
(foreign_id)..."-line, then the attribute line (typically something
like "foreign_id integer") should be removed - eventually the other
way.

Attributes might be added to describe how to handle attributes and
foreign keys - unfortunately I don't have time documenting them at the
moment.

Eventually, the module should work without any editing of the DD at
all, just reading the eventual extra configuration information from an
extra file.

The module will produce three files; the form template
($dbname.$tablename.dbt), the list template
($dbname.$tablename.found_more.dbt) and the parameter file
($dbname.$tablename.param.dbt).

About foreign keys (not implemented yet); 

Mysql doesn't have them - so if links are needed, the dd code needs
to be modified.  The dd code should be modified anyway.  In a create
table statement, the attribute should first be declared
(i.e. `user_id integer'), and later it should be declared that it's
a foreign key. One of those lines should be deleted - you will
probably want to remove the attribute declaration (the foreign key
will be respected), alternatively the foreign key declaration
(letting the foreign key be threated as just another attribute).


=head1 KNOWN BUGS

This is just some loose hacks.  This is under construction (maybe it would
be even better to start from scratch redoing it).  This is absolutely not
tested very well.  It is not a SQL parser, and it's only tested for the
output from mysql and solid.  It's linebreak sensitive, so it might not be
compatible with other DBMSs.  Foreign keys are not supported yet.  This
documentation sucks.  The code sucks.  Well.

=head1 AUTHOR

Tobias Brox <tobiasb@funcom.com>
