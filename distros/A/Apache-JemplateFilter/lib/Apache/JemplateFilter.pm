package Apache::JemplateFilter;

use warnings;
use strict;
use Apache::Filter;
use Apache::Constants qw( OK HTTP_OK );
use Apache::Log;
use Apache::File;
use Jemplate 0.12;

=head1 NAME

Apache::JemplateFilter - Jemplate complie filter for Apache

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';
our $cache   = {};

=head1 SYNOPSIS

in httpd.conf

    PerlModule Apache::Filter

    <Location /foo/tmpl/>
        SetHandler      perl-script
        PerlSetVar      Filter On
        PerlHandler     Apache::JemplateFilter
    </Location>

Requests for /foo/tmpl/* are compiled by Jemplate.

=head1 DESCRIPTION

This module is Jemplate compile filter for Apache1.x (mod_perl1.x).

For Apache2, use L<Apache2::JemplateFilter>.

=head1 FUNCTIONS

=head2 handler

=cut

sub handler {
    my $r   = shift;
    my $log = $r->server->log;

    $r = $r->filter_register;

    my ( $fh, $status ) = $r->filter_input();
    return $status unless $status == OK;

    my $filename = $r->filename;

    # cache hit ?
    my $c = $cache->{$filename};
    if ( $c && $c->{mtime} == $r->mtime ) {
        $r->set_content_length( length $c->{js} );
        $r->content_type('application/x-javascript');
        $r->send_http_header($r->content_type);
        $r->print( $c->{js} );
        return OK;
    }

    my $buf;
    {
        local $/ = undef;
        $buf = <$fh>;
    }

    ( my $tmpl_filename = $filename ) =~ s/.*[\/\\]//;
    my $jemplate = Jemplate->new( EVAL_JAVASCRIPT => 1 );
    my $js;
    eval {
        $js =
            $jemplate->_preamble
            . $jemplate->compile_template_content( $buf, $tmpl_filename );
    };
    if ($@) {
        my $msg = sprintf "%s compile error while processing %s. %s",
            __PACKAGE__,
            $r->uri,
            $@;
        $msg =~ s/\'/\\'/g;         # '
        $msg =~ s/[\x0A\x0D]/ /g;
        $js  = "throw('$msg')";
        $log->error($msg);
    }
    $r->set_content_length( length $js );
    $r->content_type('application/x-javascript');
    $r->send_http_header($r->content_type);
    $r->print($js);
    $cache->{$filename} = { js => $js, mtime => $r->mtime };
    return OK;
}

=head1 AUTHOR

FUJIWARA Shunichiro, C<< <fujiwara at topicmaker.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-apache-jemplatefilter at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache-JemplateFilter>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<Apache::Filter> L<Jemplate> L<Apache2::JemplateFilter>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Apache::JemplateFilter

=head1 COPYRIGHT & LICENSE

Copyright 2006 FUJIWARA Shunichiro, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Apache::JemplateFilter
