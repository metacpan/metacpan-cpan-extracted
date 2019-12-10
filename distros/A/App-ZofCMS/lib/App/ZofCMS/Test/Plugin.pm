package App::ZofCMS::Test::Plugin;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

use base 'Test::Builder::Module';

my $Test = Test::Builder->new;

sub import {
    my $self = shift;
    my $caller = caller;
    no strict 'refs';
    *{$caller.'::plugin_ok'}   = \&plugin_ok;

    $Test->exported_to($caller);
    $Test->plan( tests => 3);
}

sub plugin_ok {
    my ( $plugin_name, $template_with_input, $query, $config_hash ) = @_;

    $template_with_input ||= {};
    $query ||= {};

    eval "use App::ZofCMS::Plugin::$plugin_name";
    if ( $@ ) {
        $Test->ok(1);
        $Test->ok(1);
        $Test->ok(1);
        $Test->diag("Failed to use App::ZofCMS::Plugin::$plugin_name");
        exit 0;
    }
    my $o = "App::ZofCMS::Plugin::$plugin_name"->new;
    $Test->ok( $o->can('new'), "new() method is available");
    $Test->ok( $o->can('process'), "process() method is available");

    SKIP: {
        eval "use App::ZofCMS::Config";
        if ( $@ ) {
            $Test->ok (1);
            $Test->diag ("App::ZofCMS::Config is required for process() testing");
            last;
        }

        my $config = App::ZofCMS::Config->new;
        $config->conf( $config_hash || {} );

        $o->process( $template_with_input, $query, $config );

        delete @$template_with_input{ qw/t d conf plugins/ };
        $Test->ok( 0 == keys %$template_with_input,
            "Template must be empty after deleting {t}, {d}, {conf}"
            . " and {plugins} keys"
        );

        $Test->diag(
            "Query ended up as: \n" . join "\n", map
                "[$_] => [$query->{$_}]", keys %$query
        );
    }
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Test::Plugin - test module for testing ZofCMS plugins

=head1 SYNOPSIS

    #!/usr/bin/env perl

    use strict;
    use warnings;

    use Test::More;

    eval "use App::ZofCMS::Test::Plugin;";
    plan skip_all
    => "App::ZofCMS::Test::Plugin required for testing plugin"
        if $@;

    plugin_ok(
        'PlugName',  # plugin's name
        { input => 'Foo' }, # plugin takes input via first level 'input' key
        { foo => 'bar'   }, # query parameters
    );

=head1 DESCRIPTION

The module provides a basic test suit for ZofCMS plugins. See SYNOPSIS
for usage. That would be in one of your t/test.t files.

=head2 plugin_ok

    plugin_ok(
        'PlugName',  # plugin's name
        { input => 'Foo' }, # plugin takes input via first level 'input' key
        { foo => 'bar'   }, # query parameters
        { foo => 'bar'   }, # the loaded "main config" file hashref
    );

Takes three arguments, second, third and fourth are optional.
First argument is the name
of your plugin with the C<App::ZofCMS::Plugin::> part stripped off (i.e.
the name that you would use in ZofCMS template to include the plugin).
Second parameter is optional, it must be a hashref which would represent
the input from your plugin. In the example above the plugin takes input
via first level key C<input> in ZofCMS template. This is basically to
check that any first level keys used by the plugin are deleted by the
plugin. Third parameter is optional and is also a hashref which represents
query parameters with keys being parameters names and values being
parameters' values. Use this if your plugin depends on some query
parameters. Fourth parameter is again a hashref which represents the
hashref normally present in ZofCMS "main configuration file".

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