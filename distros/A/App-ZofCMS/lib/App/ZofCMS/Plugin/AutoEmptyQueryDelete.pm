package App::ZofCMS::Plugin::AutoEmptyQueryDelete;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

sub new { bless {}, shift }

sub process {
    my ( $self, $t, $q ) = @_;

    my @delete;
    for ( keys %$q ) {
        push @delete, $_
            unless defined $q->{$_}
                and length $q->{$_};
    }

    delete @$q{ @delete };
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::AutoEmptyQueryDelete - automatically delete empty keys from query parameters

=head1 SYNOPSIS

    plugins => [
        { AutoEmptyQueryDelete => 100 },
        # plugins that work on query parameters with larger priority value
    ],

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that I made after I got sick and tired of
constantly writing this (where C<$q> is query parameters hashref):

    do_something
        if defined $q->{foo}
            and length $q->{foo};

By simply including this module in the list of plugins to run, I can save a few keystrokes
by writing:

    do_something
        if exists $q->{foo};

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 WHAT DOES THE PLUGIN DO

The plugin doesn't do much, but simply C<delete()>s query parameters that are not defined
or are of zero length if they are. With that being done, we can use a simple C<exists()>
on a key.

=head1 USING THE PLUGIN

Plugin does not need any configuration. It will be run as long as it is included
in the list of the plugins to run:

    plugins => [
        { AutoEmptyQueryDelete => 100 },
        # plugins that work on query parameters with larger priority value
    ],

Make sure that the priority of the plugin is set to run B<before> your other code
that would check on query with C<exists()>

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