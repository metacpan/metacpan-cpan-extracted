package Alien::SwaggerUI;
our $VERSION = '0.001';
# ABSTRACT: Render OpenAPI spec documentation with Swagger-UI

#pod =head1 SYNOPSIS
#pod
#pod     use Alien::SwaggerUI;
#pod     my $app_dir = Alien::SwaggerUI->root_dir;
#pod
#pod     #-- Serve Swagger-UI with Mojolicious::Lite
#pod     use File::Spec::Functions qw( catfile );
#pod     use Alien::SwaggerUI;
#pod     use Mojolicious::Lite;
#pod
#pod     get '/swagger/*path' => { path => 'index.html' }, sub {
#pod         my ( $c ) = @_;
#pod         my $path = catfile( Alien::SwaggerUI->root_dir, $c->stash( 'path' ) );
#pod         my $file = Mojo::Asset::File->new( path => $path );
#pod         $c->reply->asset( $file );
#pod     };
#pod
#pod     app->start;
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module contains L<Swagger UI|http://swagger.io/swagger-ui/>. This
#pod pure-JavaScript application renders beautiful documentation for your
#pod application's L<OpenAPI specification|https://www.openapis.org>.
#pod
#pod The application is contained in a C<share/> directory. You can get the path
#pod to this directory with the L</root_dir> method.
#pod
#pod To render your specific API documentation, pass it in with the
#pod C<?url=/path/to/spec> query parameter.
#pod
#pod =head1 SEE ALSO
#pod
#pod =over
#pod
#pod =item L<Swagger UI|http://swagger.io/swagger-ui/>
#pod
#pod =item L<OpenAPI specification|https://www.openapis.org>
#pod
#pod =back
#pod
#pod =cut

use strict;
use warnings;
use File::Share qw( dist_dir );

sub root_dir {
    return dist_dir( 'Alien-SwaggerUI' );
}

1;

__END__

=pod

=head1 NAME

Alien::SwaggerUI - Render OpenAPI spec documentation with Swagger-UI

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Alien::SwaggerUI;
    my $app_dir = Alien::SwaggerUI->root_dir;

    #-- Serve Swagger-UI with Mojolicious::Lite
    use File::Spec::Functions qw( catfile );
    use Alien::SwaggerUI;
    use Mojolicious::Lite;

    get '/swagger/*path' => { path => 'index.html' }, sub {
        my ( $c ) = @_;
        my $path = catfile( Alien::SwaggerUI->root_dir, $c->stash( 'path' ) );
        my $file = Mojo::Asset::File->new( path => $path );
        $c->reply->asset( $file );
    };

    app->start;

=head1 DESCRIPTION

This module contains L<Swagger UI|http://swagger.io/swagger-ui/>. This
pure-JavaScript application renders beautiful documentation for your
application's L<OpenAPI specification|https://www.openapis.org>.

The application is contained in a C<share/> directory. You can get the path
to this directory with the L</root_dir> method.

To render your specific API documentation, pass it in with the
C<?url=/path/to/spec> query parameter.

=head1 SEE ALSO

=over

=item L<Swagger UI|http://swagger.io/swagger-ui/>

=item L<OpenAPI specification|https://www.openapis.org>

=back

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Doug Bell.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
