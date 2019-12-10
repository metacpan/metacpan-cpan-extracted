package App::ZofCMS::Plugin::Sub;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

sub new { bless {}, shift }

sub process {
    my ( $self, $template, $query, $config ) = @_;
    my $sub = $template->{plug_sub} ? $template->{plug_sub} : $config->conf->{plug_sub};
    return
        unless defined $sub;

    delete $template->{plug_sub};
    delete $config->conf->{plug_sub};

    $sub->( $template, $query, $config );
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::Sub - plugin to execute a subroutine, i.e. sub with priority setting

=head1 SYNOPSIS

In your Main Config File or ZofCMS Template file:

    plugins => [ { Sub => 1000 }, ], # set needed priority
    plug_sub => sub {
        my ( $template, $query, $config ) = @_;
        # do stuff
    }

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that allows you to execute a sub... by setting
plugin's priority setting you, effectively, can set the priority of the sub. Not much but I
need this.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 MAIN CONFIG FILE AND ZofCMS TEMPLATE FIRST-LEVEL KEYS

=head2 C<plugins>

    plugins => [ { Sub => 1000 }, ], # set the needed priority here

You obviously need to add the plugin in the list of plugins to exectute. Since the entire
purpose of this plugin is to execute the sub with a certain priority setting, you'd set
the appropriate priority in the plugin list.

=head2 C<plug_sub>

    plug_sub => sub {
        my ( $template, $query, $config ) = @_;
    }

Takes a subref as a value.
The plugin will not run unless C<plug_sub> first-level key is present in either Main Config
File or ZofCMS Template file. If the key is specified in both files, the sub set in
ZofCMS Template will take priority. The sub will be executed when plugin is run. The
C<@_> will contain (in that order): ZofCMS Template hashref, query parameters hashref
where keys are parameter names and values are their values, L<App::ZofCMS::Config> object.

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