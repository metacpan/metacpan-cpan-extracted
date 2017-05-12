package AI::CBR;

use warnings;
use strict;


=head1 NAME

AI::CBR - Framework for Case-Based Reasoning

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

    use AI::CBR::Sim qw(sim_eq ...);
    use AI::CBR::Case;
    use AI::CBR::Retrieval;

    my $case = AI::CBR::Case->new(...);
    my $r = AI::CBR::Retrieval->new($case, \@case_base);
    ...


=head1 DESCRIPTION

Framework for Case-Based Reasoning in Perl.
For an overview, please see my slides from YAPC::EU 2009.

In brief, you need to specifiy an L<AI::CBR::Case>
with the help of similarity functions from L<AI::CBR::Sim>.
Then you can find similar cases from a case-base
with L<AI::CBR::Retrieval>.

The technical documentation can be found in the
individual modules of this distribution.


=head1 SEE ALSO

=over 4

=item * L<AI::CBR::Sim>

=item * L<AI::CBR::Case>

=item * L<AI::CBR::Case::Compound>

=item * L<AI::CBR::Retrieval>

=back


=head1 AUTHOR

Darko Obradovic, C<< <dobradovic at gmx.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ai-cbr at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AI-CBR>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AI::CBR


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AI-CBR>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AI-CBR>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AI-CBR>

=item * Search CPAN

L<http://search.cpan.org/dist/AI-CBR>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Darko Obradovic, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of AI::CBR::Case
