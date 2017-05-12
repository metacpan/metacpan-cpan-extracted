package Dancer2::Plugin::Swagger2;

use strict;
use warnings;

# ABSTRACT: A Dancer2 plugin for creating routes from a Swagger2 spec
our $VERSION = '0.003'; # VERSION

use Dancer2 ':syntax';
use Dancer2::Plugin;
use Module::Load;
use Swagger2;
use Swagger2::SchemaValidator;


sub DEBUG { !!$ENV{SWAGGER2_DEBUG} }


register swagger2 => sub {
    my ( $dsl, %args ) = @_;
    my $conf = plugin_setting;

    ### get arguments/config values/defaults ###

    my $controller_factory =
         $args{controller_factory} || \&_default_controller_factory;
    my $url = $args{url} or die "argument 'url' missing";
    my $validate_spec =
        exists $args{validate_spec}   ? !!$args{validate_spec}
      : exists $conf->{validate_spec} ? !!$conf->{validate_spec}
      :                                 1;
    my $validate_requests =
        exists $args{validate_requests}   ? !!$args{validate_requests}
      : exists $conf->{validate_requests} ? !!$conf->{validate_requests}
      :                                     $validate_spec;
    my $validate_responses =
        exists $args{validate_responses}   ? !!$args{validate_responses}
      : exists $conf->{validate_responses} ? !!$conf->{validate_responses}
      :                                      $validate_spec;

    # parse Swagger2 file
    my $spec = Swagger2->new($url)->expand;

    if ( $validate_spec or $validate_requests or $validate_responses ) {
        if ( my @errors = $spec->validate ) {
            if ($validate_spec) {
                die join "\n" => "Swagger2: Invalid spec:", @errors;
            }
            else {
                warn "Spec contains errors but"
                  . " request/response validation is enabled!";
            }
        }
    }

    my $basePath = $spec->api_spec->get('/basePath');
    my $paths    = $spec->api_spec->get('/paths');    # TODO might be undef?

    while ( my ( $path => $path_spec ) = each %$paths ) {
        my $dancer2_path = $path;

        $basePath and $dancer2_path = $basePath . $dancer2_path;

        # adapt Swagger2 syntax for URL path arguments to Dancer2 syntax
        # '/path/{argument}' -> '/path/:argument'
        $dancer2_path =~ s/\{([^{}]+?)\}/:$1/g;

        while ( my ( $http_method => $method_spec ) = each %$path_spec ) {
            my $coderef = $controller_factory->(
                $method_spec, $http_method, $path, $dsl, $conf, \%args
            ) or next;

            DEBUG and warn "Add route $http_method $dancer2_path";

            my $params = $method_spec->{parameters};

            # Dancer2 DSL keyword is different from HTTP method
            $http_method eq 'delete' and $http_method = 'del';

            $dsl->$http_method(
                $dancer2_path => sub {
                    if ($validate_requests) {
                        my @errors =
                          _validate_request( $method_spec, $dsl->request );

                        if (@errors) {
                            DEBUG and warn "Invalid request: @errors\n";
                            $dsl->status(400);
                            return { errors => [ map { "$_" } @errors ] };
                        }
                    }

                    my $result = $coderef->();

                    if ($validate_responses) {
                        my @errors =
                          _validate_response( $method_spec, $dsl->response,
                            $result );

                        if (@errors) {
                            DEBUG and warn "Invalid response: @errors\n";
                            $dsl->status(500);

                            # TODO hide details of server-side errors?
                            return { errors => [ map { "$_" } @errors ] };
                        }
                    }

                    return $result;
                }
            );
        }
    }
};

register_plugin;

sub _validate_request {
    my ( $method_spec, $request ) = @_;

    my @errors;

    for my $parameter_spec ( @{ $method_spec->{parameters} } ) {
        my $in       = $parameter_spec->{in};
        my $name     = $parameter_spec->{name};
        my $required = $parameter_spec->{required};

        if ( $in eq 'body' ) {    # complex data structure in HTTP body
            my $input  = $request->data;
            my $schema = $parameter_spec->{schema};

            push @errors, _validator()->validate_input( $input, $schema );
        }
        else {    # simple key-value-pair in HTTP header/query/path/form
            my $type = $parameter_spec->{type};
            my @values;

            if ( $in eq 'header' ) {
                @values = $request->header($name);
            }
            elsif ( $in eq 'query' ) {
                @values = $request->query_parameters->get_all($name);
            }
            elsif ( $in eq 'path' ) {
                @values = $request->route_parameters->get_all($name);
            }
            elsif ( $in eq 'formData' ) {
                @values = $request->body_parameters->get_all($name);
            }
            else { die "Unknown value for property 'in' of parameter '$name'" }

            # TODO align error messages to output style of SchemaValidator
            if ( @values == 0 and $required ) {
                $required and push @errors, "No value for parameter '$name'";
                next;
            }
            elsif ( @values > 1 ) {
                push @errors, "Multiple values for parameter '$name'";
                next;
            }

            my $value  = $values[0];
            my %input  = ( $name => $value );
            my %schema = ( properties => { $name => $parameter_spec } );

            $required and $schema{required} = [$name];

            push @errors, _validator()->validate_input( \%input, \%schema );
        }
    }

    return @errors;
}

sub _validate_response {
    my ( $method_spec, $response, $result ) = @_;

    my $responses = $method_spec->{responses};
    my $status    = $response->status;

    my @errors;

    if ( my $response_spec = $responses->{$status} || $responses->{default} ) {

        my $headers = $response_spec->{headers};

        while ( my ( $name => $header_spec ) = each %$headers ) {
            my @values = $response->header($name);

            if ( $header_spec->{type} eq 'array' ) {
                push @errors,
                  _validator()->validate_input( \@values, $header_spec );
            }
            else {
                if ( @values == 0 ) {
                    next;    # you can't make a header 'required' in Swagger2
                }
                elsif ( @values > 1 ) {

                   # TODO align error message to output style of SchemaValidator
                    push @errors, "header '$name' has multiple values";
                    next;
                }

                push @errors,
                  _validator()->validate_input( $values[0], $header_spec );
            }
        }

        if ( my $schema = $response_spec->{schema} ) {
            push @errors, _validator()->validate_input( $result, $schema );
        }
    }
    else {
        # TODO Call validate_input($response, {}) like
        #      in Mojolicious::Plugin::Swagger2?
        # Swagger2-0.71/lib/Mojolicious/Plugin/Swagger2.pm line L315
    }

    return @errors;
}


sub _default_controller_factory {
    # TODO simplify argument list
    my ( $method_spec, $http_method, $path, $dsl, $conf, $args, ) = @_;

    # from Dancer2 app
    my $namespace = $args->{controller} || $conf->{controller};
    my $app = $dsl->app->name;

    # from Swagger2 file
    my $module;
    my $method = $method_spec->{operationId};
    if ( $method =~ s/^(.+)::// ) {    # looks like Perl module
        $module = $1;
    }

    # different candidates possibly reflecting operationId
    my @controller_candidates = do {
        if ($namespace) {
            if ($module) { $namespace . '::' . $module, $module }
            else         { $namespace }
        }
        else {
            if ($module) {
                (                      # parens for better layout by Perl::Tidy
                    $app . '::' . $module,
                    $app . '::Controller::' . $module,
                    $module,           # maybe a top level module name?
                );
            }
            else { $app, $app . '::Controller' }
        }
    };

    # check candidates
    for my $controller (@controller_candidates) {
        local $@;
        eval { load $controller };
        if ($@) {
            if ( $@ =~ m/^Can't locate / ) {    # module doesn't exist
                DEBUG and warn "Can't load '$controller'";

                # don't do `next` here because controller could be
                # defined in other package ...
            }
            else {    # module doesn't compile
                die $@;
            }
        }

        if ( my $cb = $controller->can($method) ) {
            return $cb;    # confirmed candidate
        }
        else {
            DEBUG and warn "Controller '$controller' can't '$method'";
        }
    }

    # none found
    warn "Can't find any handler for operationId '$method_spec->{operationId}'";
    return;
}

my $validator;
sub _validator { $validator ||= Swagger2::SchemaValidator->new }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::Swagger2 - A Dancer2 plugin for creating routes from a Swagger2 spec

=head1 VERSION

version 0.003

=head1 SYNOPSIS

C<example/my_app.pl>:

    #!/usr/bin/env perl

    use Dancer2;
    use Dancer2::Plugin::Swagger2;
    use Path::Tiny;

    swagger2( url => path(__FILE__)->parent->child('swagger2.yaml') );

    sub my_controller {
        return "Hello World!\n";
    }

    dance;


C<example/swagger2.yaml>:

    ---
    swagger: "2.0"
    info:
      title: MyApp's API
      version: "1.0"
    basePath: /api
    paths:
      /welcome:
        get:
          operationId: my_controller
          responses:
            200:
              description: success


Then on the terminal run:

    perl my_app.pl
    curl http://localhost:3000/api/welcome

You'll find the example files displayed above in the distribution and repository.

=head1 MIGRATING FROM DANCER1

If you've been using Dancer1 before you might know L<Dancer::Plugin::Swagger>.
Please note that that module's workflow is completely different! It is about
creating the spec from the app. The module described in this text is about
reading the spec and creating parts of the app for you.

=head1 DEBUGGING

To see some more debug messages on STDERR set environment variable C<SWAGGER2_DEBUG>
to a true value.

=head1 METHODS

=head2 swagger2( url => $url, ... )

Import routes from Swagger file. Named arguments:

=over

=item * C<url>: URL to passed to L<Swagger2> module

=item * C<controller_factory>: custom callback generator/finder that returns callbacks to routes

=item * C<validate_spec>: boolish value (default: true) telling if Swagger2 file shall be validated by official Swagger specification

=item * C<validate_requests>: boolish value (default: same as C<validate_spec>) telling if HTTP requests shall be validated by loaded specification (needs C<validate_spec> to be true)

=item * C<validate_responses>: boolish value (default: same as C<validate_spec>) telling if HTTP responses shall be validated by loaded specification (needs C<validate_spec> to be true)

=back

=head2 default_controller_factory

Default method for finding a callback for a given C<operationId>. Can be
overriden by the C<controller_factory> argument to C<swagger2> or config option.

The default uses the C<controller> argument/config option or the name of
the app (possibly with C<::Controller> appended). If the C<operationId>
looks like a Perl module the module name is tried under the namespace
mentioned above and as a top level module name.

The module warns as long as controller modules or methods can't be found
and returns a coderef on the first match.

=head1 SEE ALSO

=over

=item * L<Mojolicious::Plugin::Swagger2> A similar plugin for the L<Mojolicious> Web framework

=item * L<http://swagger.io/>: Website of the Swagger alias OpenAPI Specification

=back

=head1 ACKNOWLEDGEMENT

This software has been developed with support from L<STRATO|https://www.strato.com/>.
In German: Diese Software wurde mit Unterstützung von L<STRATO|https://www.strato.de/> entwickelt.

=head1 AUTHORS

=over 4

=item *

Daniel Böhmer <dboehmer@cpan.org>

=item *

Tina Müller <cpan2@tinita.de>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Daniel Böhmer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
