package Apache2::JemplateFilter;

use warnings;
use strict;
use mod_perl2;

use base qw(Apache2::Filter);
use Apache2::Const -compile => qw(OK);
use Apache2::RequestRec ();
use Apache2::Response   ();
use Apache2::Log        ();
use APR::Finfo          ();
use APR::Brigade        ();
use Jemplate 0.12;

our $cache = {};

=head1 NAME

Apache2::JemplateFilter - Jemplate complie filter for Apache2

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

in httpd.conf

    PerlLoadModule Apache2::JemplateFilter
    <Location /foo/tmpl/>
        PerlOutputFilterHandler Apache2::JemplateFilter
    </Location>

Requests for /foo/tmpl/* are compiled by Jemplate.

=head1 DESCRIPTION

This module is Jemplate complie filter for Apache2 (mod_perl2).

For Apache1.x (mod_perl1.x), use L<Apache::JemplateFilter>.

=head1 FUNCTIONS

=head2 handler

Output filter hander method.

=cut

sub handler {
    my ( $f, $bb ) = @_;

    my $finfo    = $f->r->finfo;
    my $filename = $finfo->fname;

    # cache hit ?
    my $c = $cache->{$filename};
    if ( $c && $c->{mtime} == $finfo->mtime ) {
        $f->r->set_content_length( length $c->{js} );
        $f->r->content_type('application/x-javascript');
        $f->print( $c->{js} );
        return Apache2::Const::OK;
    }
    my $buf;
    my $len = $bb->flatten($buf);
    if ($len) {
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
	      $f->r->uri,
	      $@;
            $msg =~ s/\'/\\'/g;         # '
            $msg =~ s/[\x0A\x0D]/ /g;
            $js = "throw('$msg')";
            $f->r->log_error($msg);
        }
        $f->r->set_content_length( length $js );
        $f->r->content_type('application/x-javascript');
        $f->print($js);
        $cache->{$filename} = { js => $js, mtime => $finfo->mtime };
    }
    return Apache2::Const::OK;
}

=head1 SEE ALSO

L<Jemplate> L<Apache::JemplateFilter>

=head1 AUTHOR

Fujiwara Shunichiro, C<< <fujiwara at topicmaker.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Fujiwara Shunichiro, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Apache2::JemplateFilter
