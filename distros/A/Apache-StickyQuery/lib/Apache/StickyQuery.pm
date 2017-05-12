package Apache::StickyQuery;

use strict;
use vars qw($VERSION);
$VERSION = '0.02';

use Apache::Constants qw(:common);
use Apache::File;
use Carp ();
use HTML::StickyQuery;

sub handler ($$) {
    my($class, $r) = @_;

    my $filtered = uc($r->dir_config('Filter')) eq 'ON';
    $r = $r->filter_register if $filtered;

    # only for text/html
    return DECLINED unless ($r->content_type eq 'text/html' && $r->is_main);

    my($fh, $status);
    if ($filtered) {
	($fh, $status) = $r->filter_input;
	undef $fh unless $status == OK;
    } else {
	$fh = Apache::File->new($r->filename);
    }

    return DECLINED unless $fh;

    $r->send_http_header;

    local $/;			# slurp
    my $input = <$fh>;

    my $stickyquery = $class->make_stickyquery($r);
    my $paramref    = $class->retrieve_param($r);

    $r->print($stickyquery->sticky(
	scalarref => \$input, param => $paramref,
    ));
    return OK;
}

sub make_stickyquery {
    my($class, $r) = @_;
    my %opt = map {
	my $key = 'StickyQuery' . ucfirst($_);
	my $val = $r->dir_config($key);
	defined $val ? ($key => $val) : ();
    } qw(abs regexp override);
    return HTML::StickyQuery->new(%opt);
}

sub retrieve_param {
    my($class, $r) = @_;
    my %in = $r->args;
    return \%in;
}

1;
__END__

=head1 NAME

Apache::StickyQuery - rewrites links using sticky query

=head1 SYNOPSIS

  # in httpd.conf
  <Location /stickyquery>
  SetHandler perl-script
  PerlHandler Apache::StickyQuery
  </Location>

  # filter aware
  PerlModule Apache::StickyQuery
  SetHandler perl-script
  PerlSetVar Filter On
  PerlHandler Apache::RegistryFilter Apache::StickyQuery Apache::Compress

=head1 DESCRIPTION

Suppose page transactions like this:

       foo.cgi       =>   bar.html       =>   baz.cgi
     ?sid=0123456                           ?sid=0123456

It is difficult to keep sid query parameter between two cgis without
cookies (or mod_rewrite hacks).

Apache::StickyQuery is a filter that rewrites all links in HTML file
using "sticky query". It would be useful in keeping state (ie. like
Session IDs) without using Cookies. See L<HTML::StickyQuery> for
details.

This module is Filter aware, meaning that it can work within
Apache::Filter framework without modification.

=head1 CONFIGURATION

StickyQuery parameters are automatically retrieved via current query
string. Options to change this is one of TODOs. (Hint: inherit from
Apache::StickyQuery and override C<retrieve_param>)

Apache::StickyQuery has the following configuration variables.

  PerlSetVar StickyQueryAbs 0
  PerlSetVar StickyQueryOverride 1
  PerlSetVar StickyQueryRegexp ^/cgi-bin/

each of which corresponds to those of HTML::StickyQuery. See
L<HTML::StickyQuery> for details.

=head1 AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTML::StickyQuery>, L<Apache::Filter>

=cut
