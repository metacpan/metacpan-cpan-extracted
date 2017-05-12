package App::ZofCMS::Plugin::Captcha;

use warnings;
use strict;

our $VERSION = '1.001002'; # VERSION

use base 'App::ZofCMS::Plugin::Base';
use GD::SecurityImage;

sub _key { 'plug_captcha' }
sub _defaults {
    string  => undef,
    file    => undef,
    width   => 80,
    height  => 20,
    lines   => 5,
    particle => 0,
    no_exit => 1,
    style   => 'rect',
    format  => 'gif',
    tcolor  => '#895533',
    lcolor  => '#000000',
}
sub _do {
    my ( $self, $conf, $t, $q, $config ) = @_;

    my $image = GD::SecurityImage->new(
        width   => $conf->{width},
        height  => $conf->{height},
        lines   => $conf->{lines},
        gd_font => 'giant'
    );

    $image->random( $conf->{string} );
    $image->create('normal', @$conf{qw/style tcolor lcolor/} );

    if ( $conf->{particle} ) {
        $image->particle( ref $conf->{particle} ? @{ $conf->{particle} } : () );
    }

    my ( $image_data, $mime_type, $random_number ) = $image->out( force => $conf->{format} );
    $t->{d}{session}{captcha} = $random_number;

    if ( defined $conf->{file} and length $conf->{file} ) {
        if ( open my $fh, '>', $conf->{file} ) {
            binmode $fh;
            print $fh $image_data;
            close $fh;
        }
        else {
            $t->{t}{plug_captcha_error} = $!;
            return;
        }
    }
    else {
        binmode STDOUT;
        print "Content-Type: image/$mime_type\n\n";
        print $image_data;
        exit
            unless $conf->{no_exit};
    }
}

1;
__END__

=encoding utf8

=for stopwords RGB bots captcha captchas crypto cryptocrap runcycle runlevel subref

=head1 NAME

App::ZofCMS::Plugin::Captcha - plugin to utilize security images (captchas)

=head1 SYNOPSIS

    plugins => [
        { Session => 1000 },
        { Captcha => 2000 },
    ],
    plugins2 => [
        qw/Session/
    ],

    plug_captcha => {},

    # Session plugin configuration (i.e. database connection is left out for brevity)

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that provides means to generate and display
security images, known as "captchas" (i.e. protecting forms from bots).

The plugin was coded with idea that you will be using L<App::ZofCMS::Plugin::Session>
along with it to store the generated random string; however, it's not painfully
necessary to use Session plugin (just easier with it).

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and L<App::ZofCMS::Template>

=head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

=head2 C<plugins>

    plugins => [
        { Session => 1000 },
        { Captcha => 2000 },
    ],
    plugins2 => [
        qw/Session/
    ],

B<Mandatory>. You need to include the plugin in the list of plugins to execute. I'm using
Session plugin here to first load existing session and after Captcha is ran, to save
the session.

=head2 C<plug_captcha>

    # all defaults
    plug_captcha => {},

    # set all arguments
    plug_captcha => {
        string  => 'Zoffix Znet Roxors',
        file    => 'captcha.gif',
        width   => 80,
        height  => 20,
        lines   => 5,
        particle => 0,
        no_exit => 1,
        style   => 'rect',
        format  => 'gif',
        tcolor  => '#895533',
        lcolor  => '#000000',
    },

    # or set some via a subref
    plug_captcha => sub {
        my ( $t, $q, $config ) = @_;
        return {
            string  => 'Zoffix Znet Roxors',
            file    => 'captcha.gif',
        }
    },

B<Mandatory>. Takes either a hashref or a subref as a value. If subref is specified,
its return value will be assigned to C<plug_captcha> as if it was already there. If
sub returns an C<undef>, then plugin will stop further processing.
The C<@_> of the subref will
contain (in that order): ZofCMS Template hashref, query parameters hashref and
L<App::ZofCMS::Config> object. To run the plugin with all the defaults,
use an empty hashref. Possible keys/values for the hashref
are as follows:

=head3 C<string>

    plug_captcha => {
        string  => 'Zoffix Znet Roxors',
    },

B<Optional>. Specifies the captcha string. Takes either a scalar string or C<undef>.
If set to C<undef>, the plugin will generate a random numeric string. B<Defaults to:>
C<undef>.

=head3 C<file>

    plug_captcha => {
        file    => 'captcha.gif',
    },

B<Optional>. Takes either a scalar string or C<undef> as a value. If set to a string,
it represents the name of the file into which to save the captcha image (relative to
C<index.pl>). If set to C<undef>, plugin will output correct HTTP headers and the image
directly into the browser. B<Defaults to:> C<undef>.

=head3 C<no_exit>

    plug_captcha => {
        no_exit => 1,
    },

B<Optional>. This one is relevant only when C<file> (see above) is set to C<undef>.
Takes either true or false values. If set to a B<false value>, plugin will call
C<exit()> as soon as it finishes outputting the image to the browser. You'd use it
if you're generating your own string and are able to store it with the Session plugin
before Captcha plugin runs. If set to a B<true value>, plugin will not call C<exit()> and
the runcycle will continue; this way the Captcha plugin generated random string can
be stored by Session plugin later in the runlevel. B<Note:> that in this case, after the
image is printed the browser will also send some garbage (and by that I mean the
standard HTTP Content-type headers that ZofCMS prints along with whatever may be in
your template); even though I haven't noticed that causing any problems with the image,
if it does cause broken image for you, simply use L<App::ZofCMS::Plugin::Sub> and call
C<exit()> within it. B<Defaults to:> C<1>

=head3 C<width>

    plug_captcha => {
        width   => 80,
    },

B<Optional>. Takes a positive integer as a value. Specifies captcha image's width in pixels.
B<Defaults to:> C<80>

=head3 C<height>

    plug_captcha => {
        height  => 20,
    },

B<Optional>. Takes a positive integer as a value. Specifies captcha image's height in
pixels.B<Defaults to:> C<20>

=head3 C<lines>

    plug_captcha => {
        lines   => 5,
    },

B<Optional>. Specifies the number of crypto-lines to generate. See L<GD::SecurityImage> for
more details. B<Defaults to:> C<5>

=head3 C<particle>

    plug_captcha => {
        particle => 0, # disable particles
    },

    plug_captcha => {
        particle => 1, # let plugin decide the right amount
    },

    plug_captcha => {
        particle => [40, 50], # set amount yourself
    },

B<Optional>. Takes either false values, true values or an arrayref as a value. When set to an
arrayref, the first element of it is density and the second one is maximum
number of dots to generate - these dots will add more cryptocrap to your captcha. See
C<particle()> method in L<GD::SecurityImage> for more details. When set to a true value
that is not an arrayref, L<GD::SecurityImage> will try to determine optimal number of
particles. When set to a false value, no extra particles will be created.
B<Defaults to:> C<0>

=head3 C<style>

    plug_captcha => {
        style   => 'rect',
    },

B<Optional>. Specifies the cryptocrap style of captcha.
See L<GD::SecurityImage> C<create()> method for possible styles.
B<Defaults to:> C<rect>

=head3 C<format>

    plug_captcha => {
        format  => 'gif',
    },

B<Optional>. Takes string C<gif>, C<jpeg> or C<png> as a value. Specifies the format
of the captcha image. Some formats may be unavailable depending on your L<GD> version.
B<Defaults to:> C<gif>

=head3 C<tcolor>

    plug_captcha => {
        tcolor  => '#895533',
        lcolor  => '#000000',
    },

B<Optional>. Takes 6-digit hex RGB notation as a value. Specifies the color
of the text (and particles if they are on). B<Defaults to:> C<#895533>

=head3 C<lcolor>

    plug_captcha => {
        lcolor  => '#000000',
    },

B<Optional>. Takes 6-digit hex RGB notation as a value. Specifies the color
of cryptocrap lines. B<Defaults to:> C<#000000>

=head1 OUTPUT

    $t->{d}{session}{captcha} = 'random_number';

    $t->{t}{plug_captcha_error} = 'error message';

Plugin will put the captcha string into C<< $t->{d}{session}{captcha} >> where
C<$t> is ZofCMS Template hashref. Currently there is no way to change that.

If you're saving captcha to a file, possible I/O error message will be put into
C<< $t->{t}{plug_captcha_error} >> where C<$t> is ZofCMS Template hashref.

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/App-ZofCMS-PluginBundle-Naughty>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/App-ZofCMS-PluginBundle-Naughty/issues>

If you can't access GitHub, you can email your request
to C<bug-App-ZofCMS-PluginBundle-Naughty at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut