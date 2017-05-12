package Catalyst::View::HTML::Template;

use strict;
use base 'Catalyst::View';

use HTML::Template;

our $VERSION = '0.03';

=head1 NAME

Catalyst::View::HTML::Template - HTML::Template View Class

=head1 SYNOPSIS

    # use the helper
    create.pl view HTML::Template HTML::Template

    # lib/MyApp/View/HTML/Template.pm
    package MyApp::View::HTML::Template;

    use base 'Catalyst::View::HTML::Template';

    __PACKAGE__->config(
        die_on_bad_params => 0,
        file_cache        => 1,
        file_cache_dir    => '/tmp/cache'
    );

    1;

    # Meanwhile, maybe in an 'end' action
    $c->forward('MyApp::View::HTML::Template');


=head1 DESCRIPTION

This is the C<HTML::Template> view class. Your subclass should inherit from this
class.

=head2 METHODS

=over 4

=item process

Renders the template specified in C<< $c->stash->{template} >> or C<<
$c->request->match >>.
Template params are set up from the contents of C<< $c->stash >>,
augmented with C<base> set to C<< $c->req->base >> and C<name> to 
C<< $c->config->{name} >>.  Output is stored in C<< $c->response->body >>.

=cut

sub process {
    my ( $self, $c ) = @_;

    my $filename = $c->stash->{template} || $c->req->match;
    my $body = $self->render($c,$filename);

    unless ( $c->response->headers->content_type ) {
        $c->res->headers->content_type('text/html; charset=utf-8');
    }

    $c->response->body($body);

    return 1;
}

=item render

Renders the given template and returns output. Template params are set up
either from the contents of  C<%$args> if $args is a hashref, or C<< $c->stash >>,
augmented with C<base> set to C<< $c->req->base >> and C<name> to
C<< $c->config->{name} >>.

=cut

sub render {
    my ( $self, $c, $filename, $args ) = @_;

    unless ($filename) {
        $c->log->debug('No template specified for rendering') if $c->debug;
        return 0;
    }

    my %options = (
        cache    => 1,
        filename => $filename,
        path     => [ $c->path_to('root'), $c->path_to('root','base') ],
    );

    $c->log->debug(qq/Rendering template "$filename"/) if $c->debug;

    my $template = HTML::Template->new( %options, %{ $self } );

    my $template_params = $args && ref($args) eq 'HASH' ? $args : $c->stash;

    $template->param(
        base => $c->req->base,
        name => $c->config->{name},
        %$template_params
    );

    my $output;

    eval { $output = $template->output };

    if ( my $error = $@ ) {
        chomp $error;
        $error = qq/Couldn't render template "$filename". Error: "$error"/;
        $c->log->error($error);
        $c->error($error);
        return 0;
    }
    return $output;
}

=item config

This allows your view subclass to pass additional settings to the
HTML::Template config hash.

=back

=head1 SEE ALSO

L<HTML::Template>, L<Catalyst>, L<Catalyst::Base>.

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
