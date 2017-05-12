package Acme::ICan::tSpell;

our $VERSION = '0.02';

use Moo;
use MooX::LazierAttributes qw/rw lzy/;
use MooX::ValidateSubs;
use Types::Standard qw/Object Str HashRef/;
use HTTP::Tiny;
use URI::Escape;
use Carp qw/croak/;

attributes (
    tiny => [Object, {lzy, default => sub {HTTP::Tiny->new}}],
    base_url => [Str, {lzy, default => 'http://www.google.com/search?gws_rd=ssl&hl=en&q='}],
);

validate_subs ( 
    get => { params => [ [Str] ], returns => [[HashRef]] },
    spell_check => { 
        params => { check => [Str], base_url => [Str, 'base_url'] },
        returns => [[Str, 1]],
    }, 
    spell => { params => [[Str]], returns => [[Str]] },
);

sub get {
    my $response = $_[0]->tiny->get($_[1]);
    $response->{success} and return $response;
    croak sprintf "something went terribly wrong status - %s - reason - %s", 
        $response->{status}, $response->{reason};
}

sub spell_check {
    my $moon = $_[0]->get(sprintf('%s%s', $_[1]->{base_url}, uri_escape($_[1]->{check})))->{content};
    if ($moon =~ m{(?:Showing results for|Did you mean|Including results for)[^\0]*?<a.*?>(.*?)</a>}){
        (my $str = $1) =~ s/<.*?>//g;
        return $str;
    }
    return $_[1]->{check};
}

sub spell {
    return $_[0]->spell_check({ check => $_[1] });
}

1;

__END__

=head1 NAME

Acme::ICan::tSpell - What do you do..

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

You use google...

    use Acme::ICan'tSpell;

    my $speller = Acme::ICan'tSpell->new();
    ...
    
    $speller->spell('thakn yuo'); # thank you;

=head1 SUBROUTINES/METHODS

=head2 spell

Accepts a word, phrase or sentence and uses google search to return a
correctly spelled version. 

    $speller->spell();

=head1 AUTHOR

Robert Acock, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-ican-tspell at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-ICan-tSpell>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::ICan::tSpell

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-ICan-tSpell>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-ICan-tSpell>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-ICan-tSpell>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-ICan-tSpell/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2017 Robert Acock.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Acme::ICan::tSpell
