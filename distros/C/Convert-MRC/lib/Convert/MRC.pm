#
# This file is part of Convert-MRC
#
# This software is copyright (c) 2013 by Alan K. Melby.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
# MRC to TBX converter
# written June-Nov 2008 by Nathan E. Rasmussen
# Modified 2013 by Nathan G. Glenn

# Example input data follows:

# TEST DATA HERE

package Convert::MRC;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use English qw(-no_match_vars);

use Log::Message::Simple qw (:STD);

#import global constants used in processing
use Convert::MRC::Variables;

# ABSTRACT: CONVERT MRC TO TBX-BASIC
our $VERSION = '4.03'; # VERSION

use open ':encoding(utf8)', ':std';    # incoming/outgoing data will be UTF-8

our @origARGV = @ARGV;
local @ARGV = (q{-}) unless @ARGV;            # if no filenames given, take std input

#use batch() if called as a script
__PACKAGE__->new->batch(@ARGV) unless caller;

#allows us to get some kind of version string during development, when $VERSION is undefined
#($VERSION is inserted by a dzil plugin at build time)
sub _version {
	## no critic (ProhibitNoStrict)
	no strict 'vars';
	return $VERSION || q{??};
}


sub new {
    my ($class) = @_;
    my $self = bless {}, $class;
    $self->_init;
    return $self;
}

sub _init {
    my ($self) = @_;
    $self->input_fh( \*STDIN );
    $self->tbx_fh( \*STDOUT );
    $self->log_fh( \*STDERR );
	return;
}


sub tbx_fh {
	## no critic (RequireBriefOpen)
    my ( $application, $fh ) = @_;
    if ($fh) {
        if ( ref($fh) eq 'GLOB' ) {
            $application->{tbx_fh} = $fh;
        }
        else {
            open my $fh2, '>', $fh or die "Couldn't open $fh";
            $application->{tbx_fh} = $fh2;
        }
    }
    return $application->{tbx_fh};
}


sub log_fh {
	## no critic (RequireBriefOpen)
    my ( $application, $fh ) = @_;
    if ($fh) {
        if ( ref($fh) eq 'GLOB' ) {
            $application->{log_fh} = $fh;
        }
        else {
            open my $fh2, '>', $fh or die "Couldn't open $fh";
            $application->{log_fh} = $fh2;
        }
    }
    return $application->{log_fh};
}

#same thing as Log::Message::Simple::error, but verbose is always off.
sub _error {
    my ($msg) = @_;
    error $msg, 0;
	return;
}

#prints the given message to the current log file handle.
sub _log {
    my ( $self, $message ) = @_;
    print { $self->{log_fh} } $message;
	return;
}


sub input_fh {
	## no critic (RequireBriefOpen)
    my ( $application, $fh ) = @_;
    if ($fh) {
        if ( ref($fh) eq 'GLOB' ) {
            $application->{input_fh} = $fh;
        }
		#emulate diamond operator
		elsif ($fh eq q{-}){
			$application->{input_fh} = \*STDIN;
		}
        else {
            open my $fh2, '<', $fh or die "Couldn't open $fh";
            $application->{input_fh} = $fh2;
        }
    }
    return $application->{input_fh};
}


sub batch {
    my ( $self, @mrc_files ) = @_;
    ## no critic (ProhibitOneArgSelect)
    for my $mrc (@mrc_files) {

        # find an appropriate name for output and warning files
        my $suffix = _get_suffix($mrc);

        #set output, error and input files
        my $outTBX  = "$mrc$suffix.tbx";
        my $outWarn = "$mrc$suffix.log";

        # print STDERR "See $outTBX and $outWarn for output.\n";
        $self->input_fh($mrc);
        $self->log_fh($outWarn);
        $self->tbx_fh($outTBX);

        #convert the input file, sending output to appropriate file handles
        $self->convert;

        # close these so that they are written.
        close $self->log_fh();
        close $self->tbx_fh();

        # close input too, since it's been exhausted.
        close $self->input_fh();

        # print STDERR "Finished processing $mrc.\n";
    }
	return;
}

# return a file suffix to ensure nothing is overwritten
sub _get_suffix {
    my ($file_name) = @_;
    my $suffix = q{};
    $suffix--
      while ( -e "$file_name$suffix.tbx" or -e "$file_name$suffix.log" );
    return $suffix;
}


sub convert {
    ## no critic (ProhibitOneArgSelect)
    my ($self) = @_;
    my $select = select $self->{tbx_fh};

    # informative header for the log file
	my $version = _version();
    msg("MRC2TBX converter version $version");

    #if called as a script, output this
    # if ( not caller ) {
    # msg(    "Called with "
    # . scalar @origARGV
    # . " argument"
    # . ( @origARGV == 1 ? '' : 's' ) . ":\n\t"
    # . ( join "\t", @origARGV ) );
    # }

    # set up per-file status flags
    my %header;    # contains the header information
    my $segment = 'header';    # header, body, back

    # what's open; need to be accessible in all methods
    $self->{concept}        = undef;
    $self->{langSet}        = undef;
    $self->{term}           = undef;
    $self->{party}          = undef;
    $self->{langSetDefined} = 0;

    #array containing all rows for an ID
    $self->{unsortedTerm} = undef;

    my @party;                 # collect all rows for a responsible party
    my %responsible;           # accumulate parties by type
    my ( @idsUsed, @linksMade );    # track these
    my $started = 0;    # flag for MRCTermTable line (start-of-processing)
    my $aborted = 0;    # flag for early end-of-processing
                        # process the file
    while ( readline( $self->{input_fh} ) ) {

        # eliminate a (totally superfluous) byte-order mark
        s/^(?:\xef\xbb\xbf|\x{feff})// if $INPUT_LINE_NUMBER == 1;

       #check for =MRCtermTable at the beginning of the file to begin processing
        if (/^=MRCtermTable/i) {    # start processing
            $started = 1;
            next;
        }
        next unless $started;

        next if (/^\s*$/);          # if it's only whitespace
        my $row;
        next unless $row = $self->_parseRow($_);

        # (if the row won't parse, _parseRow() returns undef)

        # if in header, A row?

        # print STDOUT $segment;
        # print STDOUT Dumper $row;
        # A-row: build header
        if ( $segment eq 'header' && $row->{'ID'} eq 'A' ) {
            $self->_buildHeader( $self->_parseRow($_), \%header )
              or _error "Could not interpret header line $INPUT_LINE_NUMBER, skipped.";
        }

        # not A-row: print header, segment = body
        if ( $segment eq 'header' && $row->{'ID'} ne 'A' ) {

            # better have enough for a header!
            unless ( $self->_printHeader( \%header ) ) {
                _error
"TBX header could not be completed because a required A-row is missing or malformed.";
                $aborted = 1;
                last;
            }
            $segment = 'body';
        }

        # if in body, C row?

        # C-row: lots to do
        if ( $segment eq 'body' && exists $row->{'Concept'} ) {

            # catch a misordered-input problem

            # The next 3 if tests are one action in principle.
            # Each depends on the preceding, and all depend on the
            # closeX() subs being no-ops if it's already closed,
            # and on the fact that nothing follows terms in langSet
            # or follows langSet in termEntry. Meddle not, blah blah.

            {
				## no critic (ProhibitNoWarnings)
                no warnings 'uninitialized';
				## use critic

                # concept, langSet, term might be undef
                # if new concept, close old and open new
                if ( $row->{'Concept'} ne $self->{concept} ) {
                    $self->_closeTerm();
                    $self->_closeLangSet();
                    $self->_closeConcept();

                    # open concept
                    $self->{concept} = $row->{'Concept'};
                    print '<termEntry id="C' . $self->{concept} . "\">\n";

                    # (not row ID, which may go further)
                    push @idsUsed, 'C' . $self->{concept};
                }

                # if new langSet ...
                if ( exists $row->{'LangSet'}
                    && $row->{'LangSet'} ne $self->{langSet} )
                {
                    $self->_closeTerm();
                    $self->_closeLangSet();

                    # open langSet
                    $self->{langSet} = $row->{'LangSet'};
                    print '<langSet xml:lang="' . $self->{langSet} . "\">\n";
                }

                # if new term ...
                if ( exists $row->{'Term'}
                    && $row->{'Term'} ne $self->{term} )
                {
                    $self->_closeTerm();

                    # open term
                    $self->{term} = $row->{'Term'};
                    undef $self->{unsortedTerm};    # redundant
                    push @idsUsed,
                      'C' . $self->{concept} . $self->{langSet} . $self->{term};
                }
            }    # resume warnings on uninitialized values

            # verify legal insertion
            my $level;    # determine where we are from row ID
            if ( defined $row->{'Term'} ) {
                $level = 'Term';
            }
            elsif ( defined $row->{'LangSet'} ) {
                if ( defined $self->{term} ) {
                    _error
                      "LangSet-level row out of order in line $INPUT_LINE_NUMBER, skipped.";
                    next;
                }
                $level = 'LangSet';
            }
            elsif ( defined $row->{'Concept'} ) {
                if ( defined $self->{langSet} ) {
                    _error
                      "Concept-level row out of order in line $INPUT_LINE_NUMBER, skipped.";
                    next;
                }
                $level = 'Concept';
            }
            else {
       #this should never happen; missing level is found when reading the row in
                croak "Can't find level in row $INPUT_LINE_NUMBER, stopped";
            }

            # (can't happen)

            # is the datcat allowed at the level of the ID?
            unless ( $legalIn{$level}{ $row->{'DatCat'} } ) {
                _error
"Data category '$row->{'DatCat'}' not allowed at the $level level in line $INPUT_LINE_NUMBER, skipped.";
                next;
            }

            # set langSetDefined if definition (legal only at langSet level)
            $self->{langSetDefined} = 1 if ( $row->{'DatCat'} eq 'definition' );

            # bookkeeping: record links made
            push @linksMade, $row->{'Link'}->{'Value'}
              if ( defined $row->{'Link'} );

            # print item, or push into pre-tig list, depending
            if ( $level eq 'Term' ) {
                push @{ $self->{unsortedTerm} }, $row;
            }
            else {
                $self->_printRow($row);
            }

        }    # end if (in body, reading C-row)

        # not C-row: close any structures, segment = back
        if ( $segment eq 'body' && !exists $row->{'Concept'} ) {
            $self->_closeTerm();
            $self->_closeLangSet();
            $self->_closeConcept();
            print "</body>\n";
            $segment = 'back';
            print "<back>\n";
        }

        # if in back, R row?
        # R-row: separate parties, verify legality, stack it up
        if ( $segment eq 'back' && exists $row->{'Party'} ) {

            # have we changed parties?
            if ( defined $self->{party} && $row->{'Party'} ne $self->{party} ) {

                # change parties
                my $type;

                # what kind of party is the old one?
                my $topRow = shift @party;
                if ( $topRow->{'DatCat'} eq 'type' ) {
                    $type = $topRow->{'Value'};
                }
                else {
                    unshift @party, $topRow;
                    $type = 'unknown';
                }

                # file its info under its type and clean it out
                push @{ $responsible{$type} }, [@party];
                undef @party;
            }

            # no? OK, add it to the current party.
            $self->{party} = $row->{'Party'};    # the party don't stop!
                 # article says the first row must be type, but we can sort:
            if ( $row->{'DatCat'} eq 'type' ) {
                unshift @party, $row;
            }
            else {
                push @party, $row;
            }
        }    # end if (in back and reading R-row)

        # not R-row: warn file is misordered, last line
        # this code only runs if the A C R order is broken
        if ( $segment eq 'back' && !exists $row->{'Party'} ) {
            _error
"Don't know what to do with line $INPUT_LINE_NUMBER, processing stopped. The rows in your file are not in proper A C R order.";
            $aborted = 1;
            last;
        }

    }    # end while (<$self->input_fh>)

    # finish up

    # if in body, close structures, body
    if ( $segment eq 'body' ) {
        $self->_closeTerm();
        $self->_closeLangSet();
        $self->_closeConcept();
        print "</body>\n";
    }

    # if in back, sort and print parties, close back
    if ( $segment eq 'back' ) {

        # file the last party under its type
        my $type;
        my $topRow = shift @party;
        if ( $topRow->{'DatCat'} eq 'type' ) {
            $type = $topRow->{'Value'};
        }
        else {
            unshift @party, $topRow;
            $type = 'unknown';
        }
        push @{ $responsible{$type} }, [@party];

        # print a refObjectList for each type of party,
        # within which each arrayref gets noted and _printRow()ed.
        if ( exists $responsible{'person'} ) {
            print "<refObjectList type=\"respPerson\">\n";
            push @idsUsed, $_->[0]->{'ID'} foreach @{ $responsible{'person'} };
            $self->_printRow($_) foreach @{ $responsible{'person'} };
            print "</refObjectList>\n";
        }
        if ( exists $responsible{'organization'} ) {
            print "<refObjectList type=\"respOrg\">\n";
            push @idsUsed, $_->[0]->{'ID'}
              foreach @{ $responsible{'organization'} };
            $self->_printRow($_) foreach @{ $responsible{'organization'} };
            print "</refObjectList>\n";
        }
        if ( exists $responsible{'unknown'} ) {
            _error
"At least one of your responsible parties has no type (person, organization, etc.) and has been provisionally printed as a respParty. To conform to TBX-Basic, you must list each party as either a person or an organization.";
            print "<refObjectList type=\"respParty\">\n";
            push @idsUsed, $_->[0]->{'ID'} foreach @{ $responsible{'unknown'} };
            $self->_printRow($_) foreach @{ $responsible{'unknown'} };
            print "</refObjectList>\n";
        }
        print "</back>\n";
    }

    # closing formalities
    if ( not $started ) {
        my $err =
"The input MRC is missing a line beginning with =MRCTermTable. You must include such a line to switch on the TBX converter -- all preceding material is ignored.";

        carp $err;
        _error $err;

        $self->_finish_processing($select);
        return;
    }

    #in case the file was header only
    if ( $segment eq 'header' and not $aborted ) {

        #check and print header
        unless ( $self->_printHeader( \%header ) ) {
            _error
"TBX header could not be completed because a required A-row is missing or malformed.";
            $aborted = 1;
        }

        #alert user to lack of content
        _error('The file contained no concepts or parties.');

        #close the opened, and empty, body element
        print "</body>\n";
    }

    if ($aborted) {
        carp "See log -- processing could not be completed.\n";
        $self->_finish_processing($select);
        return;
    }

    print "</text>\n</martif>\n";
    msg( "File includes links to:\n\t" . ( join "\n\t", @linksMade ) )
      if @linksMade;

    msg "File includes IDs:\n\t" . ( join "\n\t", @idsUsed )
      if @idsUsed;

    # TODO: is this necessary? also look for tbx_fh and input_fh
    # next open would close implicitly but not reset $INPUT_LINE_NUMBER
    $self->_finish_processing($select);
    return;
}

sub _finish_processing {
	## no critic (ProhibitOneArgSelect)
    my ( $self, $select ) = @_;

    #clear all processing data
    delete $self->{concept};
    delete $self->{langSet};
    delete $self->{term};
    delete $self->{party};
    delete $self->{unsortedTerm};
    delete $self->{party};
    delete $self->{langSetDefined};

    #print all messages to the object's log
    $self->_log( Log::Message::Simple->stack_as_string() );
    Log::Message::Simple->flush();

    select $select;

    # user's responsibility to close the various filehandles
	return;
}


# do nothing if no term level is open
sub _closeTerm {
    my ($self) = @_;
    if ( defined $self->{term} ) {

        # print STDOUT Dumper $self->{unsortedTerm} ;
        # print STDOUT Dumper $self;
        my $id = ${ $self->{unsortedTerm} }[0]->{'ID'} ||

          #necessary for error reporting; $ID might be undef
          'C' . $self->{concept} . $self->{langSet} . $self->{term};
        my $tig        = $self->_sortRefs( @{ $self->{unsortedTerm} } );
        my $posContext = pop @$tig;
        unless ( $posContext || $self->{langSetDefined} ) {
            _error
"Term $id (see line @{[$INPUT_LINE_NUMBER - 1]}) is lacking an element necessary for TBX-Basic.\n\tTo make it valid for human use only, add one of:\n\t\ta definition (at the language level)\n\t\tan example of use in context (at the term level).\n\tTo make it valid for human or machine processing, add its part of speech (at the term level).";
        }
        $self->_printRow($tig);
        undef $self->{term};
        undef $self->{unsortedTerm};
    }
	return;
}

# nothing if no lang level is open
sub _closeLangSet {
    my ($self) = @_;
    if ( defined $self->{langSet} ) {
        print "</langSet>\n";
        undef $self->{langSet};
        undef $self->{langSetDefined};
    }
	return;
}

# nothing if no concept level is open
sub _closeConcept {
    my ($self) = @_;
    if ( defined $self->{concept} ) {
        print "</termEntry>\n";
        undef $self->{concept};
    }
	return;
}


my $NUM_MONTHS = 12;
sub _parseRow {
    my ( $self, $row_text ) = @_;
    $row_text =~ s/\s*$//; # super-chomp: cut off any trailing whitespace at all
         # later, split will eliminate between-field whitespace
         # and the keyword and langtag parsers will eliminate other space
         # outside of values

    # fields are delimited by at least one tab and possibly spaces
    my @field = split / *(?:\t *)+/, $row_text;

    # grab the three mandatory fields
    my %row;
    $row{'ID'}     = shift @field;
    $row{'DatCat'} = shift @field;
    $row{'Value'}  = shift @field;

    # verify essential completeness
    unless ( $row{'ID'} && $row{'DatCat'} && $row{'Value'} ) {
        _error "Incomplete row in line $INPUT_LINE_NUMBER, skipped.";
        return;
    }

    # verify well-formed ID and extract its semantics
    if ( $row{'ID'} =~ /^[Cc] *(\d{3}) *($langCode)? *(\d*)$/ ) {
        if ( $3 && !$2 ) {
            _error
              "Bad ID '$row{'ID'}' (no language section) in line $INPUT_LINE_NUMBER, skipped.";
            return;
        }
        $row{'Concept'} = $1;
        $row{'LangSet'} = "\L$2" if ($2);               # smash to lowercase
        $row{'Term'}    = 0 + $3 if ( $2 && $3 ne q{} ); # cast to int
                                                        # clean up the ID itself
        $row{'ID'}      = "C$row{'Concept'}";
        $row{'ID'} .= $row{'LangSet'} if $row{'LangSet'};
        $row{'ID'} .= $row{'Term'} if defined $row{'Term'};
    }
    elsif ( $row{'ID'} =~ /^[Rr] *(\d{3})$/ ) {
        $row{'Party'} = $1;
        $row{'ID'}    = "R$1";
    }
    elsif ( $row{'ID'} =~ /^[Aa]$/ ) {

        # this is a header line and okey-dokey
        $row{'ID'} = 'A';
    }
    else {
        _error
          "Bad ID '$row{'ID'}' (format not recognized) in line $INPUT_LINE_NUMBER, skipped.";
        return;
    }

    # correct case of the datcat, or warn and skip if can't match
    if ( my $correct = $correctCaps{'DatCat'}{ lc( $row{'DatCat'} ) } ) {

        # the datcat is recognized
        unless ( $row{'DatCat'} eq $correct ) {
            _error "Correcting '$row{'DatCat'}' to '$correct' in line $INPUT_LINE_NUMBER.";
            $row{'DatCat'} = $correct;
        }
    }
    else {
        _error "Unknown data category '$row{'DatCat'}' in line $INPUT_LINE_NUMBER, skipped.";
        return;
    }

    # parse off any local language override in Value
    if ( $row{'Value'} =~ /^\[($langCode)] *(.*)$/ ) {
        $row{'RowLang'} = " xml:lang=\"\L$1\"";    # lower case
        $row{'Value'}   = $2;
    }    # otherwise RowLang will (warn and) print nothing when asked

    # check certain Values against picklists and case-correct
    if ( $row{'DatCat'} eq 'termLocation' ) {
        if ( my $correct = $correctCaps{'termLocation'}{ lc( $row{'Value'} ) } )
        {
            # the value is a recognized termLocation
            unless ( $row{'Value'} eq $correct ) {
                _error "Correcting '$row{'Value'}' to '$correct' in line $INPUT_LINE_NUMBER.";
                $row{'Value'} = $correct;
            }
        }
        else {
            _error
"Unfamiliar termLocation '$row{'Value'}' in line $INPUT_LINE_NUMBER. If this is a location in a user interface, consult the suggested values in the TBX spec.";

            # but DON'T return undef, because this should not
            # lead to skipping the row, unlike other picklists
        }
    }
    elsif ( $correctCaps{ $row{'DatCat'} } ) {
        my %caps = %{ $correctCaps{ $row{'DatCat'} } };

        # grab a correction hash appropriate to DatCat,
        # if one exists
        if ( my $correct = $caps{ lc( $row{'Value'} ) } ) {
            unless ( $row{'Value'} eq $correct ) {
                _error "Correcting '$row{'Value'}' to '$correct' in line $INPUT_LINE_NUMBER.";
                $row{'Value'} = $correct;
            }
        }
        else {
            _error
"'$row{'Value'}' not a valid $row{'DatCat'} in line $INPUT_LINE_NUMBER, skipped. See picklist for valid values.";
            return;
        }
    }    # else it's not a correctible datcat, so let it be

    # get additional fields and language tags off of the row
    # forcing the keyword to one initial cap and prewriting the XMLattr
    foreach (@field) {
        my $keyword;
        if (/^([^:]+): *(?:\[($langCode)])? *(.+)$/) {
            $keyword = "\u\L$1";
            $row{$keyword}{'Value'} = $3;
            $row{$keyword}{'FieldLang'} = " xml:lang=\"\L$2\"" if $2;
        }
        else {
            _error "Can't parse additional field '$_' in line $INPUT_LINE_NUMBER, ignored.";
            next;
        }

        # check if a FieldLang makes sense
        if ( $row{$keyword}{'FieldLang'} && !$allowed{$keyword}{'FieldLang'} ) {
            _error
"Language tag makes no sense with keyword '$keyword' in line $INPUT_LINE_NUMBER, ignored.";
            delete $row{$keyword}{'FieldLang'};
        }

        # check if this datcat can have this keyword
        # this bit might be better done in the controller?
        # heh. Too late now.
        unless ( $allowed{ $row{'DatCat'} }{$keyword} ) {
            _error
"Data category $row{'DatCat'} does not allow keyword '$keyword', ignored in line $INPUT_LINE_NUMBER.";
            if ( $keyword eq 'Source' or $keyword eq 'Note' ) {
                _error
"You may attach a source or note to an entire term entry (or a language section or concept entry) by placing it on its own line with the appropriate ID, like this: \n\t$row{ 'ID' }\t\l$keyword\t$row{ $keyword }{ 'Value' }";
            }
            delete $row{$keyword};
        }
    }
    # check for malformed Date
    if ( $row{'Date'} ) {
        if ( $row{'Date'}{'Value'} =~ /^(\d{4})-(\d{2})-(\d{2})$/ ) {
            if ( $1 eq '0000' || $2 eq '00' || $3 eq '00' ) {
                _error
"Consider correcting: Zeroes in date '$row{'Date'}{'Value'}', line $INPUT_LINE_NUMBER.";
            }
            elsif ( $2 <= $NUM_MONTHS && $3 <= $NUM_MONTHS ) {
                _error
"Consider double-checking: Month and day are ambiguous in '$row{'Date'}{'Value'}', line $INPUT_LINE_NUMBER.";
            }
            elsif ( $2 > $NUM_MONTHS ) {
                _error "Consider correcting: Month $2 is nonsense in line $INPUT_LINE_NUMBER.";
            }
        }
        else {
            _error
"Date '$row{'Date'}{'Value'}' not in ISO format (yyyy-mm-dd) in line $INPUT_LINE_NUMBER, ignored.";
            delete $row{'Date'};
        }
    }

    # check for Link where it's needed
    if ( $row{'DatCat'} eq 'transactionType' ) {
        _error
          "Consider adding information: No responsible party linked in line $INPUT_LINE_NUMBER."
          unless $row{'Link'};
    }
    elsif (
        $row{'DatCat'} =~ /^(?:crossReference|externalCrossReference|xGraphic)$/
        && !$row{'Link'} )
    {
        _error "$row{'DatCat'} without Link in line $INPUT_LINE_NUMBER, skipped.";
        return;
    }

    return \%row;
}

sub _buildHeader {
    my ( $self, $srcRef, $destRef ) = @_;
    my $destKey;
    return unless ( $destKey = $corresp{ $srcRef->{'DatCat'} } );

# print STDOUT "$destKey\n" . Dumper ($destRef) . "\n" . Dumper ($srcRef) . "\n";
# a validity check, not just a pointless translation
    if ( $destKey eq 'Language' and defined $destRef->{'Language'} ) {
        _error "Duplicate workingLanguage ignored in line $INPUT_LINE_NUMBER.";
        return;
    }
    push @{ $destRef->{$destKey} }, $srcRef->{'Value'};
    return 1;
}

sub _printHeader {
    my ( $self, $info ) = @_;

    # my $info = %{shift}; # that's a copy, but the hash is small
    return unless ( defined $info->{'Language'} && defined $info->{'Source'} );
    print <<"REQUIRED1";
<?xml version='1.0' encoding="UTF-8"?>
<!DOCTYPE martif SYSTEM "TBXBasiccoreStructV02.dtd">
<martif type="TBX-Basic-V1" xml:lang="$$info{'Language'}[0]">
<martifHeader>
<fileDesc>
<titleStmt>
<title>termbase from MRC file</title>
REQUIRED1

    # print termbase-wide subjects, if such there be
    _error
"Termbase-wide subject fields are recorded in the <titleStmt> element of the TBX header."
      if ( exists $info->{'Subject'} and scalar @{ $info->{'Subject'} } );
    my $sbj;
    print <<"SUBJECT" while $sbj = shift @{ $info->{'Subject'} };
<note>entire termbase concerns subject: $sbj</note>
SUBJECT
	my $version = _version();
    print <<"REQUIRED2";
</titleStmt>
<sourceDesc>
<p>generated by Convert::MRC version $version</p>
</sourceDesc>
REQUIRED2
    while ( my $src = shift @{ $info->{'Source'} } ) {
        print <<"SOURCE";
<sourceDesc>
<p>$src</p>
</sourceDesc>
SOURCE
    }

    print <<'REQUIRED3';
</fileDesc>
<encodingDesc>
<p type="DCSName">TBXBasicXCSV02.xcs</p>
REQUIRED3

    #	my $sbj;
    #	print <<SUBJECT while $sbj = shift @{$info->{'Subject'}};
    #<p type="subjectField">$sbj</p>
    #SUBJECT

    print <<'REQUIRED3';
</encodingDesc>
</martifHeader>
<text>
<body>
REQUIRED3

	return 1;
}

# structure a term's worth of data rows for printing
sub _sortRefs {## no critic (RequireArgUnpacking)
    my ( $self, @rows ) = @_;
    my ( @termGrp, @auxInfo, $term, $pos, $context, $ID );

    $ID = $_[0]->{'ID'}

#this is necessary for printing diagnostics when something has gone wrong ($ID would be undef otherwise)
      || 'C' . $self->{concept} . $self->{langSet} . $self->{term};

    # print STDOUT Dumper $_[0];
    # print STDOUT Dumper \@rows;
    # print STDOUT Dumper $self;
    for my $row (@rows) {
        if ( not defined $row->{'DatCat'} ) {

            #this should never happen; it should be caught during row parsing.
            next;
        }
        my $datCat = $row->{'DatCat'};
        if ( $datCat eq 'term' ) {
            unshift @termGrp, $row;    # stick it on the front
            $term = 1;
        }
        elsif ( my $position = $position{$datCat} ) {
            if ( 'termGrp' eq $position ) {
                push @termGrp, $row;    # stick it on the back
                $pos = 1 if $datCat eq 'partOfSpeech';
            }
            elsif ( 'auxInfo' eq $position ) {
                push @auxInfo, $row;
                $context = 1 if $datCat eq 'context';
            }
        }
        else {
            #should never happen; should be caught during row parsing
            _error "Data category '$datCat' is not allowed at the term level.";
        }
    }

    if ( not $term ) {
        _error
"There is no term row for '$ID', although other data categories describe such a term. See line @{[$INPUT_LINE_NUMBER - 1]}.";
    }

    if ( not $pos ) {
        _error
"Term $ID lacks a partOfSpeech row. This TBX file may not be machine processed. See line @{[$INPUT_LINE_NUMBER - 1]}.";
    }

    unshift @auxInfo, \@termGrp;
    push @auxInfo, ( $pos || $context );    # 1 or undef
    return \@auxInfo;
}

sub _printRow {
    my ( $self, $item ) = @_;
	## no critic (ProhibitNoWarnings)
    no warnings 'uninitialized';            # for undefined language attributes
	## use critic
    if ( ref $item eq 'HASH' ) {            # printing a single item
                                            # print as appropriate
        my $datCat;
        $datCat = $item->{'DatCat'};
        if ( not defined $datCat ) {

            #should never happen; rows with undefined datcats are skipped.
            _error "Data category undefined. Cannot print row at $INPUT_LINE_NUMBER";
            return;
        }

        # sort by datcat
        if ( $datCat eq 'term' ) {
            print "<term>$item->{'Value'}</term>\n";

            # we deliberately ignore RowLang, because LangSet
            # should give the language of a term entry
        }

        # note and source as standalones, not keyword-fields
        elsif ( $datCat eq 'note' ) {
            print "<note$item->{'RowLang'}>$item->{'Value'}</note>\n";
        }

        elsif ( $datCat =~ /^(?:source|customerSubset|projectSubset)$/ ) {
            print
"<admin type=\"$datCat\"$item->{'RowLang'}>$item->{'Value'}</admin>\n";
        }

        # sorry this one's so gross, but it is
        elsif ( $datCat eq 'transactionType' ) {
            print "<transacGrp>\n";
            print
"\t<transac type=\"transactionType\">$item->{'Value'}</transac>\n";
            print "\t<date>$item->{'Date'}->{'Value'}</date>\n"
              if $item->{'Date'};

            #I don't think Note is allowed in transationType (Nate G)
            print
"\t<note$item->{'Note'}->{'FieldLang'}>$item->{'Note'}->{'Value'}</note>\n"
              if $item->{'Note'};
            if ( $item->{'Responsibility'} || $item->{'Link'} ) {
                print "\t<transacNote type=\"responsibility\"";
                print " target=\"$item->{'Link'}->{'Value'}\""
                  if $item->{'Link'};
                print
"$item->{'Responsibility'}->{'FieldLang'}>$item->{'Responsibility'}->{'Value'}";
                print "Responsible Party"
                  unless $item->{'Responsibility'}->{'Value'};
                print "</transacNote>\n";
            }
            print "</transacGrp>\n";
        }

        elsif ( $datCat eq 'crossReference' ) {
            print
"<ref type=\"crossReference\" target=\"$item->{'Link'}->{'Value'}\"$item->{'RowLang'}>$item->{'Value'}</ref>\n";
        }

        elsif ($datCat eq 'externalCrossReference'
            || $datCat eq 'xGraphic' )
        {
            print
"<xref type=\"$datCat\" target=\"$item->{'Link'}->{'Value'}\"$item->{'RowLang'}>$item->{'Value'}</xref>\n";
        }

        elsif ( $datCat =~ /^(?:email|title|role|org|uid|tel|adr|fn)$/ ) {
            print "\t<item type=\"$datCat\">$item->{'Value'}</item>\n";

            # RowLang is ignored here too -- attr not allowed
        }

        elsif ( $meta{$datCat} eq 'termNote' ) {
            print
"<termNote type=\"$datCat\"$item->{'RowLang'}>$item->{'Value'}</termNote>\n"
              ;    # using tigs means no termNoteGrp
        }

        else {     # everything else is easy
            my $meta;
            $meta = $meta{$datCat}
              or die "_printRow() can't print a $datCat ";    # shouldn't happen
            print "<${meta}Grp>\n";
            print
"\t<$meta type=\"$datCat\"$item->{'RowLang'}>$item->{'Value'}</$meta>\n";

            #I don't think Note is allowed in transationType (Nate G)
            print
"\t<note$item->{'Note'}->{'FieldLang'}>$item->{'Note'}->{'Value'}</note>\n"
              if $item->{'Note'};
            print
"\t<admin type=\"source\"$item->{'Source'}->{'FieldLang'}>$item->{'Source'}->{'Value'}</admin>\n"
              if $item->{'Source'};
            print "</${meta}Grp>\n";
        }

    }
    elsif ( ref $item eq 'ARRAY' ) {

        # if first item isn't arrayref, it's a resp-party
        if ( ref $item->[0] ne 'ARRAY' ) {
            print "<refObject id=\"$item->[0]->{'ID'}\">\n";
            $self->_printRow($_) foreach @$item;
            print "</refObject>\n";
        }
        else {
            # then it's a tig
            my $termGrp = shift @$item;
            my $id;
            if ( exists $termGrp->[0] ) {

                # if there's a term or any termNote
                $id = $termGrp->[0]->{'ID'};
            }
            else {
                #should never happen (right? Nate G)
                # if must, get the ID from an auxInfo
                # (implies the input is defective)
                $id = $item->[0]->{'ID'};
            }
            print "<tig id=\"$id\">\n";

            # <termGrp> if this were an ntig
            $self->_printRow($_) foreach @$termGrp;

            # </termGrp>
            $self->_printRow($_) foreach @$item;
            print "</tig>\n";
        }
    }
    else {
        #this should never happen
        die "_printRow() called incorrectly, stopped";
    }
	return;
}

1;

__END__

=pod

=head1 NAME

Convert::MRC - CONVERT MRC TO TBX-BASIC

=head1 VERSION

version 4.03

=head1 SYNOPSIS

	use strict;
	use warnings;

	my $converter = Convert::MRC->new;
	$converter->input_fh('/path/to/MRC/file.mrc');
	$converter->tbx_fh('/path/to/output/file.tbx');
	$converter->log_fh('/path/to/log/file.log');
	$converter->convert;

=head1 DESCRIPTION

=head2 MRC

The MRC format is fully described in an article by Alan K. Melby which
appeared in
L<Tradumatica|http://www.ttt.org/tbx/AKMtradumaArticle-publishedVersion.pdf>.
At an approximation, it is a file of tab-separated rows, each consisting
of an ID, a data category, and a value
to be stored for that category in the object with the given ID. The file
should be sorted on its first column. If it is not, the converter may
skip rows (if they are at too high a level) or end processing early
(if the order of A-rows, C-rows, and R-rows is broken).

=head2 CONVERSION TO TBX-BASIC

This translator receives a file or list of files in this format and
emits TBX-Basic, a standard format for terminology interchange.
Incorrect or unusable input is skipped, with one exception, and the
problem is noted in a log file. The outputs generally have the same
filename as the inputs, and a suffix of .tbx and .warnings, but a number
may be added to the filename to ensure the output filenames are unique.

The exception noted is this: If the user documents a party responsible
for some change in the termbase, but does not state whether that party
is a person or an organization, the party will be included in the TBX
as a "respParty". This designation does not conform to the TBX-Basic
standard and will need to be changed (to "respPerson" or "respOrg")
before the file will validate. This is one of the circumstances in which
the converter will output invalid TBX-Basic.

The other circumstance is that a file might not contain a definition,
a part of speech, or a context sentence for some term, or might not
contain a term itself. The converter detects these and warns about them,
but there is no way it could fix them. It does not detect or warn about
concepts containing no langSet or langSets containing no term, but these
are also invalid.

=head1 NAME

Convert::MRC- Perl extension for converting MRC files into TBX-Basic.

=head1 METHODS

=head2 C<new>

Creates and returns a new instance of Convert::MRC.

=head2 C<tbx_fh>

Optional argument: string file path or GLOB

Sets and/or returns the file handle used to print the converted TBX.

=head2 C<log_fh>

Optional argument: string file path or GLOB

Sets and/or returns the file handle used to log any messages.

=head2 C<input_fh>

Optional argument: string file path or GLOB; '-' means STDIN

Sets and/or returns the file handle used to read the MRC data from.

=head2 C<batch>

Processes each of the input files, printing the converted TBX file to a file with the same name and the suffix ".tbx".
Warnings are also printed to a file with the same name and the suffix ".log".

=head2 C<convert>

Converts the input MRC data into TBX-Basic:

=over 2

=item * Reading MRC data from L</input_fh>

=item * Printing TBX-Basic data to L</tbx_fh>

=item * Logging messages to L</log_fh>

=back

=head1 SEE ALSO

=over 2

=item * The homepage for this program is located L<here|http://tbxconvert.gevterm.net/mrc2tbx/index.html>. You can use it online
(one file at a time), and can also view a tutorial about MRC files.

=item * A more in-depth look at MRC can be found L<in this article|http://www.ttt.org/tbx/AKMtradumaArticle-publishedVersion.pdf>.

=item * General TBX iformation can be found L<here|http://www.ttt.org/tbx>.

=back

=head1 AUTHOR

Nathan Rasmussen, Nathan Glenn <garfieldnate@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Alan K. Melby.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
