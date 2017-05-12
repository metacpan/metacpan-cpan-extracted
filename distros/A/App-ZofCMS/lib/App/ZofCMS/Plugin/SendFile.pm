package App::ZofCMS::Plugin::SendFile;

use warnings;
use strict;

our $VERSION = '1.001007'; # VERSION

use MIME::Types;
use File::Spec;

sub new { bless {}, shift; }

sub process {
    my ( $self, $t, $q, $config ) = @_;

    my $file = delete $t->{plug_send_file};

    $file = delete $config->conf->{plug_send_file}
        unless defined $file
            and length $file;

    if ( ref $file eq 'CODE' ) {
        $file = $file->( $t, $q, $config );
    }

    return
        unless defined $file
            and length $file;

    my ( $disposition, $type, $filename );
    if ( ref $file eq 'ARRAY' ) {
        ( $file, $disposition, $type, $filename ) = @$file;
    }

    $filename = (File::Spec->splitdir( $file ))[-1]
        unless defined $filename;

    $disposition = 'inline'
        unless defined $disposition;

    open my $fh, '<', $file
        or do { $t->{t}{plug_send_file_error} = $!; return; };

    $type = MIME::Types->new->mimeTypeOf($file)
        unless defined $type;

    $type = 'application/octet-stream'
        unless defined $type;

    print "Content-Disposition: $disposition; filename=$filename\n";

    print "Content-Type: $type\n\n";
    print for <$fh>;
    exit;
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::SendFile - plugin for flexible sending of files as well as files outside of web-accessible directory

=head1 SYNOPSIS

In your ZofCMS Template or Main Config File:

    plugins => [ qw/SendFile/ ],

    plug_send_file => [
        '../zcms_site/config.txt',  # filename to send; this one is outside the webdir
        'attachment',               # optional to set content-disposition to attachment
        'text/plain',               # optional to set content-type instead of guessing one
        'LOL.txt',                  # optional to set filename instead of using same as original
    ],

In your HTML::Template template:

    <tmpl_if name='plug_send_file_error'>
        <p class="error">Got error: <tmpl_var escape='html' name='plug_send_file_error'></p>
    </tmpl_if>

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that provides means for flexible sending of files
(e.g. sending it as an attachment (for download) or changing the filename), most important
feature of the plugin is that you can use it to send files outside of web-accessible
directory which in conjunction with say L<App::ZofCMS::Plugin::UserLogin> can provide user
account restricted file sending.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and
L<App::ZofCMS::Template>

=head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

=head2 C<plugins> and notes on exiting

    plugins => [ qw/SendFile/ ],

    plugins => [
        { UserLogin => 200 },
        { SendFile  => 300 },
    ],

We need to include the plugin in the list of plugins to execute; ensure to get the right
priority if you're using other plugins.

B<NOTE:> unless an error occurs, the plugins calls C<exit()> when it's done sending the file,
make sure that all the required plugins had their chance to execute BEFORE this one.

=head2 C<plug_send_file>

    plug_send_file => 'foo.txt', # file to send

    plug_send_file => [
        '../zcms_site/config.txt',  # filename to send; this one is outside the webdir
        'attachment',               # optional to set content-disposition to attachment
        'text/plain',               # optional to set content-type instead of guessing one
        'LOL.txt',                  # optional to set filename instead of using same as original
    ],

    plug_send_file => sub {
        my ( $t, $q, $conf ) = @_;
        return 'foo.txt';
    },

B<Mandatory>. Takes either a string, subref or an arrayref as a value, can be specified in
either ZofCMS Template or Main Config File; if set in both, the value in ZofCMS Template is
used.

When set to a subref, the sub will be executed and its return value will be assigned to the key; returning C<undef> will stop the plugin from execution. The C<@_> will contain
(in that order): ZofCMS Template hashref, query parameters hashref, L<App::ZofCMS::Config>
object.

When set to a string it's the same as setting to an arrayref with just one value in it.

Here are how arrayref elements are interpreted:

=head3 FIRST ELEMENT

    plug_send_file => [
        '../zcms_site/config.txt',
    ],

B<Mandatory>. Specifies the name of the file to send. The filename is relative to C<index.pl>
and can be outside of webroot. Note that if you're taking this name from the user, it's up
to you to ensure that it's safe.

=head3 SECOND ELEMENT

    plug_send_file => [
        '../zcms_site/config.txt',
        'attachment',
    ],

B<Optional>. Specifies C<Content-Disposition> type, which can be C<inline>, C<attachment> or
an extension-token. See RFC 2183 for details.
B<Note:> this parameter only takes the TYPE not the whole header (which isn't supported by
the plugin so you'll have to modify it if you need this). B<Defaults to:> C<inline>, you can
set this to C<undef> to take it's default value.

=head3 THIRD ELEMENT

    plug_send_file => [
        '../zcms_site/config.txt',
        undef,
        'text/plain',
    ]

B<Optional>. Specifies the C<Content-Type> to use. When set to C<undef>, the plugin will
try to guess the correct type to use using C<MIME::Types> module.
B<Defauts to:> C<undef>

=head3 FOURTH ELEMENT

    plug_send_file => [
        '../zcms_site/config.txt',
        undef,
        undef,
        'LOL.txt',
    ],

B<Optional>. Speficies the filename to use when sending the file. Note that this applies
even when content disposition type is set to C<inline> for when the user would want
to save the file. When set to C<undef>, the plugin will use the same name as the original
file. B<Defaults to:> C<undef>.

=head1 HTML::Template VARIABLES - ERROR HANDLING

=head2 C<plug_send_file_error>

    <tmpl_if name='plug_send_file_error'>
        <p class="error">Got error: <tmpl_var escape='html' name='plug_send_file_error'></p>
    </tmpl_if>

If the plugin cannot read the file you specified for sending, it will set the
C<plug_send_file_error> key inside C<t> ZofCMS Template special key to the error message (to
the value of C<$!> to be specific) and will stop processing (i.e. won't send any files
or C<exit()>).

=head2 "default" Content-Type

If plugin was told to derive the right Content-Type of the file, but it couldn't derive one,
it will use C<application/octet-stream>

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