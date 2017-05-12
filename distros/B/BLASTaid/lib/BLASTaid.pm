package BLASTaid;

# | PACKAGE | BLASTaid
# | AUTHOR  | Todd Wylie
# | EMAIL   | perldev@monkeybytes.org
# | ID      | $Id: BLASTaid.pm 20 2006-03-15 21:28:53Z Todd Wylie $

use version; $VERSION = qv('0.0.3');
use warnings;
use strict;
use Carp;
use IO::File;
use IO::Seekable;


# --------------------------------------------------------------------------
# N E W  (class CONSTRUCTOR)
# ==========================================================================
# USAGE      : BLASTaid->new();
# PURPOSE    : Constructor for class.
# RETURNS    : Object handle.
# PARAMETERS : report       => ''
#            : index        => ''
# THROWS     : croaks if arguments are missing or report file is suspect
# COMMENTS   : Feed the interface a WU-BLAST report path and also the 
#            : path/name where you want the index file saved. If the index 
#            : file specified already exists, use it.
# --------------------------------------------------------------------------
sub new {
    my ($class, %arg) = @_;

    # Do some simple file validation checks.
    if (!$arg{report}   ) { croak "new requires a REPORT value"                }   
    if (!-f $arg{report}) { croak "report [$arg{report}] does not exist"       }
    if (!-T $arg{report}) { croak "report [$arg{report}] is not a text report" }
    
    # Deal with the index file initialization.
    if (!$arg{index}) { croak "new requires a INDEX value" }   
    
    # Class setup.
    my $self  = {
        _report  => $arg{report},
        _index   => $arg{index},
        _ignored => [],
    };
    bless($self, $class);
    
    # If the supplied index already exists then use it. Else, build
    # the index file. Populate the object with the index regardless.
    if (-f $self->{_index}) {
        $self->_load_index_file();
    }
    else {
        $self->_build_index();
    }
    
    return($self);
}


# --------------------------------------------------------------------------
# E A C H  R E P O R T  (accessor method)
# ==========================================================================
# USAGE      : BLASTaid->each_report( ignore => 'yes' );
# PURPOSE    : Accessor method, iterator for object.
# RETURNS    : Query names.
# PARAMETERS : ignore => ''
# THROWS     : croaks if no query names are in object
# COMMENTS   : If ignore = yes, reports with no alignments are skipped.  
# --------------------------------------------------------------------------
sub each_report {
    my ($class, %arg)  = @_;
    
    # Must have a valid ignore clause:
    if (!defined $arg{ignore}) { croak "each_report requires a IGNORE value" }

    # Iterate through the record index returning associated query
    # name:
    my @queries;
    foreach my $id ( sort {$a <=> $b} keys %{$class->{_id}} ) {
        unless ( $class->{_id}->{$id}->{_name} eq "END-OF-FILE" ) {
            unless ( $arg{ignore} eq "yes" ) {
                push( @queries, $class->{_id}->{$id}->{_name} );
            }
            else {
                if ($class->{_id}->{$id}->{_alignments} eq "TRUE") { 
                    push( @queries, $class->{_id}->{$id}->{_name} );
                }
                else {
                    push( @{$class->{_ignored}}, $class->{_id}->{$id}->{_name} );
                }
            }
        }
    }
    if (@queries < 1) { croak "no queries found in object" }
    
    return(@queries);
}


# --------------------------------------------------------------------------
# R E T U R N  R E P O R T  (accessor method)
# ==========================================================================
# USAGE      : BLASTaid->return_report( query => 'contig1.0' );
# PURPOSE    : Accessor method for returning a report,
# RETURNS    : String of BLAST report content.
# PARAMETERS : query => ''
# THROWS     : croaks if no query argument is indicated
#            : croaks if report string is null
#            : croaks if a record is partial (no EXIT CODE)
# --------------------------------------------------------------------------
sub return_report {
    my ($class, %arg) = @_;
    
    # Must have a query name to continue.
    if (!defined $arg{query} || $arg{query} eq ""          ) { croak "return_report must have a QUERY argument"           }
    if (!defined $class->{_queries}->{_name}->{$arg{query}}) { croak "return_report cannot locate $arg{query} in object"  }

    # Seek ahead to the entry and grab the report's text.
    my $pass = "false";
    my $REPORT = new IO::File;
    $REPORT->open( "$class->{_report}" ) or croak "could not open file $class->{_report}";
    $REPORT->seek( $class->{_queries}->{_name}->{$arg{query}}->{_start}, 0 );
    my $string;
    my $seeking = <$REPORT>;
    $string     = $seeking;
  SEEKENTRY:
    while (<$REPORT>) {
        if ($_ =~ /EXIT CODE (\d+)/) { $pass = "true" };
        last SEEKENTRY if ($_ =~ /^BLAST/);
        $string .= $_;
    }
    $REPORT->close;
    
    # Error checking.
    if ($string eq ""  ) { croak "return_report has null return for $arg{query}" };
    if ($pass ne "true") { croak "$arg{query} is a partial report"               };
    
    return($string);
}


# --------------------------------------------------------------------------
# B U I L D  I N D E X  (internal method) 
# ==========================================================================
# USAGE      : BLASTaid->_build_index();
# PURPOSE    : Builds & saves the index file for byte positions.
# RETURNS    : none
# PARAMETERS : none
# THROWS     : croaks if BLAST report cannot be opened
#            : croaks if object entries are not complete
# --------------------------------------------------------------------------
sub _build_index {
    my $class = shift;
    
    # Open the specified BLAST report and index it.
    my $id;
    my $REPORT = new IO::File;
    $REPORT->open( "$class->{_report}" ) or croak "could not open file $class->{_report}";
    while (<$REPORT>) {
        if (/^(BLAST\S+)\s+/) {
            $id++;
            $class->{_id}->{$id}->{_start}      = $REPORT->tell - length($_);
            $class->{_id}->{$id}->{_alignments} = "TRUE";
            $class->{_id}->{$id}->{_type}       = $1;
        }
        elsif (/^Query\=\s+(\S+)/) {
            $class->{_id}->{$id}->{_name} = $1;
        }
        elsif (/\s*.+NONE.+\s*/) {
            # No alignments:
            $class->{_id}->{$id}->{_alignments} = "FALSE";
        }
        elsif ($REPORT->eof) {
            $id++;
            $class->{_id}->{$id}->{_start}      = $REPORT->tell - length($_);
            $class->{_id}->{$id}->{_name}       = "END-OF-FILE";
            $class->{_id}->{$id}->{_alignments} = "FALSE";
            $class->{_id}->{$id}->{_type}       = "N/A";
        }
    }
    $REPORT->close;
    
    # Make sure that all entries have needed values. Revise the object
    # to support the query names as unique keys.
    foreach my $report (sort {$a <=> $b} keys %{$class->{_id}}) {
        if (
            !defined $class->{_id}->{$report}->{_name} ||
            !defined $class->{_id}->{$report}->{_start}
            ) {
            croak "missing QUERY NAME or START for entry $report";
        }
        else {
            $class->{_queries}->{_name}->{ $class->{_id}->{$report}->{_name} } = {
                _start      => $class->{_id}->{$report}->{_start},
                _alignments => $class->{_id}->{$report}->{_alignments},
                _type       => $class->{_id}->{$report}->{_type},
            };
        }
    }
    
    # Save the object to an index file.
    $class->_save_index_file();
    
    return($class);
}


# --------------------------------------------------------------------------
# S A V E  I N D E X  F I L E  (internal method)
# ==========================================================================
# USAGE      : BLASTaid->_save_index_file();
# PURPOSE    : Saves the object to an index byte file.
# RETURNS    : none
# PARAMETERS : none
# THROWS     : croaks if index file cannot be saved
# --------------------------------------------------------------------------
sub _save_index_file {
    my $class = shift;
    
    # Save the object to a file.
    my $OUT = new IO::File;
    $OUT->open( ">$class->{_index}" ) or croak "could not write file $class->{_index}";
    foreach my $report (sort {$a <=> $b} keys %{$class->{_id}}) {
        my $line = sprintf "%-15s %-15s %-15s %-15s $class->{_id}->{$report}->{_name}", $report, $class->{_id}->{$report}->{_start}, $class->{_id}->{$report}->{_alignments}, $class->{_id}->{$report}->{_type};
        $OUT->print("$line\n");
    }
    $OUT->close;
    
    return($class);
}


# --------------------------------------------------------------------------
# L O A D  I N D E X  F I L E  (internal method) 
# ==========================================================================
# USAGE      : BLASTaid->_load_index_file();
# PURPOSE    : Populates an object from a saved index file.
# RETURNS    : none
# PARAMETERS : none
# THROWS     : croaks if index file cannot be opened
#            : croaks if object entries are not complete
#            : croaks if the first entry is not byte position 0
# --------------------------------------------------------------------------
sub _load_index_file {
    my $class = shift;
    
    # Load object from a file.
    my $IN = new IO::File;
    $IN->open( "$class->{_index}" ) or croak "could not open file $class->{_index}";
    while(<$IN>) {
        chomp;
        my ($report, $start, $alignments, $type, $name) = split(/\s+/, $_);
        $class->{_id}->{$report} = {
            _start      => $start,
            _name       => $name,
            _type       => $type,
            _alignments => $alignments,
        };
    }
    
    # Make sure that all entries have needed values. Revise the object
    # to support the query names as unique keys.
    if ($class->{_id}->{1}->{_start} != 0) { croak "check incoming INDEX format" }
    foreach my $report (sort {$a <=> $b} keys %{$class->{_id}}) {
        if (
            !defined $class->{_id}->{$report}->{_name}  ||
            !defined $class->{_id}->{$report}->{_start} ||
            !defined $class->{_id}->{$report}->{_type}
            ) {
            croak "missing QUERY NAME or START or TYPE for entry $report";
        }
        else {
            $class->{_queries}->{_name}->{ $class->{_id}->{$report}->{_name} } = {
                _start      => $class->{_id}->{$report}->{_start},
                _alignments => $class->{_id}->{$report}->{_alignments},
                _type       => $class->{_id}->{$report}->{_type},
            };
        }
    }
    
    return($class);
}


# --------------------------------------------------------------------------
# T Y P E  (accessor method) 
# ==========================================================================
# USAGE      : BLASTaid->type( report => '' )
# PURPOSE    : Returns the BLAST report type.
# RETURNS    : Scalar: BLAST type name.
# PARAMETERS : report => ''
# THROWS     : croaks if report attribute is missing
#            : croaks if type is null in the index onject
# --------------------------------------------------------------------------
sub type {
    my ( $class, %arg ) = @_;
    
    # Do some simple file validation checks.
    if ( !$arg{report} ) { croak "new requires a REPORT value" }   

    # Validation & return:
    if (defined $class->{_queries}->{_name}->{$arg{report}}->{_type}) {
        return( $class->{_queries}->{_name}->{$arg{report}}->{_type} );
    }
    else {
        croak "type is null for report $arg{report}";
    }
    
}


# --------------------------------------------------------------------------
# U N D E F  (accessor method)
# ==========================================================================
# USAGE      : BLASTaid->undef();
# PURPOSE    : Deletes the object.
# RETURNS    : Scalar: BLAST type name.
# PARAMETERS : none
# THROWS     : none
# --------------------------------------------------------------------------
sub undef {
    my $class = shift;
    
    # Delete content from the object.
    undef(%{$class});
    
    return($class);
}

1;  # End of module.

__END__

=head1 NAME

BLASTaid - A simple interface for byte indexing a WU-BLAST multi-part report for faster access.


=head1 VERSION

This document describes BLASTaid version 0.0.3


=head1 SYNOPSIS

    use BLASTaid;
    my $blast  = BLASTaid->new( 
                           report => 'REPORT.blast', 
                           index  => '/tmp/REPORT.index' 
                               );
    my $string = $blast->return_report( 
                         query => 'gi|29294646|ref|NM_024852.2|' 
                                      );
    print $string;
  
=head1 DESCRIPTION

This module was written to aid accessing specific reports from longer, multi part WU-BLAST (http://blast.wustl.edu/) alignments reports. Depending on parameters and starting input, BLAST reports may be several gigabytes in size. Extremely large files can prove to be problematic and rate-limiting in post-process analysis. BLASTaid takes a multi-part BLAST report and creates a byte index. Specific reports may be pulled directly from the larger set by jumping directly to the entry via the byte-index. The index file need only be created one time per BLAST report... the module automatically uses a supplied index file if it already exists. A developer may also loop through every report in the report in a systematic way. Retrieval is always based around QUERY name, as this should be a unique value in the BLAST report. When BLASTaid makes QUERY names, it takes the first section of the BLAST report's "Query=" line before any white space.
Version 0.0.2 saw a revision in index format. The new format was needed to suppport BLAST report parsing via the BLASTaid::Parse module. Version 0.0.1 index files will not work with this version: re-compile the index using this version.

A simple interface script--BLASTaid--has been included in this distribution for command line usage. Run "perldoc BLASTaid" for more information.

=head1 INTERFACE 

The following methods are supported:

=head2 new

new: Class constructor; builds the byte index file for the BLAST report if the supplied --index file does not already exist. Loads the index if the --index file does exist. The --report option is for the path/name of the BALST report.

    my $blast  = BLASTaid->new( 
                           report => 'REPORT.blast', 
                           index  => '/tmp/REPORT.index' 
                               );

=head2 return_report

return_report: Given a supplied QUERY name, return a string representing the query's report. The string retains formatting found in the original report. 

    my $string = $blast->return_report( 
                         query => 'gi|29294646|ref|NM_024852.2|' 
                                      );

=head2 each_report

each_report: Iterator method to walk through all of the queries (reports) in the BLAST report. Each iteration returns a query name for the current report; reports are in the order found in the original BLAST report.

    foreach my $query ( $blast->each_report() ) {
        my $string = $blast->return_report( query => $query );
        print $string;
    }

=head2 type

type: Accessor method to return the BLAST report type as indicated in the BLASTaid index.

    foreach my $query ( $blast->each_report() ) {
        my $type = $blast->type( report => $query );
        print $type;
    }

=head2 undef

undef: Explicitly delete a BLASTaid index object.

    $blast->undef();


=head1 DIAGNOSTICS

A user may encounter messages associated with this module if required method arguments are malformed or missing. Of interest are:

=over

=item C<< no queries found in object >>

[Method each_report found no queries in the object. Did you prime the object with the "new" method first?]

=item C<< return_report cannot locate ... in object >>

[You've requested a query name that is not in the index. Compare the query name you supplied agianst those in the byte index file. They should be identical for BLASTaid to work properly.]

=item C<< ... is a partial report >>

[One of the returned reports is truncated--i.e., there is no terminating "EXIT CODE" line in the BLAST report. Investigate the original BLAST report.]

=item C<< check incoming INDEX format >>

[You've tried to load a byte index file that is corrupt or incorrect. Remove the index file and run BLASTaid again and it will make a new index file.]

=back


=head1 CONFIGURATION AND ENVIRONMENT

BLASTaid requires no configuration files or environment variables. This distribution supplies the perl script "BLASTaid", which is a command line interface for BLASTaid.pm's main functions. The default installation is /usr/bin/. If you are installing on a Windows based system, please manually place the BLASTaid script somewhere in your perl path.


=head1 DEPENDENCIES

This module uses IO::File & IO::Seekable.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported. This module is limited to parsing WU-BLAST style reports--it does not currently support NCBI or other formats.

Please report any bugs or feature requests to
C<bug-blastaid@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 UPDATES

=head2 0.0.2

 -- Version 0.0.1 index files will not work with this version: re-compile the index using this version.
 -- Index order now corresponds to order of queries in the multi-report BLAST file.
 -- ID parse is a little lazier now; previous regex was being to restrictive.
 -- Index output now includes if alignements are in the report (TRUE) or no alignments (FALSE).
 -- Index output now includes type of BLAST per report.
 -- Partial report is no longer restricted to "EXIT CODE 0"; simply requires an EXIT CODE to continue.
 -- The "each_report" method now supports an "ignore" attribute... for ignoring entries without alignments.
 -- Added the following external methods: type; undef.

=head2 0.0.1

 --Inital release to CPAN. Only indexes--no parsing of BLAST reports.

=head1 ACKNOWLEDGMENTS

This module was written by T. Wylie at Washington University School of Medicine's Genome Sequencing Center. It is a small component of a larger code base for the Computational Biology group. Future releases will interact with this module readily. The author wishes to thank fellow CompBio members Jarret Glasscock & David Messina for feedback and support.

=head1 AUTHOR

Todd Wylie  

C<< <perldev@monkeybytes.org> >>  

L<< http://www.monkeybytes.org >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006, Todd Wylie C<< <perldev@monkeybytes.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perlartistic.


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
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=head1 NOTE

This software was written using the latest version of GNU Emacs, the
extensible, real-time text editor. Please see
L<http://www.gnu.org/software/emacs> for more information and download
sources.
