package Bio::CUA::SeqIO;

=head1 NAME

Bio::CUA::SeqIO - a package to parse sequence file if module
L<Bio::SeqIO> is unavailable in the system.

=head1 SYNOPSIS

	use Bio::CUA::SeqIO;

	# create an IO to a sequence file in FASTA format
	my $io = Bio::CUA::SeqIO->new("seq_file.fa")

	# read each sequence as a Bio::CUA::Seq object from this io
	while(my $seq = $io->next_seq)
	{
		printf("%s: %d\n", $seq->id, $seq->length);
	}

=head1 DESCRIPTION

This is an auxiliary module to process sequences in case the module
L<Bio::SeqIO> is not installed in the system. At present, this module
can only process fasta-formatted sequence file.

=cut

use 5.006;
use strict;
use parent qw/Bio::CUA/;
use Bio::CUA::Seq; # sequence object package

my $seq_pkg = 'Bio::CUA::Seq';

=head1 METHODS

=head2 new

 Title   : new
 Usage   : $io = Bio::CUA::SeqIO->new(-file => "seq_file.fa")
 Function: create an IO to read sequences from a file
 Returns : an object of this class
 Args    : a hash in the format of
 -file => "seq_file.fa"

=cut

sub new
{
	my ($caller, @args) = @_;

	my $self = $caller->SUPER::new(@args);

	$self->_initialize(@args) or return undef;

	return $self;
}

# open the file and prepare to read the sequence
sub _initialize
{
	my ($self, @args) = @_;

	my $hashRef = $self->_array_to_hash(\@args);
	my $file = $hashRef->{'file'};
	$self->throw("option '-file' is needed for creating object of",
		ref($self)) unless(defined $file);

	$file =~ s/^[\s><]+//;
	my $fh = $self->_open_file($file) or return;

	$self->{'_fh'} = $fh;
	return 1;
}

=head2 next_seq

 Title   : next_seq
 Usage   : my $seq = $self->next_seq;
 Function: read next sequence in the IO stream
 Returns : an object of L<Bio::CUA::Seq> or undef if no more
 sequence
 Args    : none

=cut

sub next_seq
{
	my $self = shift;

	my $fh = $self->{'_fh'};

	$self->throw("No open filehandle stored in the object of $self") 
	unless($fh);
	return undef if(eof($fh)); # no more sequences
		
	$self->throw("Errors on filehandle $fh") if(tell($fh) < 0);

	my $moreData = 0; # indicates whether more data rather than
	# comments or empty lines
	my $seqStr = '';
	my $defLine;
	# the defline read by the program when reading the last sequence
	$defLine = $self->{'_last_defline'} if(exists
		$self->{'_last_defline'});
	while(<$fh>)
	{
		next if /^\s*$/ or /^#/; # empty or comment lines
		chomp;
		$moreData = 1;
		if(/^>/) # a new sequence
		{
			if($defLine) # reach next sequence
			{
				# store this line for next time's use
				$self->{'_last_defline'} = $_;
				last;
			}else # this is what to read, only for the 1st seq
			{
				$defLine = $_;
				$seqStr = '';
				next;
			}
		}

		$seqStr .= $_;
	}

	return undef unless($moreData);

	my ($id, $desc) = $defLine =~ /^>(\S+)(.*)$/;
	$desc =~ s/^\s+//;

	my $seqObj = $seq_pkg->new(
		-seq   =>  $seqStr,
		-id    =>  $id,
		-desc  =>  $desc );

	return $seqObj;
}

=head1 AUTHOR

Zhenguo Zhang, C<< <zhangz.sci at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-cua at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-CUA>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::CUA::SeqIO


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-CUA>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-CUA>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bio-CUA>

=item * Search CPAN

L<http://search.cpan.org/dist/Bio-CUA/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Zhenguo Zhang.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.


=cut

1; # End of Bio::CUA::SeqIo
