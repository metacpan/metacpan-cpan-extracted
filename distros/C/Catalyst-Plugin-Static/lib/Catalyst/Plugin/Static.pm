package Catalyst::Plugin::Static;

use strict;
use base 'Class::Data::Inheritable';
use File::MimeInfo::Magic;
use File::stat;
use File::Slurp;
use File::Spec::Functions qw/catdir no_upwards splitdir/;
use MRO::Compat;;

our $VERSION = '0.11';


=head1 NAME

Catalyst::Plugin::Static - DEPRECATED - Serve static files with Catalyst

=head1 SYNOPSIS

    use Catalyst 'Static';

    # let File::MMagic determine the content type
    $c->serve_static;

    # or specify explicitly if you know better
    $c->serve_static('text/css');

=head1 DESCRIPTION

Serve static files from config->{root}. You probably want to use
use L<Catalyst::Plugin::Static::Simple> rather than this module.

=head2 METHODS

=over 4

=item finalize

This plugin overrides finalize to make sure content is removed on
redirect.

=cut

sub finalize {
    my $c = shift;
    if ( $c->res->status =~ /^(1\d\d|[23]04)$/ ) {
        $c->res->headers->remove_content_headers;
        $c->finalize_headers;
    }
    return $c->next::method(@_);

}

=item serve_static

Call this method from your action to serve requested path
as a static file from your root. takes an optional content_type
parameter

=cut

sub serve_static {
    my $c    = shift;
    my $r = eval {
    my $path = $c->config->{root} . '/' . $c->req->path;
    $c->serve_static_file( $path, @_ );
    };
    warn("serve_static puked $@") if $@;
    $r;
}

=item serve_static_file <file>

Serve a specified static file.

=cut

sub serve_static_file {
    my $c    = shift;
    my $path = catdir(no_upwards(splitdir( shift )));

    if ( -f $path ) {

        my $stat = stat($path);

        if ( $c->req->headers->header('If-Modified-Since') ) {

            if ( $c->req->headers->if_modified_since == $stat->mtime ) {
                $c->res->status(304); # Not Modified
                $c->res->headers->remove_content_headers;
                return 1;
            }
        }

        my $type = shift || mimetype($path);
        my $content = read_file($path);
        $c->res->headers->content_type($type);
        $c->res->headers->content_length( $stat->size );
        $c->res->headers->last_modified( $stat->mtime );
        $c->res->output($content);
        if ( $c->config->{static}->{no_logs} && $c->log->can('abort') ) {
           $c->log->abort( 1 );
	}
        $c->log->debug(qq/Serving file "$path" as "$type"/) if $c->debug;
        return 1;
    }

    $c->log->debug(qq/Failed to serve file "$path"/) if $c->debug;
    $c->res->status(404);

    return 0;
}

=back

=head1 SEE ALSO

L<Catalyst>.

=head1 CAVEATS

This module is not as optimized for static files as a normal web
server, and is most useful for stand alone operation and development.

=head1 AUTHOR

Sebastian Riedel, C<sri@cpan.org>
Christian Hansen <ch@ngmedia.com>
Marcus Ramberg <mramberg@cpan.org>

=head1 THANK YOU

Torsten Seemann and all the others who've helped.

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
