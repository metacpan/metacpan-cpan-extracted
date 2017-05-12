#!/usr/local/bin/perl
#
# $Id$
#
# Cared for by Hilmar Lapp <hlapp at gmx.net>
#
# Copyright Hilmar Lapp
#
# You may distribute this module under the same terms as perl itself

#
# (c) Hilmar Lapp, hlapp at gmx.net, 2003.
# (c) GNF, Genomics Institute of the Novartis Research Foundation, 2003.
#
# You may distribute this module under the same terms as perl itself.
# Refer to the Perl Artistic License (see the license accompanying this
# software package, or see http://www.perl.com/language/misc/Artistic.html)
# for the terms under which you may use, modify, and redistribute this module.
# 
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
# MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#

=head1 NAME 

load_ontology.pl

=head1 SYNOPSIS

  # for loading the Gene Ontology:
  load_ontology.pl --host somewhere.edu --dbname biosql \
                   --namespace "Gene Ontology" --format goflat \
                   --fmtargs "-defs_file,GO.defs" \
                   function.ontology process.ontology component.ontology
  # in practice, you will want to use options for dealing with
  # obsolete terms; read the documentation of respective arguments

  # for loading the SOFA part of the sequence ontology (currently
  # there is no term definition file for SOFA):
  load_ontology.pl --host somewhere.edu --dbname biosql \
                   --namespace "SOFA" --format soflat sofa.ontology

=head1 DESCRIPTION

This script loads a BioSQL database with an ontology. There are a number of
options to do with where the BioSQL database is (ie, hostname,
user for database, password, database name) followed by the database
name you wish to load this into and then any number of files that make
up the ontology. The files are assumed formatted identically with the
format given in the --format flag.

There are more options than the ones shown above, see below. In
particular, there is a variety of options to specify how you want to
handle obsolete terms. If you try to load the Gene Ontology, you will
want to check out those options. Also, you may want to consult a
thread from the bioperl mailing list in this regard, see
http://bioperl.org/pipermail/bioperl-l/2004-February/014846.html .

Also, consider using --safe always unless you do want the script to
terminate at the first issue it encounters with loading.

=head1 ARGUMENTS

The arguments after the named options constitute the filelist. If
there are no such files, input is read from stdin. Mandatory options
are marked by (M). Default values for each parameter are shown in
square brackets.  (Note that -bulk is no longer available):

=over 2 

=item --host $URL

the host name or IP address incl. port [localhost]

=item --dbname $db_name

the name of the schema [biosql]

=item --dbuser $username

database username [root]

=item --dbpass $password

password [undef]

=item --driver $driver

the DBI driver name for the RDBMS e.g., mysql, Pg, or Oracle

=item --dsn dsn

Instead of providing the database connection and driver parameters
individually, you may also specify the DBI-formatted DSN that is to be
used verbatim for connecting to the database. Note that if you do give
individual parameters in addition they will not supplant what is in
the DSN string. Hence, the only database-related parameter that may be
useful to specify in addition is --driver, as that is used also for
selecting the driver-specific adaptors that generate SQL
code. Usually, the driver will be parsed out from the DSN though and
therefore will be set as well by setting the DSN.

Consult the POD of your DBI driver for how to properly format the DSN
for it. A typical example is dbi:Pg:dbname=biosql;host=foo.bar.edu
(for PostgreSQL). Note that the DSN will be specific to the driver
being used.

=item --schema schemaname

The schema under which the BioSQL tables reside in the database. For
Oracle and MySQL this is synonymous with the user, and won't have an
effect. PostgreSQL since v7.4 supports schemas as the namespace for
collections of tables within a database.

=item --initrc paramfile

Instead of, or in addition to, specifying every individual database
connection parameter you may put them into a file that when read by
perl evaluates to an array or hash reference. This option specifies
the file to read; the special value DEFAULT (or no value) will use a
file ./.bioperldb or $HOME/.bioperldb, whichever is found first in
that order.

Constructing a file that evaluates to a hash reference is very
simple. The first non-space character needs to be an open curly brace,
and the last non-space character a closing curly brace. In between the
curly braces, write option name enclosed by single quotes, followed by
=> (equal to or greater than), followed by the value in single
quotes. Separate each such option/value pair by comma. Here is an
example:

{ 
    '-dbname' => 'mybiosql', '-host' => 'foo.bar.edu', '-user' => 'cleo' 
}

Line breaks and white space don't matter (except if in the value
itself). Also note that options only have a single dash as prefix, and
they need to be those accepted by Bio::DB::BioDB->new()
(L<Bio::DB::BioDB>) or Bio::DB::SimpleDBContext->new()
(L<Bio::DB::SimpleDBContext>). Those sometimes differ slightly from the
option names used by this script, e.g., --dbuser corresponds to -user.

Note also that using the above example, you can use it for --initrc
and still connect as user caesar by also supplying --dbuser caesar on
the command line. I.e., command line arguments override any parameters
also found in the initrc file.

Finally, note that if using this option with default file name and the
default file is not found at any of the default locations, the option
will be ignored; it is not considered an error.

=item --namespace $namesp 

The namespace (name of the ontology) under which the terms and
relationships in the input files are to be created in the database
[bioperl ontology]. Note that the namespace will be left untouched if the
object(s) to be submitted has it set already.

Note that the DAG-edit flat file parser from more recent (1.2.2 and
later) bioperl releases can auto-discover the ontology name.

=item --lookup

Flag to look-up by unique key first, converting the insert into an
update if the object is found. This pertains to terms only, as there
is nothing to update about relationships if they are found by unique
key (the unique key comprises of all columns).

=item --noupdate

Don't update if object is found (with --lookup). Again, this only
pertains to terms.

=item --remove

Flag to remove terms before actually adding them (this necessitates a
prior lookup). Note that this is not relevant for relationships (if
one is found by lookup, removing and re-adding has essentially the
same result as leaving it untouched).

=item --noobsolete

Flag to exclude from upload terms marked as obsolete. Note that with
this flag, any update, removal, or object merge that you specify using
other parameters will not apply to obsolete terms. I.e., if you have
terms existing in your database that are marked as obsolete in the
input file, using this flag will prevent the existing terms from being
updated to reflect the obsolete status. Therefore, this flag is best
used when first loading an ontology. You may want to consider using
--updobsolete instead.

Note that relationships found in the input file(s) that reference an
obsolete term will be omitted from loading with this flag in effect.

=item --updobsolete

Flag to exclude from upload terms marked as obsolete unless they are
already present in the database. If they are, they will be updated,
and the --mergeobjs procedure will apply. If they are not, they will
be treated as if --noobsolete had been specified. Note that
relationships will not be updated for obsolete terms.

In contrast to --noobsolete, using this flag will increase the
database operations mildly (because of the look-ups necessary to
determine whether obsolete terms are present, and the subsequent
update for those that are), but it will capture change of status for
existing terms. At the same time, you won't load obsolete terms from a
new ontology that you haven't loaded before.

=item --delobsolete

Delete terms marked as obsolete from the database. Note that --remove
together with --noobsolete will have the same effect. Note also that
specifying this flag will not affect those terms that are only in your
database but not in the input file, regardless of whether they are
marked as obsolete or not.

Be aware that even though deleting obsolete terms may sound like a
very sane thing to do, you may have annotated features or bioentries using
those terms. Deleting the obsolete terms will then remove those
annotations (qualifier/value pairs) as well.

=item --safe

flag to continue despite errors when loading (the entire object
transaction will still be rolled back)

=item --testonly 

don't commit anything, rollback at the end

=item --format

This may theoretically be any OntologyIO format understood by
bioperl. All input files must have the same format.

Examples: 
    # this is the default
    --format goflat
    # Simple ASCII hierarchy (e.g., eVoc)
    --format simplehierarchy

Note that some formats may come with event-type parsers, specifically
with XML SAX event parsers. While those aren't truly
OntologyIO-compliant parsers (they can't be because OntologyIO defines
a stream of ontologies as the API), this script supports them
nevertheless. For instance, at the time of this writing there is an
InterPro XML SAX event handler (aliased to --format interprosax) which
will persist terms to the database as they are encountered in the
event stream, which greatly reduces the amount of memory
needed. Credit for conceiving this idea and writing the SAX handler
goes to Juguang Xiao, juguang at tll.org.sg.

=item --fmtargs

Use this argument to specify initialization parameters for the parser
for the input format. The argument value is expected to be a string
with parameter names and values delimited by comma.

Usually you will want to protect the argument list from interpretation
by the shell, so surround it with double or single quotes.

If a parameter value contains a comma, escape it with a backslash
(which means you also must protect the whole argument from the shell
in order to preserve the backslash)

Examples:

    # turn parser exceptions into warnings (don't try this at home)
    --fmtargs "-verbose,-1"
    # verbose parser with an additional path argument
    --fmtargs "-verbose,1,-indexpath,/home/luke/warp"
    # escape commas in values
    --fmtargs "-ontology_name,Big Blue\, v2,-indent_string,\,"

=item --mergeobjs

This is a string or a file defining a closure. If provided, the
closure is called if a look-up for the unique key of the new object
was successful (hence, it will never be called without supplying
--lookup, but not --noupdate, at the same time).

The closure will be passed three (3) arguments: the object found by
lookup, the new object to be submitted, and the Bio::DB::DBAdaptorI
(see L<Bio::DB::DBAdaptorI>) implementing object for the desired
database. If the closure returns a value, it must be the object to be
inserted or updated in the database (if $obj->primary_key returns a
value, the object will be updated). If it returns undef, the script
will skip to the next object in the input stream.

The purpose of the closure can be manifold. It was originally
conceived as a means to customarily merge attributes or associated
objects of the new object to the existing (found) one in order to
avoid duplications but still capture additional information (e.g.,
annotation). However, there is a multitude of other operations it can
be used for, like physically deleting or altering certain associated
information from the database (the found object and all its associated
objects will implement Bio::DB::PersistentObjectI, see
L<Bio::DB::PersistentObjectI>). Since the third argument is the
persistent object and adaptor factory for the database, there is
literally no limit as to the database operations the closure could
possibly do.

=item --computetc "[identity];[base predicate];[subclasses];[ontology]"

Recompute the transitive closure table for the ontology after it has
been loaded. A possibly existing transitive closure will be deleted
first.

The argument specifies three terms the algorithm relies on, and their
ontology, each separated by semicolon. Each of the three terms may be
omitted, but the semicolons need to be present. Alternatively, you may
omit the argument altogether in which case it will assume a sensible
default value ("identity;related-to;implies;Predicate Ontology"). See
below for what this means.

Every predicate in the ontology for which the transitive closure is to
be computed is expected to have a relationship to itself. This
relationship is commonly referred to as the identity relationship. The
first term specifies the predicate name for this relationship, e.g.,
'identity'. The second and third term pertain to ontologies that have
valid paths with mixed predicates. If this occurs, the second term
denotes the base predicate for any combination of two different
predicates, and the third predicate denotes the predicate for the
relationship between any predicate and the base predicate, where the
base predicate is the object and the ontology's predicate is the
subject. For instance, one might want to provide 'related-to' as the
base predicate, and 'implies' as the predicate of the subclassing
relationship, which would give rise to triples like
(is-a,implies,related-to), (part-of,implies,related-to), etc. The
string following the last semicolon denotes the name of the ontology
under which to store those triples as well as the identity, base
predicate, and subclasses predicate terms.

If any of the terms are omitted (provided as empty strings), the
corresponding relationships will not be generated. Note that the
computed transitive closure may then be incomplete.

=item more args

The remaining arguments will be treated as files to parse and load. If
there are no additional arguments, input is expected to come from
standard input.

=back

=head1 Authors

Hilmar Lapp E<lt>hlapp at gmx.netE<gt>

=cut


use Getopt::Long;
use Symbol;
use Carp (qw:cluck confess croak:);
use Bio::DB::BioDB;
use Bio::OntologyIO;
use Bio::Root::RootI;

####################################################################
# Defaults for options changeable through command line
####################################################################
my $host; # should make the driver to default to localhost
my $dbname;
my $dbuser;
my $driver;
my $dbpass;
my $schema;
my $format = 'goflat';
my $fmtargs = '';
my $namespace = "bioperl ontology";
my $initrc;              # use an initialization file for parameters?
my $dsn;                 # DSN to use verbatim for connecting, if any
my $mergefunc;           # if and how to merge old (found) and new objects
# flags
my $remove_flag = 0;     # remove object before creating?
my $lookup_flag = 0;     # look up object before creating, update if found?
my $no_update_flag = 0;  # do not update if found on look up?
my $no_obsolete = 0;     # whether to include obsolete terms
my $upd_obsolete = 0;    # whether to include obsolete terms
my $del_obsolete = 0;    # whether to delete obsolete terms
my $compute_tc;          # compute the transitive closure?
my $help = 0;            # WTH?
my $debug = 0;           # try it ...
my $testonly_flag = 0;   # don't commit anything, rollback at the end?
my $safe_flag = 0;       # tolerate exceptions on create?
my $printerror = 0;      # whether to print DBI error messages
my $computetc_default = "identity;related-to;implies;Predicate Ontology";
####################################################################
# Global defaults or definitions not changeable through commandline
####################################################################

#
# map of I/O type to the next_XXXX method name
#
# Right now there is only a single IO subsystem we support here, so we
# could do well without. We leave it in here to easily be able to adapt
# in the future should it become necessary.
#
my %nextobj_map = (
		   'Bio::OntologyIO' => 'next_ontology',
		   );

####################################################################
# End of defaults
####################################################################

#
# get options from commandline 
#
my $ok = GetOptions( 'host:s'      => \$host,
		     'driver:s'    => \$driver,
		     'dbname:s'    => \$dbname,
		     'dbuser:s'    => \$dbuser,
		     'dbpass:s'    => \$dbpass,
                     'dsn=s'       => \$dsn,
                     'schema=s'    => \$schema,
		     'format:s'    => \$format,
		     'fmtargs=s'   => \$fmtargs,
                     'initrc:s'    => \$initrc,
		     'namespace:s' => \$namespace,
		     'mergeobjs:s' => \$mergefunc,
		     'safe'        => \$safe_flag,
		     'remove'      => \$remove_flag,
		     'lookup'      => \$lookup_flag,
		     'noupdate'    => \$no_update_flag,
		     'noobsolete'  => \$no_obsolete,
		     'updobsolete' => \$upd_obsolete,
		     'delobsolete' => \$del_obsolete,
		     'computetc:s' => \$compute_tc,
		     'debug'       => \$debug,
		     'testonly'    => \$testonly_flag,
                     'printerror'  => \$printerror,
		     'h|help'      => \$help
		     );

if((! $ok) || $help) {
    if(! $ok) {
	print STDERR "missing or unsupported option(s) on commandline\n";
    }
    system("perldoc $0");
    exit($ok ? 0 : 2);
}

#
# determine the function for re-throwing exceptions depending on $debug and
# $safe_flag
#
our $throw = $safe_flag ?
    ($debug > 0 ? \&Carp::cluck : \&Carp::carp) :
    ($debug > 0 ? \&Carp::confess : \&Carp::croak);

#
# check $computetc whether it needs to assume the default value
#
$compute_tc = $computetc_default
    unless $compute_tc || (!defined($compute_tc));

#
# load and/or parse object merge function if supplied
#
my $merge_objs = parse_code($mergefunc) if $mergefunc;

#
# determine input source(s)
#
my @files = @ARGV ? @ARGV : (\*STDIN);

#
# determine input format and type. Having copy-and-pasted it from
# load_seqdatabase.pl, we support more sophistication than we currently
# need or disclose.
#
my $objio;
my @fmtelems = split(/::/, $format);
if(@fmtelems > 1) {
    $format = pop(@fmtelems);
    $objio = join('::', @fmtelems);
} else {
    # default is OntologyIO
    $objio = "OntologyIO";
}
$objio = "Bio::".$objio if $objio !~ /^Bio::/;
my $nextobj = $nextobj_map{$objio}||"next_ontology"; 

# the format might come with argument specifications
my @fmtargs = split(/,/,$fmtargs,-1);
# arguments might have had commas in them - we require them to be
# escaped by backslash and need to stitch them back together now
my $i = 0;
while($i+1 < @fmtargs) {
    if($fmtargs[$i] =~ s/\\$//) {
	splice(@fmtargs, $i, 2, $fmtargs[$i].",".$fmtargs[$i+1]);
    } else {
	$i++;
    }
}

#
# check whether we need to apply defaults
#
$initrc = "DEFAULT" unless $initrc || !defined($initrc);

#
# create the DBAdaptorI for our database
#
my $db = Bio::DB::BioDB->new(-database   => "biosql",
                             -printerror => $printerror,
			     -host       => $host,
			     -dbname     => $dbname,
			     -driver     => $driver,
			     -user       => $dbuser,
			     -pass       => $dbpass,
                             -dsn        => $dsn,
                             -schema     => $schema,
                             -initrc     => $initrc,
			     );
$db->verbose($debug) if $debug > 0;

#
# Open the ontology parser on all files supplied. Unlike other IO parsers,
# ontologies may easily involve more than 1 input file to extract the
# entire ontology.
#

# open depending on whether it's a stream or a bunch of files
my $ontin;
my @parserargs = $format ? (-format => $format) : ();
push(@parserargs, @fmtargs);

if(@files == 1) {
    my $prmname = ref($files[0]) ? "-fh" : "-file";
    $ontin = $objio->new($prmname, $files[0], @parserargs);
} else {
    $ontin = $objio->new(-files => \@files, @parserargs);
}

# set up the array of constant arguments to pass to the persistence handler
my @persist_args = ('-db'          => $db,
                    '-termfactory' => $ontin->term_factory,
                    '-throw'       => $throw,
                    '-mergeobs'    => $merge_objs,
                    '-lookup'      => $lookup_flag,
                    '-remove'      => $remove_flag,
                    '-noupdate'    => $no_update_flag,
                    '-noobsolete'  => $no_obsolete,
                    '-delobsolete' => $del_obsolete,
                    '-updobsolete' => $upd_obsolete,
                    '-testonly'    => $testonly_flag,
                    );


# The input parser may in fact be a SAX event handler, not a truly
# OntologyIO-compliant parser. A SAX handler needs to be treated
# fundamentally different from this point on than an OntologyIO
# compliant parser. While the former is to be handed off to a XML SAX
# parser, the latter needs to be looped over the ontologies it
# returns.

if ($ontin->isa("Bio::OntologyIO::Handlers::BaseSAXHandler")) {
    # this is a SAX event handler, not a true OntologyIO parser

    # pull in the XML SAX parser
    eval {
        require XML::Parser::PerlSAX;
    };
    croak "failed to load required XML SAX parser:\n$@" if $@;
    
    # complete setup of the SAX event handler: pass in our persistence handlers
    $ontin->persist_term_handler(\&persist_term, @persist_args);
    $ontin->persist_relationship_handler(\&persist_relationship,@persist_args);
    $ontin->db($db);

    # make sure the (default) ontology has a name
    my $ont = $ontin->_ontology();
    $ont->name($namespace) unless $ont->name;

    # instantiate the XML SAX parser and pass it the event handler
    my $parser = XML::Parser::PerlSAX->new(Handler => $ontin);

    # parsing the file will persist all terms and relationships, so we need
    # to delete the relationships first to avoid having stale ones around
    print STDERR "\t...deleting all relationships for ",$ont->name,"\n";
    remove_all_relationships('-ontology' => $ont, @persist_args);

    # now go ahead and parse the file
    print STDERR "\t...parsing and loading ",$ont->name,"\n";
    $parser->parse(Source => {SystemId => $files[0]});

    # Generate the transitive closure if requested
    if($compute_tc) {
        print STDERR "\t... transitive closure\n";
        compute_tc($db, $ont, $ontin->term_factory(), $compute_tc);
    }
    
    print STDERR "\tDone with ",$ont->name,"\n";

} else {
    # this is a truly OntologyIO compliant parser, or so I hope

    # loop over the input stream(s)
    while( my $ont = $ontin->$nextobj ) {
        # don't forget to add namespace if the parser doesn't supply one
        $ont->name($namespace) unless $ont->name();
        
        print STDERR "Loading ontology ",$ont->name(),":\n\t... terms\n";

        # in order to allow callbacks to the user and generally a
        # better ability to interfere with and customize the upload
        # process, we load all terms first here instead of simply
        # going for the relationships

        foreach my $term ($ont->get_all_terms()) {
            # call the persistence handler - there is only one right now
            persist_term('-term' => $term, @persist_args);
        }

        # after all terms have been processed, we run through the relationships
        # more or less non-interactively (i.e., without invoking a callback)
        
        print STDERR "\t... relationships\n";

        # first off, we need to delete the existing relationships in order
        # to avoid having stale ones around
        remove_all_relationships('-ontology' => $ont, @persist_args);

        # now go and insert all of them
        foreach my $rel ($ont->get_relationships()) {
            # pass on to persistence function - there's only one right now
            persist_relationship('-rel' => $rel, @persist_args);
        }
        
        # Generate the transitive closure if requested
        if($compute_tc) {
            print STDERR "\t... transitive closure\n";
            compute_tc($db, $ont, $ontin->term_factory(), $compute_tc);
        }

        print STDERR "\tDone with ".$ont->name.".\n";
    }

    # close the parser explicitly in case it needs this to be called
    $ontin->close();
}

print STDERR "Done, cleaning up.\n";

if ($db && $testonly_flag) {
    $db->get_object_adaptor("Bio::Ontology::TermI")->rollback();
}
# done!

#################################################################
# Implementation of functions                                   #
#################################################################

sub parse_code{
    my $src = shift;
    my $code;

    # file or subroutine?
    if(-r $src) {
	if(! (($code = do $src) && (ref($code) eq "CODE"))) {
	    die "error in parsing code block $src: $@" if $@;
	    die "unable to read file $src: $!" if $!;
	    die "failed to run $src, or it failed to return a closure";
	}
    } else {
	$code = eval $src;
	die "error in parsing code block \"$src\": $@" if $@;
	die "\"$src\" fails to return a closure"
	    unless ref($code) eq "CODE";
    }
    return $code;
}

sub compute_tc{
    my ($db, $ont, $termfact, $params) = @_;

    # split the parameter string into term names and ontology name
    my ($idpred,$basepred,$subclpred,$predont) = split(/;/,$params);
    # setup the predicate ontology
    $predont = Bio::Ontology::Ontology->new(-name => $predont);
    # setup the terms from their names and ontology
    if($idpred) {
	$idpred = $termfact->create_object(-name => $idpred,
					   -ontology => $predont);
    }
    if($basepred) {
	$basepred = $termfact->create_object(-name => $basepred,
					     -ontology => $predont);
    }
    if($subclpred) {
	$subclpred = $termfact->create_object(-name => $subclpred,
					      -ontology => $predont);
    }
    # we need the ontology object adaptor
    my $ontadp = $db->get_object_adaptor($predont);

    # done with setup, go for it
    eval {
	$ontadp->compute_transitive_closure($ont,
					    -truncate => 1,
					    -predicate_superclass => $basepred,
					    -subclass_predicate => $subclpred,
					    -identity_predicate => $idpred);
	$ontadp->commit();
    };
    if($@) {
	my $msg = "transitive closure generation failed for ".$ont->name.
	    ":\n$@";
	$ontadp->rollback();
	&$throw($msg);
    }
}

=head2 persist_term

 Title   : persist_term
 Usage   :
 Function: Persist an ontology term to the database. This function may
           also be used as the persistence handler for event handlers,
           e.g., an XML event stream handler.

           This method requires many options and accepts even
           more. See below.

 Example :
 Returns : 
 Args    : Named parameters. Currently the following parameters are
           recognized. Mandatory parameters are marked by an M in 
           parentheses. Flags by definition are not mandatory; their
           default value will be false.

             -term        the ontology term object to persist (M)
             -db          the adaptor factory returned by Bio::DB::BioDB (M)
             -termfactory the factory for creating terms (M)
             -throw       the error notification method to use
             -mergeobs    the closure for merging old and new term
             -lookup      whether to lookup terms first
             -remove      whether to delete existing term first
             -noobsolete  whether to completely ignore obsolete terms
             -delobsolete whether to delete existing obsolete terms
             -updobsolete whether to update existing obsolete terms
             -testonly    whether to not commit the term upon success


=cut

sub persist_term {
    my ($term, $db, $termfactory, $throw,
        $merge_objs, $lookup_flag, $remove_flag, $no_update_flag,
        $no_obsolete, $del_obsolete, $upd_obsolete,
        $testonly_flag) =
          Bio::Root::RootI->_rearrange([qw(TERM
                                           DB
                                           TERMFACTORY
                                           THROW
                                           MERGEOBJS
                                           LOOKUP
                                           REMOVE
                                           NOUPDATE
                                           NOOBSOLETE
                                           DELOBSOLETE
                                           UPDOBSOLETE
                                           TESTONLY)],
                                       @_);
    # if the term is obsolete and we don't want to look at obsolete
    # terms, skip to the next one right away
    return if $no_obsolete && $term->is_obsolete();
    # look up or delete first? this may pertain only to obsolete terms.
    my ($pterm, $lterm, $adp);
    if($lookup_flag || $remove_flag ||
       (($del_obsolete || $upd_obsolete) && $term->is_obsolete())) {
        # look up
        $adp = $db->get_object_adaptor($term);
        $lterm = $adp->find_by_unique_key($term,
                                          -obj_factory => $termfactory);
	    # found?
        if($lterm) {
            # merge old and new if a function for this is provided
            $term = &$merge_objs($lterm, $term, $db) if $merge_objs;
            # the return value may indicate to skip to the next
            return unless $term;
        } elsif(($del_obsolete || $upd_obsolete) && $term->is_obsolete()) {
            # don't store obsolete terms if we're supposed to only update
            # or delete them
            return;
        }
    }
    # try to serialize
    eval {
        $adp = $lterm->adaptor() if $lterm;
        # delete if requested
        if($lterm &&
           ($remove_flag || ($del_obsolete && $term->is_obsolete()))) {
            $lterm->remove();
        }
        # on update, skip the rest if we are not supposed to update,
        # and proceed with insert or update otherwise
        if(! ($lterm && $no_update_flag)) {
            # create a persistent object out of the term
            $pterm = $db->create_persistent($term);
            $adp = $pterm->adaptor();
            # store the primary key of what we found by lookup (this
            # is going to be an udate then)
            if($lterm && $lterm->primary_key) {
                $pterm->primary_key($lterm->primary_key);
            }
            $pterm->store();
        }
        $adp->commit() unless $testonly_flag;
    };
    if ($@) {
        my $msg = "Could not store term ";
        if (defined($term->object_id())) {
            $msg .= $term->object_id().", name ";
        }
        $msg .= "'".$term->name()."':\n$@\n";
        $adp->rollback();
        $throw = \&Carp::croak unless $throw;
        &$throw($msg);
    }
}

=head2 remove_all_relationships

 Title   : remove_all_relationships
 Usage   :
 Function: Removes all relationships of an ontology from the
           database. This is a necessary step before inserting the
           latest ones in order to avoid stale relationships staying
           in the database.

           See below for the parameters that this method accepts
           and/or requires.

 Example :
 Returns : 
 Args    : Named parameters. Currently the following parameters are
           recognized. Mandatory parameters are marked by an M in 
           parentheses. Flags by definition are not mandatory; their
           default value will be false.

             -ontology    the ontology for which to remove relationships (M)
             -db          the adaptor factory returned by Bio::DB::BioDB (M)
             -throw       the error notification method to use
             -testonly    whether to not commit the term upon success


=cut

sub remove_all_relationships {
    my ($ont, $db, $throw, $testonly_flag) = 
          Bio::Root::RootI->_rearrange([qw(ONTOLOGY
                                           DB
                                           THROW
                                           TESTONLY)],
                                       @_);

    my $reladp = $db->get_object_adaptor("Bio::Ontology::RelationshipI");
    eval {
        $reladp->remove_all_relationships($ont);
        $reladp->commit() unless $testonly_flag;
    };
    if ($@) {
        $reladp->rollback();
        $throw = \&Carp::croak;
        &$throw("failed to remove relationships prior to inserting them: $@");
    }
}

=head2 persist_relationship

 Title   : persist_relationship
 Usage   :
 Function: Persist a term relationship to the database. This function
           may also be used as the persistence handler for event
           handlers, e.g., an XML event stream handler.

           See below for the required and recognized parameters.

 Example :
 Returns : 
 Args    : Named parameters. Currently the following parameters are
           recognized. Mandatory parameters are marked by an M in 
           parentheses. Flags by definition are not mandatory; their
           default value will be false.

             -rel         the term relationship object to persist (M)
             -db          the adaptor factory returned by Bio::DB::BioDB (M)
             -throw       the error notification method to use
             -noobsolete  whether to completely ignore obsolete terms
             -delobsolete whether to delete existing obsolete terms
             -testonly    whether to not commit the term upon success


=cut

sub persist_relationship {
    my ($rel, $db, $throw, $no_obsolete, $del_obsolete, $testonly_flag) =
          Bio::Root::RootI->_rearrange([qw(REL
                                           DB
                                           THROW
                                           NOOBSOLETE
                                           DELOBSOLETE
                                           TESTONLY)],
                                       @_);
    # don't bother with relationships that reference an obsolete term
    # if we don't load obsolete terms
    if($del_obsolete || $no_obsolete) {
        return if ($rel->subject_term->is_obsolete() ||
                   $rel->object_term->is_obsolete() ||
                   $rel->predicate_term->is_obsolete());
    }
    my $prel = $db->create_persistent($rel);
    eval {
        $prel->create(); 
        $prel->commit() unless $testonly_flag;
    };
    if ($@) {
        my $msg = "Could not store term relationship (".
            join(",",
                 $rel->subject_term->name(),
                 $rel->predicate_term->name(), 
                 $rel->object_term->name()).
                 "):\n$@\n";
        $prel->rollback();
        $throw = \&Carp::croak unless $throw;
        &$throw($msg);
    }
}
