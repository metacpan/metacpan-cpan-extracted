package App::ZofCMS::Plugin::Barcode;

use warnings;
use strict;

our $VERSION = '1.001008'; # VERSION

use GD::Barcode;
use base 'App::ZofCMS::Plugin::Base';

sub _key { 'plug_barcode' }
sub _defaults {
    code    => undef,
    format  => 'png', # gif or png
    type    => 'UPCA',
    no_text => 0,
    height  => 50,
    file    => undef,
}
sub _do {
    my ( $self, $conf, $t, $q, $config ) = @_;

    $conf->{code} = $conf->{code}->( $t, $q, $config )
        if ref $conf->{code} eq 'CODE';

    return
        unless defined $conf->{code}
            and length $conf->{code};

    $conf->{type} = $conf->{type}->( $t, $q, $config )
        if ref $conf->{type} eq 'CODE';

    return
        unless defined $conf->{type}
            and length $conf->{type};

    my $bar = GD::Barcode->new( @$conf{ qw/type code/ } );

    unless ( $bar ) {
        $t->{t}{plug_barcode_error} = $GD::Barcode::errStr;
        return;
    }

    if ( defined $conf->{file} and length $conf->{file} ) {
        if ( open my $fh, '>', $conf->{file} ) {
            binmode $fh;
            print $fh $conf->{format} eq 'png'
                ? $bar->plot( Height => $conf->{height}, NoText => $conf->{no_text} )->png
                : $bar->plot( Height => $conf->{height}, NoText => $conf->{no_text} )->gif;
        }
        else {
            $t->{t}{plug_barcode_error} = $!;
            return;
        }
    }
    else {
        binmode STDOUT;
        if ( $conf->{format} eq 'png' ) {
            print "Content-Type: image/png\n\n";
            print $bar->plot( Height => $conf->{height}, NoText => $conf->{no_text} )->png;
        }
        else {
            print "Content-Type: image/gif\n\n";
            print $bar->plot( Height => $conf->{height}, NoText => $conf->{no_text} )->gif;
        }
        exit;
    }
}

1;
__END__

=encoding utf8

=head1 NAME

App::ZofCMS::Plugin::Barcode - plugin to generate various bar codes

=head1 SYNOPSIS

In your Main Config File or ZofCMS Template:

    plugins => [
        qw/Barcode/
    ],

    # direct output to browser with default values for optional arguments
    plug_barcode => {
        code => '12345678901',
    },

    # or

    # save to file with all options set
    plug_barcode => {
        code    => '12345678901',
        file    => 'bar.png',
        type    => 'UPCA', # default
        format  => 'png',  # default
        no_text => 0,      # default
        height  => 50,     # default
    },

In your HTML::Template template (in case errors occur):

    <tmpl_if name='plug_barcode_error'>
        <p>Error: <tmpl_var escape='html' name='plug_barcode_error'></p>
    </tmpl_if>

=head1 DESCRIPTION

The module is a plugin for L<App::ZofCMS> that provides means to generate various
types of barcodes and either output them directly to the browser or save them as
an image.

This documentation assumes you've read L<App::ZofCMS>, L<App::ZofCMS::Config> and
L<App::ZofCMS::Template>

=head1 FIRST-LEVEL ZofCMS TEMPLATE AND MAIN CONFIG FILE KEYS

=head2 C<plugins>

    plugins => [
        qw/Barcode/
    ],

B<Mandatory>.
You need to add the plugins to the list of plugins to execute. B<Note:>
if you're outputting
directly to the browser instead of saving the barcode into a file, the
B<plugin will call
exit() as soon as it finishes print()ing the image UNLESS an error
occurred>, so make sure to
run anything that needs to be run before that point.

=head2 C<plug_barcode>

    # direct output to browser with default values for optional arguments
    plug_barcode => {
        code => '12345678901',
    },

    # save to file with all options set
    plug_barcode => {
        code    => '12345678901',
        file    => 'bar.png',
        type    => 'UPCA', # default
        format  => 'png',  # default
        no_text => 0,      # default
        height  => 50,     # default
    },

    # set config with a sub
    plug_barcode => sub {
        my ( $t, $q, $config ) = @_;
    }

B<Mandatory>. Specifies plugin's options. Takes a hashref or a subref as a value. If subref is
specified,
its return value will be assigned to C<plug_barcode> as if it was already there. If sub returns
an C<undef>, then plugin will stop further processing. The C<@_> of the subref will
contain (in that order): ZofCMS Tempalate hashref, query parameters hashref and
L<App::ZofCMS::Config> object. Possible keys/values of the hashref
are as follows:

=head3 C<code>

    plug_barcode => {
        code    => '12345678901',
    },

    # or

    plug_barcode => {
        code    => sub {
            my ( $t, $q, $config ) = @_;
            return '12345678901';
        }
    },

B<Mandatory>. Takes either a string or a subref as a value. If the value is a subref,
it will be called and its value will be assigned to C<code> as if it was already there.
The C<@_> of the subref will contain (in this order): ZofCMS Template hashref, query
parameters hashref and L<App::ZofCMS::Config> object.

Specifies the code for the barcode to generate. Valid values depend
on the C<type> of the barcode you're generating. If value is an invalid barcode, plugin
will error out (see C<ERROR HANDLING> section below). If value is either C<undef>
or an empty string, plugin will stop further processing (no exit()s)

=head3 C<file>

    plug_barcode => {
        code    => '12345678901',
        file    => 'bar.png',
    },

B<Optional>. Takes a string that represents the name of the file (relative to C<index.pl>)
into which to save the image. When is not defined (or set to an empty string) the plugin
will print out the right C<Content-type> header and output the image right into the browser
B<and then will call exit() UNLESS an error occurred> . Plugin will B<NOT> call C<exit()> if
saving to the file. B<By default> is not specified (output barcode image directly to the
browser).

=head3 C<type>

    plug_barcode => {
        code    => '12345678901',
        type    => 'UPCA',
    },

    # or
    plug_barcode => {
        code    => '12345678901',
        type    => sub {
            my ( $t, $q, $config ) = @_;
            return 'UPCA';
        },
    },

B<Optional>. Takes a string or a subref as a value. If the value is a subref,
it will be called and its value will be assigned to C<type> as if it was already there.
The C<@_> of the subref will contain (in this order): ZofCMS Template hashref, query
parameters hashref and L<App::ZofCMS::Config> object.

Represents the type of barcode to generate.
See L<GD::Barcode> distribution for possible types. B<As of this writing> these are currently
available types:

    COOP2of5
    Code39
    EAN13
    EAN8
    IATA2of5
    ITF
    Industrial2of5
    Matrix2of5
    NW7
    QRcode
    UPCA
    UPCE

If value is either C<undef> or an empty string, plugin will stop further processing (no exit()s)
B<Defaults to:> C<UPCA>

=head3 C<format>

    plug_barcode => {
        code    => '12345678901',
        format  => 'png',
    },

B<Optional>. Can be set to either string C<png> or C<gif> (case sensitive).
Specifies the format of the image to generate (C<png> is for PNG images and C<gif> is for GIF
images). B<Defaults to:> C<png>

=head3 C<no_text>

    plug_barcode => {
        code    => '12345678901',
        no_text => 0,
    },

B<Optional>. Takes either true or false values. When set to a true value, the plugin
will not generate text (i.e. it will only make the barcode lines) in the output image.
B<Defaults to:> C<0>

=head3 C<height>

    plug_barcode => {
        code    => '12345678901',
        height  => 50,
    },

B<Optional>. Takes positive integer numbers as a value. Specifies the height of the
generated barcode image. B<Defaults to:> C<50>

=head1 ERROR HANDLING

    <tmpl_if name='plug_barcode_error'>
        <p>Error: <tmpl_var escape='html' name='plug_barcode_error'></p>
    </tmpl_if>

In an error occurs while generating the barcode (i.e. wrong code length was specified
or some I/O error occurred if saving to a file), the plugin will set
the C<< $t->{t}{plug_barcode_error} >> (where C<$t> is ZofCMS Template hashref)
to the error message.

=head1 SEE ALSO

L<GD::Barcode>

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