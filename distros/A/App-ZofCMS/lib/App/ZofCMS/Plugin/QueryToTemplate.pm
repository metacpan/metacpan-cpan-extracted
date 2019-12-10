package App::ZofCMS::Plugin::QueryToTemplate;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

sub new { bless {}, shift; }

sub process {
    my ( $self, $template, $query, $config  ) = @_;

    keys %$query;
    while ( my ( $key, $value ) = each %$query ) {
        $template->{t}{"query_$key"} = $value;
    }

    return;
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::QueryToTemplate - ZofCMS plugin to automagically make query parameters available in the template

=head1 SYNOPSIS

In your ZofCMS template, or in your main config file (under C<template_defaults>
or C<dir_defaults>):

    plugins => [ qw/QueryToTemplate/ ];

In any of your L<HTML::Template> templates:

    <tmpl_var name="query_SOME_QUERY_PARAMETER_NAME">

=head1 DESCRIPTION

Plugin can be run at any priority level and it does not take any input from
ZofCMS template.

Upon plugin's execution it will stuff the C<{t}> first level key (see
L<App::ZofCMS::Template> if you don't know what that key is) with all
the query parameters as keys and values being the parameter values. Each
query parameter key will be prefixed with C<query_>. In other words,
if your query looks like this:

    http://foo.com/index.pl?foo=bar&baz=beerz

In your template parameter C<foo> would be accessible as C<query_foo>
and parameter C<baz> would be accessible via C<query_baz>

    Foo is: <tmpl_var name="query_foo">
    Baz is: <tmpl_var name="query_baz">

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/App-ZofCMS>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/App-ZofCMS/issues>

If you can't access GitHub, you can email your request
to C<bug-App-ZofCMS at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut