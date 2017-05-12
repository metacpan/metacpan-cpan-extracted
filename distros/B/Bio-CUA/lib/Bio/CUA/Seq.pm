package Bio::CUA::Seq;

=head1 NAME

Bio::CUA::Seq - a module processing sequence object

=head1 SYNOPSIS

	use Bio::CUA::Seq;

	my $obj = Bio::CUA::Seq->new(
		-seq  => 'AGGTGCCG...',
		-id   => 'test_id',
		-desc => 'sequence description'
		);

	# available methods
	$obj->length; # get sequence length
	$obj->id; # get sequence id
	$obj->desc; # get sequence description
	$obj->seq; # get sequence string

=head1 DESCRIPTION

This module is called by L<Bio::CUA::SeqIO> to create sequence
object which has some basic methods required by the modules in the
distribution L<http://search.cpan.org/dist/Bio-CUA/>. The purpose of
this module is to increase the portability of the distribution.

=cut

use 5.006;
use strict;
use warnings;
use base qw/Bio::CUA/;

=head1 METHODS

=head2 new

 Title   : new
 Usage   : my $obj = Bio::CUA::Seq->new(%params);
 Function: create sequence object
 Returns : an object of this class
 Args    : arguments are specified in a hash and acceptable keys as follows:

=over 5

=item C<-seq>

the sequence string for the object, which can only be characters in
the range A-Z and a-z. Other characters are eliminated by the method.

=item C<-id>

the sequence name

=item C<-desc>

extra description of this sequence

=back

=cut

sub new
{
	my ($caller, @args) = @_;

	my $self = $caller->SUPER::new(@args);

	my $hashRef = $self->_array_to_hash(\@args);

	my $str = $hashRef->{'seq'};
	$str =~ s/[^a-z]+//gi; # eliminate unknown chars

	$self->warn("No valid sequence string found",
	exists $hashRef->{'id'}? "for ".$hashRef->{'id'}:"")
	unless($str);

	$self->set_tag('seqstr', $str);
	$self->set_tag('id', $hashRef->{'id'}) if(exists $hashRef->{'id'});
	$self->set_tag('desc', $hashRef->{'desc'}) if(exists
		$hashRef->{'desc'});
	
	return $self;
}

=head2 length

 Title   : length
 Usage   : my $len = $self->length;
 Function: get the length of the sequence
 Returns : an integer
 Args    : None

=cut

sub length
{
	my $str = $_[0]->get_tag('seqstr');
	return length($str);
}

=head2 id

 Title   : id
 Usage   : my $id = $self->id;
 Function: get sequence name/id
 Returns : a string
 Args    : None

=cut

sub id
{
	$_[0]->get_tag('id');
}

=head2 desc

 Title   : desc
 Usage   : my $desc = $self->desc
 Function: get sequence description
 Returns : a string or undef if not exist
 Args    : None

=cut

sub desc
{
	$_[0]->get_tag('desc');
}

=head2 seq

 Title   : seq
 Usage   : my $seq = $self->seq
 Function: get sequence string of the object
 Returns : a string
 Args    : None

=cut

sub seq
{
	$_[0]->get_tag('seqstr');
}

=head1 AUTHOR

Zhenguo Zhang, C<< <zhangz.sci at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-cua at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-CUA>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::CUA::Seq


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

1; # End of Bio::CUA::Seq
