package Dancer2::Plugin::HTTP::Caching;

=head1 NAME

Dancer2::Plugin::HTTP::Caching - RFC 7234 compliant

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use warnings;
use strict;

use Carp;
use Dancer2::Plugin;

use HTTP::Date;

=head1 SYNOPSIS

Setting the HTTP response headers 'Expire' and 'Cache-Control' according to
RFC 7234

    
    use Dancer2;
    use Dancer2::Plugin::HTTP::Caching;
    
    get '/aging' => sub {
        http_cache_max_age          3600; # one hour
        http_cache_private;
        http_cache_must_revalidate;
        http_cache_no_cache         'Set-Cookie';
        http_cache_no_cache         'WWW-Authenticate';
        http_expire                 'Thu, 31 Dec 2015 23:23:59 GMT';
        
        "This content must be refreshed within 1 Hour\"
    };
    

=head1 RFC_7234 HTTP: Caching

That RFC describes a lot on how to store and respond with cached data. But
basically, to make caching work it falls in two parts:

1) A origin server that SHOULD provide a expiration-date and or directives that
tell the cache long it can hold the data. That is basically enough for
web-server to do, sending off information about freshness.

2) A caching server that once in a while checks with the origin server what to
do with it's cached-data, a process called validation. Validation is handled by
conditional-requests using request headers like 'If-Modified-Since' and when
not, the server SHOULD send a status of 304 (Not Modified).

Handling conditional requests by the server is beyond the scope of this caching
plugin, and is not described as such in the RFC. For this to work, use the
Dancer2::Plugin::HTTP-ConditionalRequest

Maybe in a future release there might be a option to have a cache run inside the
Dancer app, but if one wants a cache in the origin server, one could simply use
plack middle ware that will implement it (Although there is not even one module
on CPAN that actually does it right)

=head1 Dancer2 Keywords

No further explenation is given, see the RFC itself.

=cut

=head2 http_cache_must_revalidate

see RFC 7234: ¤ 5.2.2.1.  must-revalidate

=cut

# RFC 7234: ¤ 5.2.2.1.  must-revalidate
register http_cache_must_revalidate => sub {
        shift->_append_cache_control_directive('must-revalidate' => @_);
    return;
};

=head2 http_cache_no_cache

see RFC 7234: ¤ 5.2.2.2.  no-cache

takes a string, or a list of strings of HTTP-Response Header-fields

=cut

# RFC 7234: ¤ 5.2.2.2.  no-cache
register http_cache_no_cache => sub {
    shift->_append_cache_control_directive_quoted('no-cache' => @_);
    return;
};

=head2 http_cache_no_store

see RFC 7234: ¤ 5.2.2.3.  no-store

=cut

# RFC 7234: ¤ 5.2.2.3.  no-store
register http_cache_no_store => sub {
    shift->_append_cache_control_directive('no-store' => @_);
    return;
};

=head2 http_cache_no_transform

see RFC 7234: ¤ 5.2.2.4.  no-transform

=cut

# RFC 7234: ¤ 5.2.2.4.  no-transform
register http_cache_no_transform => sub {
    shift->_append_cache_control_directive('no-transform' => @_);
    return;
};

=head2 http_cache_public

see RFC 7234: ¤ 5.2.2.5.  public

=cut

# RFC 7234: ¤ 5.2.2.5.  public
register http_cache_public => sub {
    shift->_append_cache_control_directive('public' => @_);
    return;
};

=head2 http_cache_private

see RFC 7234: ¤ 5.2.2.6.  private

takes a string, or a list of strings of HTTP-Response Header-fields

=cut

# RFC 7234: ¤ 5.2.2.6.  private
register http_cache_private => sub {
    shift->_append_cache_control_directive_quoted('private' => @_);
    return;
};

=head2 http_cache_proxy_revalidate

see RFC 7234: ¤ 5.2.2.7.  proxy-revalidate

=cut

# RFC 7234: ¤ 5.2.2.7.  proxy-revalidate
register http_cache_proxy_revalidate => sub {
    shift->_append_cache_control_directive('proxy-revalidate' => @_);
    return;
};

=head2 http_cache_max_age

see RFC 7234: ¤ 5.2.2.8.  max-age

takes a 'delta-seconds' integer

=cut

# RFC 7234: ¤ 5.2.2.8.  max-age
register http_cache_max_age => sub {
    shift->_append_cache_control_directive_seconds('max-age' => @_);
    return;
};

=head2 http_cache_s_maxage

see RFC 7234: ¤ 5.2.2.9.  max-age

takes a 'delta-seconds' integer

=cut

# RFC 7234: ¤ 5.2.2.9.  s-maxage
register http_cache_s_maxage => sub {
    shift->_append_cache_control_directive_seconds('s-maxage' => @_);
    return;
};

=head2 http_expire

This Keywords set one of the two HTTP response headers that are related to
caching. It takes a HTTP Date formatted string that will tell any caching server
that the stored respource should be refreshed after the specified date/time

See RFC 7234: ¤ 5.3

=cut

# RFC 7234: ¤ 5.3.      Expires
register http_expire => sub {
    $_[0]->log( warning =>
        "http_expire: missing date" )
        unless  $_[1];
    $_[0]->header('Expires' => $_[1]);
    return;
};

sub _append_cache_control {
    my $dsl         = shift;
    my $directive   = shift;
    my $value       = shift;
    
    $dsl->header('Cache-Control' =>
        join ', ',
            $dsl->header('Cache-Control'),
            ( defined $value ? join '=', $directive, $value : $directive)
    );
    return $dsl->header('Cache-Control')
};

sub _append_cache_control_directive {
    my $dsl         = shift;
    my $directive   = shift;
    
    $dsl->log( warning =>
        "http_cache_control: '$directive' does not take any parameters"
    ) if @_ ;
    
    return $dsl->_append_cache_control($directive, undef);
};

sub _append_cache_control_directive_seconds {
    my $dsl         = shift;
    my $directive   = shift;
    my $seconds     = shift || 0;
    
    $dsl->log( warning =>
        "http_cache_control: '$directive' does only take 'delta-seconds'"
    ) if @_ ;
    
    $dsl->log( error =>
        "http_cache_control: '$directive' requires number of seconds"
    ) unless $seconds =~ /\d+/ ;
    
    my $value = $seconds;
    return $dsl->_append_cache_control($directive, $value);
};

sub _append_cache_control_directive_quoted {
    my $dsl         = shift;
    my $directive   = shift;
    my @strings     = ref $_[0] eq 'ARRAY' ? @$_[0] : @_; 
#   my @strings     = @_; 
    
    my $value = @strings ? '"' . join(' ', @strings) . '"' : undef;
    return $dsl->_append_cache_control($directive, $value);
};



on_plugin_import {
    my $dsl = shift;
    my $app = $dsl->app;
};

register_plugin;

=head1 AUTHOR

Theo van Hoesel, C<< <Th.J.v.Hoesel at THEMA-MEDIA.nl> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dancer2-plugin-http-caching at rt.cpan.org>, or through the web
interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer2-Plugin-HTTP-Caching>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::HTTP::Caching


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer2-Plugin-HTTP-Caching>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer2-Plugin-HTTP-Caching>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer2-Plugin-HTTP-Caching>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer2-Plugin-HTTP-Caching/>

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
