package App::ZofCMS::Plugin::InstalledModuleChecker;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

sub new { bless {}, shift }
sub process {
    my ( $self, $t, $q, $config ) = @_;

    my $modules = delete $t->{plug_installed_module_checker};

    $modules = delete $config->conf->{plug_installed_module_checker}
        unless defined $modules;

    return
        unless defined $modules;

    my @results;
    for ( @$modules ) {
        eval "use $_";
        if ( $@ ) {
            push @results, { info => "$_ IS NOT INSTALLED: $@" };
        }
        else {
            push @results, { info => "$_ IS INSTALLED [version " . $_->VERSION . " ]" };
        }
    }
    $t->{t}{plug_installed_module_checker} = \@results;
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::InstalledModuleChecker - utility plugin to check for installed modules on the server

=head1 SYNOPSIS

In ZofCMS Template or Main Config File:

    plugins => [
        qw/InstalledModuleChecker/,
    ],

    plug_installed_module_checker => [
        qw/ Image::Resize
            Foo::Bar::Baz
            Carp
        /,
    ],

In HTML::Template template:

    <ul>
        <tmpl_loop name='plug_installed_module_checker'>
        <li>
            <tmpl_var escape='html' name='info'>
        </li>
        </tmpl_loop>
    </ul>

=head1 DESCRIPTION

The module is a utility plugin for L<App::ZofCMS> that provides means to check for whether
or not a particular module is installed on the server and get module's version if it is
installed.

The idea for this plugin came to me when I was constantly writing "little testing scripts"
that would tell me whether or not a particular module was installed on the crappy
server that I have to work with all the time.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and
L<App::ZofCMS::Template>

=head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

=head2 C<plugins>

    plugins => [
        qw/InstalledModuleChecker/,
    ],

B<Mandatory>. You need to include the plugin in the list of plugins to execute.

=head2 C<plug_installed_module_checker>

    plug_installed_module_checker => [
        qw/ Image::Resize
            Foo::Bar::Baz
            Carp
        /,
    ],

B<Mandatory>. Takes an arrayref as a value.
Can be specified in either ZofCMS Template or Main Config File; if set in
both, the value in ZofCMS Template takes precedence. Each element of the arrayref
must be a module name that you wish to check for "installedness".

=head1 OUTPUT

    <ul>
        <tmpl_loop name='plug_installed_module_checker'>
        <li>
            <tmpl_var escape='html' name='info'>
        </li>
        </tmpl_loop>
    </ul>

Plugin will set C<< $t->{t}{plug_installed_module_checker} >> (where C<$t> is ZofCMS Template
hashref) to an arrayref of hashrefs; thus, you'd use a C<< <tmpl_loop> >> to view the info.
Each hashref will have only one key - C<info> - with information about whether or
not a particular module is installed.

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