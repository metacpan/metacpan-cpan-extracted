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
# (c) Hilmar Lapp, hlapp at gmx.net, 2004.
# (c) GNF, Genomics Institute of the Novartis Research Foundation, 2004.
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

add-term-annot.pl

=head1 SYNOPSIS

   add-term-annot.pl --host somewhere.edu --dbname biosql
                       

=head1 DESCRIPTION


=head1 ARGUMENTS

The arguments after the named options constitute the filelist. If
there are no such files, input is read from stdin. Mandatory options
are marked by (M). Default values for each parameter are shown in
square brackets.

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

the DBI driver name for the RDBMS e.g., mysql, Pg, or Oracle [mysql]

=item --namespace $namesp 

The namespace, i.e., name of the ontology, for the terms to be associated.

=item --testonly 

don't commit anything, rollback at the end

=item --logchunk

If supplied with an integer argument n greater than zero, progress
will be logged to stderr every n entries of the input file(s). Default
is no progress logging.

=item -u, -z, or --uncompress

Uncompress the input file(s) on-the-fly by piping them through
gunzip. Gunzip must be in your path for this option to work.

=item more args

The remaining arguments will be treated as files to parse and load. If
there are no additional arguments, input is expected to come from
standard input.

=back

=head1 Authors

Hilmar Lapp E<lt>hlapp at gmx.netE<gt>

=cut


use Getopt::Long;
use Carp (qw:cluck confess:);
use Symbol;

use Bio::Ontology::Ontology;
use Bio::Ontology::Term;
use Bio::Annotation::OntologyTerm;
use Bio::Seq::SeqFactory;
use Bio::DB::BioDB;
use Bio::DB::Query::BioQuery;
use Bio::DB::Query::QueryConstraint;

####################################################################
# Defaults for options changeable through command line
####################################################################
my $host; # should make the driver to default to localhost
my $dbname = "biosql";
my $dbuser = "root";
my $driver = 'mysql';
my $dbpass;
my $namespace;
my $logchunk = 0;        # every how many entries to log progress (0 = don't)
# flags
my $uncompress = 0;      # whether to pipe through gunzip
my $help = 0;            # WTH?
my $debug = 0;           # try it ...
my $testonly_flag = 0;   # don't commit anything, rollback at the end?
my $printerror = 0;      # whether to print DBI error messages
####################################################################
# Global defaults or definitions not changeable through commandline
####################################################################

my $flat_flag = 0;       # don't attach children (when doing a lookup)?

####################################################################
# End of defaults
####################################################################

#
# get options from commandline 
#
my $ok = GetOptions( 'host=s'         => \$host,
                     'driver=s'       => \$driver,
                     'dbname=s'       => \$dbname,
                     'dbuser=s'       => \$dbuser,
                     'dbpass=s'       => \$dbpass,
                     'namespace=s'    => \$namespace,
                     'logchunk=i'     => \$logchunk,
                     'debug'          => \$debug,
                     'testonly'       => \$testonly_flag,
                     'printerror'     => \$printerror,
                     'u|z|uncompress' => \$uncompress,
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
# determine the function for re-throwing exceptions depending on $debug
#
my $throw = ($debug > 0) ? \&Carp::confess : \&Carp::croak;

#
# determine input source(s)
#
my @files = @ARGV ? @ARGV : (\*STDIN);

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
                             );
$db->verbose($debug) if $debug > 0;

# the ontology for the terms to associate
my $ont = _find_or_create_ont($db, $namespace) if $namespace;

# persistence adaptors that we'll use multiple times
my $seqadp = $db->get_object_adaptor("Bio::SeqI");
my $termadp = $db->get_object_adaptor("Bio::Ontology::TermI");

# declarations
my $time = time();
my $n_entries = 0;

# the sequence object factory
my $seqfactory = Bio::Seq::SeqFactory->new(-type => "Bio::Seq");

#
# loop over every input file and load its content
#
foreach $file ( @files ) {
    
    my $fh = $file;

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

    # reset entry counter and timer
    $n_entries = 0;
    $time = time();

    # loop over the stream
    while (my $line = <$fh>) {
        
        chomp($line);

        if ($line =~ /^##\s*(\w+):\s*(.*)/) {
            # processing instruction line
            my $procinstr = $1;
            my $val = $2;
            # trim leading and trailing whitespace from the value
            $val =~ s/^\s+//;
            $val =~ s/\s+$//;
            # interpret the instruction
            if (lc($procinstr) eq "ontology") {
                $ont = _find_or_create_ont($db, $val);
            } elsif (lc($procinstr) eq "columns") {
                @colnames = split(/[\t,]/, $val);
            } else {
                warn("ignoring unknown processing instruction '$procinstr'");
            }
            next;
        }

        # ignore empty and comment lines
        next if ($line =~ /^#/) || ($line =~ /^\s*$/);

        # this is a data line, split into columns
        my @fields = split(/[\t,]/, $line);        

        # gather the sequence (bioentry) query constraints and bind
        # values, and at the same time define the term
        my $term = Bio::Ontology::Term->new(-ontology => $ont);
        my @qcs = ();
        my @values = ();
        for (my $i = 0; $i < @colnames; $i++) {
            if ($colnames[$i] =~ /^term.*\.(.*)/i) {
                my $attr = $1;
                $term->$attr($fields[$i]);
            } else {
                my $qc = Bio::DB::Query::QueryConstraint->new();
                # namespace is a special case because it's a separate entity
                # in the relational model but not an object in the object model
                if (lc($colnames[$i]) eq "namespace") {
                    $qc->set("db.name = ?");
                } else {
                    $qc->set("seq.".$colnames[$i]." = ?");
                }
                push(@qcs, $qc);
                push(@values, $fields[$i]);
            }
        }
        # skip to next one if no constraints found
        if (!@qcs) {
            warn("no constraints found in line '$line', skipping");
            next;
        }

        # try to lookup the term
        my $pterm = $termadp->find_by_unique_key($term);

        # find the matching seq objects (bioentries)
        my $query = Bio::DB::Query::BioQuery->new(
            -datacollections => ["Bio::SeqI seq", 
                                 "BioNamespace=>Bio::SeqI db"],
            -where => ["and", \@qcs]);
        my $qres = $seqadp->find_by_query(
            $query,
            -name=>'seq['.join(";",@colnames).']',
            -values => \@values,
            -obj_factory => $seqfactory,
            -flat_only => 1);
        
        # for each sequence found, attach the term if it's not
        # associated with the term already
        while (my $seq = $qres->next_object()) {
            # if the term hasn't been found it can't be associated either
            if ($pterm) {
                my $rs = $termadp->find_by_association(-objs => [$seq,$pterm]);
                # skip to next sequence if we find a record
                next if @{$rs->each_Object()};
            } else {
                $pterm = $db->create_persistent($term);
            }
            # add the term as annotation using an adapter
            $seq->annotation->add_Annotation(
                Bio::Annotation::OntologyTerm->new(-term => $pterm));
            # and try to serialize
            eval {
                $seq->store(); 
            };
            if ($@) {
                $seqadp->rollback();
                &$throw("Failed to update ".$seq->object_id().": $@\n");
            }
        }

        # increment entry counter
        $n_entries++;
        # and report progress if enabled
        if (($logchunk > 0) && (($n_entries % $logchunk) == 0)) {
            $time = _report_progress($time, $logchunk);
        }

    }
    close($fh);

    # final progress report for the file if progress reports are enabled
    if (($logchunk > 0) && (($n_entries % $logchunk) != 0)) {
        _report_progress($time, $logchunk);
    }
}

if ($seqadp) {
    $testonly_flag ? $seqadp->rollback() : $seqadp->commit();
}

# done!

#################################################################
# Implementation of functions                                   #
#################################################################

=head2 _report_progress

 Title   : _report_progress
 Usage   :
 Function: Reports the progress to STDERR.
 Example :
 Returns : The new stopped time to be passed to the next call
 Args    : - the time at which progress was reported last
           - every how many entries progress is reported


=cut

sub _report_progress {
    my $time = shift;
    my $logchunk = shift;

    my $elapsed = time() - $time;
    printf STDERR 
        "\t... loaded $n_entries entries "
        . "(in %.2d:%.2d:%.2d, %5.2f entries/s)\n",
        $elapsed/3600, ($elapsed % 3600)/60, $elapsed % 60,
        $logchunk / $elapsed;
    return time();
}

=head2 _find_or_create_ont

 Title   : _find_or_create_ont
 Usage   :
 Function: Find or create the ontology entry with the given name.
 Example :
 Returns : A persistent Bio::Ontology::OntologyI object
 Args    : - the persistence adaptor factory (the $db handle)
           - the name of the ontology


=cut

sub _find_or_create_ont {
    my $db = shift;
    my $ont_name = shift;

    my $ontadp = $db->get_object_adaptor("Bio::Ontology::OntologyI");
    my $ont = Bio::Ontology::Ontology->new(-name => $ont_name);
    my $pont = $ontadp->find_by_unique_key($ont);
    if (!$pont) {
        $pont = $db->create_persistent($ont)->create();
    }
    return $pont;
}
