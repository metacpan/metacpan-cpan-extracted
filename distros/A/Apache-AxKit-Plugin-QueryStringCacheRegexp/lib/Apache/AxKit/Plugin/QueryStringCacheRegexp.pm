# $Id: QueryStringCacheRegexp.pm,v 1.12 2006/08/07 14:12:06 c10232 Exp $
package Apache::AxKit::Plugin::QueryStringCacheRegexp;

use strict;
use Apache::Constants qw(OK);
use Apache::Request;

our $VERSION = '0.04';

sub handler {
    my $r = shift;
    my $cache_extra;

    # An extra bend to correctly make multiple-valued CGI-Parameters
    # significant by concatenating them. (The whole exercise is to
    # create a "axkit_cache_extra"-string that depends as little as
    # possible on how the QueryString "looks"; i.e. the order of the
    # parameters should not be significant unless there are multiple
    # occurences of the same key)
    my @args = $r->args();
    my %args;
    while (@args) {$args{ shift(@args) } .= shift(@args);}
    
    my $use = $r->dir_config('AxQueryStringCacheRegexpUse') || '^\w+$';             #'
    my $ignore = $r->dir_config('AxQueryStringCacheRegexpIgnore') || undef;

    foreach (sort keys %args) {
        if ( length $_ && /$use/ && ( (not defined $ignore) || (not /$ignore/) ) ) {
            $cache_extra .= $_ . "=" . $args{$_} . ";";
        }
    }

    AxKit::Debug(7, "[QueryStringCacheRegexp] QueryString in: " . $r->args . " significant for caching: $cache_extra");

    $r->notes('axkit_cache_extra', $r->notes('axkit_cache_extra') . $cache_extra);

    return OK;
}

1;
__END__

=head1 NAME

Apache::AxKit::Plugin::QueryStringCacheRegexp - Cache based on QS and
regular expression matching

=head1 SYNOPSIS

  SetHandler axkit
  AxAddPlugin Apache::AxKit::Plugin::QueryStringCacheRegexp
  PerlSetVar AxQueryStringCacheRegexpUse    '\w{2,15}'
  PerlSetVar AxQueryStringCacheRegexpIgnore 'foo.*'

=head1 DESCRIPTION

This module is a replacement for
Apache::AxKit::Plugin::QueryStringCache.  It offers the following at the
expense of a little overhead:

The querystring is "taken apart", the parameters are matched against a
positive (I<use>) and a negative (I<ignore>) pattern, both to be
specified in F<httpd.conf>. A changed order of parameters, old (C<&>)
vs. new-style (C<;>) delimiters or multiple occurances of the same
parameter will not force AxKit to retransform a document.

Parameters taken into account will have to match the I<use>-pattern
I<and not> match the I<ignore>-pattern (if given).

Setting C<AxDebugLevel 7> or greater prints some debug-info to the log.

C<PerlSetVar AxQueryStringCacheRegexpUse    '^\w{2,15}$'>

Takes a perl regular expression; C<^\w+$> is used if omitted.

C<PerlSetVar AxQueryStringCacheRegexpIgnore '^foo.*'>

Takes a perl regular expression; No negative matching is made if
omitted.

In this example above, one defines all parameters of 2 to 15
alphanumeric characters which do not begin with "foo", as significant
for the cache.

=head1 BUGS/FEATURES

None known at this time.

=head1 SEE ALSO

L<Apache::AxKit::Plugin::QueryStringCache>

L<http://www.axkit.org/>

L<http://www.axkitbook.com/>

=head1 AUTHOR

Hansjoerg Pehofer, E<lt>hansjoerg.pehofer@uibk.ac.atE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2006 by Hansjoerg Pehofer

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.4 or, at
your option, any later version of Perl 5 you may have available.

=cut
