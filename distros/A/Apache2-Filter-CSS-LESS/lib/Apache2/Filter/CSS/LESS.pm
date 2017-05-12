package Apache2::Filter::CSS::LESS;

use 5.008;
use strict;

use APR::Table;
use Apache2::Const -compile => qw(OK);
use Apache2::Filter;
use Apache2::Log;
use Apache2::RequestRec;
use Apache2::RequestUtil;

use CSS::LESSp;

our $VERSION = '0.30';

sub handler :method {
    my ($class, $f) = @_;

    my $r = $f->r;

    my $ctx = $f->ctx;
    while ($f->read(my $buffer, 4096)) {
        $ctx .= $buffer;
    }

    unless ($f->seen_eos) {
        $f->ctx($ctx);
        return Apache2::Const::OK;
    }

    if ($ctx) {
        my $css = join '', CSS::LESSp->parse($ctx);

        # fix headers, change content type
        $r->headers_out->unset('Content-Length');
        $r->content_type($r->dir_config('LessContentType') || 'text/css');

        $f->print($css);
    }

    return Apache2::Const::OK;
}

1;

__END__

=head1 NAME

Apache2::Filter::CSS::LESS - Apache2 LESS to CSS conversion filter

=head1 SYNOPSIS

  <LocationMatch "\.less$">
      PerlOutputFilterHandler   Apache2::Filter::CSS::LESS
      # optionally, set the output content type.
      # default content type is text/css
      # PerlSetVar LessContentType "text/plain"
  </LocationMatch>

=head1 DESCRIPTION

Apache2::Filter::CSS::LESS is a mod_perl2 output filter which converts CSS
LESS files into CSS on demand using C<CSS::LESSp>.

=head2 Caching

Conversion of LESS files to CSS requires considerably more CPU resources than
simply serving up static CSS files.  Therefore, it is recommended that you use
some sort of cache in order to minimize the processing required to convert LESS
files. An example to cache everything under C</less> using C<mod_cache>:

 # cache root directory
 CacheRoot /path/to/disk/cache
 # turn on cache for "/less/" location
 CacheEnable disk /less/

see the C<mod_cache> documentation for more details.

=head1 CONFIGURATION

The following C<PerlSetVar>'s are recognized:

=over 4

=item B<LessContentType>

Sets the output content type of the filtered CSS.  The default content type
is C<text/css>.

=back

=head1 SOURCE

You can contribute or fork this project via github:

http://github.com/mschout/apache2-filter-css-less

 git clone git://github.com/mschout/apache2-filter-css-less.git

=head1 BUGS

Please report any bugs or feature requests to
bug-apache2-filter-css-less@rt.cpan.org, or through the web
interface at http://rt.cpan.org/

=head1 AUTHOR

Michael Schout E<lt>mschout@cpan.orgE<gt>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Michael Schout.

This program is free software; you can redistribute it and/or modify it under
the terms of either:

=over 4

=item *

the GNU General Public License as published by the Free Software Foundation;
either version 1, or (at your option) any later version, or

=item *

the Artistic License version 2.0.

=back

=head1 SEE ALSO

L<CSS::LESSp>, L<Apache2>

=cut
