package Catalyst::Plugin::Acme::LOLCAT;

use strict;
use Acme::LOLCAT ();

=head1 NAME

Catalyst::Plugin::Acme::LOLCAT - IM IN UR CATALYST APLACASHUN REWRITIN YUR OUTPUTS.

=head1 VERSION

Version 0.03

=cut

our $VERSION = "0.03";

=head1 SYNOPSIS

See L<Acme::LOLCAT> if you don't already know what this will do to
your Catalyst plain text and HTML output.

 use Catalyst qw/
                 Your::Regular::Plugins
                 Acme::LOLCAT
                /;

 # And observe the corrected output of your application

=cut

my $skip = qr/\Ascript|style\z/;

sub finalize {
    my $c = shift;

    return $c->NEXT::finalize unless $c->response->body
        and
        $c->response->content_type =~ m,^text/(plain|html),;

    if ( $1 eq 'plain' )
    {
        $c->response->{body} = Acme::LOLCAT::translate($c->response->{body});
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
            pop @queue if $t->[0] eq 'E'
                or 
                ( $t->[0] eq 'S' and $t->[-1] =~ m,/>\z, ); # self-closer

            if ( 
                 $t->[0] eq 'T'
                 and
                 not $t->[2]
                 and
                 not grep /$skip/, @queue )
            {
                my $txt = $t->[1] =~ /\w/ ? Acme::LOLCAT::translate($t->[1]) : $t->[1];
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

=head1 AUTHOR

Ashley Pond V, ashley at cpan.org.

=head1 BUGS

I love bugs! Hymenoptera, dictyoptera, coleoptera, all of them.

Expects valid nesting. May sometimes interfere with tags that should
be literal, like E<lt>scriptE<gt> and E<lt>styleE<gt>, when it's not
present.

=head1 TODO

Targeted tags in config file?

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

   perldoc Catalyst::Plugin::Acme::LOLCAT

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-Plugin-Acme-LOLCAT>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-Plugin-Acme-LOLCAT>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-Plugin-Acme-LOLCAT>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-Plugin-Acme-LOLCAT>

=back

=head1 SEE ALSO

L<Acme::LOLCAT>, L<Catalyst::Plugin::Acme::Scramble>, L<Catalyst>,
L<Catalyst::Runtime>.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2007 Ashley Pond V, all rights reserved.

This program is free software; you can redistribute it and modify it
under the same terms as Perl itself.

=cut

1; # End of Catalyst::Plugin::Acme::LOLCAT
