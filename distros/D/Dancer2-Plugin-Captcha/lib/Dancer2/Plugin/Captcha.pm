package Dancer2::Plugin::Captcha;

$Dancer2::Plugin::Captcha::VERSION   = '0.14';
$Dancer2::Plugin::Captcha::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

Dancer2::Plugin::Captcha - Dancer2 add-on for CAPTCHA.

=head1 VERSION

Version 0.14

=cut

use 5.006;
use strict; use warnings;
use Data::Dumper;

use Dancer2::Plugin;
use GD::SecurityImage;

=head1 DESCRIPTION

A very simple plugin for L<Dancer2> to process CAPTCHA.I needed this for my other
project (in-progress) available on L<github|https://github.com/Manwar/Dancer2-Cookbook>.

The core functionality of the plugin is supported by L<GD::SecurityImage>.

=head1 SYNOPSIS

=head2 Setting up the application configuration.

The plugin expect a session engine configured for it to perform its task,

    session: Simple

    plugins:
      Captcha:
        new:
          width: 160
          height: 175
          lines: 5
          gd_font: 'giant'
        create: [ 'normal', 'default' ]
        out:
          force: 'png'
        particle: [ 100 ]

=head2 Setting up the application route handler.

    get '/get_captcha' => sub {
        return generate_captcha();
    };

    post '/validate_captcha' => sub {
        return "Invalid captcha code."
            unless (is_valid_captcha(request->params->{captcha}));

        remove_captcha;
    };

=head2 Setting up the application template.

    <form method="POST" action="/validate_captcha">
        <label>Enter the Captcha</label>
        <input type="text" name="captcha" style="width: 120px;">
        <img id="img1" src="<% request.uri_base %>/get_captcha" style="margin-bottom:20px;">
        <button type="submit">Submit</button>
    </form>

=head1 CONFIGURATION

The plugin can be configured in the application configuration file as below:

    plugins:
      Captcha:
        new:
        create:
        particle:
        out:

=head2 new

The following keys can be assigned to method 'new':

    +------------+--------------------------------------------------------------+
    | Key        | Description                                                  |
    +------------+--------------------------------------------------------------+
    | width      | The width of the image (in pixels).                          |
    | height     | The height of the image (in pixels).                         |
    | ptsize     | The point size of the ttf character.                         |
    | lines      | The number of lines in the background of the image.          |
    | font       | The absolute path to your TrueType font file.                |
    | gd_font    | The possible value are 'small', 'large', 'mediumbold',       |
    |            | 'tiny' and 'giant'.                                          |
    | bgcolor    | The background color of the image.                           |
    | send_ctobg | If has a true value, the random security code will be        |
    |            | displayed in the background and the lines will pass over it. |
    | frame      | If has a true value, a frame will be added around the image. |
    | scramble   | If set, the characters will be scrambled.                    |
    | angle      | Sets the angle (0-360) for scrambled/normal characters.      |
    | thickness  | Sets the line drawing width.                                 |
    | rndmax     | The minimum length if the random string. Default is 6.       |
    | rnd_data   | Default character set used to create the random string is    |
    |            | [0..9].                                                      |
    +------------+--------------------------------------------------------------+

See L<GD::SecurityImage/new> for more details.

=head2 create

The data should be in the format as below for method 'create':

    [ $method, $style, $text_color, $line_color ]

The key C<$method> and C<$style> are mandatory and the rest all are optionals.

The key C<$method> can have one of the following values:

    normal or ttf

The key C<$style> can have one of the following values:

    +---------+-----------------------------------------------------------------+
    | Key     | Description                                                     |
    +---------+-----------------------------------------------------------------+
    | default | The default style. Draws horizontal, vertial and angular lines. |
    | rect    | Draws horizontal and vertical lines.                            |
    | box     | Draws two filled rectangles.                                    |
    | circle  | Draws circles.                                                  |
    | ellipse | Draws ellipses.                                                 |
    | ec      | Draws both ellipses and circles.                                |
    | blank   | Draws nothing.                                                  |
    +---------+-----------------------------------------------------------------+

=head2 out

The following keys can be assigned to method 'out':

    +----------+----------------------------------------------------------------+
    | Key      | Description                                                    |
    +----------+----------------------------------------------------------------+
    | force    | Can have one of the formats 'jpeg' or 'png' or 'gif'.          |
    | compress | Can be between 1 and 100.                                      |
    +----------+----------------------------------------------------------------+

=head2 particle

The data should be in the format as below for method 'particle':

    [ $density, $maximum_dots ]

The default value for C<$density> is dependent on the image's height & width. The
greater value of height and width is taken and multiplied by 20 for defaults.

The key C<$maximum_dots> defines the maximum number of dots near the default dot.
The default value is 1. If you set it to 4, the selected pixel and 3 other pixels
near it will be used and colored.

=head1 METHODS

=head2 generate_captcha(\%params, $id)

It returns captcha image as per the given parameters and C<$id> is the captcha
ID (optional, default value is 'default'). If  the key 'random' is not defined
then the default character sets [0..9] will be used.

    get '/get_captcha' => sub {
        return generate_captcha({
            new => {
                width   => 500,
                height  => 75,
                lines   => 5,
                gd_font => 'giant',
            },
            particle => [ 100 ],
            out      => { force => 'png' },
            random   => <your_randomly_generated_string>,
        });
    };

=cut

register generate_captcha => sub {
    my ($dsl, $init, $id) = @_;

    $init = {}        unless defined $init;
    $id   = 'default' unless defined $id;

    my $conf = plugin_setting();

    foreach my $key (qw(new out)) {
        $conf->{$key} //= {};
        $init->{$key} //= {};
        $init->{$key} = { %{$conf->{$key}}, %{$init->{$key}} };
    }

    foreach my $key (qw(create particle)) {
        $conf->{$key} //= [];
        $init->{$key} ||= $conf->{$key};
    }

    $dsl->engine('session')
        or die "ERROR: Session engine required for the plugin ".__PACKAGE__.".\n";

    my $image = GD::SecurityImage->new(%{$init->{new}});
    $image->random($init->{random});
    $image->create(@{$init->{create}});
    $image->particle(@{$init->{particle}});
    my ($captcha, $mime_type, $random_number) = $image->out(%{$init->{out}});

    $dsl->_save_captcha($id, 'string' => $random_number);
    $dsl->header('Pragma' => 'no-cache');
    $dsl->header('Cache-Control' => 'no-cache');
    $dsl->content_type($mime_type);

    return $captcha;
};

=head2 is_valid_captcha($input, $id)

The C<$input> is the captcha  code  entered by the user and C<$id> is the captcha
ID (optional, default value is 'default'). It returns 0 or 1 depending on whether
the captcha matches or not.

    post '/validate_captcha' => sub {
        return "Invalid captcha code."
            unless (is_valid_captcha(request->params->{captcha}));

        remove_captcha;
    };

=cut

register is_valid_captcha => sub {
    my ($dsl, $input, $id) = @_;

    $id = 'default' unless defined $id;
    my $captcha = $dsl->_get_captcha($id, 'string');
    ((defined $input) && (defined $captcha) && ($input eq $captcha))
        ?
        (return 1)
        :
        (return 0);
};

=head2 remove_captcha($id)

The C<$id> is the captcha ID (optional, default value is 'default').
It removes the captcha from the session.

=cut

register remove_captcha => sub {
    my ($dsl, $id) = @_;

    $id = 'default' unless defined $id;

    my $captcha = $dsl->session('captcha');
    return unless defined $captcha;
    return unless ((exists $captcha->{$id}) && (exists $captcha->{$id}{'string'}));

    $captcha->{$id}{'string'} = undef;
    $dsl->session('captcha' => $captcha);
};

register_plugin;

#
#
# PRIVATE METHODS

sub _save_captcha {
    my ($dsl, $id, $key, $value) = @_;

    die "ERROR: Missing captcha ID.\n"    unless defined $id;
    die "ERROR: Missing captcha key.\n"   unless defined $key;
    die "ERROR: Missing captcha value.\n" unless defined $value;

    my $captcha = $dsl->app->session->read('captcha') || {};
    $captcha->{$id} ||= {};
    $captcha->{$id}{$key} = $value;
    $dsl->app->session->write('captcha' => $captcha);
}

sub _get_captcha {
    my ($dsl, $id, $key) = @_;

    die "ERROR: Missing captcha ID.\n"  unless defined $id;
    die "ERROR: Missing captcha key.\n" unless defined $key;

    my $captcha = $dsl->app->session->read('captcha');
    return unless defined $captcha;

    return $captcha->{$id}{$key};
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/Dancer2-Plugin-Captcha>

=head1 ACKNOWLEDGEMENTS

Inspired by the package L<Dancer::Plugin::Captcha::SecurityImage> (Alessandro Ranellucci <aar@cpan.org>).

=head1 SEE ALSO

L<Dancer::Plugin::Captcha::SecurityImage>, L<GD::SecurityImage>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer2-plugin-captcha at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer2-Plugin-Captcha>.
I will  be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer2::Plugin::Captcha

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer2-Plugin-Captcha>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer2-Plugin-Captcha>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer2-Plugin-Captcha>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer2-Plugin-Captcha/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2015 - 2019 Mohammad S Anwar.

This program  is  free software; you can redistribute it and / or modify it under
the  terms  of the the Artistic License (2.0). You may obtain  a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any  use,  modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License.By using, modifying or distributing the Package,
you accept this license. Do not use, modify, or distribute the Package, if you do
not accept this license.

If your Modified Version has been derived from a Modified Version made by someone
other than you,you are nevertheless required to ensure that your Modified Version
 complies with the requirements of this license.

This  license  does  not grant you the right to use any trademark,  service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent license
to make,  have made, use,  offer to sell, sell, import and otherwise transfer the
Package with respect to any patent claims licensable by the Copyright Holder that
are  necessarily  infringed  by  the  Package. If you institute patent litigation
(including  a  cross-claim  or  counterclaim) against any party alleging that the
Package constitutes direct or contributory patent infringement,then this Artistic
License to you shall terminate on the date that such litigation is filed.

Disclaimer  of  Warranty:  THE  PACKAGE  IS  PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS  "AS IS'  AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES    OF   MERCHANTABILITY,   FITNESS   FOR   A   PARTICULAR  PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS
REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL,  OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE
OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Dancer2-Plugin-Captcha
