package App::ZofCMS::Plugin::AutoDump;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

use Data::Dumper;

sub new { bless {}, shift }

sub process {
    my ( $self, $t, $q ) = @_;

    die Dumper [
        $q,
        $t,
    ];
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::AutoDump - debugging plugin to quickly dump out
query parameters and ZofCMS Template hashref

=head1 SYNOPSIS

    plugins => [
        { Sub => 200 },
        { AutoDump => 300 },
    ],

    plug_sub => sub { ## this is optional, just for an example
        my ( $t, $q ) = @_;
        $t->{foo} = 'bar';
        $q->{foo} = 'bar';
    },

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that provides means to quickly use L<Data::Dumper>
to dump query parameters hashref as well as ZofCMS Template hashref.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 HOW TO USE

    plugins => [
        { Sub => 200 },
        { AutoDump => 300 },
    ],

This plugin requires no configuration. To run it simply include it in the list of plugins
to execute with the priority set at the right point of execution line.

=head1 HOW IT WORKS

Plugin assumes that you're using L<CGI::Carp> (should be on by default if you've used
C<zofcms_helper> script to generate site's skeleton). When plugin is run it calls
C<die Dumper [ $q, $t ]> where C<$q> is query parameters hashref and C<$t> is
ZofCMS Template hashef... therefore, in the browser's output the first hashef is the query.

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