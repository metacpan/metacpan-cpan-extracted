package CracTools::Output;
{
  $CracTools::Output::DIST = 'CracTools';
}
# ABSTRACT: A module to manage CracTools output files.
$CracTools::Output::VERSION = '1.25';

use strict;
use warnings;

use File::Basename;
use CracTools;
use CracTools::Const;

use constant DEFAULT_SEP => "\t";

use strict;
use warnings;


sub new {
  my $class = shift;

  my %args = @_;

  my $sep = DEFAULT_SEP unless $args{sep};
  my $na = defined $args{NA}? $args{NA} : $CracTools::Const::NOT_AVAILABLE;
  my $output = $args{file};
  my $out_stream;

  if(defined $output) {
    open($out_stream,">$output") or die ("Enable to open $output file.\n");
  } else {
    $out_stream = \*STDOUT;
  }
  
  my $self = bless {
    sep => $sep, 
    out_stream => $out_stream,
    NA => $na,
  }, $class;
  
  return $self
}


sub printHeaders {
  my $self = shift;
  my %args = @_;

  my $version = $args{version};
  my $summary = $args{summary};
  my @arguments;
  if(defined $args{args}) {
    @arguments = @{$args{args}};
  }

  $self->printlnOutput("# Date: ".localtime);
  $self->printlnOutput("# Module: $CracTools::DIST (v $CracTools::VERSION)");
  if(defined $version) {
    $self->printlnOutput("# Script: ".basename($0)." (v $version)");
  } else {
    $self->printlnOutput("# Script: ".basename($0));
  }
  if(@arguments > 0) {
    $self->printOutput("# Args: ");
    foreach my $arg (@arguments) {
      $self->printOutput(" $arg");
    }
    $self->printlnOutput();
  }
  if(defined $summary) {
    $self->printlnOutput("# Summary:");
    my @lines = split /\n/, $summary;
    foreach my $line (@lines) {
      $self->printlnOutput("# $line");
    }
  }
  #$self->printlnOutput();
}


sub printHeaderLine {
  my $self = shift;
  my $first_field = shift;
  $first_field = '' unless defined $first_field;
  $self->printLine("# $first_field",@_);
}


sub printLine {
  my $self = shift;
  for(my $cpt = 0; $cpt < scalar @_; $cpt++) {
    if(!defined $_[$cpt]) {
      $_[$cpt] = $self->{NA};
    }
  }
  $self->printlnOutput(join($self->{sep},@_));
}


sub printOutput {
  my $self = shift;
  my $stuff = shift;
  my $stream = $self->{out_stream};
  print $stream $stuff;
}


sub printlnOutput {
  my $self = shift;
  my $stuff = shift;
  if(defined $stuff) {
    $self->printOutput("$stuff\n");
  } else {
    $self->printOutput("\n");
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CracTools::Output - A module to manage CracTools output files.

=head1 VERSION

version 1.25

=head1 SYNOPSIS

  # Creating a default output object.
  # Everything will be print to the standard output
  my $output = CracTools::Output->new();
  
  # Print nice headers
  my $output->printHeaders(version => '1.01',summary => 'blabla', args => @ARGV);
  
  # This will print "foo\tbar\n"
  $output->printLine('foo','bar');
  
  # Using semicolon as separator charcater
  my $output = CracTools::Output->new(sep => ';');
  
  # Print into a file
  my $output = CracTools::Output->new(file => 'foo.bar');

=head1 DESCRIPTION

CracTools::Output is a simple tool to generate Char-Separated files.

=head1 METHODS

=head2 new

  Arg [sep]  : (Optional) Character to use as separator for columns
  Arg [file] : (Optional) String - Ouput file, if not specified
               CracTools::Output prints to STDOUT.
  Arg [NA]   : (Optional NA string to use when for undef variables

  Example     : $output = CracTools::Output->new(file => 'output.txt', sep => '\t');
  Description : Create a new CracTools::Output object
  ReturnType  : CracTools::Output

=head2 printHeaders

  Arg [version]  : (Optional) Version number of the script that is calling "printHeaders" method.
  Arg [summary]  : (Optional) String - Summary text to print in headers (can have multiple lines

  Example     : $output->printHeaders(version => $version, summary => "Found $n reads");
  Description : Print headers to the output stream with CracTools-core version, date, name of calling script.

=head2 printHeaderLine

  Arg [1] : Array of strings

  Example     : $output->printHeaderLine("Read Id","Read_seq","Nb_occ");
  Description : Print header line to the file (with a "# " append to the start of the line)

=head2 printLine

  Arg [1] : Array of strings

  Example     : $output->printLine("Read Id","Read_seq","Nb_occ");
  Description : Print a line to the file, each string of the array parameter is print
                with the separator defined for the output.

=head2 printOutput

  Arg [1] : String - Value to print

  Example     : $output->printLine("This is a line");
  Description : Print the string in parameter to the output stream.

=head2 printlnOutput

  Arg [1] : String - Value to print

  Example     : $output->printLine("This is a line");
  Description : Print the string in parameter to the output stream with an extra "\n" at the end of the string.

=head1 AUTHORS

=over 4

=item *

Nicolas PHILIPPE <nphilippe.research@gmail.com>

=item *

Jérôme AUDOUX <jaudoux@cpan.org>

=item *

Sacha BEAUMEUNIER <sacha.beaumeunier@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by IRMB/INSERM (Institute for Regenerative Medecine and Biotherapy / Institut National de la Santé et de la Recherche Médicale) and AxLR/SATT (Lanquedoc Roussilon / Societe d'Acceleration de Transfert de Technologie).

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
