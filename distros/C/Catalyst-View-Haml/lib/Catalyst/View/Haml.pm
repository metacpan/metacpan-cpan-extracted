package Catalyst::View::Haml;
use Moose;
use Text::Haml;
use Path::Class::File;
use Encode;
use Carp;
use Try::Tiny;
use namespace::autoclean;

extends 'Catalyst::View';
our $VERSION = '1.00';

has 'haml' => ( is => 'rw', isa => 'Text::Haml' );

has 'catalyst_var' => ( is => 'rw', isa => 'Str', default => 'c' );

has 'template_extension' => ( is => 'rw', isa => 'Str', default => '.haml' );

has 'path' => ( is => 'rw', isa => 'ArrayRef' );

has 'charset' => ( is => 'rw', isa => 'Str', default => 'utf-8' );

has 'format' => (
    is      => 'rw',
    isa     => 'Str',
    default => 'xhtml',
    trigger => sub { \&_reset_attribute('format', @_) },
);

has 'vars_as_subs' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    trigger => sub { \&_reset_attribute('vars_as_subs', @_) },
);

has 'escape_html' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
    trigger => sub { \&_reset_attribute('escape_html', @_) },
);

sub _reset_attribute {
    my ($method_name, $self, $value )= @_;
    
    $self->_build_haml() unless $self->haml;
    $self->haml->$method_name( $value );
}

sub _build_haml {
    my ($self, $c) = @_;

    my $haml = Text::Haml->new(
        vars_as_subs => $self->vars_as_subs,
        encoding     => $self->charset,
        escape_html  => $self->escape_html,
        format       => $self->format,
    );
    $self->path([ $c->path_to('root') ]) unless $self->path;
    $self->haml( $haml );
}


sub ACCEPT_CONTEXT {
    my ($self, $c) = @_;

    $self->_build_haml($c) unless $self->haml;
    return $self;
}


sub process {
    my ($self, $c) = @_;

    my $stash = $c->stash;
    my $template = $stash->{template}
      || $c->action . $self->template_extension;

    unless (defined $template) {
        $c->log->debug('No template specified for rendering') if $c->debug;
        return 0;
    }

    $self->_build_haml( $c ) unless $self->haml;

    foreach my $path ( @{ $self->path } ) {
        my $file = Path::Class::File->new( $path, $template );
        next unless -e $file->stringify;

        my $output;
        try {
            $output = eval { $self->render( $c, $file, $stash ) };
        }
        catch {
            return $self->_rendering_error( $c, "$file : $_" );
        };
        
        my $res = $c->response;
        unless ( $res->content_type ) {
            $res->content_type('text/html; charset=' . $self->charset);
        }

        $res->body( $output );

        return 1;
    }
}


sub render {
    my ($self, $c, $file, $vars) = @_;

    local $vars->{ $self->catalyst_var } =
        $vars->{ $self->catalyst_var } || $c;

    my $fh = $file->openr;
    $fh->binmode(':utf8');
    
    # slurp file (chunk size = 4096 bytes)
    my $tmpl = '';
    while ( $fh->sysread( my $buffer, 4096, 0 ) ) {
        $tmpl .= $buffer;
    }

    # handle encoding
    $tmpl = Encode::decode($self->charset, $tmpl) if $self->charset;

    # render
    my $output = $self->haml->render($tmpl, %$vars);
    if (my $error = $self->haml->error) {
        croak $error;
    }
    return $output;
}


sub _rendering_error {
    my ($self, $c, $err) = @_;
    my $error = qq/Couldn't render template "$err"/;
    $c->log->error($error);
    $c->error($error);
    return 0;
}

__PACKAGE__->meta->make_immutable();


42; # End of Catalyst::View::Haml

__END__

=pod

=head1 NAME

Catalyst::View::Haml - Haml View Class for Catalyst

=head1 SYNOPSIS

New to Haml? Check out L<http://haml-lang.com/tutorial.html>. This module lets
you create a Haml view for your Catalyst application:

  package MyApp::View::Web;
  use Moose;
  extends 'Catalyst::View::Haml';
  
  # ...your custom code here...
  
  1;

or use the helper to create it for you:

   myapp_create.pl view Web Haml

then you can write your templates in Haml!

  #content
    .left.column
      %h2 Welcome to our site!
      %p= $information
    .right.column
      = $item->{body}

If you want to omit sigils in your Haml templates, just set the 'vars_as_subs'
option:

  package MyApp::View::Web;
  use Moose;
  extends 'Catalyst::View::Haml';

  has '+vars_as_subs', default => 1;

  1;

this way the Haml template above becomes:

  #content
    .left.column
      %h2 Welcome to our site!
      %p= information
    .right.column
      = item->{body}


=head1 CONFIGURATION

You may specify the following configuration items in from your config file
or directly on the view object.

=head2 catalyst_var

The name used to refer to the Catalyst app object in the template

=head2 template_extension

The suffix used to auto generate the template name from the action name
(when you do not explicitly specify the template filename); Defaults to '.haml'

=head2 charset

The charset used to output the response body. The value defaults to 'UTF-8'.

=head2 path

Array reference specifying one or more directories in which template files are
located. Defaults to your application's "root" directory.

=head2 format

Sets Haml output format. Can be set to 'xhtml', 'html' or 'html5'. Defaults to
'xhtml'.

=head2 vars_as_subs

When set to true, Perl variables become lvalue subroutines, so you can use
them in you Haml templates without sigils. Default is false.

=head2 escape_html

Switch on/off Haml output html escaping. Default is on.

=head1 TODO

=over 4

=item * CACHE (!)

=item * filters

=item * helpers

=item * Missing Text::Haml options

=back

=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-view-haml at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-View-Haml>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::View::Haml


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-View-Haml>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-View-Haml>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-View-Haml>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-View-Haml/>

=back


=head1 ACKNOWLEDGEMENTS

Viacheslav Tykhanovskyi (vti) for his awesome L<Text::Haml> implementation of
L<Haml|http://haml-lang.com>, the entire Haml and Catalyst teams of devs,
and Daisuke Maki (lesterrat) for Catalyst::View::Xslate, from which lots of
this code was borrowed (sometimes nearly verbatim).

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Breno G. de Oliveira.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
