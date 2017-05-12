package Acme::URL;
use strict;
use warnings;
use 5.008001;
use Devel::Declare ();
use LWP::Simple ();
use base 'Devel::Declare::Context::Simple';

our $VERSION = '0.01';

sub import {
    my $class  = shift;
    my $caller = caller;
    my $ctx    = __PACKAGE__->new;

    Devel::Declare->setup_for(
        $caller,
        {
            http => {
                const => sub { $ctx->parser(@_) },
            },
        },
    );

    no strict 'refs';
    *{$caller.'::http'} = sub ($) { LWP::Simple::get( $_[0] ) };
}

sub parser {
    my $self = shift;
    $self->init(@_);
    $self->skip_declarator;          # skip past "http"

    my $line = $self->get_linestr;   # get me current line of code
    my $pos  = $self->offset;        # position just after "http"
    my $url  = substr $line, $pos;   # url & everything after "http"

    for my $c (split //, $url) {
        # if blank, semicolon, closing parenthesis or a comma(!) then no longer a URL
        last if $c eq q{ };
        last if $c eq q{;};
        last if $c eq q{)};
        last if $c eq q{,};
        $pos++;
    }    

    # wrap the url with http() sub and quotes
    substr( $line, $pos,          0 ) = q{")};
    substr( $line, $self->offset, 0 ) = q{("http};

    # pass back changes to parser
    $self->set_linestr( $line );

    return;
}


1;

__END__


=head1 NAME

Acme::URL - Bareword URL with HTTP request

=head1 VERSION

Version 0.01


=head1 SYNOPSIS

URL without any strings attached performing a HTTP request returning the content:

    use Modern::Perl;
    use JSON qw(decode_json);
    use Acme::URL;

    # print the json
    say http://twitter.com/statuses/show/6592721580.json;

    # => "He nose the truth."
    say decode_json( http://twitter.com/statuses/show/6592721580.json )->{text};


=head1 DESCRIPTION

See L<http://transfixedbutnotdead.com/2009/12/16/url-develdeclare-and-no-strings-attached/>

NB. This module is just a play thing and just intended as an investigation into using L<Devel::Declare>.
So go play with it and don't do anything stupid with it :)


=head1 EXPORT

=head2 http()

NB.  Devel::Declare will always trigger the bareword http


=head1 FUNCTIONS

=head2 import

=head2 parser


=head1 AUTHOR

Barry Walsh, C<< <draegtun at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-url at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-URL>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::URL


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-URL>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-URL>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-URL>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-URL/>

=back


=head1 ACKNOWLEDGEMENTS

See L<Devel::Declare> for the black magic used!


=head1 DISCLAIMER

This is (near) beta software.   I'll strive to make it better each and every day!

However I accept no liability I<whatsoever> should this software do what you expected ;-)

=head1 COPYRIGHT & LICENSE

Copyright 2009 Barry Walsh (Draegtun Systems Ltd), all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

