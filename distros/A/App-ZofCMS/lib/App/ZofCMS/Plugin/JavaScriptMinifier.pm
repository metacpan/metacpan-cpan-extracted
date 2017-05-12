package App::ZofCMS::Plugin::JavaScriptMinifier;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

use JavaScript::Minifier (qw/minify/);
use base 'App::ZofCMS::Plugin::Base';

sub _key { 'plug_js_minifier' }
sub _defaults {
    auto_output => 1,
    cache       => 1,
    file        => undef,
}
sub _do {
    my ( $self, $conf, $t ) = @_;

    return
        unless defined $conf->{file}
            and length $conf->{file};

    -e $conf->{file}
        or die "$conf->{file} was not found";

    open my $fh, '<', $conf->{file}
        or die "$conf->{file} could not be opened for reading: $!";

    my $js = minify( input => $fh );

    if ( $conf->{auto_output} ) {
        if ( $conf->{cache} ) {
            print "Expires: Fri, 29 Oct 2038 14:19:41 GMT\n"
        }
        print "Content-type: text/javascript\n\n";
        print $js;
        exit;
    }
    else {
        $t->{t}{plug_js_minifier} = $js;
    }
}
1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::JavaScriptMinifier - plugin for minifying JavaScript files

=head1 SYNOPSIS

In your ZofCMS Template or Main Config File:

    plugins => [
        qw/JavaScriptMinifier/,
    ],

    plug_js_minifier => {
        file => 'main.js',
    },

Now, this page can be linked into your document as a JavaScript file (it
will be minified)

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that provides means to send minified JavaScript files.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 WTF IS MINIFIED?

Minified means that all the useless stuff (which means whitespace, etc)
will be stripped off the JavaScript file to save a few bytes. See L<JavaScript::Minifier> for more info.

=head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

=head2 C<plugins>

    plugins => [
        qw/JavaScriptMinifier/,
    ],

B<Mandatory>. You need to include the plugin to the list of plugins to execute.

=head2 C<plug_js_minifier>

    plug_js_minifier => {
        file        => 'main.js',
        auto_output => 1, # default value
        cache       => 1, # default value
    },

    plug_js_minifier => sub {
        my ( $t, $q, $config ) = @_;
        return {
            file        => 'main.js',
            auto_output => 1,
            cache       => 1,
        };
    },

B<Mandatory>. Takes a hashref or a subref as a value. If subref is specified,
its return value will be assigned to C<plug_js_minifier> as if it was already there. If sub returns
an C<undef>, then plugin will stop further processing. The C<@_> of the subref will
contain (in that order): ZofCMS Tempalate hashref, query parameters hashref and
L<App::ZofCMS::Config> object. Individual keys can be set in both Main Config
File and ZofCMS Template, if the same key set in both, the value in ZofCMS Template will
take precedence. The following keys/values are accepted:

=head3 C<file>

    plug_js_minifier => {
        file        => 'main.js',
    }

B<Mandatory>. Takes a string as an argument that specifies the name of the
JavaScript file to minify. The filename is relative to C<index.pl> file.

=head3 C<cache>

    plug_js_minifier => {
        file        => 'main.js',
        cache       => 1,
    },

B<Optional>. Takes either true or false values. When set to a true value the plugin will
send out an HTTP C<Expires> header that will say that this content expries in like 2038, thus
B<set this option to a false value while still developing your JavaScript>. This argument
has no effect when C<auto_output> (see below) is turned off (set to a false value).
B<Defaults to:> C<1>

=head3 C<auto_output>

    plug_js_minifier => {
        file        => 'main.js',
        auto_output => 1,
    },

B<Optional>. Takes either true or false values. When set to a true value, plugin will
automatically send C<text/javascript> C<Content-type> header (along with C<Expires> header if
C<cache> argument is set to a true value), output the minified JavaScript file B<and exit()>.
Otherwise, the minified JavaScript file will be put into C<< $t->{t}{plug_js_minifier} >>
where C<$t> is ZofCMS Template hashref and you can do whatever you want with it.
B<Defaults to:> C<1>

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