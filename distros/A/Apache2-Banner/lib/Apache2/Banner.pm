package Apache2::Banner;

use 5.008008;
use strict;
use warnings;

{
    our $VERSION = '0.01';
    require XSLoader;
    XSLoader::load('Apache2::Banner', $VERSION);
}

1;
__END__

=encoding utf8

=head1 NAME

Apache2::Banner - a patch for Apache2::ServerUtil

=head1 SYNOPSIS

 use Apache2::Banner ();

 $banner=Apache2::Banner::banner;
 $description=Apache2::Banner::description;
 $datestr=Apache2::Banner::date $time;

=head1 DESCRIPTION

C<Apache2::Banner> reimplements a few functions that
L<Apache2::ServerUtil> didn't get right at least up to mod_perl 2.0.5.

Future mod_perl versions may fix the problem.

=head2 $banner=Apache2::Banner::banner

C<Apache2::ServerUtil::get_server_banner> should do the trick. But it calls
the Apache API function only once when L<Apache2::ServerUtil> is loaded.
That is not correct because the module may be loaded very early, for example
in a C<< <Perl> >> container in the F<httpd.conf>. Modules may register
components later. Hence, the L<Apache2::ServerUtil> notion of the banner
is wrong.

The I<server banner> is influenced by the C<ServerTokens> directive.

=head2 $banner=Apache2::Banner::description

The same here, C<Apache2::ServerUtil::get_server_banner> should do it but
doesn't.

The I<server banner> is not influenced by the C<ServerTokens> directive.

With C<ServerTokens Full> banner and description are equal.

=head2 $datestr=Apache2::Banner::date $time

returns C<$datestr> exactly the same way as the HTTP C<Date> header would be
formatted.

=head2 EXPORT

None.

=head1 SEE ALSO

L<Apache2::ServerUtil>

=head1 AUTHOR

Torsten Förtsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Torsten Förtsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
