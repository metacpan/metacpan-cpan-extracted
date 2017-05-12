package Catalyst::View::HTML::Template::Compiled;

use strict;
use base 'Catalyst::Base';

use HTML::Template::Compiled ();
use Path::Class              ();

our $VERSION = '0.16';

__PACKAGE__->mk_accessors(qw/htc catalyst/);

=head1 NAME

Catalyst::View::HTML::Template::Compiled - HTML::Template::Compiled View Class

=head1 SYNOPSIS

    # use the helper
    script/myapp_create.pl view HTML::Template::Compiled HTML::Template::Compiled

    # lib/MyApp/View/HTML/Template.pm
    package MyApp::View::HTML::Template::Compiled;

    use base 'Catalyst::View::HTML::Template::Compiled';

    __PACKAGE__->config(
    	use_default_path => 0, # defaults to 1

        # any HTML::Template::Compiled configurations items go here
        # see HTML::Template::Compiled documentation for more details
    );

    1;

    # Meanwhile, maybe in an 'end' action
    $c->forward('MyApp::View::HTML::Template::Compiled');

=head1 DESCRIPTION

This is the C< HTML::Template::Compiled > view class. Your subclass should inherit from this
class.

=head1 METHODS

=over 4

=item new

Internally used by C<Catalyst>. Used to configure some internal stuff.

=cut

sub new {
    my ( $class, $c, $arguments ) = @_;
    my $config = {
        use_perl => 0,
        %{ $class->config },
        %{ $arguments },
    };

    my @config_names = $class->config_names;
    foreach (@config_names) {
        if(exists $c->config->{$_}) {
            $config = {
                %{ $config },
                %{ $c->config->{$_} || {} },
            };
        }
    }

    $config->{use_default_path} = 1
      unless defined $config->{use_default_path};

    my $self = $class->NEXT::new(
        $c, { %$config },
    );
    $self->catalyst( $c );
    $self->config($config);

    return $self;
}

=item process

Renders the template specified in I< $c->stash->{template} >, I< $c->request->match >,
I< $c->config->{template}->{filename} > or I< __PACKAGE__->config->{filename} >.

Template params are set up from the contents of I< $c->stash >,
augmented with C< base > set to I< $c->req->base >, I< name > to
I< $c->config->{name} > and I< c > to I< $c >. Output is stored in I< $c->response->body >.

=cut

sub process {
    my ( $self, $c ) = @_;

    return 0 unless $self->prepare_process( $c );
    return 0 unless $self->prepare_htc( $c );
    return 0 unless $self->prepare_render( $c );

    my $retval = 0;
    if( $retval = defined( my $body = $self->render( $c ) ) ) {
        $c->res->headers->content_type('text/html; charset=utf-8')
          unless ( $c->response->headers->content_type );

        $c->response->body($body);
    }

    return $self->finalize_process( $c );
}

=item prepare_process

Pretty much the first thing called by I< process >.
Only used for sub-classing. Return a i<true>-value if everything is okay,
otherwise I< process > will fail.

=cut

sub prepare_process {
    my ($self, $c ) = @_;

    return 1;
}

=item finalize_process

Will be called right before I< process > finishes.
Only used for sub-classing. Whatever it returns,
I< process > will return.

=cut

sub finalize_process {
    my ($self, $c ) = @_;

    return 1;
}

=item prepare_htc

Creates the C< HTML::Template::Compiled > object.
On success, returns the filename to be rendered; undef otherwise.

=cut

sub prepare_htc {

    my ($self, $c ) = @_;
    $c ||= $self->catalyst;

    my $filename = $self->template( $c );
    unless( $filename && $self->htc ) {
        my $error = "Nothing to render.";
        $c->log->error($error);
        $c->error($error);
        return undef;
    }

    return $self->htc->get_file;
}

=item htc

Accessor to the C<HTML::Template::Compiled> object.
May returns undef then the object has not yet been created
or creating has failed.

=cut

=item prepare_render

First thing before C< render > is called.
Assigns the parameters like the ones from the
stash.

=cut

sub prepare_render {
    my ($self, $c ) = @_;
    $c ||= $self->catalyst;

    $self->htc->param(
        base => $c->request->base,
        name => $c->config->{name},
        c    => $c,
        %{ $c->stash }
    );

    return 1;
}

=item render

This is where the rendering magic happens.
Returns the rendered output on success, or undef otherwise.

=cut

sub render {
    my ($self, $c ) = @_;
    $c ||= $self->catalyst;

    $c->log->debug(sprintf('Trying to render template "%s" ...', $self->htc->get_file))
      if $c->debug;

    my $body;
    eval { $body = $self->htc->output };
    if ( my $error = $@ ) {
        chomp $error;
        $error = sprintf(
            qq/Couldn't render template "%s". Error: "%s"/,
            $self->htc->get_file, $error
        );
        $c->log->error($error);
        $c->error($error);
        return undef;
    }

    return $body;
}

=item template

Tries to find the right template to render.
Returns its filename or undef.
Actually only used internally.

=cut

sub template {
    my ($self, $c ) = @_;

    $c ||= $self->catalyst;
    $c->log->debug('Finding template to render ...')
      if $c->debug;

    my %options = (
        %{ $self->config },
        path => $self->path( $c ),
    );

    my $extension = $self->config->{extension} || '';
    if ($extension) {
        $extension = ".$extension"
          unless substr( $extension, 0, 1 ) eq '.';
    }
    my $prefix = $self->config->{prefix} || '';
    my @filenames = (
        $c->stash->{template},
        $prefix . $c->request->match . $extension,
        $prefix . $c->request->action . $extension,
        $self->config->{filename},
        $c->config->{template}->{filename},
    );

    my $htc;
    foreach my $filename (@filenames) {
        next unless $filename;

        $options{filename} = $filename;
        eval { $htc = HTML::Template::Compiled->new(%options); };
        last unless $@;

        $c->log->debug( "HTC error: $@" ) if $c->debug;
    }

    $self->htc( $htc );

    return $options{filename};
}

=item path

Returns a array ref with paths used to find the templates in.

=cut

sub path {
    my ($self, $c) = @_;

    $c ||= $self->catalyst;

    my $templ_path = $self->config->{path} || '';
    $templ_path = [$templ_path]
      unless 'ARRAY' eq ref $templ_path;

    my $path = $self->_build_path(
        $templ_path,
        ( map { $c->path_to($_) } @$templ_path ),
        (
            $self->config->{use_default_path}
            ? ( $c->config->{root}, $c->config->{root} . '/base' )
            : ()
        ),
    );

    return $path;
}

sub _build_path {
    my ( $self, @paths ) = @_;

    my @retval = ();
    foreach my $path (@paths) {
        next unless defined $path;

        if ( ref($path) eq 'ARRAY' ) {
            push @retval, $self->_build_path( @{$path} );
        }
        elsif ( ref($path) eq 'Path::Class::Dir' ) {

            # stringify it
            push @retval, "" . $path->absolute;
        }
        else {
            push @retval, $self->_build_path( Path::Class::dir($path) );
        }
    }

    return wantarray ? @retval : [@retval];
}

=item config

C<< use_default_path >>: if set, will include I<< $c->config->{root} >> and
I<< $c->config->{root} . '/base' >> to look for the template. I<< Defaults to 1 >>.

This also allows your view subclass to pass additional settings to the
C<< HTML::Template::Compiled >> config hash.

=item config_names

A list of names that are used to locate configuration parameters
for the view inside C< $c->config >.

=cut

sub config_names {
    return qw/View::HTML::Template::Compiled V::HTML::Template::Compiled View::HTC V::HTC template/;
}

=item catalyst

Normally all methods are called with the I< $c > as the first parameter.
Just to insure that you have it as a method it case you need it. :)
Will be initializes by C< new >.

=cut

=back

=head1 SEE ALSO

L<HTML::Template::Compiled>, L<Catalyst>, L<Catalyst::Base>.

=head1 AUTHOR

Sascha Kiefer, C<esskar@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
