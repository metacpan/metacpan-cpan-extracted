package Acme::BooK::Is::My::Bitch;
$Acme::BooK::Is::My::Bitch::VERSION = '0.05';
use 5.006;
use warnings;
use strict;

use Acme::MetaSyntactic;

# ###### Implementation ###########

sub new { shift }

my $de_underscore = sub { map { y/_/ /; $_ } @_ };

my %methods = (
    'tell_the_truth' => [
        'You know, my favorite pornstar is definitely %s.',
        'pornstars', $de_underscore
    ],
    'thats_nothing' => [
        'Oh, that\'s nothing! You should\'ve seen what I auctioned in %s!',
        'yapc', $de_underscore
    ],
    'code' => [
        'You know, I wrote some code for the %s space mission, but it was rejected for its lack of clarity...',
        'space_missions', $de_underscore
    ],
    'next_talk' => [
        'My next lightning talk will be called "%s! %s!! %s!!!"',
        'batman', sub { map { y/_/-/; ucfirst } @_ }
    ],
    'next_yapc' => [
         'I think the next YAPC should be on %s!',
         'planets', ],
    'sql' => [
         'I think we can solve that with a %s %s %s',
         'sql', ],
    'twisted_perl' => [
        'I\'m pretty sure I could do that just by using %s and %s',
        'opcodes',
    ],
    'words_of_wisdom' => [
        'My grandfather once told me:' . ' %s' x 7,
        'loremipsum',
    ],
    ( # quotes that need a theme/category
        'baby_girl' => [
            'You know we considered naming our baby girl %s?',
            'pornstars/female',
            sub { ( my $baby = shift ) =~ s/_.*$//; $baby }
        ],
        meeting_room => [
            'I think this meeting room should be called %s',
            [ 'barbapapa/nl', 'barbapapa/en' ],
        ],
        favourite_colour => [
            'My favourite colour is %s',
            [ 'colours/en', 'colours/x-11' ],
            sub { my $colour = shift; return $colour =~ /pink|rose/i ? $de_underscore->( $colour ) : (); }
        ]
    )x!! ( $Acme::MetaSyntactic::VERSION >= 1.011 ),
);

for my $method ( keys %methods ) {
    my ( $template, $theme, $filter ) = @{ $methods{$method} };
    $filter ||= sub {@_};
    my $qty =()= $template =~ /%s/g;
    no strict 'refs';
    *{$method} = sub {
        my $th = ref $theme ? $theme->[rand @$theme] : $theme;
        my @args;
        @args = $filter->( metaname( $th => $qty ) ) while !@args;
        return sprintf $template, @args;
    };
}

sub available_quotes { return sort keys %methods }

sub random_quote {
    my $self = shift;
    my $method  = (keys %methods)[ rand keys %methods ];
    return $self->$method();
}

1;    # Magic true value required at end of module

=pod

=encoding iso-8859-1

=head1 NAME

Acme::BooK::Is::My::Bitch - BooK is my Bitch

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use Acme::BooK::Is::My::Bitch;

    my $bitch = Acme::BooK::Is::My::Bitch->new();

    my $quote = $bitch->random_quote();

=head1 DESCRIPTION

Acme::BooK::Is::My::Bitch has a great story behind it.

At YAPC::EU::2006, in Birmingham, England, BooK auctioned the right
for someone to pick a module from CPAN and have that module's name
(temporarily) tattoed in his arm for all the conferences BooK would go
to during 2007.

Cog asked if the module had to exist by that time, and BooK said "No."

BIG MISTAKE!

=head1 INTERFACE

=head2 Program Interface

=head3 new

Creates a new Acme::BooK::Is::My::Bitch object.

    my $bitch = Acme::BooK::Is::My::Bitch->new();

Since all methods are actually class methods, the following line
is exactly equivalent to the above one (and shorter!):

    my $bitch = 'Acme::BooK::Is::My::Bitch';

=head3 available_quotes

Returns the list of available quote methods.

=head2 Module Interface

=head3 baby_girl

BooK has no imagination for naming his kids.

    my $baby_girl_quote = $bitch->baby_girl();

=head3 code

BooK is really clever.

    my $code_quote = $bitch->code();

=head3 favourite_colour

BooK has a favourite colour. A whole palette of it.

    my $colour_quote = $bitch->favourite_colour();

=head3 meeting_room

BooK had a clever scheme for naming meeting rooms. Nobody ever listened.

    my $meeting_room_quote = $bitch->meeting_room();

=head3 next_talk

BooK is known to auto-generate the names of his lightning talks.

    my $next_talk_quote = $bitch->next_talk();

=head3 next_yapc

BooK has something to say about the place the next YAPC::EU is going to be.

    my $next_yapc_quote = $bitch->next_yapc();

=head3 sql

BooK claims he's not an SQL guru.

    my $sql_quote = $bitch->sql();

=head3 tell_the_truth

BooK has the pornstars theme on L<Acme::MetaSyntactic>. There must be a reason.

    my $tell_the_truth_quote = $bitch->tell_the_truth();

=head3 thats_nothing

BooK has the craziest ideas ever for auctions.

    my $thats_nothing_quote = $bitch->thats_nothing();

=head3 twisted_perl

BooK is known to write very obfuscated code.

    my $twisted_perl_quote = $bitch->twisted_perl();

=head3 words_of_wisdom

BooK claims he got a lot of wisdom from his grandfather.

    my $words_of_wisdom_quote = $bitch->words_of_wisdom();

=head3 random_quote

To tell you the truth, no one really knows what BooK is going to say next.

    my $random_quote_quote = $bitch->random_quote();

=head1 CONFIGURATION AND ENVIRONMENT

Acme-BooK-Is-My-Bitch requires no configuration files or environment variables.

=head1 DEPENDENCIES

=over

=item *

L<Acme::MetaSyntactic>,
L<Acme::MetaSyntactic::Themes>.

=back

=head1 FUTURE

=over

=item *

BooK is still growing. This module will evolve as BooK's arms grow.

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

All reported bugs have been fixed, all requested features have been added.

=head1 AUTHOR

José Castro  C<< <cog@cpan.org> >>

=head1 MAINTAINER

Philippe Bruhat (BooK) C<< <book@cpan.org> >>

=head1 ACKNOWLEDGEMENTS

BooK actually wrote part of the code for this module and suggested
some of the ideas that were turned into methods.

This module is not about Cog mocking BooK; it's rather about Cog B<and>
BooK making fun of themselves.

We spent a very funny afternoon in a mini-hackathon in Birmingham
starting up this module. We finished its first version while at the
Old Joint pub with some more YAPC attendees.

=head1 $_ IS MY BITCH

The phrase "I<...> is my bitch" has been thrown around a lot during past
YAPC Europe conferences. This tradition has thankfully been lost, but some
artifacts remain:

=over 4

=item L<http://perl.ismybit.ch/>

The T-shirt that started it all when the first YAPC Europe was organized,
back in 2000.

=item L<http://schwern.ismybit.ch/>

Schwern worked for Belfast.pm, and all he got was this lousy T-shirt.
One of those shirts was auctioned at the Amsterdam YAPC in 2001.

=item L<http://greg.mccarroll.ismybit.ch/>

Dave Cross bought an obfuscation by BooK at the Amsterdam YAPC auction.
The code was revelead during the Paris YAPC auction in 2003, and the
crowd bid (and won) against Greg to see it run.

=item L<http://book.ismybit.ch/>

The temporary tatoo alluded to above, at the Vienna YAPC in 2007.

=back

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Jose Castro C<< <cog@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

__END__

# ABSTRACT: BooK is my Bitch

