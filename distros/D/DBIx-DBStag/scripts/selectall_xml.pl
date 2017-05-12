#!/usr/local/bin/perl -w

# POD docs at end of file

use strict;

use Carp;
use DBIx::DBStag;
use Data::Dumper;
use Getopt::Long;

my $debug;
my $help;
my $db;
my $nesting;
my $show;
my $file;
my $user;
my $pass;
my $template_name;
my $where;
my $select;
my $rows;
my $writer;
my $verbose;
my @order;
my $color;
my $out;
my $sgml;
my $pre_sql;
my $aliaspolicy;
my $metadata;
my @matrixcols;
my @matrixcells;

# cmd line interpreter gets rid of quotes; need to use backspace
my @ARGV2 = ();
while (my $arg = shift @ARGV) {
    while (substr($arg,-1) eq '\\' && @ARGV) {
	my $next = shift @ARGV;
	substr($arg,-1,1," $next");
    }
    push(@ARGV2,$arg);
}
@ARGV = @ARGV2;
GetOptions(
           "help|h"=>\$help,
	   "rows"=>\$rows,
           "show"=>\$show,
	   "sgml"=>\$sgml,
	   "nesting|n=s"=>\$nesting,
	   "file|f=s"=>\$file,
	   "db|d=s"=>\$db,
	   "user|u=s"=>\$user,
	   "pass|p=s"=>\$pass,
	   "template|t=s"=>\$template_name,
	   "where|wh=s"=>\$where,
	   "matrixcol|mcol=s@"=>\@matrixcols,
	   "matrixcell|mcell=s@"=>\@matrixcells,
	   "writer|w=s"=>\$writer,
	   "select|s=s"=>\$select,
	   "order=s@"=>\@order,
	   "verbose|v"=>\$verbose,
	   "aliaspolicy|alias=s"=>\$aliaspolicy,
           "colour|color"=>\$color,
	   "out|o=s"=>\$out,
	   "pre=s"=>\$pre_sql,
           "metadata"=>\$metadata,
	   "trace"=>\$ENV{DBSTAG_TRACE},
          );
@ARGV = map { if (/^\/(.*)/) {$template_name=$1;()} else {$_} } @ARGV;


if ($help && !$template_name && !$db) {
    system("perldoc $0");
    exit 0;
}

if ((@matrixcols && !@matrixcells) ||
    (!@matrixcols && @matrixcells)) {
    print STDERR "-matrixcol and -matrixcell must be set together!\n";
    exit 1;
}
if (@matrixcols) {
    $rows = 1;
}

my $H = Data::Stag->getformathandler($writer || $ENV{STAG_WRITER} || 'xml');
$H->use_color(1) if $color;
if ($sgml) {
    $rows = 1;
    $H = Data::Stag->getformathandler('xml');
}

my $sql;
if ($file) {
    open(F, $file) || die $file;
    $sql = join('', <F>);
    close(F);
}
elsif ($template_name) {
    # No SQL required if template provided
}
elsif ($help) {
    # deal with this later...
}
else {
    $sql = shift @ARGV;

    if ($sql eq '-') {
	print STDERR "Reading SQL from STDIN...\n";
	$sql = <STDIN>;
    }
#    if ($sql =~ /^\/(.*)/) {
#	# shorthand for a template
#	$template_name = $1;
#	$sql = '';
#    }
}

my $template;
if ($template_name) {
    $template =
      DBIx::DBStag->new->find_template($template_name);
}

if ($help) {
    if ($template)  {
	my $varnames = $template->get_varnames;
	my $desc = $template->desc;
	#	$desc =~ s/\s+/ /;
	if ($verbose) {
	    require "Term/ANSIColor.pm";

	    $template->show(\*STDOUT,
			    undef,
			    sub { Term::ANSIColor::color(@_)}
			   );
	}
	else {
	    $desc =~ s/\n */\n  /mg;
	    print "DESC:\n  $desc\n";
	}
	print "PARAMETERS:\n";
	foreach my $vn (@$varnames) {
	    print "  $vn\n";
	}
	my $nesting = $template->nesting;
	if ($nesting) {
	    print "QUERY RESULT STRUCTURE (NESTING):\n";
	    print $nesting->sxpr;
	}
    }
    else {
	# show templates
	my $dbh =
	  DBIx::DBStag->new;
	my $templates = $dbh->find_templates_by_dbname($db);
	foreach my $template (@$templates) {
	    if ($verbose) {
		require "Term/ANSIColor.pm";
		$template->show(\*STDOUT,
			    undef,
			    sub { Term::ANSIColor::color(@_)},
			       );
	    }
	    else {
		my $desc = $template->desc || '';
		$desc =~ s/\s*$//;
		
		printf "NAME: %s\nDESC: %s\n//\n",
		  $template->name, $desc;
	    }
	}
    }
    exit 0;
}

if (!$db) {
    die "you must specify a database name (logical name or dbi path) with -d";
}

# QUERY DB
my $dbh = 
  DBIx::DBStag->connect($db, $user, $pass);

$dbh->include_metadata($metadata);

if ($pre_sql) {
    $dbh->do($pre_sql);
}

my $xml;
my @sel_args = (-sql=>$sql, -nesting=>$nesting);
if ($template) {
    if ($where) {
	$template->set_clause(where => $where);
    }
    if ($select) {
	$template->set_clause(select => $select);
    }
    if (@order) {
	$template->set_clause(order => join(", ",@order));
    }

    my @args = ();
    my %argh = ();
    while (my $arg = shift @ARGV) {
#	print "ARG:$arg;;\n";
	if ($arg =~ /(.*)\@=(.*)/) {
            my ($k,$v) = ($1,$2);
            $v = [split(/\,/,$v)];
	    $argh{$k} = $v;
	}
	elsif ($arg =~ /(.*)=(.*)/) {
            my ($k,$v) = ($1,$2);
	    $argh{$k} = $v;
	}
	else {
	    push(@args, $arg);
	}
    }
    my $bind = \@args;
    if (%argh) {
	$bind = \%argh;
	if (@args) {
	    die("can't used mixed argument passing");
	}
    }
    @sel_args =
      (-template=>$template, -nesting=>$nesting, -bind=>$bind);
}
if ($aliaspolicy) {
    push(@sel_args, -aliaspolicy=>$aliaspolicy);
}
eval {
    if ($rows) {
        
        my $count = 0;
        my $prep_h = $dbh->prepare_stag(@sel_args);
        my $cols = $prep_h->{cols};
        my $sth = $prep_h->{sth};
        my $exec_args = $prep_h->{exec_args};
        my $rv = $sth->execute(@$exec_args);
        if (@matrixcols) {
            my @COL = ();
            my @CELL = ();
            for (my $i=0;$i<@$cols;$i++) {
                my $col = $cols->[$i];
                foreach (@matrixcols) {
                    if ($_ eq $col) {
                        $COL[$i]=1;
                    }
                }
                foreach (@matrixcells) {
                    if ($_ eq $col) {
                        $CELL[$i]=1;
                    }
                }
            }
            while (my $r = $sth->fetchrow_arrayref) {
                my @row = ();
                for (my $i=0;$i<@$cols;$i++) {
                    if ($COL[$i]) {
                    }
                    elsif ($COL[$i]) {
                    }
                    else {
                    }
                }                
            }
        }
        while (my $r = $sth->fetchrow_arrayref) {
            # TODO: html
            if ($sgml) {
                if (!$count) {
                    $H->start_event('table');
                    $H->event(title=>"Query Results");
                    $H->start_event('tgroup');
                    $H->event('@'=>[
                                    [cols=>scalar(@$r)]]);
                    $H->event(thead=>[
                                      [row=>[
                                             map {[entry=>$_]} @$cols]]]);
                    $H->start_event('tbody');
                }
                $H->event(row=>[map {[entry=>$_]} @$r]);
            } 
            else {
                # ASCII
                printf "%s\n", 
                  join("\t", map {esc_col_val($_)} @$r);
            }
            $count++;
        }
    }                            # end of ROWS mode
    else {
        # HIERARCHICAL
        my $fh;
        if ($out) {
            my $fh = FileHandle->new(">$out") || die "cannot write to $out";
            $H->fh($fh);
        }
        else {
            $H->fh(\*STDOUT);
        }
        my $stag = $dbh->selectall_stag(@sel_args);
        $stag->events($H);
        $fh->close if $fh;
    }
};
if ($@) {
    print "FAILED\n$@";
}

$dbh->disconnect;
if ($show) {
    my ($sql, @exec_args) = $dbh->last_sql_and_args;
    print "DBI SQL:\n$sql\n\nARGUMENT BINDINGS: @exec_args\n";
}
#print $xml;
exit 0;

sub esc_col_val {
    my $str = shift;
    return '\\NULL' unless defined $str;
    $str =~ s/\t/\\t/g;
    $str =~ s/\n/\\n/g;
    $str;
}

__END__

=head1 NAME 

selectall_xml.pl

=head1 SYNOPSIS

  selectall_xml.pl [-d <dbi>] [-f file of sql] [-nesting|n <nesting>] SQL

=head1 DESCRIPTION

This script will query a database using either SQL provided by the
script user, or using an SQL templates; the query results will be
turned into XML using the L<DBIx::DBStag> module. The nesting of the
XML can be controlled by the DBStag SQL extension "USE NESTING..."

=head2 EXAMPLES

  selectall_xml.pl -d "dbi:Pg:dbname=mydb;host=localhost"\
        "SELECT * FROM a NATURAL JOIN b"


=head2 TEMPLATES

A parameterized SQL template (canned query) can be used instead of
specifying the full SQL

For example:

  selectall_xml.pl -d genedb /genedb-gene gene_symbol=Adh

Or:

  selectall_xml.pl -d genedb /genedb-gene Adh 

Or:

  selectall_xml.pl -d genedb /genedb-gene gene_symbol@=Adh,dpp,bam,indy

A template is indicated by the syntactic shorthand of using a slash to
precede the template name; in this case the template is called
B<genedb-gene>. the -t option can also be used.

All the remaining arguments are passed in as SQL template
parameters. They can be passed in as either name=value pairs, or as a
simple list of arguments which get passed into the template in order

To use templates, you should have the environment variable
B<DBSTAG_TEMPLATE_DIRS> set. See B<DBIx::DBStag> for details.

=head2 LISTING AVAILABLE TEMPLATES FOR A DB

   selectall_xml.pl -d mydb -h

=head2 LISTING VARIABLES FOR A TEMPLATE

   selectall_xml.pl /genedb-gene -h

=head1 ENVIRONMENT VARIABLES

=over

=item DBSTAG_DBIMAP_FILE

A file containing configuration details for local databases

=item DBSTAG_TEMPLATE_DIRS

list of directories (seperated by B<:>s) to be searched when templates
are requested

=back

=head1 COMMAND LINE ARGUMENTS

=over

=item -h|help

shows this page if no other arguments are given

if a template is specified, gives template details

if a db is specified, lists templates for that db

use in conjunction with -v for full descriptions

=item -d|dbname DBNAME

this is either a full DBI locator string (eg
B<dbi:Pg:dbname=mydb;host=localhost>) or it can also be a shortened
"nickname", which is then looked up in the file pointed at by the
environment variable B<DBSTAG_DBIMAP_FILE>

=item -u|user USER

database user identity

=item -p|password PASS

database password

=item -f|file SQLFILE

this is a path to a file containing SQL that will be executed, as an
alternative to writing the SQL on the command line

=item -n|nesting NESTING-EXPRESSIONS

a bracketed expression indicating how to the resulting objects/XML
should be nested. See L<DBIx::DBStag> for details.

=item -t|template TEMPLATE-NAME

the name of a template; see above

=item -wh|where WHERE-CLAUSE

used to override the WHERE clause of the query; useful for combining
with templates

You can append to an existing where clause by using the prefix B<+>

=item -s|select SELECT-COLS

used to override the SELECT clause of the query; useful for combining
with templates

=item -rows

sometimes it is preferable to return the results as a table rather
than xml or a similar nested structure. specifying -rows will fetch a
table, one line per row, and columns seperated by tabs

=item -pre SQL

a piece of SQL is that is executed immediately before the main query; e.g.:

  -pre "SET search_path=myschema,public"

=item -o|out FILE

a file to output the results to

=item -w|writer WRITER

writer class; can be any perl class, or one of these

=over

=item xml [default]

=item sxpr

lisp S-Expressions

=item itext

indented text

=back

=item -color

shows results in color (sxpr and itext only)

=item -show

will show the parse of the SQL statement

=back


=cut

