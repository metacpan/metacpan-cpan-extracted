package Bio::AGP::LowLevel;
use strict;
use warnings;
use English;
use Carp;

use File::Basename;
use UNIVERSAL qw/isa/;
use List::Util qw/first/;

=head1 NAME

Bio::AGP::LowLevel - functions for dealing with AGP files

=head1 SYNOPSIS
 

 $lines_arrayref = agp_parse('my_agp_file.agp');

 agp_write( $lines => 'my_agp_file.agp');



=head1 DESCRIPTION

functions for working with AGP files.

=head1 FUNCTIONS

All functions below are EXPORT_OK.

=cut

use base qw/ Exporter /;

our @EXPORT_OK;
BEGIN {
  @EXPORT_OK = qw(
                  agp_parse
                  agp_write
                  agp_format_part
                  agp_contigs                 
                 );
}


=head2 str_in

  Usage: print "it's valid" if str_in($thingy,qw/foo bar baz/);
  Desc : return 1 if the first argument is string equal to at least one of the
         subsequent arguments
  Ret  : 1 or 0
  Args : string to search for, array of strings to search in
  Side Effects: none

  I kept writing this over and over in validation code and got sick of it.

=cut

sub str_in {
  my $needle = shift;
  return defined(first {$needle eq $_} @_) ? 1 : 0;
}

=head2 is_filehandle

  Usage: print "it's a filehandle" if is_filehandle($my_thing);
  Desc : check whether the given thing is usable as a filehandle.
         I put this in a module cause a filehandle might be either
         a GLOB or isa IO::Handle or isa Apache::Upload
  Ret  : true if it is a filehandle, false otherwise
  Args : a single thing
  Side Effects: none

=cut

sub is_filehandle {
  my ($thing) = @_;
  return isa($thing,'IO::Handle') || isa($thing,'Apache::Upload') || ref($thing) eq 'GLOB';
}


=head2 agp_parse

  Usage: my $lines = agp_parse('~/myagp.agp',validate_syntax => 1, validate_identifiers => 1);
  Desc : parse an agp file
  Args : filename or filehandle, hash-style list of options as 
                       validate_syntax => if true, error
                           if there are any syntax errors,
                       validate_identifiers => if true, error
                          if there are any identifiers that
                          CXGN::Tools::Identifiers doesn't recognize
                          IMPLIES validate_syntax
                       error_array => an arrayref.  if given, will push
                          error descriptions onto this array instead of
                          using warn to print them to stderr
  Ret  : undef if error, otherwise return an
         arrayref containing line records, each of which is like:
         { comment => 'text' } if a comment,
         or if a data line:
         {  objname  => the name of the object being assembled
                       (same for every record),
            ostart   => start coordinate for this component (object),
            oend     => end coordinate for this component   (object),
            partnum  => the part number appearing in the 4th column,
            linenum  => the line number in the file,
            type     => letter type present in the file (/[ADFGNOPUW]/),
            typedesc => description of the type, one of:
                         - (A) active_finishing
                         - (D) draft
                         - (F) finished
                         - (G) wgs_finishing
                         - (N) known_gap
                         - (O) other
                         - (P) predraft
                         - (U) unknown_gap
                         - (W) wgs_contig
            ident    => identifier of the component, if any,
            length   => length of the component,
            is_gap   => 1 if the line is some kind of gap, 0 if it
                        is covered by a component,
            gap_type => one of:
                 fragment: gap between two sequence contigs (also
                    called a "sequence gap"),
                 clone: a gap between two clones that do not overlap.
  		 contig: a gap between clone contigs (also called a
  		    "layout gap").
  		 centromere: a gap inserted for the centromere.
  		 short_arm: a gap inserted at the start of an
  		    acrocentric chromosome.
  		 heterochromatin: a gap inserted for an especially
     		    large region of heterochromatic sequence (may also
  		    include the centromere).
  		 telomere: a gap inserted for the telomere.
  		 repeat: an unresolvable repeat.
            cstart   => start coordinate relative to the component,
            cend     => end coordinate relative to the component,
            linkage  => 'yes' or 'no', only set for type of 'N',
            orient   => '+', '-', 0, or 'na'
                        orientation of the component
                        relative to the object,
         }

  Side Effects: unless error_array is given, will print error
                descriptions to STDERR with warn()
  Example:

=cut

sub agp_parse {
  my $agpfile = shift;
  our %opt = @_;

  $agpfile or croak 'must provide an AGP filename';

  if($opt{validate_identifiers}) {
    $opt{validate_syntax} = 1;
  }

  #if the argument is a filehandle, use it, otherwise try to use it as
  #a filename
  my $agp_in; #< filehandle for reading AGP
  our $bn;    #< basename of file we're parsing
  ($agp_in,$bn) = do {
    if( is_filehandle($agpfile) ) {
      ($agpfile,'<AGP>')
    } else {
      open my $f,$agpfile
	or die "$! opening '$agpfile'\n";
      ($f,$agpfile)
    }
  };

  our $parse_error_flag = 0;
  sub parse_error(@) {

    return unless $opt{validate_syntax};

    $parse_error_flag = 1;
    my $errstr = "$bn:$.: ".join('',@_)."\n";
    #if we're pushing errors onto an error_array, do that
    if ($opt{error_array}) {
      push @{$opt{error_array}},$errstr;
    } else { # otherwise just warn
      warn $errstr;
    }
  }

  my @records;

  my $last_end;
  my $last_partnum;
  my $last_objname;

  my $assembled_sequence = '';
  while (my $line = <$agp_in>) {
    no warnings 'uninitialized';
#    warn "parsing $line";
    chomp $line;
    $line =~ s/\r//g; #remove windows \r chars

    #deal with comments
    if($line =~ /#/) {
      if( $line =~ s/^#// ) {
	push @records, { comment => $line };
	next;
      }
      parse_error("not a valid comment line, # must be first character on line");
      next;
    }

    my @fields = split /\t/,$line,10;
    @fields == 9
      or parse_error "This line contains ".scalar(@fields)." columns.  All lines must have 9 columns.";

    #if there just really aren't many columns, this probably isn't a valid AGP line
    next unless @fields >= 5 && @fields <= 10;

    my %r = (linenum => $.); #< the record we're building for this line, starting with line number

    #parse and check the first 5 cols
    @r{qw( objname ostart oend partnum type )} = splice @fields,0,5;
    $r{objname}
      or parse_error "'$r{obj_name}' is a valid object name";
    #end
    if ( defined $last_end && defined $last_objname && $r{objname} eq $last_objname ) {
      $r{ostart} == $last_end+1
	or parse_error "start coordinate not contiguous with previous line's end";
    }
    $last_end = $r{oend};
    $last_objname = $r{objname};

    #start
    $r{oend} >= $r{ostart} or parse_error("end must be >= start");

    #part num
    $last_partnum ||= 0;
    $r{partnum} == $last_partnum + 1
      or parse_error("part numbers not sequential");

    $last_partnum = $r{partnum};

    #type
    if ( $r{type} =~ /^[NU]$/ ) {
      (@r{qw( length gap_type linkage)}, my $empty, my $undefined) = @fields;
      @fields = ();
      my %descmap = qw/ U unknown_gap N known_gap /;
      $r{typedesc} = $descmap{$r{type}}
	or parse_error("unregistered type $r{type}");
      $r{is_gap}   = 1;

      my $gap_size_to_use = $opt{gap_length} || $r{length};

      $r{length} == $r{oend} - $r{ostart} + 1
	or parse_error("gap size of '$r{length}' does not agree with ostart, oend of ($r{ostart},$r{oend})");

      str_in($r{gap_type},qw/fragment clone contig centromere short_arm heterochromatin telomere repeat/)
	or parse_error("invalid gap type '$r{gap_type}'");

      str_in($r{linkage},qw/yes no/)
	or parse_error("linkage (column 8) should be 'yes' or 'no'\n");

      defined $empty && $empty eq ''
	or parse_error("9th column should be present and empty\n");

      push @records,\%r;

  } elsif ( $r{type} =~ /^[ADFGOPW]$/ ) {
      my %descmap = qw/A active_finishing D draft F finished G wgs_finishing N known_gap O other P predraft U unknown_gap W wgs_contig/;
      $r{typedesc} = $descmap{$r{type}}
	or parse_error("unregistered type $r{type}");
      $r{is_gap} = 0;

      @r{qw(ident cstart cend orient)} = @fields;
      if($opt{validate_identifiers}) {
	my $comp_type = identifier_namespace($r{ident})
	  or parse_error("cannot guess type of '$r{ident}'");
      } else {
	$r{ident} or parse_error("invalid identifier '$r{ident}'");
      }

      str_in($r{orient},qw/+ - 0 na/)
	or parse_error("orientation must be one of +,-,0,na");

      $r{cstart} >= 1 && $r{cend} > $r{cstart}
	or parse_error("invalid component start and/or end ($r{cstart},$r{cend})");

      $r{length} = $r{cend}-$r{cstart}+1;

      $r{length} == $r{oend} - $r{ostart} + 1
	or parse_error("distance between object start, end ($r{ostart},$r{oend}) does not agree with distance between component start, end ($r{cstart},$r{cend})");

      push @records, \%r;
    } else {
      parse_error("invalid component type '$r{type}', it should be one of {A D F G N O P U W}");
    }
  }

  return if $parse_error_flag;

  #otherwise, everything was well
  return \@records;
}


=head2 agp_write

  Usage: agp_write($lines,$file);
  Desc : writes a properly formatted AGP file
  Args : arrayref of line records to write, with the line records being
             in the same format as those returned by agp_parse above,
         filename or filehandle to write to,
  Ret :  nothing meaningful

  Side Effects: dies on failure.  if you gave it a filehandle, does
                not close it
  Example:

=cut

sub agp_write {
  my ($lines,$file) = @_;
  $file or confess "must provide file to write to!\n";

  my $out_fh = is_filehandle($file) ? $file
    : do {
      open my $f,">$file" or croak "$! opening '$file' for writing";
      $f
    };

  foreach my $line (@$lines) {
      print $out_fh agp_format_part( $line );
  }

  return;
}

=head2 agp_format_part( $record )

Format a single AGP part line (string terminated with a newline) from
the given record hashref.

=cut

sub agp_format_part {
    my ( $line ) = @_;

    return "#$line->{comment}\n" if $line->{comment};

    #and all other lines
    my @fields = @{$line}{qw(objname ostart oend partnum type)};
    if( $line->{type} =~ /^[NU]$/ ) {
      push @fields, @{$line}{qw(length gap_type linkage)},'';
    } else {
      push @fields, @{$line}{qw(ident cstart cend orient)};
    }

    return join("\t", @fields)."\n";
}


=head2 agp_contigs

  Usage: my @contigs = agp_contigs( agp_parse($agp_filename) );
  Desc : extract and number contigs from a parsed AGP file
  Args : arrayref of AGP lines, like those returned by agp_parse() above
  Ret  : list of contigs, in the same order as they occur in the
         file, formatted as:
            [ agp_line_hashref, agp_line_hashref, ... ],
            [ agp_line_hashref, agp_line_hashref, ... ],
            ...

=cut

sub agp_contigs {
  my $lines = shift;

  my @contigs = ([]);
  foreach my $l (@$lines) {
    next if $l->{comment};
    if( $l->{typedesc} =~ /_gap$/ ) {
      push @contigs,[] if @{$contigs[-1]};
    } else {
      push @{$contigs[-1]},$l;
    }
  }
  pop @contigs if @{$contigs[-1]} == 0;
  return @contigs;
}

=head1 AUTHOR(S)

Robert Buels

Sheena Scroggins

=cut

###
1;#do not remove
###
