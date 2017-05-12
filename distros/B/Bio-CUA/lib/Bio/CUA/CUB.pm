package Bio::CUA::CUB;

use 5.006;
use strict;
use warnings;
use parent qw/Bio::CUA::Summarizer/;

=head1 NAME

Bio::CUA::CUB - This is the parent class for all classs processing
codon usage bias (CUB).


=head1 SYNOPSIS

At present, this class largely inherits from
L<Bio::CUA::Summarizer>. The class may be updated in future depending
on the needs of new analyses.

Please refer to its child classes L<Bio::CUA::CUB::Builder> and
L<Bio::CUA::CUB::Calculator> for usage of methods.

=head1 METHODS

=head2 no_atg

 Title   : no_atg
 Usage   : $status = $self->no_atg([$newVal])
 Function: get/set the status whether ATG should be excluded in tAI
 calculation.
 Returns : current status after updating
 Args    : optional. 1 for true, 0 for false

=cut

sub no_atg
{
	my ($self, $val) = @_;
	$self->set_tag('no_atg',$val) if(defined($val));
	return $self->get_tag('no_atg');
}


=head1 AUTHOR

Zhenguo Zhang, C<< <zhangz.sci at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bio-cua at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-CUA>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this class with the perldoc command.

    perldoc Bio::CUA::CUB


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

1; # End of Bio::CUA::CUB
