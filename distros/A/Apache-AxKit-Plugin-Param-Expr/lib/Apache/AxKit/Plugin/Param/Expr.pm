package Apache::AxKit::Plugin::Param::Expr;
use strict;

our $VERSION = 0.2;
use Apache::Constants qw(OK);
use Apache::Request;

sub handler {
    my $r = shift;
    my @param = $r->dir_config->get('AxParamExpr');
    $r->pnotes('INPUT',{}) unless $r->pnotes('INPUT');
    my $apr = Apache::Request->instance($r);
    while (@param > 1) {
        my $val = eval($param[-1]);
        AxKit::Debug(5,"param '$param[-2]': ($param[-1]) = $val");
        throw Apache::AxKit::Exception::Error(-text => "AxParamExpr '$param[-2]': $@") if $@;
        $val = '' if !defined $val;
        $r->pnotes('INPUT')->{$param[-2]} = $val;
        $apr->param($param[-2],$val);
        pop @param;
        pop @param;
    }
    my $key = '';
    @param = $r->dir_config->get('AxCacheParamExpr');
    while (@param > 1) {
        my $val = eval($param[-1]);
        AxKit::Debug(5,"param '$param[-2]': ($param[-1]) = $val");
        throw Apache::AxKit::Exception::Error(-text => "AxCacheParamExpr '$param[-2]': $@") if $@;
        $val = '' if !defined $val;
        $r->pnotes('INPUT')->{$param[-2]} = $val;
        $apr->param($param[-2],$val);
        $key .= '|'.$val;
        pop @param;
        pop @param;
    }
    @param = $r->dir_config->get('AxCacheExpr');
    while (@param) {
        my $val = $r->pnotes('INPUT')->{$param[0]};
        AxKit::Debug(5,"param '$param[0]': () = $val");
        throw Apache::AxKit::Exception::Error(-text => "AxCacheExpr '$param[0]': $@") if $@;
        $val = '' if !defined $val;
        $key .= '|'.$val;
        shift @param;
    }
    $r->notes('axkit_cache_extra', $r->notes('axkit_cache_extra') . $key);
    return OK;
}

1;
__END__

=head1 NAME

Apache::AxKit::Plugin::Param::Expr - Add arbitrary expressions as AxKit parameters

=head1 SYNOPSIS

  AxAddPlugin Apache::AxKit::Plugin::Param::Expr
  PerlAddVar AxParamExpr uri '$r->uri'
  PerlAddVar AxCacheParamExpr day 'time()/86400'
  PerlAddVar AxCacheExpr '$r->connection->user'

=head1 DESCRIPTION

This plugin allows you to define additional AxKit parameters (used via
toplevel <xsl:param name="..."/> elements in XSLT or $cgi->param('...') in
XSP). Parameters declared this way override any submitted form content or
query string parameters.
Use 'AxParamExpr' for values that do not influence caching behaviour and
'AxCacheParamExpr' for values that do. In the example above, parameter "uri"
does not modify cache validity (the uri is already part of the cache key)
while "day" does (every new day all cached pages become invalid - somebody
better cleaned up the cache regularly, since the new pages will have a
different cache key).
For symmetry, 'AxCacheExpr' allows you to change the caching behaviour
without adding a parameter. The above example could be used to tell the cache
that every user has different pages.

=head1 AUTHOR and LICENSE

Copyright (C) 2004, Jörg Walter.

This plugin is licensed under either the GNU GPL Version 2, or the Perl Artistic
License.

=cut

