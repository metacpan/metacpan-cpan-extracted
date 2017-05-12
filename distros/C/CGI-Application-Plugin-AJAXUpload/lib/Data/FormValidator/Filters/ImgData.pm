package Data::FormValidator::Filters::ImgData;

use warnings;
use strict;
use Carp;
use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw(
    filter_resize
);

use version; our $VERSION = qv('0.0.3');

# Module implementation here

sub filter_resize {
    my $width = shift;
    my $height = shift;
    my $type = shift || 'jpeg';
    return sub {
        use GD;
        GD::Image->trueColor( 1 );
        my $data = shift;
        my $image = GD::Image->new($data);
        my $old_width = ($image->getBounds)[0];
        my $old_height = ($image->getBounds)[1];
        my $k_h = $height / $old_height;
        my $k_w = $width / $old_width;
        my $k = ($k_h < $k_w ? $k_h : $k_w);
        my $new_height = int($old_height * $k);
        my $new_width  = int($old_width * $k);
        my $new_image = GD::Image->new($new_width, $new_height);
        $new_image->copyResampled($image,
            0, 0,               # (destX, destY)
            0, 0,               # (srcX,  srxY )
            $new_width, $new_height,    # (destX, destY)
            $old_width, $old_height
        );
        return $new_image->$type();
    };
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Data::FormValidator::Filters::ImgData - Resize image on the fly

=head1 VERSION

This document describes Data::FormValidator::Filters::ImgData version 0.0.3

=head1 SYNOPSIS

    use MyWebApp;
    use CGI::Application::Plugin::JSON qw(to_json);
    use CGI::Application::Plugin::AJAXUpload;
    use Data::FormValidator::Filters::ImgData;

    sub setup {
        my $c = shift;
        $c->ajax_upload_httpdocs('/var/www/vhosts/mywebapp/httpdocs');
        
        my $profile = $c->ajax_upload_default_profile;
        $profile->{field_filters}->{value} = filter_resize(300,200);

        $c->ajax_upload_setup(
            run_mode=>'file_upload',
            upload_subdir=>'/img/uploads',
            dfv_profile=>$profile,
        );
        return;
    }

=head1 DESCRIPTION

This module rewrites and formats an image. It is intended specifically to work
with L<CGI::Application::Plugin::AJAXUpload> and hence
L<Data::FormValidator>. Unlike, for example L<Data::FormValidator::Filters::Image>,
it takes raw image data and returns raw image data.

=head1 INTERFACE 

=head2 filter_resize

This returns the subroutine reference that does the work. It takes as arguments
the I<width> and I<height> in that order. There is an optional third argument
which is the format. This defaults to C<jpeg> but can be anything that works as
a method on a L<GD::Image> object returning image data.

=head1 ACKNOWLEDGEMENTS

The core of the code is copied from L<Image::Resize>. However the constructor
for that module does not take raw data.

=head1 DEPENDENCIES

This module uses the L<GD> module.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-ajaxupload@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Nicholas Bamber  C<< <nicholas@periapt.co.uk> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Nicholas Bamber C<< <nicholas@periapt.co.uk> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
