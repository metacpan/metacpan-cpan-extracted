package Bio::CUA;

use 5.006;
use strict;
use warnings;
use Carp;

# some global variables
our $VERSION = '1.04';
my $sep = "\t";
#my @openFHs; # all file handles opened by this class

=pod

=head1 NAME

Bio::CUA - Codon Usage Analyzer.

=head1 VERSION

Version 1.04

=head1 SYNOPSIS

This is the root class for the whole distribution of
L<http://search.cpan.org/dist/Bio-CUA/>,
providing some routine methods used by all classs in the
distribution L<http://search.cpan.org/dist/Bio-CUA/>. Users should not use this class
directly. Please start with its child classes such as
L<Bio::CUA::Summarizer>, L<Bio::CUA::CUB::Builder>.

=head1 DESCRIPTION

The aim of this distribution is to provide comprehensive and flexible
tools to analyze codon usage bias (CUB) and relevant problems, so that
users can speed up the genetic research by taking advantage of this
convenience.

One amino acid can be encoded by more than one synonymous codon, and
synonymous codons are unevenly used. For example, some codons are used
more often than other synonymous ones in highly expressed genes (I<Sharp
and Li 1987>). To measure the unevenness of codon usage, multiple
metrics of codon usage bias have been developed, such as Fop
(Frequency of optimal codons), CAI (Codon Adaptation Index), tAI (tRNA
Adaptation Index), and ENC (Effective Number of Codons). The causes of
CUB phenomena are complicated, including, mutational bias, selection on 
translational efficiency or accurancy. CUB is one fundamental concept
in genetics. 

So far, no software exists to compute all the above CUB metrics, and
more importantly parameters of CUB calculations are often fixed in
software, so one can only analyze genes in a limited list of species
and one can not incorporate its own parameters such as sequences of
highly expressed genes in a tissue. 

This package mainly solves these two problems. We also extend some
methods, such as GC-content corrected ENC, background-data normalized
CAI, etc. See the relevant methods in CUB classes for more details.

=head1 METHODS

=cut

sub new
{
	my ($caller, @args) = @_;
	my $self = {};
	my $class = ref($caller)? ref($caller) : $caller;

	bless $self, $class;
	my $hashRef = $self->_array_to_hash(\@args);

	# only process its own argument
	$self->debug(1) if($hashRef->{'debug'});

	return $self;
}

# store and retrieve tag values
sub get_tag
{
	my ($self, $tag) = @_;
	return $self->{'_tags'}->{$tag};
}

sub set_tag
{
	my ($self, $tag, $val) = @_;
	$self->{'_tags'}->{$tag} = $val;
}

=head2 debug

 Title   : debug
 Usage   : $true_of_false=$self->debug([$bool]);
 Function: get/set the boolean value.
 Returns : 0 as false, 1 as true
 Args    : optional. 0 or 1 for false and true, respectively.

=cut

sub debug
{
	my ($self, $val) = @_;
	$self->set_tag('debug', $val) if($val);
	return $self->get_tag('debug');
}


=head2 throw

 Title   : throw
 Usage   : $self->throw("Some fatal errors");
 Function: stop and report when fatal errors in formatted message
 Returns : None
 Args    : error message

=cut

# simplified version
sub throw
{
	my ($self, @args) = @_;
	my $class = ref($self) || $self;
	$class = ' '.$class if $class;
	my $title = "------------- EXCEPTION$class -------------";
	my $footer = ('-' x length($title))."\n";
	#my $text = join("\n", @args);
	my $text = _format_text(join(' ',@args));
	croak "\n$title\n", "MSG: $text\n", $footer, "\n";
}

=head2 warn

 Title   : warn
 Usage   : $self->warn("Please pay attention here")
 Function: report warning message when something looks not good
 Returns : None
 Args    : warning messages.

=cut

sub warn
{
	my ($self, @args) = @_;

	my $class = ref($self) || $self;
	$class = ' '.$class if $class;
	my $title = "------------- WARNING$class -------------";
	my $footer = ('-' x length($title))."\n";
	my $text = _format_text(join(' ',@args));
	#my $text = join("\n", @args);
	carp "\n$title\n", "MSG: $text\n", $footer, "\n";
}

# format the text into blocks with same line length
sub _format_text
{
	my ($text, $lineLen) = @_;

	$lineLen ||= 60;
	chomp($text);
	my $result = '';

	my @blocks = split /\n/, $text;

	foreach my $b (@blocks)
	{
		my $newB = _break_into_lines($b, $lineLen);
		$result .= $newB;
	}
	return $result;
}

sub _break_into_lines
{
	my ($text, $size) = @_;

	my $lines = '';
	my $textLen = length($text);

	my $accuLen = 0;
	while($accuLen < $textLen)
	{
		my $lineLen = $accuLen + $size > $textLen? $textLen - $accuLen
		: $size;
		my $l = substr($text,$accuLen,$lineLen);
		$accuLen += $lineLen;
		$lines .= $l."\n";
	}

	return $lines;
}

# return hash ref by reading into an array ref
sub _array_to_hash
{
	my ($self,$arrayRef,$nc) = @_;

	$self->throw("parameter '$arrayRef' to _array_to_hash is not an array reference")
	unless(ref($arrayRef) eq 'ARRAY');

	my %hash;

	$self->throw("Odd number of elements are in the array fed to",
		"_array_to_hash, check the array $arrayRef")
	unless($#$arrayRef % 2);

	for(my $i = 0; $i < $#$arrayRef; $i += 2)
	{
		my $k = $arrayRef->[$i];
		$k =~ s/^\-*//; # removing leading '-'
		$k = lc($k) unless($nc);
		$hash{$k} = $arrayRef->[$i+1];
	}

	return \%hash;
}


# write out hash to an outfile
sub _write_out_hash
{
	my ($self, $outFile, $hashRef) = @_;

	my $fh;
	open($fh, "> $outFile") or die "Can not open $outFile:$!";
	# let's sort the hash so that every time the same order is
	# produced
	my @sortedKeys = sort keys(%$hashRef);
	foreach my $k (@sortedKeys)
	{
		print $fh join($sep, $k, $hashRef->{$k}),"\n";
	}
	close $fh;

	return 1;
}

# open a file and return its file handle
sub _open_file
{
	my ($self, $file, $mode) = @_;

	$mode ||= ' ';

	my $fh;
	open($fh, "$mode $file") or $self->throw("can not open $file:$!");
	#push @openFHs, $fh;
	return $fh;
}

# parse the first $num fields of input file, and use the vaule at the
# first column as key
sub _parse_file
{
	my ($self, $file, $num) = @_;

	my %hash;
	my $fh = $self->_open_file($file);
	while(<$fh>)
	{
		next if /^#/ or /^\s*$/;
		chomp;
		s/^\s+//; # remove leading blanks
		my @fields = split /\s+/;
		if($num > 1)
		{
			$hash{uc($fields[0])} = $num > 2? 
				[@fields[1..($num-1)]] : $fields[1];
		}else
		{
			$hash{uc($fields[0])}++;
		}
	}
	close $fh;
	return \%hash;
}

# this method is called when object of this or child classes is being
# destroyed
# close the file handle if the object has one
sub DESTROY
{
	my $self = shift;
	#print $self;
	close $self->{'_fh'} if(exists $self->{'_fh'});
#	$self->SUPER::DESTROY(@_);
}

=head1 AUTHOR

Zhenguo Zhang, C<< <zhangz.sci at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-cua at
rt.cpan.org> or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-CUA>.  I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=cut

=head1 SUPPORT

You can find documentation for this class with the perldoc command.

	perldoc Bio::CUA

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

1; # End of Bio::CUA

