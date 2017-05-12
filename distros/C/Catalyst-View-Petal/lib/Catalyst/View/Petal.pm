package Catalyst::View::Petal;

use strict;
use base 'Catalyst::View';

use Petal;

our $VERSION = '0.03';

=head1 NAME

Catalyst::View::Petal - Petal View Class

=head1 SYNOPSIS

    # use the helper
    create.pl view Petal Petal

    # lib/MyApp/View/Petal.pm
    package MyApp::View::Petal;

    use base 'Catalyst::View::Petal';

    __PACKAGE__->config(
        input              => 'XML',
        output             => 'XML',
        error_on_undef_var => 0
    );

    1;

    # Meanwhile, maybe in an 'end' action
    $c->forward('MyApp::View::Petal');


=head1 DESCRIPTION

This is the C<Petal> view class. Your subclass should inherit from this
class.

=head2 METHODS

=over 4

=item process

Renders the template specified in C<< $c->stash->{template} >> or C<<
$c->request->match >>.
Template variables are set up from the contents of C<< $c->stash >>,
augmented with C<base> set to C<< $c->req->base >>, C<c> to C<$c> and
C<name> to C<< $c->config->{name} >>.  Output is stored in
C<< $c->response->body >>.

=cut

sub process {
    my ( $self, $c ) = @_;

    my $file = $c->stash->{template} || $c->req->match;

    unless ($file) {
        $c->log->debug('No template specified for rendering') if $c->debug;
        return 0;
    }

    my %options = (
        base_dir => [ $c->config->{root}, $c->config->{root} . "/base" ],
        file     => $file
    );

    unless ( $c->debug ) {
        $options{debug_dump}         = 0;
        $options{error_on_undef_var} = 0;
    }

    my $process = {
        base => $c->req->base,
        c    => $c,
        name => $c->config->{name},
        %{ $c->stash }
    };

    $c->log->debug(qq/Rendering template "$file"/) if $c->debug;

    my $petal = Petal->new( %options, %{ $self->config } );

    my $body;

    eval { $body = $petal->process($process) };

    if ( my $error = $@ ) {
        chomp $error;
        $error = qq/Couldn't render template "$file". Error: "$error"/;
        $c->log->error($error);
        $c->error($error);
        return 0;
    }

    unless ( $c->response->headers->content_type ) {
        $c->res->headers->content_type('text/html; charset=utf-8');
    }

    $c->response->body($body);

    return 1;
}

=item config

This allows your view subclass to pass additional settings to the
Petal config hash.

=back

=head1 SEE ALSO

L<Petal>, L<Catalyst>, L<Catalyst::Base>.

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
