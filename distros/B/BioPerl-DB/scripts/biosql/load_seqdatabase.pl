#!/bin/perl
#
# You may distribute this module under the same terms as perl itself.
# Refer to the Perl Artistic License (see the license accompanying this
# software package, or see http://www.perl.com/language/misc/Artistic.html)
# for the terms under which you may use, modify, and redistribute this module.
#
# $Id$
#

=head1 NAME 

load_seqdatabase.pl

=head1 SYNOPSIS

   load_seqdatabase.pl --host somewhere.edu --dbname biosql \
                       --namespace swissprot --format swiss \
                       swiss_sptrembl swiss.dat primate.dat

=head1 DESCRIPTION

This script loads a BioSQL database with sequences. There are a number
of options that have to do with where the database is and how it's
accessed and the format and namespace of the input files. These are
followed by any number of file names. The files are assumed to be
formatted identically with the format given by the --format flag. See
below for more details.

=head1 ARGUMENTS

The arguments after the named options constitute the filelist. If
there are no such files, input is read from stdin. Default values for
each parameter are shown in square brackets. Note that --bulk is no
longer available.

=over 2

=item --host $URL

The host name or IP address incl. port. The default is undefined,
which will get interpreted differently depending on the driver. E.g.,
the mysql driver will assume localhost if host is undefined; the
PostgreSQL driver will use a local (file-)socket connection to the
local host, whereas it will use a TCP socket (which has to be enabled
separately when starting the postmaster) if you specify 'localhost';
the Oracle driver doesn't need (or may even get confused by) a host
name if the local tnsnames.ora can properly resolve the SID, which
would be specified using --dbname.

=item --port $port

the port to which to connect; usually the default port chosen by the
driver will be appropriate. 

=item --dbname $db_name

the name of the schema [biosql]

=item --dbuser $username

database username [root]

=item --dbpass $password

password [undef]

=item --driver $driver

the DBI driver name for the RDBMS e.g., mysql, Pg, or Oracle [mysql]

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
curly braces, write option name enclosed in single quotes, followed by
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

The namespace under which the sequences in the input files are to be
created in the database. Note that the namespace will be
left untouched if the object to be submitted has it set already [bioperl].

=item --lookup

flag to look-up by unique key first, converting the insert into an
update if the object is found

=item --flatlookup

Similar to --lookup, but only the 'flat' row for the object is looked
up, meaning no children will be fetched and attached to the
object. This is potentially much faster than a full recursive object
retrieval, but as a result the retrieved object lacks all association
properties (e.g., a flat Bio::SeqI object would lack all features and
all annotation, but still have display_id, accession, version
etc.). This option is therefore most useful if you want to delete
found objects (--remove), as then any time spent on retrieving more
than the row together with the primary key is wasted.

=item --noupdate

don't update if object is found (with --lookup)

=item --remove

flag to remove sequences before actually adding them (this
necessitates a prior lookup)

=item --safe

flag to continue despite errors when loading (the entire object
transaction will still be rolled back)

=item --testonly

don't commit anything, rollback at the end

=item --format

This may theoretically be any IO subsytem and the format understood by
that subsystem to parse the input file(s). IO subsytem and format must
be separated by a double colon. See below for which subsystems are
currently supported.

The default IO subsystem is SeqIO. 'Bio::' will automatically be
prepended if not already present. As of now the other supported
subsystem is ClusterIO. All input files must have the same format.

Examples:
    # this is the default
    --format genbank
    # SeqIO format EMBL
    --format embl
    # Bio::ClusterIO stream with -format => 'unigene'
    --format ClusterIO::unigene

=item --fmtargs

Use this argument to specify initialization parameters for the parser
for the input format. The argument value is expected to be a string
with parameter names and values delimited by commas.

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
    --fmtargs "-myspecialchar,\,"

=item --pipeline

This is a sequence of Bio::Factory::SeqProcessorI (see
L<Bio::Factory::SeqProcessorI>) implementing objects that will be
instantiated and chained in exactly this order. This allows you to
write re-usable modules for custom post-processing of objects after
the stream parser returns them. See L<Bio::Seq::BaseSeqProcessor> for
a base implementation for such modules.

Modules are separated by the pipe character '|'. In addition, you can
specify initialization parameters for each of the modules by enclosing
a comma-separated list of alternating parameter name and value pairs
in parentheses or angle brackets directly after the module.

This option will be ignored if no value is supplied.

Examples:
    # one module
    --pipeline "My::SeqProc"
    # two modules in the specified order
    --pipeline "My::SeqProc|My::SecondSeqProc"
    # two modules, the first of which has two initialization parameters
    --pipeline "My::SeqProc(-maxlength,1500,-minlength,300)|My::SecondProc"

=item --seqfilter

This is either a string or a file defining a closure to be used as
sequence filter. The value is interpreted as a file if it refers to a
readable file, and a string otherwise. See add_condition() in
L<Bio::Seq::SeqBuilder> for more information about what the code will
be used for. The closure will be passed a hash reference with an
accumulated list of initialization paramaters for the prospective
object. It returns TRUE if the object is to be built and FALSE
otherwise.

Note that this closure operates at the stream parser level. Objects it
rejects will be skipped by the parser. Objects it accepts can still be
intercepted at a later stage (options --remove, --update, --noupdate,
--mergeobjs).

Note that not necessarily all stream parsers support a
Bio::Factory::ObjectBuilderI (see L<Bio::Factory::ObjectBuilderI>)
object. Email bioperl-l@bioperl.org to find out which ones do. In
fact, at the time of writing this, only Bio::SeqIO::genbank supports
it.

This option will be ignored if no value is supplied.

=item --mergeobjs

This is also a string or a file defining a closure. If provided, the
closure is called if a look-up for the unique key of the new object
was successful. Hence, it will never be called without supplying
--lookup at the same time. 

Note that --noupdate will B<not> prevent the closure from being
called. I.e., if you make changes to the database in your merge script
as opposed to only modifying the object, --noupdate will B<not>
prevent those changes. This is a feature, not a bug. Obviously,
modifications to the in-memory object will have no effect with
--noupdate since the database won't be updated with it.

The closure will be passed three arguments: the object found by
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

This option will be ignored if no value is supplied.

=item --logchunk

If supplied with an integer argument n greater than zero, progress
will be logged to stderr every n entries of the input file(s). Default
is no progress logging.

=item --debug

Turn on verbose and debugging mode. This will produce a *lot* of
logging output, hence you will want to capture the output in a
file. This option is useful if you get some mysterious failure
somewhere in the events of loading or updating a record, and you would
like to see, e.g., precisely which SQL statement fails. Usually you
turn on this option because you've been asked to do so by a person
responding after you posted your problem to the Bioperl mailing list.

=item -u, -z, or --uncompress

Uncompress the input file(s) on-the-fly by piping them through
gunzip. Gunzip must be in your path for this option to work.

=item more args

The remaining arguments will be treated as files to parse and load. If
there are no additional arguments, input is expected to come from
standard input.

=back

=head1 Authors

Ewan Birney E<lt>birney at ebi.ac.ukE<gt>
Mark Wilkinson E<lt>mwilkinson at gene.pbi.nrc.caE<gt>
Hilmar Lapp E<lt>hlapp at gmx.netE<gt>
Chris Mungall E<lt>cjm at fruitfly.orgE<gt>
Elia Stupka E<lt>elia at tll.org.sgE<gt>

=cut


use Getopt::Long;
use Carp (qw:cluck confess:);
use Symbol;
use Bio::Root::Root;
use Bio::DB::BioDB;
use Bio::Annotation::SimpleValue;
use Bio::SeqIO;
use Bio::ClusterIO;

####################################################################
# Defaults for options changeable through command line
####################################################################
my ($host,$port);
my $dbname;
my $dbuser;
my $driver;
my $dbpass;
my $schema;
my $format = 'genbank';
my $fmtargs = '';
my $namespace = 'bioperl';
my $logchunk = 0;        # log progress after <x> entries (0 = don't)
my $seqfilter;           # see conditions in Bio::Seq::SeqBuilder
my $mergefunc;           # if and how to merge old (found) and new objects
my $pipeline;            # see Bio::Factory::SequenceProcessorI
my $initrc;              # use an initialization file for parameters?
my $dsn;                 # DSN to use verbatim for connecting, if any
#
# flags
#
my $remove_flag = 0;     # remove object before creating
my $lookup_flag = 0;     # look up object before creating, update if found
my $flat_flag = 0;       # don't attach children (when doing a lookup)
my $no_update_flag = 0;  # do not update if found on look up
my $help = 0;            # WTH
my $debug = 0;           # try it ...
my $testonly_flag = 0;   # don't commit anything, rollback at the end
my $safe_flag = 0;       # tolerate exceptions on create
my $uncompress = 0;      # whether to pipe through gunzip
my $printerror = 0;      # whether to print DBI error messages
####################################################################
# Global defaults or definitions not changeable through commandline
####################################################################

#
# map of I/O type to the next_XXXX method name
#
my %nextobj_map = (
                   'Bio::SeqIO'     => 'next_seq',
                   'Bio::ClusterIO' => 'next_cluster',
                   );

####################################################################
# End of defaults
####################################################################

#
# get options from commandline 
#
my $ok = GetOptions( 'host=s'         => \$host,
                     'port=i'         => \$port,
                     'driver=s'       => \$driver,
                     'dbname=s'       => \$dbname,
                     'dbuser=s'       => \$dbuser,
                     'dbpass=s'       => \$dbpass,
                     'dsn=s'          => \$dsn,
                     'schema=s'       => \$schema,
                     'format=s'       => \$format,
                     'fmtargs=s'      => \$fmtargs,
                     'initrc:s'       => \$initrc,
                     'seqfilter:s'    => \$seqfilter,
                     'namespace=s'    => \$namespace,
                     'pipeline:s'     => \$pipeline,
                     'mergeobjs:s'    => \$mergefunc,
                     'logchunk=i'     => \$logchunk,
                     'safe'           => \$safe_flag,
                     'remove'         => \$remove_flag,
                     'lookup'         => \$lookup_flag,
                     'flatlookup'     => \$flat_flag,
                     'noupdate'       => \$no_update_flag,
                     'debug'          => \$debug,
                     'testonly'       => \$testonly_flag,
                     'u|z|uncompress' => \$uncompress,
                     'printerror'     => \$printerror,
                     'h|help'         => \$help
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
my $throw = $safe_flag ?
    ($debug > 0 ? \&Carp::cluck : \&Carp::carp) :
    ($debug > 0 ? \&Carp::confess : \&Carp::croak);

# set the lookup flag in addition if only --flatlookup specified
$lookup_flag = $flat_flag if ($flat_flag);

#
# load and/or parse condition if supplied
#
my $condition = parse_code($seqfilter) if $seqfilter;

#
# load and/or parse object merge function if supplied
#
my $merge_objs = parse_code($mergefunc) if $mergefunc;

#
# determine input source(s)
#
my @files = @ARGV ? @ARGV : (\*STDIN);

#
# determine input format and type
#
my $objio;
my @fmtelems = split(/::/, $format);
if(@fmtelems > 1) {
    $format = pop(@fmtelems);
    $objio = join('::', @fmtelems);
} else {
    # default is SeqIO
    $objio = "SeqIO";
}
$objio = "Bio::".$objio if $objio !~ /^Bio::/;
my $nextobj = $nextobj_map{$objio} || "next_seq"; # next_seq is the default

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
# setup the pipeline if desired
#
my @pipemods = ();
if($pipeline) {
    if($objio ne "Bio::SeqIO") {
        die "pipelining sequence processors not supported for non-SeqIOs\n";
    }
    @pipemods = setup_pipeline($pipeline);
    warn "you specified -pipeline, but no processor modules resulted\n"
        unless @pipemods;
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
                             -port       => $port,
                             -dbname     => $dbname,
                             -driver     => $driver,
                             -user       => $dbuser,
                             -pass       => $dbpass,
                             -dsn        => $dsn,
                             -schema     => $schema,
                             -initrc     => $initrc,
                             );
$db->verbose($debug) if $debug > 0;

# declarations
my ($pseq, $adp);
my $time = time();
my $n_entries = 0;

#
# loop over every input file and load its content
#
foreach $file ( @files ) {
    
    my $fh = $file;
    my $seqin;

    # create a handle if it's not one already
    if(! ref($fh)) {
        $fh = gensym;
        my $fspec = $uncompress ? "gunzip -c $file |" : "<$file";
        if(! open($fh, $fspec)) {
            warn "unable to open $file for reading, skipping: $!\n";
            next;
        }
        print STDERR "Loading $file ...\n";
    }
    # create stream
    $seqin = $objio->new(-fh => $fh,
                         $format ? (-format => $format) : (),
                         @fmtargs);

    # establish filter if provided
    if($condition) {
        if(! $seqin->can('sequence_builder')) {
            $seqin->throw("object IO parser ".ref($seqin).
                          " does not support control by ObjectBuilderIs");
        }
        $seqin->sequence_builder->add_object_condition($condition);
    }

    # chain to pipeline if pipelining is requested
    if(@pipemods) {
        $pipemods[0]->source_stream($seqin);
        $seqin = $pipemods[-1];
    }

    # reset entry counter and timer
    $n_entries = 0;
    $time = time();

    # loop over the stream
    while( my $seq = $seqin->$nextobj ) {
        # increment entry counter
        $n_entries++;

        # report progress if enabled
        if (($logchunk > 0) && (($n_entries % $logchunk) == 0)) {
            my $elapsed = time() - $time;
            printf STDERR 
                "\t... loaded $n_entries entries "
                . "(in %.2d:%.2d:%.2d, %5.2f entries/s)\n",
                $elapsed/3600, ($elapsed % 3600)/60, $elapsed % 60,
                $logchunk / $elapsed;
            $time = time();
        }

        # we can't store the structure for structured values yet, so
        # flatten them
        if($seq->isa("Bio::AnnotatableI")) {
            flatten_annotations($seq->annotation);
        }
        # don't forget to add namespace if the parser doesn't supply one
        $seq->namespace($namespace) unless $seq->namespace();
        # look up or delete first?
        my $lseq;
        if($lookup_flag || $remove_flag) {
            # look up
            $adp = $db->get_object_adaptor($seq);
            $lseq = $adp->find_by_unique_key($seq,
                                             -obj_factory => 
                                             $seqin->object_factory(),
                                             -flat_only => $flat_flag);
            # found?
            if($lseq) {
                # merge old and new if a function for this is provided
                $seq = &$merge_objs($lseq, $seq, $db) if $merge_objs;
                # the return value may indicate to skip to the next
                next unless $seq;
            }
        }
        # try to serialize
        eval {
            # set the adaptor variable before any operation which may throw
            # us out of the eval block
            $adp = $lseq ? $lseq->adaptor() : $db->get_object_adaptor($seq);
            # delete first if requested
            $lseq->remove() if $remove_flag && $lseq;
            # on update, skip the rest if we are not supposed to update
            if(! ($lseq && $no_update_flag)) {
                # create a persistent object out of the seq if it's
                # not one already (merge_objs may have returned the
                # looked up sequence, i.e., $lseq)
                $pseq = $seq->isa("Bio::DB::PersistentObjectI") 
                    ? $seq : $db->create_persistent($seq);
                # store the primary key of what we found by lookup (this
                # is going to be an udate then)
                if($lseq && $lseq->primary_key) {
                    $pseq->primary_key($lseq->primary_key);
                }
                $pseq->store(); # inserts if primary key not set
            }
            $adp->commit() unless $testonly_flag;
        };
        if ($@) {
            my $msg = "Could not store ".$seq->object_id().": $@\n";
            if($adp) {
                $adp->rollback();
            } else {
                $msg .= "\nFailed to load adaptor for ".ref($seq).
                    " - not good. You may want to ctrl-c your run ".
                    "if you had --safe switched on.";
            }
            &$throw($msg);
        }

    }
    $seqin->close();
}

# final progress report if enabled
if (($logchunk > 0) && (($n_entries % $logchunk) != 0)) {
    my $elapsed = time() - $time;
    $elapsed = 1 unless $elapsed; # avoid division by zero
    printf STDERR 
                "\t... loaded $n_entries entries "
                . "(in %.2d:%.2d:%.2d, %5.2f entries/s)\n",
                $elapsed/3600, ($elapsed % 3600)/60, $elapsed % 60,
                ($n_entries % $logchunk) / $elapsed;
}

$adp->rollback() if $adp && $testonly_flag;

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

sub setup_pipeline{
    my $pipeline = shift;
    my @pipemods = ();

    # split into modules
    my @mods = split(/\|/, $pipeline);
    # instantiate a module 'loader'
    my $loader = Bio::Root::Root->new();
    # load and instantiate each one, then concatenate
    foreach my $mod (@mods) {
        # separate module name from potential arguments
        my $modname = $mod;
        my @modargs = ();
        if($modname =~ /^(.+)[\(<](.*)[>\)]$/) {
            $modname = $1;
            @modargs = split(/,/, $2);
        }
        $loader->_load_module($modname);
        my $proc = $modname->new(@modargs);
        if(! $proc->isa("Bio::Factory::SequenceProcessorI")) {
            die "Pipeline processing module $modname does not implement ".
                "Bio::Factory::SequenceProcessorI. Bummer.\n";
        }
        $proc->source_stream($pipemods[$#pipemods]) if @pipemods;
        push(@pipemods, $proc);
    }
    return @pipemods;
}

sub flatten_annotations {
    my $anncoll = shift;
    foreach my $ann ($anncoll->remove_Annotations()) {
        if($ann->isa("Bio::Annotation::StructuredValue")) {
            foreach my $val ($ann->get_all_values()) {
                $anncoll->add_Annotation(Bio::Annotation::SimpleValue->new(
                                           -value => $val,
                                           -tagname => $ann->tagname()));
            }
        } else {
            $anncoll->add_Annotation($ann);
        }
    }
}
