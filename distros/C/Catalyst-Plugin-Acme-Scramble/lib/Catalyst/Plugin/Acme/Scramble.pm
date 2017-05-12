package Catalyst::Plugin::Acme::Scramble;

use strict;

=head1 NAME

Catalyst::Plugin::Acme::Scramble - tset the budnos of lieibiglty and dstraneotme how we pcvreiee wdors wtih yuor Ctyslaat apicapltion

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

 use Catalyst qw/
                 Your::Regular::Plugins
                 Acme::Scramble
                /;

 # And observe the corrected output of your application

Implements a potent meme about how easily we can read scrambled text
if the first and last letters remain constant. Operates on text/plain
and text/html served by your Catalyst application.

=cut

my $skip = qr/script|style|map|area/;

sub finalize {
    my $c = shift;

    return $c->NEXT::finalize unless $c->response->body
        and
        $c->response->content_type =~ m,^text/(plain|html),;

    if ( $1 eq 'plain' )
    {
        _scramble_block( \$c->response->{body} );
    }
    else
    {
        require HTML::TokeParser;
        my $p = HTML::TokeParser->new( \$c->response->{body} );
        my $repaired = '';
        my @queue;

        while ( my $t = $p->get_token() )
        {
            push @queue, $t->[1] if $t->[0] eq 'S'; # assumes well-formed
            pop @queue if $t->[0] eq 'E';
            if ( 
                 $t->[0] eq 'T'
                 and
                 not $t->[2]
                 and
                 not grep /$skip/, @queue )
            {
                my $txt = $t->[1];
                _scramble_block(\$txt);
                $repaired .= $txt;
            }
            else
            {
                $repaired .= ( $t->[0] eq 'T' ) ? $t->[1] : $t->[-1];
            }
        }
        $c->response->{body} = $repaired;
    }

    $c->NEXT::finalize;
}

sub _scramble_block {
    my $text = shift;

    ${$text} =~ s{
                  ( (?:(?<=[^[:alpha:]])|(?<=\A))
                    (?<!&)(?-x)(?<!&#)(?x)
                    (?:
                       ['[:alpha:]]+ | (?<!-)-(?!-)
                     )+
                    (?=[^[:alpha:]]|\z)
                   )
                  }
                 {_scramble_word($1)}gex;
}

sub _scramble_word {
    my $word = shift || return '';
    my @piece = split //, $word;
    shuffle(@piece[1..$#piece-1])
        if @piece > 2;
    join('', @piece);
}

sub shuffle {
    for ( my $i = @_; --$i; ) {
        my $j = int(rand($i+1));
        @_[$i,$j] = @_[$j,$i];
    }
}

=head1 AUTHOR

Ashley Pond V, ashley at cpan.org.

=head1 BUGS

I love bugs! Hymenoptera, dictyoptera, coleoptera, all of them.

Expects valid nesting. May sometimes interfere with tags that should
be literal, like E<lt>scriptE<gt> and E<lt>styleE<gt>, when it's not
present.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::Plugin::Acme::Scramble

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-Acme-Scramble>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-Acme-Scramble>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-Acme-Scramble>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-Acme-Scramble>

=back

=head1 TODO

Support application/xhtml+xml? If it's served that way, or even as any
XML, we could use an XML parser and just scramble the #text parts.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Runtime>.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Ashley Pond V, all rights reserved.

This program is free software; you can redistribute it and modify it
under the same terms as Perl itself.

=cut

1; # End of Catalyst::Plugin::Acme::Scramble
