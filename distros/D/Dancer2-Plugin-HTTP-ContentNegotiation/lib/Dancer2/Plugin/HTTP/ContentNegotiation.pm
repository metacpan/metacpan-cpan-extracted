package Dancer2::Plugin::HTTP::ContentNegotiation;

=head1 NAME

Dancer2::Plugin::HTTP::ContentNegotiation - Server-driven negotiation

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

use warnings;
use strict;

use Carp;
use Dancer2::Plugin;

=head1 SYNOPSIS

HTTP specifies two types of content negotiation. These are server-driven
negotiation and agent-driven negotiation. Server-driven negotiation uses request
headers to select a variant, and agent-driven negotiation uses a distinct URI
for each variant.

This plugin handles server-driven negotiation.

    use Dancer2;
    
    use Dancer2::Plugin::HTTP::ContentNegotiation;
    
    get '/greetings' => sub {
        http_choose_language (
            'en'    => sub { 'Hello World' },
            'en-GB' => sub { 'Hello London' },
            'en-US' => sub { 'Hello Washington' },
            'nl'    => sub { 'Hallo Amsterdam' },
            'de'    => sub { 'Hallo Berlin' },
            # default is first in the list
        );
    };
    
    get '/choose/:id' => sub {
        my $data = SomeResource->find(param('id'));
        http_choose_media_type (
            'application/json'  => sub { to_json $data },
            'application/xml '  => sub { to_xml $data },
            { default => undef }, # default is 406: Not Acceptable
        );
    };
    
    get '/thumbnail/:id' => sub {
        http_choose_media_type (
            [ 'image/png', 'image/gif', 'image/jpeg' ]
                => sub { Thumbnail->new(param('id'))->to(http_chosen->minor) },
            { default => 'image/png' }, # must be one listed above
        );
    };
    
    dance;

=head1 HTTP ContentNegotiation

Clients that make an HTTP request can specify what kind of response they prefer.
This can be a specific MIME-type, a different language, the text-encoding (if it
applies to text documents) and wether it should be compressed or not. For this,
the HTTP specifications in RFC 7231 (HTTP/1.1 Semantics and Content) Section 5.3
explains how to use resp. Accept, Accept-Language, Accept-Charset and
Accept-Encoding header fields.

The server can try to send a response that the client would accept, but if there
is no respresentation avaialbe in that format or language, it has three options.
Either give a response in a different way, or respond with a status message 406,
Not Accaptable. Another option would provide a list of available formats.

=cut

use HTTP::Headers::ActionPack;

# use List::MoreUtils 'first_index';

our $negotiator = HTTP::Headers::ActionPack->new->get_content_negotiator;
our %http_headers = (
    'media_type'    => "Accept",
    'language'      => "Accept-Language",
    'charset'       => "Accept-Charset",
    'encoding'      => "Accept-Encoding",
);

=head1 DANCER2 KEYWORDS

Each of the 'http_choose_...' keywords take the following arguments:

=over

=item a paired list with 'selectors' and coderefs.

those selectors, be it a single one or a anonymous array ref, numerate the
available choices, the coderef following will be executed if there would be a
match.

=item an optional hashref with options.

The only option there is at this moment is 'default'. If not present and there
is no match, it will use the first mentioned selector. If spcified, it will take
that selector. Set to undef will return a status code of 406, Not Acceptable.

=back

    http_choose_selector (
        selection_1
            => sub { ... },
        [ selction_2, selection_3, selection_4 ]
            => sub { ... },
        { default => selection_3 }
    );

=cut

=head2 http_choose_media_type

This keyword is used to make a selection between different MIME-types. Please
use this explicit version, as there is also http_choose (there is no
Accept-MediaType, it's simply Accept)

=cut

register 'http_choose_media_type' => sub {
    return _http_choose ( @_, 'media_type' );
};

=head2 http_choose_language

This keyword works in conjunction with the Accept-Language.

=cut

register 'http_choose_language' => sub {
    return _http_choose ( @_, 'language' );
};

=head2 http_choose_charset

This keyword should only be used with non-binary media-types, like XML or JSON.
It is used to select in what 'encoding' the representation should be delivered.

NOTE: not sure yet how this word with the default UTF-8 Encoding of Dancer2.

=cut

register 'http_choose_charset' => sub {
    return _http_choose ( @_, 'charset' );
};

=head2 http_choose_encoding

Mainly used for specifying compressed or uncompressed content. It has nothing to
do whith character encoding though!

NOTE: not sure if this is the right place to compress files or not - maybe it
would be better of to do this in Middleware.

=cut

register 'http_choose_encoding' => sub {
    return _http_choose ( @_, 'encoding' );
};

=head2 http_choose

Naming compatability with the HTTP Headers, please use te explicit
'http_choose_media_type'

=cut

register 'http_choose' => sub {
    return _http_choose ( @_, 'media_type' );
};

sub _http_choose {
    my $dsl     = shift;
    my $switch  = pop; 
    my $options = (@_ % 2) ? pop : undef;
    
    my @choices = _parse_choices(@_);
    
    # prepare for default behaviour
    # default                ... if none match, pick first in definition list
    # default => 'choice'    ... takes this as response, must be defined!
    # default => undef       ... do not make assumptions, return 406
    my $choice_first = ref $_[0] eq 'ARRAY' ? $_[0]->[0] : $_[0];
    my $choice_default = $options->{'default'} if exists $options->{'default'};
    
#   # make sure that a 'default' is actually in the list of choices
#   
#   if ( $choice_default and not exists $choices{$choice_default} ) {
#       $dsl->app->log ( warning =>
#           qq|Invallid http_choose usage: |
#       .   qq|'$choice_default' does not exist in choices|
#       );
#       $dsl->status(500);
#       $dsl->halt;
#   }
    
    # choose from the provided definition
    my $selected = undef;
    my $method = 'choose' . '_' . $switch;
    if ( $dsl->request->header($http_headers{$switch}) ) {
        $selected = $negotiator->$method (
            [ map { $_->{selector} } @choices ],
            $dsl->request->header($http_headers{$switch})
        );
    };
    
    # if nothing selected, use sensible default
#   $selected ||= exists $options->{'default'} ? $options->{'default'} : $choice_first;
    unless ($selected) {
        $selected = $negotiator->$method (
            [ map { $_->{selector} }  @choices ],
            exists $options->{'default'} ? $options->{'default'} : $choice_first
        );
    };
    
    # if still nothing selected, return 406 error
    unless ($selected) {
        $dsl->status(406); # Not Acceptable
        $dsl->halt;
    };
    
    $dsl->vars->{"http_chosen_$switch"} = $selected;
    
    # set the apropriate headers for Content-Type and Content-Language
    # XXX Content-Type could consist of type PLUS charset if it's text-based
    if ($switch eq 'media_type') {
        $dsl->header('Content-Type' => "$selected" );
    };
    if ($switch eq 'language') {
        $dsl->header('Content-Language' => "$selected" );
    };
    
    $dsl->header('Vary' =>
        join ', ', $http_headers{$switch}, $dsl->header('Vary')
    ) if @choices > 1 ;
    
    my @coderefs = grep {$_->{selector} eq $selected} @choices;
    return $coderefs[0]{coderef}->($dsl);
};

=head2 http_chosen_media_type

returns a MediaType object that has been chosen.

This feature is experimental, but provides methods like type, major and minor

=cut

register 'http_chosen_media_type' => sub {
    return _http_chosen ( @_, 'media_type' );
};

=head2 http_chosen_language

returns the LanguageTag being chosen from the selectors.

Experimental too and should privde methods like language, primary, extlang,
script, region and variant

=cut

register 'http_chosen_language' => sub {
    return _http_chosen ( @_, 'language' );
};

=head2 http_chosen_charset

returns the chosen Charset.

=cut

register 'http_chosen_charset' => sub {
    return _http_chosen ( @_, 'charset' );
};

=head2 http_chose_encoding

returns wether or not the resouce should be compressed and how.

=cut

register 'http_chosen_encoding' => sub {
    return _http_chosen ( @_, 'encoding' );
};

=head2 http_chosen

Naming compatability with the HTTP Headers, please use te explicit
'http_chosen_media_type'

=cut

register 'http_chosen' => sub {
    return _http_chosen ( @_, 'media_type' );
};

sub _http_chosen {
    my $dsl     = shift;
    my $switch  = pop;
    
    $dsl->app->log ( error =>
        "http_chosen_$switch does not exist"
    ) unless exists $dsl->vars->{"http_chosen_$switch"}; 
    
    $dsl->app->log( error =>
        "http_chosen_$switch is designed for read-only"
    ) if (@_ >= 1);
    
    return unless exists $dsl->vars->{"http_chosen_$switch"};
    return $dsl->vars->{"http_chosen_$switch"};
};

on_plugin_import {
    my $dsl = shift;
    my $app = $dsl->app;
};

sub _parse_choices {
    # _parse_choices
    # unraffles a paired list into a list of hashes,
    # each hash containin a 'selector' and associated coderef.
    # since the 'key' can be an arrayref too, these are added to the list with
    # seperate values
    
    my @choices;
    while ( @_ ) {
        my ($choices, $coderef) = @{[ shift, shift ]};
        last unless $choices;
        # turn a single value into a ARRAY REF
        $choices = [ $choices ] unless ref $choices eq 'ARRAY';
        # so we only have ARRAY REFs to deal with
        foreach ( @$choices ) {
            if ( ref $coderef ne 'CODE' ) {
                die
                    qq{Invallid http_choose usage: }
                .   qq{'$_' needs a CODE ref};
            }
#           if ( exists $choices{$_} ) {
#               die
#                   qq{Invallid http_choose usage: }
#               .   qq{Duplicated choice '$_'};
#           }
            push @choices,
            {
                selector => $_,
                coderef  => $coderef,
            };
        }
    }
    return @choices;
}; # _parse_choices

register_plugin;

=head1 CAVEATS

the underlying HTTP::ActionPack has it's own bugs - for the time being this
module uses those modules and will suffer from many of the shortcommings that
come from using ActionPack.

=head1 AUTHOR

Theo van Hoesel, C<< <Th.J.v.Hoesel at THEMA-MEDIA.nl> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dancer2-plugin-http-contentnegotiation at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer2-Plugin-HTTP-ContentNegotiation>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::HTTP::ContentNegotiation


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer2-Plugin-HTTP-ContentNegotitioan>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer2-Plugin-HTTP-ContentNegotiation>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer2-Plugin-HTTP-ContentNegotiation>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer2-Plugin-HTTP-ContentNegotiation/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Theo van Hoesel.

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

1;
