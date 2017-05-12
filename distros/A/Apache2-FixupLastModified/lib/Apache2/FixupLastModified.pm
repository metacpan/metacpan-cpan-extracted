package Apache2::FixupLastModified;

use warnings FATAL => 'all';
use strict;

use Apache2::RequestRec ();
use Apache2::Util       ();
use Apache2::DebugLog   ();

use Apache2::Const  -compile => qw(OK DECLINED);

use APR::Finfo          ();
use APR::Table          ();

use HTTP::Date          ();

=head1 NAME

Apache2::FixupLastModified - Fixup handler for Last-Modified header

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    # httpd.conf

    # preload for debug configuration directives
    PerlLoadModule   Apache2::FixupLastModified

    # assign to fixup handler
    PerlFixupHandler Apache2::FixupLastModified

=head1 DESCRIPTION

Invoked as a Fixup handler, this module will adjust the Last-Modified
header of a subrequested resource, should it be newer than the main
request. Apache2::FixupLastModified is for use with resources that may
arbitrarily include other resources (i.e. XSLT, server side includes,
etc.) by way of subrequests.

=cut

sub handler {
    my $r = shift;
    # we only operate on subrequests
    if (my $mr = $r->main and my $finfo = $r->finfo) {
        $r->log_debug('subreq', 5, 'Invoking handler on subrequest ' . $r->uri);
        my $hdr     = $mr->headers_out->get('Last-Modified');
        my $otime   = 0;
        if ($hdr) {
            $r->log_debug
                ('invoc', 6, 'Acquiring mtime from Last-Modified header');
            $otime = HTTP::Date::str2time($hdr);
        }
        elsif (my $mrf = $mr->finfo) {
            $r->log_debug
                ('invoc', 6, 'Acquiring mtime from main request\'s finfo');
            $otime = $mrf->mtime;
        }
        else {
            $r->log_debug('invoc', 5, 
                'No finfo or Last-Modified header in main request');
        }
        if ($otime < $finfo->mtime) {
            my $new = Apache2::Util::ht_time($r->pool, $finfo->mtime);
            $r->log_debugf('invoc', 5, 
                'Overwriting Last-Modified header "%s" with "%s"', 
                    $hdr || '', $new);
            $mr->headers_out->set('Last-Modified', $new);
            return Apache2::Const::OK;
        }
    }
    else {
        $r->log_debug('subreq', 6, 'Skipping main request' . $r->uri);
    }
    Apache2::Const::DECLINED;
}

=head1 DEBUGGING

Debug levels start at 5 and end at 6. Below are the relevant debugging
categories.

=over 1

=item subreq

Enable for notification of the module's activation.

=item invoc

Enable for notification when the module does or doesn't do its job.

=back

=head1 SEE ALSO

L<Apache2::DebugLog>

=head1 AUTHOR

dorian taylor, C<< <dorian@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-apache2-fixuplastmodified@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache2-FixupLastModified>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 dorian taylor, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Apache2::FixupLastModified
