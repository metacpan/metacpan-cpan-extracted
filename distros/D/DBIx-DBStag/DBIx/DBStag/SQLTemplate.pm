# $Id: SQLTemplate.pm,v 1.28 2007/03/05 09:12:49 cmungall Exp $
# -------------------------------------------------------
#
# Copyright (C) 2003 Chris Mungall <cjm@fruitfly.org>
#
# This module is free software.
# You may distribute this module under the same terms as perl itself

#---
# POD docs at end of file
#---

package DBIx::DBStag::SQLTemplate;

use strict;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS $DEBUG $AUTOLOAD);
use Carp;
use DBI;
use Data::Stag qw(:all);
use DBIx::DBStag;
use DBIx::DBStag::Constraint;
use Text::Balanced qw(extract_bracketed);
#use SQL::Statement;
use Parse::RecDescent;
$VERSION='0.12';

our @CLAUSE_ORDER = ('select',
		     'from',
		     'where',
		     'group',
		     'order',
		     'having');

sub DEBUG {
    $DBIx::DBStag::DEBUG = shift if @_;
    return $DBIx::DBStag::DEBUG;
}

sub trace {
    my ($priority, @msg) = @_;
    return unless $ENV{DBSTAG_TRACE};
    print STDERR "@msg\n";
}

sub dmp {
    use Data::Dumper;
    print Dumper shift;
}


sub new {
    my $proto = shift; 
    my $class = ref($proto) || $proto;

    my $self = {};
    bless $self, $class;
    $self->cached_sth({});
    $self;
}

sub name {
    my $self = shift;
    $self->{_name} = shift if @_;
    return $self->{_name};
}

sub fn {
    my $self = shift;
    $self->{_fn} = shift if @_;
    return $self->{_fn};
}


sub sth {
    my $self = shift;
    $self->{_sth} = shift if @_;
    return $self->{_sth};
}

sub cached_sth {
    my $self = shift;
    $self->{_cached_sth} = shift if @_;
    return $self->{_cached_sth};
}


sub sql_clauses {
    my $self = shift;
    $self->{_sql_clauses} = shift if @_;
    return $self->{_sql_clauses};
}

sub set_clause {
    my $self = shift;
    my $ct = lc(shift);
    my $v = shift;
    $v =~ s/^ *//;
    my $add = 0;
    if ($v =~ /\+(.*)/) {
	$v = $1;
	$add = 1;
    }
    if ($ct eq 'order' || $ct eq 'group') {
	$v = "BY $v" unless $add;
    }
    my $is_set = 0;
    my $clauses = $self->sql_clauses;
    
    my @corder = @CLAUSE_ORDER;
    my @nu_clauses = ();
    foreach my $clause (@$clauses) {
	my $n = lc($clause->{name});
	next unless $n;
	if ($n eq $ct) {
	    if ($add && $clause->{value}) {
#		$clause->{value} .= " and $v";
		$clause->{value} .= " $v";
	    }
	    else {
		$clause->{value} = $v;
	    }
	    $is_set = 1;
	}
      CORDER:
	while (@corder) {
	    my $next = $corder[0];
	    if (!$is_set && $next eq $ct) {
		$is_set = 1;
		push(@nu_clauses,
		     {name=>uc($ct),
		      value=>$v});
	    }
	    last CORDER if $next eq $n;
	    shift @corder;
	}
	push(@nu_clauses,$clause);
    }
    @$clauses = @nu_clauses;
    $self->throw("Cannot set $ct") unless $is_set;
    return;
}

sub properties {
    my $self = shift;
    $self->{_properties} = shift if @_;
    return $self->{_properties};
}

sub property_hash {
    my $self = shift;
    my $pl = $self->{_properties};
    my %h = ();
    foreach (@$pl) {
	push(@{$h{$_->{name}}},$_->{value});
    }
    return \%h;
}

sub schema {
    my $sl = shift->property_hash->{schema} || [];
    $sl->[0];
}

sub stag_props {
    my $self = shift;
    $self->{_stag_props} = shift if @_;
    return $self->{_stag_props};
}

sub desc {
    my $self = shift;
    my $P = $self->properties || [];
    my ($p) = grep {$_->{name} =~ /^desc/} @$P;
    return $p->{value} if $p;
}

sub nesting {
    my $self = shift;
    my $sql_clauses = $self->sql_clauses;
    my ($use) = grep {$_->{name} =~ /use/i} @$sql_clauses;
    my $nesting;
    if ($use) {
	my $v = $use->{value};
	$v =~ s/\s*nesting\s*//i;
	$nesting = Data::Stag->parsestr($v);
    }
    return $nesting;
}

sub get_example_input {
    my $self = shift;
    my $dbh = shift;
    my $cachefile = shift;
    my $refresh = shift;
    my %ei = ();
    if ($cachefile && -f $cachefile && !$refresh) {
	my $fh = FileHandle->new($cachefile) || $self->throw("cannot open $cachefile");
	while(<$fh>) {
	    chomp;
	    my ($n, @v) = split(/\t/, $_);
	    $ei{$n} = \@v;
	}
	$fh->close;
    }
    my $P = $self->properties || [];
    my @E = map {$_->{value}} grep {$_->{name} =~ /^example_input/} @$P;
    foreach my $e (@E) {
	if ($e =~ /(\S+)\s*=\>\s*(.*)/) {
	    my $n = $1;
	    my $v = $2;
	    my @parts = split(/,\s*/, $v);
	    $ei{$n} = [];
	    while (my $part = shift @parts) {
		if ($part =~ /select/i) {
		    my $sql = "$part @parts LIMIT 5";
		    my $examples = [];
		    if (!$dbh) {
			# no connection
			last;
		    }
		    eval {
			$examples =
			  $dbh->selectcol_arrayref($sql);
			push(@{$ei{$n}}, 
			     grep {length($_) < 32} @$examples);
		    };
		    if ($@) {
			$self->throw("Problem with template - invalid example_input: $e");
		    }
		    @parts = ();
		}
		else {
		    push(@{$ei{$n}}, $part);
		}
	    }
	}
    }
    if ($cachefile) {
	my $fh = FileHandle->new(">$cachefile") || 
	  $self->throw("cannot write to $cachefile");
	foreach my $n (keys %ei) {
	    print $fh join("\t", $n, @{$ei{$n}}), "\n";
	}
	$fh->close || $self->throw;
    }
    return \%ei;
}



# ---------------------------------



# given a template and a binding, this will
# create an SQL statement and a list of exec args
# - the exec args correspond to ?s in the SQL
#
# for example WHERE foo = &foo&
# called with binding foo=bar
#
# will become WHERE foo = ?
# and the exec args will be ('bar')
#
# if the template contains option blocks eg
#
# WHERE [foo = &foo&]
#
# then the part in square brackets will only be included if
# there is a binding for variable foo
#
# if multiple option blocks are included, they will be ANDed
#
#
# if this idiom appears
#
# WHERE foo => &foo&
#
# then the operator used will either be =, LIKE or IN
# depending on the value of the foo variable
#
# if the foo variable contains % it will be LIKE
# if the foo variable contains an ARRAY it will be IN
#
# (See DBI manpage for discussion of placeholders)
sub get_sql_and_args {
    my $self = shift;
    my $bind = shift || {};

    my $where_blocks = $self->split_where_clause;
    my $varnames = $self->get_varnames; # ORDERED list of variables in Q

    my %argh = ();
    my ($sql, @args);
    my $where;

    # binding can be a simple array of VARVALs
    if ($bind &&
	ref($bind) eq 'ARRAY') {

        # assume that the order of arguments specified is
        # the same order that appears in the query
        for (my $i=0; $i<@$bind; $i++) {
	    if (!$varnames->[$i]) {
		my $n=$i+1;
		my $c = @$varnames;
		$self->throw("Argument number $n ($bind->[$i]) has no place ".
			     "to bind; there are only $c variables in the ".
			     "template");
	    }
	    # relate ordering of exec args via ordering of variables in
	    # template; store in a hash
            $argh{$varnames->[$i]} = $bind->[$i];
        }
    }
    if ($bind &&
	ref($bind) eq 'HASH') {
	# binding is already specified as a hash - no need to convert
	%argh = %$bind;
	my %varnameh = map {$_=>1} @$varnames;
	my @bad =  grep {!$varnameh{$_}} keys %argh;
	if (@bad) {
	    $self->throw("param(s) not recognised: @bad\nValid params:\n".join("\n",map {"  $_"}@$varnames));
	}
    }
    if ($bind && ref($bind) eq "DBIx::DBStag::Constraint") {
        # COMPLEX BOOLEAN CONSTRAINTS - TODO
        my $constr;
        $constr = $bind;
        ($where, @args) = $self->_get_sql_where_and_args_from_constraints($constr);
    }
    else {
        # simple rules for substituting variables
        ($where, @args) = $self->_get_sql_where_and_args_from_hashmap(\%argh);
    }
    
    my $sql_clauses = $self->sql_clauses;
    $sql = join("\n",
                map {
                    if (lc($_->{name}) eq 'where') {
			if ($where) {
			    "WHERE $where";
			}
			else {
			    '';           # no WHERE clause
			}
                    }
                    else {
                        "$_->{name} $_->{value}";
                    }
                } @$sql_clauses);
    return ($sql, @args);
}

# takes a simple set of hash variable bindings, and
# a set of option blocks [...][...]
#
# generates SQL for every block required, replaces with
# DBI placeholders, and returns SQL plus DBI execute args list
sub _get_sql_where_and_args_from_hashmap {
    my $self = shift;
    my %argh = %{shift || {}};

    my $where_blocks = $self->split_where_clause;

    # sql clauses to be ANDed
    my @sqls = ();

    # args to be fed to DBI execute() [corresponds to placeholder ?s]
    my @args = ();

    # index of variables replaced by ?s
    my $vari = 0;

  NEXT_BLOCK:
    foreach my $wb (@$where_blocks) {
        my $where = $wb->{text};
        my $varnames = $wb->{varnames};

#        trace(0, "WHEREBLOCK: $where;; VARNAMES=@$varnames;;\n");

        my $str = $where;
        while ($str =~ /(=>)?\s*\&(\S+)\&/) {
            my $op = $1 || '';
            my $varname = $2;

            my $argval = $argh{$varname};
            if (!exists $argh{$varname}) {
		# if a variable is not set in a particular block,
		# that block is ignored, and does not form
		# part of the final query
                next NEXT_BLOCK;
            }
                
                
            if ($op) {
                $op = '= ';
                if ($argval =~ /\%/) {
                    $op = ' LIKE ';
                }
            }
            my $replace_with;
            # replace arrays with IN (1,2,3,...)
            if (ref($argval)) {
                $replace_with =
                  '('.join(',',
                           map {_quote($_)} @$argval).')';
                $op = ' IN ';
            }
            else {
                $replace_with = '?';
                $args[$vari] = $argval;
                $vari++;
            }
            $str =~ s/(=>)?\s*\&$varname\&/$op$replace_with/;
        }
        push(@sqls, $str);
    }
    my $sql = join(' AND ', @sqls);
    trace(0, "WHERE:$sql");
    return ($sql, @args);
}

# takes complex boolean constraints and generates SQL
sub _get_sql_where_and_args_from_constraints {
    my $self = shift;
    my $constr = shift;

    if ($constr->is_leaf) {
        my $where_blocks = $self->split_where_clause;
        die("TODO");
    }
    else {
        my $bool = $constr->bool;
        my $children = $constr->children;
        my @all_args = ();
        my @sqls = ();
        foreach my $child (@$children) {
            my ($sql, @args) = $self->_get_sql_where_and_args($constr);            
            push(@sqls, $sql);
            push(@all_args, @args);
        }
        my $sql = '('.join(" $bool ",
                           @sqls).')';
        return ($sql, @all_args);
    }
    $self->throw("ASSERTION ERROR");
}


# splits a WHERE clause with option blocks [ x=&x& ] [ y=&y& and z=&z& ] into
# blocks, and attaches the variable names to the block
sub split_where_clause {
    my $self = shift;
    my $sql_clauses = $self->sql_clauses;
    my $sql = '';

    my ($clause) = grep {lc($_->{name}) eq 'where'} (@$sql_clauses);
    my $where = $clause->{value} || '';

    my $vari = 0;
    my %vari_by_name = ();

    # this subroutine take a where block, checks if it contains
    # one or more patterns
    #                foo.bar => &baz&
    # and adds 'baz' to the list of variable names 
    my $sub =
      sub {
          my $textin = shift;
          return unless $textin;
          my $str = $textin;

          my @varnames = ();
          while ($str =~ /(=>)?\s*\&(\S+)\&/) {
              my $op = $1 || '';
              my $varname = $2;
              push(@varnames, $varname);
              $str =~ s/(=>)?\s*\&$varname\&//;
          }
          return
            {text=>$textin,
             varnames=>\@varnames}
        };
    my @constrs = ();
    while (1) {
        my ($extracted, $remainder, $skip) =
          extract_bracketed($where, '[]');
        $extracted ||= '';
        $remainder ||= '';
        trace(0, "extraction:( E='$extracted', R='$remainder', SKIP='$skip' )\n");
        $remainder =~ s/^\s+//;
        $remainder =~ s/\s+$//;
        $skip =~ s/^\s+//;
        $skip =~ s/\s+$//;
        
        push(@constrs,
             $sub->($skip));
        if ($extracted) {
            $extracted =~ s/^\s*\[//;
            $extracted =~ s/\]\s*$//;
            push(@constrs,
                 $sub->($extracted));
        }
        else {
            push(@constrs,
                 $sub->($remainder));
            last;
        }
        $where = $remainder;
    }
    @constrs = grep {$_} @constrs;
    return \@constrs;
}


sub get_varnames {
    my $self = shift;
    my $parts = $self->split_where_clause;
    return [map {@{$_->{varnames}}} @$parts];
}

sub prepare {
    my $self = shift;
    my $dbh = shift;
    my $bind = shift;
    my ($sql, @exec_args) = $self->get_sql_and_args($bind);
    my $sth = $self->cached_sth->{$sql};
    if (!$sth) {
	$sth = $dbh->prepare($sql);
	$self->cached_sth->{$sql} = $sth;	  
    }
    return ($sql, $sth, @exec_args);
}

sub parsestr {
    my $self = shift;
    my $io = IO::String->new;
    print $io shift;
    $self->_parsefh($io);
}

sub parse {
    my $self = shift;
    my $fn = shift;
    my $fh = FileHandle->new($fn) || $self->throw("cannot open $fn");
    $self->fn($fn);
    my $name = $fn;
    $name =~ s/.*\///;
    $name =~ s/\.\w+$//;
    $self->name($name);
    $self->_parsefh($fh);
}

sub _parsefh {
    my $self = shift;
    my $fh = shift;
    my $eosql_tag_idx;
    my $tag = {name=>'', value=>''};
    my @tags = ();
    while (<$fh>) {
	chomp;
	if (/^\/\//) {
	    $eosql_tag_idx = scalar(@tags)+1;
	    next;
	}
	if (/^:(\w+)\s*(.*)/) {
	    push(@tags, $tag);
	    $tag = {name=>$1, value => $2};
	}
	elsif (/^(\w+):\s*(.*)/) {
	    push(@tags, $tag);
	    $tag = {name=>$1, value => "$2"};
	}
	else {
	    if (substr($_, -1) eq '\\') {
	    }
	    else {
		$_ = "\n$_";
	    }
	    $tag->{value} .= $_;
	}
    }
    foreach (@tags) {
	$_->{value} =~ s/^\s+//;
	$_->{value} =~ s/\s+$//;
    }
    push(@tags, $tag);
    if (!defined($eosql_tag_idx)) {
	$eosql_tag_idx = scalar(@tags);
    }
    my @clauses = splice(@tags, 0, $eosql_tag_idx);
    if (!@clauses) {
	$self->throw("No SQL");
    }
    if (@clauses == 1 && !$clauses[0]->{name}) {
	my $j = join('|',
		     'select',
		     'from',
		     'where',
		     'order',
		     'limit',
		     'group',
		     'having',
		     'use nesting',
		    );
	my @parts =
	  split(/($j)/i, $clauses[0]->{value});
	@clauses = ();
	while (my ($n, $v) = splice(@parts, 0, 2)) {
	    push(@clauses, {name=>$n, value=>$v});
	}
    }
    $self->sql_clauses(\@clauses);
    $self->properties(\@tags);
    my $sp = Data::Stag->new(properties=>[
					  map {
					      [$_->{name} => $_->{value}]
					  } @tags
					 ]);
    $self->stag_props($sp);
    $fh->close;
}

sub throw {
    my $self = shift;
    my $fmt = shift;

    print STDERR "\nERROR:\n";
    printf STDERR $fmt, @_;
    print STDERR "\n";
    confess;
}

my $default_cscheme =
  {
   'keyword'=>'cyan',
   'variable'=>'magenta',
   'text' => 'reset',
   'comment' => 'red',
   'block' => 'blue',
   'property' => 'green',
  };


sub show {
    my $t = shift;
    my $fh = shift || \*STDOUT;
    my %cscheme = %{shift || $default_cscheme};
    my $colorfunc = shift;

    my $n = $t->name;
    my $clauses = $t->sql_clauses;
    my $props = $t->properties;
    my $keyword = sub {
	my $color = $cscheme{keyword};
	$colorfunc->($color) . "@_" . $colorfunc->('reset');
    };
    my $comment = sub {
	my $color = $cscheme{comment};
	$colorfunc->($color) . "@_" . $colorfunc->('reset');
    };
    my $property = sub {
	my $color = $cscheme{property};
	$colorfunc->($color) . "@_" . $colorfunc->('reset');
    };
    my $c0 = $colorfunc->('reset');
    my $c1 = $colorfunc->($cscheme{variable});
    my $c2 = $colorfunc->($cscheme{keyword});
    my $c3 = $colorfunc->($cscheme{block});

#    my $c0 = 'reset';
#    my $c1 = $cscheme{variable};
#    my $c2 = $cscheme{keyword};
#    my $c3 = $cscheme{block};

    foreach my $clause (@$clauses) {
	my ($n, $c) = ($clause->{name}, $clause->{value});
	print $fh $keyword->("$n ");
	if ($c =~ /\[.*\]/s) {
	    $c =~ s/\[/$c3\[$c0/g;
	    $c =~ s/\]/$c3\]$c0/g;
	    $c =~ s/=\>/$c2=\>$c0/gs;
	    $c =~ s/(\&\S+\&)/$c1$1$c0/gs;
	    print $fh $c;
	    $c = '';
	}
	if ($n =~ /^use/i) {
	    $c =~ s/\(/$c3\($c0/g;
	    $c =~ s/\)/$c3\)$c0/g;
#	    print $fh $c;
#	    $c = '';
	}
	while ($c =~ /(\S+)(\s*)(.*)/s) {
	    my ($w, $sp, $next) = ($1, $2, $3);
	    if ($w =~ /^[A-Z]+$/) {
		print $fh $keyword->($w);
	    }
	    else {
		print $fh $w;
	    }
	    print $fh $sp;
	    $c = $next;
	}
	print $fh "\n";
    }
    print $fh $comment->("// -- METADATA --\n");
    foreach my $p (@$props) {    
	my ($n, $v) = ($p->{name}, $p->{value});
	print $fh $property->("$n: ");
	print $fh $v;
	print $fh "\n";
    }
}

sub _quote {
    my $v = shift;
    $v =~ s/\'/\'\'/g;
    "'$v'";
}


1;

__END__

=head1 NAME

  DBIx::DBStag::SQLTemplate - A Template for an SQL query

=head1 SYNOPSIS

  # find template by name
  $template = $dbh->find_template("mydb-personq");

  # execute this template, filling in the 'name' attribute
  $xml = $dbh->selectall_xml(-template=>$template, 
                             -bind=>{name => "fred"});

=cut

=head1 DESCRIPTION

A template represents a canned query that can be parameterized.

Templates are collected in directories (in future it will be possible
to store them in files or in the db itself).

To tell DBStag where your templates are, you should set:

  setenv DBSTAG_TEMPLATE_DIRS "$HOME/mytemplates:/data/bioconf/templates"

Your templates should end with the suffix B<.stg>, otherwise they will
not be picked up

You can name templates any way you like, but the standard way is to
use 2 or 3 fields

  SCHEMA-OBJECT

or

  SCHEMA-OBJECT-QUALIFIERS

(with underscores used within fields)

A template file should contain at minimum some SQL; for example:

=over

=item Example template 1

  SELECT 
               studio.*,
               movie.*,
               star.*
  FROM
               studio NATURAL JOIN 
               movie NATURAL JOIN
               movie_to_star NATURAL JOIN
               star
  WHERE
               [movie.genre = &genre&] [star.lastname = &lastname&]
  USE NESTING (set(studio(movie(star))))

Thats all! However, there are ways to make your template more useful

=item Example template 2

  :SELECT 
               studio.*,
               movie.*,
               star.*
  :FROM
               studio NATURAL JOIN 
               movie NATURAL JOIN
               movie_to_star NATURAL JOIN
               star
  :WHERE
               [movie.genre = &genre&] [star.lastname = &lastname&]
  :USE NESTING (set(studio(movie(star))))

  //
  schema: movie
  desc: query for fetching movies

By including B<:> at the beginning it makes it easier for parsers to
assemble SQL (this is not necessary for DBStag however)

After the // you can add tag: value data.

You should set B<schema:> if you want the template to be available to
users of a db that conforms to that schema

=back

=head2 GETTING A TEMPLATE

The L<DBIx::DBStag> object gives various methods for fetching
templates by name, by database or by schema

=head2 VARIABLES

WHERE clause variables in the template look like this

  &foo&

variables are bound at query time

  my $set = $dbh->selectall_stag(-template=>$t,
                                 -bind=>["bar"]);

or

  my $set = $dbh->selectall_stag(-template=>$t,
                                 -bind=>{foo=>"bar"});

If the former is chosen, variables are bound from the bind list as
they are found

=head2 OPTIONAL BLOCKS

  WHERE [ foo = &foo& ]

If foo is not bound then the part between the square brackets is left out

Multiple option blocks are B<AND>ed together

An option block need not contain a variable - if it contains no
B<&variable&> name it is automatically B<AND>ed

=head2 BINDING OPERATORS

The operator can be bound at query time too

  WHERE [ foo => &foo& ]

Will become either

  WHERE foo = ?

or

  WHERE foo LIKE ?

or

  WHERE foo IN (f0, f1, ..., fn)

Depending on whether foo contains the % character, or if foo is bound
to an ARRAY

=head1 METHODS


=head2 name

  Usage   - $name = $template->name
  Returns - str
  Args    -

every template has a name that (should) uniquely identify it

=head2 desc

  Usage   - $desc = $template->desc
  Returns - str
  Args    -

templates have optional descriptions

=cut

=head2 get_varnames

  Usage   - $varnames = $template->get_varnames
  Returns - listref of strs
  Args    - 

Returns the names of all variable used in this template

=cut

=head1 WEBSITE

L<http://stag.sourceforge.net>

=head1 AUTHOR

Chris Mungall <F<cjm@fruitfly.org>>

=head1 COPYRIGHT

Copyright (c) 2003 Chris Mungall

This module is free software.
You may distribute this module under the same terms as perl itself

=cut



1;

