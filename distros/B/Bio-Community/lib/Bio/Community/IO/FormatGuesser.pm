# BioPerl module for Bio::Community::IO::FormatGuesser
#
# Please direct questions and support issues to <bioperl-l@bioperl.org>
#
# Copyright 2011-2014 Florent Angly <florent.angly@gmail.com>
#
# You may distribute this module under the same terms as perl itself


=head1 NAME

Bio::Community::IO::FormatGuesser - Determine the format used by a community file

=head1 SYNOPSIS

  use Bio::Community::IO::FormatGuesser;

  my $guesser = Bio::Community::IO::FormatGuesser->new(
     -file => 'file.txt',
  );
  my $format = $guesser->guess;

=head1 DESCRIPTION

Given a file containing one or several communities, try to guess the file format
used by examining the file content (not by looking at the file name).

The guess() method will examine the data, line by line, until it finds a line
that is specific to a format. If no conclusive guess can be made, undef is returned.

If the Bio::Community::IO::FormatGuesser object is given a filehandle which is
seekable, it will be restored to its original position on return from the
guess() method.

=head2 Formats

The following formats are currently supported:

=over

=item *

generic (tab-delimited matrix, site-by-species table, QIIME summarized OTU tables, ...)

=item *

gaas

=item *

qiime

=item *

unifrac

=item *

biom

=back

See the documentation for the corresponding IO drivers to read and write these
formats in the Bio::Community::IO::* namespace.

=head1 AUTHOR

Florent Angly L<florent.angly@gmail.com>

This module was inspired and based on the Bio::IO::GuessSeqFormat module written
by Andreas Kähäri <andreas.kahari@ebi.ac.uk> and contributors. Thanks to them!

=head1 SUPPORT AND BUGS

User feedback is an integral part of the evolution of this and other Bioperl
modules. Please direct usage questions or support issues to the mailing list, 
L<bioperl-l@bioperl.org>, rather than to the module maintainer directly. Many
experienced and reponsive experts will be able look at the problem and quickly 
address it. Please include a thorough description of the problem with code and
data examples if at all possible.

If you have found a bug, please report it on the BioPerl bug tracking system
to help us keep track the bugs and their resolution:
L<https://redmine.open-bio.org/projects/bioperl/>

=head1 COPYRIGHT

Copyright 2011-2014 by Florent Angly <florent.angly@gmail.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=head2 new

 Function: Create a new Bio::Community::IO::FormatGuesser object
 Usage   : my $guesser = Bio::Community::IO::FormatGuesser->new( );
 Args    : -text, -file or -fh. If more than one of these arguments was
           provided, only one is used: -text has precendence over -file, which
           has precedence over -fh.
 Returns : a new Bio::Community::IO::FormatGuesser object

=cut


package Bio::Community::IO::FormatGuesser;

use Moose;
use MooseX::NonMoose;
use MooseX::StrictConstructor;
use Method::Signatures;
use namespace::autoclean;

extends 'Bio::Root::Root';


my %formats = (
   biom    => \&_possibly_biom    ,
   gaas    => \&_possibly_gaas    ,
   unifrac => \&_possibly_unifrac ,
   generic => \&_possibly_generic ,
   qiime   => \&_possibly_qiime   ,
);

my $real_re = qr/^(?:(?i)(?:[+-]?)(?:(?=[.]?[0123456789])(?:[0123456789]*)(?:(?:[.])(?:[0123456789]{0,}))?)(?:(?:[E])(?:(?:[+-]?)(?:[0123456789]+))|))$/;
# regular expression to match a real number, taken from Regexp::Common

=head2 file

 Usage   : my $file = $guesser->file;
 Function: Get or set the file from which to guess the format
 Args    : file path (string)
 Returns : file path (string)

=cut

has 'file' => (
   is => 'rw',
   isa => 'Str',
   required => 0,
   lazy => 1,
   default => undef,
   init_arg => '-file',
   predicate => '_has_file',
);


=head2 fh

 Usage   : my $fh = $guesser->fh;
 Function: Get or set the file handle from which to guess the format. 
 Args    : file handle
 Returns : file handle

=cut

has 'fh' => (
   is => 'rw',
   isa => 'FileHandle',
   required => 0,
   lazy => 1,
   default => undef,
   init_arg => '-fh',
   predicate => '_has_fh',
);


=head2 text

 Usage   : my $text = $guesser->text;
 Function: Get or set the text from which to guess the format. In most, if not
           all cases, the first few lines of a text string should be enough to
           determine the format.
 Args    : text string
 Returns : text string

=cut

has 'text' => (
   is => 'rw',
   isa => 'Str',
   required => 0,
   lazy => 1,
   default => undef,
   init_arg => '-text',
   predicate => '_has_text',
);


=head2 guess

 Function: Guess the file format
 Usage   : my $format = $guesser->guess;
 Args    : format string (e.g. generic, qiime, etc)
 Returns : format string (e.g. generic, qiime, etc)

=cut

method guess () {
   my $format;

   # Prepare input
   my ($in, $original_pos);
   {
      ####local $Bio::Root::IO::HAS_EOL = 1; # Need Bioperl-dev (>1.6.922) for this to work
      if ($self->_has_text) {
         $in = Bio::Root::IO->new(-string => $self->text);
      } elsif ($self->_has_file) {
         $in = Bio::Root::IO->new(-file => $self->file);
      } elsif ($self->_has_fh) {
         $original_pos = tell($self->fh);
         $in = Bio::Root::IO->new(-fh => $self->fh, -noclose => 1);
      } else {
         $self->throw('Need to provide -file, -fh or -text');
      }
   }

   # Read lines and try to attribute format
   my %test_formats = %formats;
   my %ok_formats;
   my $line_num = 0;
   while ( defined(my $line = $in->_readline) ) {

      # Read next line (and convert line endings). Exit if no lines left.
      $line_num++;
      chomp $line;

      # Skip white and empty lines.
      next if $line =~ /^\s*$/;

      # Split fields
      my @fields = split /\t/, $line;

      # Try all formats remaining
      %ok_formats = ();
      my ($test_format, $test_function);
      while ( ($test_format, $test_function) = each (%test_formats) ) {
         my $score = &$test_function(\@fields, $line, $line_num);
         if ( $score == 2 ) {
            # This line is specific of this format
            %ok_formats = ( $test_format => undef );
            last;
         } elsif ($score == 1) {
            # Line is possibly in this format
            $ok_formats{$test_format} = undef;
         } else {
            # Do not try to match this format with upcoming lines
            delete $test_formats{$test_format};
         }
      }

      # Exit if there was a match to only one format
      if (scalar keys %ok_formats == 1) {
         last;
      }

      # Exit if no formats left to try
      if (scalar keys %test_formats == 0) {
         last;
      }

      # Give up after having tested 100 lines
      if ($line_num >= 100) {
         last;
      }

   }

   # If several formats matched. Assume 'generic' if possible, undef otherwise
   if (scalar keys %ok_formats > 1) {
      for my $ok_format (keys %ok_formats) {
         if (not $ok_format eq 'generic') {
            delete $ok_formats{$ok_format};
         }
      }
   }

   if (scalar keys %ok_formats == 1) {
      $format = (keys %ok_formats)[0];
   }

   # Cleanup
   if ($in->noclose) {
      # Reset filehandle cursor to original location
      seek($self->fh, $original_pos, 0)
         or $self->throw("Could not reset the cursor to its original position: $!");
   }
   $in->close;

   return $format;
}


#-----  Format-specific methods -----#
# These methods return:
#    1 is the given line is possibly in this format
#    2 if they are sure


func _possibly_biom ($fields, $line, $line_num) {
   # Example:
   # {
   #  "id":null,
   #  "format": "Biological Observation Matrix 0.9.1-dev",
   #  "format_url": "http://biom-format.org",
   #  ...
   my $ok = 0;
   if ($line_num == 1) {
      if ($line =~ m/^{/) {
         $ok = 1;
      }
   } else {
      if ( ($line =~ m/"\S+":/) || 
           ($line =~ m/Biological Observation Matrix/) ) {
         $ok = 2; # biom for sure
      }
   }
   return $ok;
}


func _possibly_generic ($fields, $line, $line_num) {
   # Example:
   #   Species	gut	soda lake
   #   Streptococcus	241	334
   #   ...
   # Columns from the second to the last must contain numbers.
   my $ok = 0;
   my $num_fields = scalar @$fields;
   if ($num_fields >= 2) {
      if ($line_num == 1) {
        $ok = 1;
      } else {
         for my $i (1 .. $num_fields - 1) {
            if ($fields->[$i] =~ $real_re) {
               $ok = 1;
            } else {
               $ok = 0;
               last;
            }
         }
      }
   }
   return $ok;
}


func _possibly_gaas ($fields, $line, $line_num) {
   # Example:
   #    # tax_name	tax_id	rel_abund
   #    Streptococcus pyogenes phage 315.1	198538	0.791035649011735
   # or:
   #    # sequence_name	sequence_id	relative_abundance_%
   #    Milk vetch dwarf virus segment 9, complete sequence	gi|20177473|ref|NC_003646.1|	42.6354640657824	
   # First field contains string, second field an ID, third field a number.
   my $ok = 0;
   my $num_fields = scalar @$fields;
   if ($num_fields == 3) {
      if ($line_num == 1) {
        if ($line =~ m/^#\s*.+name.+id.+abund.*$/) {
           $ok = 2; # gaas for sure
         }
      } else {
        if ($line !~ m/^#/) {
           $ok = 1;
        } else {
           if ($fields->[-1] =~ $real_re) {
              $ok = 1;
           }
        }
      }
   }
   return $ok;
}


func _possibly_unifrac ($fields, $line, $line_num) {
   # Example:
   #    Sequence.1	Sample.1	1
   # or:
   #    Sequence.1	Sample.1
   # There are no headers. Two first fields contain strings. Optional third
   # field contains numbers. 
   my $ok = 0;
   my $num_fields = scalar @$fields;
   if ($line =~ m/^#/) {
      $ok = 0;
   } else {
      if ($num_fields == 2) {
         $ok = 1;
      } elsif ($num_fields == 3) {
         if ($fields->[-1] =~ $real_re) {
            $ok = 1;
         }
      }
   }
   return $ok;
}


func _possibly_qiime ($fields, $line, $line_num) {
   # Example:
   #   # QIIME v1.3.0 OTU table
   #   #OTU ID	20100302	20100304	20100823
   #   0	40	0	76
   #   1	0	142	2
   # The first line can contain any comment. The second line must have
   # the name of the columns. The last column can be an extra non-numeric
   # column containing taxonomic information.
   my $ok = 0;
   my $num_fields = scalar @$fields;
   if ($num_fields == 1) {
      if ($line_num == 1) {
         if ($line =~ m/^#/) {
            $ok = 1;
         }
      }
   } elsif ($num_fields >= 2) {
      if ($line_num == 2) {
         if ($line =~ m/^#/) {
            $ok = 2; # qiime for sure
         }
      } elsif ($line_num > 2) {
         for my $i (1 .. $num_fields - 2) {
            if ($fields->[$i] =~ $real_re) {
               $ok = 1;
            } else {
               $ok = 0;
               last;

            }
         }
      }
   }
   return $ok;
}


__PACKAGE__->meta->make_immutable;

1;
