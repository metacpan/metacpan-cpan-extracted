package Catalyst::View::PSP;

use strict;
use base 'Catalyst::Base';

use File::Spec;
use Text::PSP;
use Text::PSP::Parser;
use Text::PSP::Template;

our $VERSION = '0.01';

__PACKAGE__->mk_accessors('psp');

=head1 NAME

Catalyst::View::PSP - PSP View Class

=head1 SYNOPSIS

    # use the helper
    create.pl view PSP PSP

    # lib/MyApp/View/PSP.pm
    package MyApp::View::PSP;

    use base 'Catalyst::View::PSP';

    __PACKAGE__->config(
        workdir => '/tmp/psp'
    );

    1;

    # Meanwhile, maybe in an 'end' action
    $c->forward('MyApp::View::PSP');


=head1 DESCRIPTION

This is the C<PSP> view class. Your subclass should inherit from this
class.

=head2 METHODS

=over 4

=item new

The constructor for the PSP view.

=cut

sub new {
    my $self = shift;
    my $c    = shift;

    $self = $self->NEXT::new(@_);

    my %config = (
        create_workdir => 1,
        template_root  => $c->config->{root},
        workdir        => File::Spec->catdir( File::Spec->tmpdir, 'psp' ),
        %{ $self->config }
    );

    $self->psp( Text::PSP->new(%config) );

    return $self;
}

=item process

Renders the template specified in C<< $c->stash->{template} >> or 
C<< $c->request->match >>. Template arguments are C<$c>. Output is stored 
in C<< $c->response->body >>.

=cut

sub process {
    my ( $self, $c ) = @_;

    my $template = $c->stash->{template} || $c->req->match;

    unless ($template) {
        $c->log->debug('No template specified for rendering') if $c->debug;
        return 0;
    }

    my $psp;

    eval { $psp = $self->psp->find_template( 'base/' . $template ) };

    if ( my $error = $@ ) {
        chomp $error;
        $error = qq/Couldn't parse template "$template". Error: "$error"/;
        $c->log->error($error);
        $c->error($error);
        return 0;
    }

    $c->log->debug(qq/Rendering template "$template"/) if $c->debug;

    my $body;

    eval { $body = $psp->run($c) };

    if ( my $error = $@ ) {
        chomp $error;
        $error = qq/Couldn't render template "$template". Error: "$error"/;
        $c->log->error($error);
        $c->error($error);
        return 0;
    }

    unless ( $c->response->headers->content_type ) {
        $c->res->headers->content_type('text/html; charset=utf-8');
    }

    $c->response->body( join( "\n", @{ $body } ) );

    return 1;
}

=item config

This allows your view subclass to pass additional settings to the
Petal config hash.

=back

=head1 SEE ALSO

L<Text::PSP>, L<Catalyst>, L<Catalyst::Base>.

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
