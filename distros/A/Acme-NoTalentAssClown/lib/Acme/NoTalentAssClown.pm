package Acme::NoTalentAssClown;
use Lyrics::Fetcher;

use warnings;
use strict;

sub new {
    my ( $class, %options ) = @_;
    $class = ref($class) || $class;
    my $self = {
        agent             => $options{agent},
        entire_collection => [
            "That's What Love Is All About",
            "The Dock Of The Bay",
            "Soul Provider",
            "How Am I Supposed To Live Without You",
            "How Can We Be Lovers",
            "When I'm Back On My Feet Again",
            "Georgia On My Mind",
            "Time, Love And Tenderness",
            "When A Man Loves A Woman",
            "Missing You Now",
            "Steel Bars",
            "Said I Loved You...But I Lied",
            "Can I Touch You...There?",
            "I Promise You",
            "I Found Someone",
            "A Love So Beautiful",
            "This River"
        ]
    };
    $Lyrics::Fetcher::gid = $options{gid};
    bless( $self, $class );
    return ($self);
}

=head1 NAME

Acme::NoTalentAssClown - Get some Bolton Lyrics!

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Acme::NoTalentAssClown;

    #Defaults to use Lyrics::Fetcher::Google, but any Lyrics::Fetcher
    #plugin will work as specified by agent=>'bar'
    my $nta = Acme::NoTalentAssClown->new(gid=>'yourGoogleApi_ID'); 
    print $nta->grammys(); #finds a greatest hit
    print $nta->grammys('When a Man Loves a Woman'); #For my money, it doesn't get any better
    ...

=head1 METHODS

=over 4

=item new

Initializes Acme::NoTalentAssClown and loads lyric loader depending on agent

=item grammys

Returns the result of a search for a random greatest hit, or a hit you specify

=back

=cut


our $VERSION = '0.01';

sub grammys {
    my $self = shift;
    my ($suggestion) = @_;
    $suggestion ||=
      $self->{entire_collection}
      [ rand( scalar( @{ $self->{entire_collection} } ) ) ];
    return Lyrics::Fetcher->fetch(
        $suggestion,
        "Michael Bolton",
        $self->{agent} || "Google"
    );
}

=head1 AUTHOR

John Lifsey, C<< <nebulous@crashed.net> >>

=head1 BUGS

I'm sure there are plenty of bugs. 
But why should I change it? 
He's the one who sucks.

Please report any bugs or feature requests to
C<bug-acme-notalentassclown@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-NoTalentAssClown>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 John Lifsey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Acme::NoTalentAssClown
