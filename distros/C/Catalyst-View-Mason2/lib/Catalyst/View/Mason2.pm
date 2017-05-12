package Catalyst::View::Mason2;
BEGIN {
  $Catalyst::View::Mason2::VERSION = '0.03';
}
use Mason;
use Scalar::Util qw/blessed/;
use strict;
use warnings;
use base qw(Catalyst::View);

__PACKAGE__->mk_accessors(qw(interp));

sub new {
    my ( $class, $c, $arguments ) = @_;

    my %config = (
        comp_root        => $c->path_to( 'root', 'comps' ),
        mason_root_class => 'Mason',
        plugins          => [],
        %{ $class->config },
        %{$arguments},
    );

    # Stringify comp_root and data_dir if they are objects
    #
    foreach my $key (qw(comp_root data_dir)) {
        $config{$key} .= "" if blessed( $config{$key} );
    }

    # Add globals
    #
    push( @{ $config{allow_globals} }, '$c' );

    # Call superclass to create initial object
    #
    my $self = $class->next::method( $c, \%config );
    $self->config( {%config} );

    # Remove non-Mason parameters.
    #
    my $mason_root_class = delete( $config{mason_root_class} );
    delete @config{qw(catalyst_component_name)};

    # Create and store the interp
    #
    my $interp = $mason_root_class->new(%config);
    $self->interp($interp);

    return $self;
}

sub get_component_path {
    my ( $self, $c ) = @_;

    # If template was specified in stash, use that; otherwise use the action.
    #
    my $path = $c->stash->{template} || $c->action;
    $path = "/$path" if substr( $path, 0, 1 ) ne '/';

    return $path;
}

sub process {
    my ( $self, $c ) = @_;

    my $path = $self->get_component_path($c);
    my $output = $self->render( $c, $path, $c->stash );

    unless ( $c->response->content_type ) {
        $c->response->content_type('text/html; charset=utf-8');
    }
    $c->response->body($output);

    return 1;
}

sub render {
    my ( $self, $c, $path, $args ) = @_;

    $self->interp->set_global( '$c' => $c );
    return $self->interp->run( $path, %$args )->output;
}

1;



=pod

=head1 NAME

Catalyst::View::Mason2 - Mason 2.x view class

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    # use the helper
    script/create.pl view Mason2 Mason2

    # lib/MyApp/View/Mason2.pm
    package MyApp::View::Mason2;
    use base 'Catalyst::View::Mason2';
    __PACKAGE__->config(
        # insert Mason parameters here
    );

    1;

    # in a controller
    package MyApp::Controller::Foo;
    sub bar : Local {
        ...
        $c->stash->{name} = 'Homer';
        $c->stash->{template} = 'foo/bar';   # .mc is automatically added
    }

    # in root/comps/foo/bar.mc
    <%args>
    $.name
    </%args>

    Hello <% $.name %>! Your URI was <% $c->req->uri %>.

=head1 DESCRIPTION

Allows you to use L<Mason 2.x|Mason> for your views.

=for readme stop

=head1 VIEW CONFIGURATION

=over

=item mason_root_class

Class to use for creating the Mason object. Defaults to 'Mason'.

=back

=head1 MASON CONSTRUCTOR

Other than any special mentioned keys above, the configuration for this view
will be passed directly into C<< Mason->new >>.

There are a few defaults specific to this view:

=over

=item comp_root

If not provided, defaults C<< $c->path_to('root', 'comps') >>.

=item data_dir

If not provided, defaults C<< $c->path_to('data') >>.

=item allow_globals

Automatically includes C<$c>.

=back

All other defaults are standard Mason.

=head1 GLOBALS

All components have access to C<$c>, the current Catalyst context.

=head1 METHODS

=over

=item process ($c)

Renders the component specified in C<< $c->stash->{template} >> or, if not
specified, C<< $c->action >>.

The component path is prefixed with a '/' if it does not already have one, and
Mason will automatically add a ".mc" extension - to change the latter, you can
use

    __PACKAGE__->config(
        autoextend_request_path => 0
    );

Request arguments are taken from C<< $c->stash >>.

=item render ($c, $path, \%args)

Renders the component C<$path> with C<\%args>, and returns the output.

=back

=for readme continue

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

