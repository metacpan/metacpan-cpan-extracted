package AlignAid;


# $Id: /svk-mirror/AlignAid/trunk/lib/AlignAid.pm 688 2006-12-15T22:23:31.523908Z dmessina  $


=head1 NAME

AlignAid - easily run sequence alignments locally or on a cluster

=head1 VERSION

This document describes AlignAid version 0.0.2


=head1 SYNOPSIS

    use AlignAid;

    # create an AlignAid object
    # a single, locally run blast job is the default
    my $job = AlignAid->new( db => 'my_blast_db', dir => $dir, 
                             fasta => 'my_query.fa',
                             prog_args => 'V=20 -nonnegok' );
  
   # run the job on the current host
   my $return_value = $job->submit(outfile => 'my_results.out');

   # create an AlignAid cross_match object
   # specify the alignment program and the queue to override the defaults
   my $job2 = AlignAid->new( program => 'cross_match',
                             db => 'my_db.fa', dir => $dir,
                             fasta => 'my_query_seqs.fa', queue => 'LSF');
  
   # submit the cross_match jobs to an LSF queue (of compute nodes)
   my $return_value2 = $job2->submit(outfile => 'my_output');

   # kill the queued jobs
   my $return_value3 = $job2->kill_all;


=head1 DESCRIPTION

AlignAid is designed to make it easy to run the sequence alignment programs
Blast and cross_match. AlignAid can accept a large number of query sequences. 
If a compute cluster queue such as LSF or PBS is available, AlignAid can
automatically split the queries into multiple queue jobs. Likewise, if you
want to run the alignments locally on a single host, a single change is all
that is necessary -- AlignAid will take care of how to invoke the alignment
programs and manage the output.

AlignAid also has rudimentary support for LSF queue job control; it is 
possible to kill jobs through AlignAid's interface.


=head1 DIAGNOSTICS

=over

=item C<< could not load PP -- submitting to LSF or PBS queues will not be possible >>

The PP module couldn't be loaded by Perl. Usually this means it isn't 
installed. PP is available from the Washington University Genome Sequencing
Center.

=item C<< new requires a database >>

The mandatory database parameter wasn't passed to new(). You must specify a database for the queries to be aligned to.

=item C<< database [<foo>] does not exist >>

The database file 'foo' supplied to new() could not be located.

=item C<< new requires an output dir >>

The mandatory output directory parameter wasn't passed to new().

=item C<< directory [<foo>] does not exist >>

The directory 'foo' supplied to new() could not be located.

=item C<< [<foo>] is, that's right, not a directory >>

The value 'foo' of the directory parameter is not a directory.

=item C<< new requires a fasta file of queries >>

The mandatory fasta (query) parameter wasn't passed to new().

=item C<< fasta [<foo>] does not exist >>

The fasta file 'foo' could not be located.

=item C<< fasta [<foo>] is not a text file >>

The fasta file 'foo' is, well, not a text file.

=item C<< The PP module is required for submitting jobs to LSF or PBS queues. >>

The value of the queue parameter passed to new() was 'LSF' or 'PBS', but the
PP module isn't loaded (it's needed by AlignAid to talk to the queueing
system).

=item C<< <foo> is not a supported queue type >>

The value of the queue parameter passed to new() was not one of: 'single',
'LSF', or 'PBS'.

=item C<< must supply outfile as argument: $job->submit(outfile => 'foo') >>

The mandatory outfile parameter wasn't passed to submit().

=item C<< Couldn't open <foo> >>

The fasta file 'foo' could not be opened. This could be referring to either
the value of the 'fasta' parameter passed to new() or a temporary fasta file
created by AlignAid in preparation for submitting multiple jobs to a queueing
system.

=item C<< unrecognized alignment program >>

The value of the program parameter is not 'blastn', 'blastp', 'blastx',
'tblastn', 'tblastx', or 'cross_match'.

=item C<< job didn't get submitted! >>

One of the queue jobs AlignAid tried to submit to a queue did not actually
make it onto the queue. This is usually a transient error that occurs when
jobs are being submitted to the queueing system faster than it can handle.
This is only a warning; AlignAid will try to proceed with additional jobs.

=item C<< Sorry! PBS queueing not implemented yet! >>

Yep, you can't actually use AlignAid with a PBS queueing system yet. I don't
personally need this feature anymore, but if you really want it, feel free to
send me an email.

=item C<< single job killing not implemented yet >>

The kill_all() method only works with jobs submitted to a queueing system
right now. If you are itchin' to have this power over single jobs too, begging
via email would be appropriate.

=item C<< <num> weren't killed and still are in the queue >>

<num> jobs weren't successfully killed by kill_all() and are still on the
queue. You'll probably want to go kill them manually (or make another attempt
with kill_all() ).

=item C<< can't validate_blasts -- BPdeluxe 1.0 did not load. >>

BPdeluxe version 1.0 is needed to use the validate_blasts() method. The most
likely cause of this error is that BPdeluxe v1.0 isn't installed on your
system or it's in a directory that's not in @INC. BPdeluxe 1.0 is available
from Jarret Glasscock C<< <glasscock_cpan@mac.com> >>.

=item C<< validate_blasts only works on blast jobs >>

validate_blasts() will not work on any alignment program's output other than
one of the blast programs.

=back


=head1 CONFIGURATION AND ENVIRONMENT
  
AlignAid requires no configuration files or environment variables.


=head1 DEPENDENCIES

=over

=item Bio::SeqIO

part of BioPerl, available at bioperl.org

=item version

available from CPAN

=item PP

This is an optional dependency, needed if you want to submit jobs
to a compute cluster queueing system like LSF

=item BPdeluxe 1.0

This is an optional dependency, needed only if you want to use the
validate_blasts() method. Available from Jarret Glasscock
C<< <glasscock_cpan@mac.com> >>.

=back

=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

Spews Blast and cross_match STDERR all over the place.

No bugs have been reported.

Please report any bugs or feature requests to
C<dave-pause@davemessina.net>.


=head1 AUTHOR

Dave Messina  C<< <dave-pause@davemessina.net> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Dave Messina C<< <dave-pause@davemessina.net> >>. All rights reserved.

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

=head1 APPENDIX

The rest of the documentation details each of the functions.
Internal methods are preceded with a "_".

=cut

use version; $VERSION = qv('0.0.2');

use warnings;
use strict;
use Carp;

# determine if PP will be available
use vars qw($PP_loaded);
eval { require PP; $PP_loaded = 1;};
if( $@ ) {
    $PP_loaded = 0;
    carp "could not load PP -- submitting to LSF or PBS queues will not be possible\n";
}

use File::Spec;
use IO::File;
use Bio::SeqIO;

=head2 new

 Title        : new
 Usage        : AlignAid->new();
 Function     : Constructor for AlignAid class.
 Returns      : Object handle.
 Required Args: dir       => '' - the output directory you want created
              : db        => '' - the database file
              : fasta     => '' - the file of FASTA queries
 Optional Args: queue     => '' - 'single' by default, 'LSF' for an LSF queue
              : program   => '' - the alignment program to use. 'blastn',
              :                   'blastp', 'blastx', 'tblastn', 'tblastx', or
              :                   'cross_match'
              : prog_args => '' - args to pass to the alignment program
 Throws       : croaks if required parameters are missing or suspect.
 Comments     : none

=cut

sub new {
    my ( $class, %arg ) = @_;

    # do some crude safety checks
    if ( !$arg{db} )       { croak "new requires a database"; }
    if ( !-f $arg{db} )    { croak "database [$arg{db}] does not exist"; }
    if ( !$arg{dir} )      { croak "new requires an output dir"; }
    if ( !-e $arg{dir} )   { croak "directory [$arg{dir}] does not exist"; }
    if ( !-d $arg{dir} )   { croak "[$arg{dir}] is not a directory"; }
    if ( !$arg{fasta} )    { croak "new requires a fasta file of queries"; }
    if ( !-f $arg{fasta} ) { croak "fasta [$arg{fasta}] does not exist"; }
    if ( !-T $arg{fasta} ) { croak "fasta [$arg{fasta}] is not a text file"; }

    # set optional parameters if they were passed in or use defaults if not
    $arg{queue}   = defined( $arg{queue} )   ? $arg{queue}   : 'single';
    
    # only allow an LSF or PBS queue if PP loaded
    if ( !$PP_loaded && ($arg{queue} eq 'LSF' || $arg{queue} eq 'PBS') ) {
        croak "The PP module is required for submitting jobs to LSF or PBS queues.";
    }
    
    if ( $arg{queue} ne 'single' && $arg{queue} ne 'LSF' && $arg{queue} ne 'PBS') {
	    croak "$arg{queue} is not a supported queue type";
    }
    $arg{program} = defined( $arg{program} ) ? $arg{program} : 'blastn';
    $arg{chunk}   = defined( $arg{chunk} )   ? $arg{chunk}   : 1;

    # verify all paths are absolute paths
    $arg{db}        = File::Spec->rel2abs( $arg{db} );
    $arg{dir}       = File::Spec->rel2abs( $arg{dir} );
    $arg{fasta}     = File::Spec->rel2abs( $arg{fasta} );
    $arg{prog_name} = $arg{program};
    $arg{program}   = `which $arg{program}`;
    chomp $arg{program};

    # setup the object
    my $self = {
        _queue     => $arg{queue},
        _dir       => $arg{dir},
        _database  => $arg{db},
        _fasta     => $arg{fasta},
        _program   => $arg{program},
        _prog_args => $arg{prog_args},
	_prog_name => $arg{prog_name},
	_chunk     => $arg{chunk},
    };
    bless( $self, $class );

    return ($self);
}

=head2 submit

 Title        : submit
 Usage        : AlignAid->submit();
 Function     : start the alignment job(s) running.
 Returns      : 1 upon success, 0 upon failure
 Required Args: outfile => '' - the file where you want the output to go
 Throws       : croaks if required parameters are missing or suspect.
 Comments     : none

=cut

sub submit {
    my ( $class, %arg ) = @_;

    my @jobs;
    my $ret_val = 1;

    # default args
    $class->{_prog_args} .= ' ';
    $class->{_outfile} = $arg{outfile};
    croak "must supply outfile as argument: \$job->submit(outfile => 'foo')"
	unless defined( $class->{_outfile} );

    # run on a single processor
    if ( $class->{_queue} eq 'single' ) {

        # set up output file
        my $outfile = $class->{_outfile};
        $class->{_prog_args} .= "> $outfile";

        my $string =
"$class->{_program} $class->{_database} $class->{_fasta} $class->{_prog_args}";

        $ret_val = system($string);

        # invert system's return values for passing back
        if ( $ret_val == 0 ) { return 1; }
        else { return 0; }
    }
    # submit to a queueing system
    else {

        # open input file
        my $query_fh = IO::File->new( $class->{_fasta}, "r" )
          or croak "Couldn't open ", $class->{_fasta}, " :? :!";

        my $counter  = 0;              # the counter for the blasts
        my $internal = "$$" . "000";
        my $ENTRIES;

        my $fasta = Bio::SeqIO->new(-fh => $query_fh, '-format' => 'fasta');
        while ( my $entry = $fasta->next_seq ) {

            $ENTRIES .= $entry;
            $counter++;

            unless ( $counter < $class->{_chunk} ) {

                # setup output files
                my $fa_file    = $class->{_dir} . "/" . $internal . ".fa";
                my $out_file   = $class->{_dir} . "/" . $internal . ".blast";
                my $error_file = $class->{_dir} . "/" . $internal . ".errors";

                # create temp fasta file
                my $fa_fh = IO::File->new( $fa_file, "w" )
                  or croak "couldn't open $fa_file";
                print $fa_fh $ENTRIES;
                close $fa_fh;

		# set command string depending on program
		my $prog = $class->{_program};
		my $db   = $class->{_database};
		my $args = $class->{_prog_args};

		my $command;
		if ( $class->{_prog_name} =~ /[t]*blast[nxp]/ ) {
		    $command = "$prog $db $fa_file $args";
		}
		elsif ( $class->{_prog_name} eq 'cross_match' ) {
		    $args .= " -tags -discrep_lists ";
		    $command = "$prog $db $fa_file $args";
		}
		else { croak "unrecognized alignment program"; }

                # submit job
                if ( $class->{_queue} eq 'LSF' ) {
                    my $pp = PP->create(
                        pp_type => 'lsf',
                        command => $command,
                        q       => 'long',
                        eo      => $error_file,
                        output  => $out_file,
                    );

		    # actually start job (it's been holding up til now)
                    $pp->start();

                    # verify job made it onto the queue
                    if ( $pp->is_in_queue(1) ) {
                        push @jobs, $pp;
                    }
                    else {
                        $ret_val = 0;
                        warn "job didn't get submitted!";
                    }

                }
                elsif ( $class->{_queue} eq 'PBS' ) {
                    croak "Sorry! PBS queueing not implemented yet!\n";
                }

                # (re)set counters
                $ENTRIES = "";
                $counter = 0;
                $internal++;
            }    # end of unless
        }    # end of main while

        ### if there are any fastas left
        if ( $counter > 0 ) {

            # setup output files
            my $fa_file    = $class->{_dir} . "/" . $internal . ".fa";
            my $out_file   = $class->{_dir} . "/" . $internal . ".blast";
            my $error_file = $class->{_dir} . "/" . $internal . ".errors";

            # submit job
            if ( $class->{_queue} eq 'LSF' ) {

                my $pp = PP->run(
                    pp_type => 'lsf',
                    command =>
"$class->{_program} $class->{_database} $fa_file $class->{_prog_args}",
                    q => 'long',
                    e => $error_file,
                    o => $out_file,
                );

                # verify job made it onto the queue
                if ( $pp->is_in_queue(1) ) {
                    push @jobs, $pp;
                }
                else {
                    warn "job didn't get submitted!";
                    $ret_val = 0;
                }
            }
            elsif ( $class->{_queue} eq 'PBS' ) {
                croak "Sorry! PBS queueing not implemented yet!\n";
            }

            # (re)set counters
            $ENTRIES = "";
            $counter = 0;
            $internal++;
        }
    }    # end of multi-processor else

    # add refs to the jobs
    $class->{_jobs} = \@jobs;

    return $ret_val;
}

=head2 kill_all

 Title        : kill_all
 Usage        : AlignAid->kill_all();
 Function     : kills all running jobs
 Returns      : 1 upon success, 0 upon failure
 Args         : none
 Throws       : croaks on error
 Comments     : none

=cut

sub kill_all {

    my ( $self, %arg ) = @_;

    if ( $self->{_queue} eq 'single' ) {
        croak "single job killing not implemented yet";
    }
    elsif ( $self->{_queue} eq 'LSF' ) {

        # kill each job
        my $i = 0;
        foreach my $job ( @{ $self->{_jobs} } ) {
            $job->kill;

            unless ( $job->is_in_queue(1) ) {
                delete $self->{_jobs}[ $i++ ];
            }
        }

        if ( scalar @{ $self->{_jobs} } > 0 ) {
            my $num_jobs = scalar @{ $self->{_jobs} };
            warn "$num_jobs weren't killed and still are in the queue";
            return 0;
        }
        else { return 1; }
    }
    elsif ( $self->{_queue} eq 'PBS' ) {
        croak "Sorry! PBS queue support not implemented yet!\n";
        return 0;
    }
    else {
        croak "$self->{_queue} is not a supported queue type";
        return 0;
    }
}

=head2 validate_blasts

 Title        : validate_blasts
 Usage        : AlignAid->validate_blasts();
 Function     : checks ot make sure all of the blasts completed correctly
 Returns      : 1 upon success (no failed blasts), 0 upon failure
 Args         : none
 Throws       : croaks if you try to run it on a non-blast job
              : or if file can't be opened
 Comments     : this method is optional and requires BPdeluxe 1.0

=cut

sub validate_blasts {
    eval { require 'BPdeluxe 1.0'; };
    if ($@) {
        croak "can't validate_blasts -- BPdeluxe 1.0 did not load.\n";
        return;
    };

    my ( $class ) = @_;

### ------------------------------------------
    # not yet implemented for single-proc runs
    if ( $class->{_queue} eq 'single' ) {
	return 1;
    }
### ------------------------------------------

    my @jobs = @{ $class->{_jobs} };
    my %skip; # files to skip due to incomplete blast reports
    my $ret_val = 1;

    if ( $class->{_prog_name} !~ /[t]*blast[nxp]/ ) {
	croak "validate_blasts only works on blast jobs";
    }

    if ( $class->{_queue} eq 'single' ) {
	
    }
    foreach  my $job (@jobs) {
	my $blast_reports = $job->{oo};
	my $file = IO::File->new($blast_reports, "r")
	    or croak "couldn't open $blast_reports";
	my $multi_report = new BPdeluxe::Multi($file);
	REPORT: while ( my $report = $multi_report->nextReport ) {
	    my $name = $report->query;
	    unless ( $report->completed ) {
		print STDOUT "blast of $name didn't complete correctly\n",
		"    see file $blast_reports.\n",
		"    skipping file...\n";
		$skip{$blast_reports} = 1;
		$ret_val = 0;
		last REPORT;
	    }
	}
    }
    # save the bad files to our object
    $class->{_skip} = \%skip;
    return $ret_val;
}

=head2 consolidate_output

 Title        : consolidate_output
 Usage        : AlignAid->consolidate_output();
 Function     : checks to make sure all of the blasts completed correctly
 Returns      : 1 upon success
 Args         : none
 Throws       : croaks if you try to run it on a non-blast job
              : or if file can't be opened
 Comments     : none

=cut

sub consolidate_output {
    my ( $class, %args ) = @_;

    my %skip    = %{ $class->{_skip} };
    my $outfile = $class->{_outfile};
    if (!$outfile) { croak "no output file specified!"; }
    my $out_fh  = IO::File->new($outfile, "w")
	or croak "couldn't open $outfile";

    my @jobs = @{ $class->{_jobs} };
    JOB: foreach my $job (@jobs) {
	my $job_outfile = $job->{oo};

	# skip files with incomplete jobs
	# (currently only works with blast jobs)
	next JOB if $skip{$job_outfile};

	# open and copy output files into one big file
	my $job_fh = IO::File->new($job_outfile, "r")
	    or croak "couldn't open $job_outfile";
	while (<$job_fh>) {
	    print $out_fh $_;
	}
	close $job_fh;
    }
    close $out_fh;
    return 1;
}

1;    # Magic true value required at end of module
__END__
