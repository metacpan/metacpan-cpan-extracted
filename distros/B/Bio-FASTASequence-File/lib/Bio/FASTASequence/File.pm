package Bio::FASTASequence::File;

use 5.006001;
use strict;
use warnings;
use Bio::FASTASequence;

our $VERSION = '0.04';


# Preloaded methods go here.

sub new{
  my ($class,$filename) = @_;
  my $self = {};
  $self->{file} = $filename || '';
  _parse_file($self) if($self->{file});
  bless($self,$class);
  return $self;
}# end new

sub file{
  my ($self,$file) = @_;
  $self->{file} = $file || '';
  _parse_file($self) if($self->{file});
  return $self->{result};
}# end file

sub get_result{
  my ($self) = @_;
  return $self->{result};
}# end get_parsed

sub _parse_file{
  my ($self) = @_;
  local $/ = "\n>";
  open(FH,$self->{file}) or die($self->{file}.": ".$!);
  while(my $entry = <FH>){
    $entry = '>'.$entry unless($entry =~ /^>/);
    $entry =~ s/>$//;
    my $seq = Bio::FASTASequence->new($entry);
    $self->{result}->{$seq->getAccessionNr()} = $seq;
  }
  close FH;
}

1;
__END__

=head1 NAME

Bio::FASTASequence::File - Perl extension for Bio::FASTASequence

=head1 SYNOPSIS

  use Bio::FASTASequence::File;
  my $filename = '/path/to/file.fasta';
  my $parsed_fasta = Bio::FASTASequence::File->new($filename);
  my $hashref = $parsed_fasta->get_result();

  # or
  my $parsed = Bio::FASTASequence::File->new();
  my $hashref = $parsed->file($filename);

  # if a sequence with accession_nr H23OP3 is in the file (as an example)
  # these methods are the methods from Bio::FASTASequence
  my $crc64 = $hashref->{H23OP3}->getCRC64();
  my $sequence = $hashref->{H23OP3}->getSequence();

=head1 DESCRIPTION

This module is an extension for Bio::FASTASequence to parse a fasta-file
at once.

=head1 METHODS

=head2 new

  my $parsed_fasta = Bio::FASTASequence::File->new($filename);

creates a new instance of Bio::FASTASequence::File

=head2 file

  my $parsed = Bio::FASTASequence::File->new();
  $parsed->file($filename);

set the file for the object and parses the given file.

=head1 SEE ALSO

Bio::FASTASequence

=head1 Dependencies

This module requires Bio::FASTASequence

=head1 AUTHOR

Feel free to contact me for feature requests or bug reports:

Renee Baecker, E<lt>module@renee-baecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Renee Baecker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
