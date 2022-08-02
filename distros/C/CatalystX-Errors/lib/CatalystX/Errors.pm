package CatalystX::Errors;

our $VERSION = '0.001009';
$VERSION = eval $VERSION;
 
1;

=head1 NAME

CatalystX::Errors - Standard error handling with content negotiation and utilities

=head1 SYNOPSIS

Use in your application class

    package Example;

    use Catalyst;

    __PACKAGE__->setup_plugins([qw/Errors/]);
    __PACKAGE__->setup();
    __PACKAGE__->meta->make_immutable();

And then you can use it in a controller (or anyplace where you have C<$c> context).

    package Example::Controller::Root;

    use Moose;
    use MooseX::MethodAttributes;

    extends 'Catalyst::Controller';

    sub root :Chained(/) PathPart('') CaptureArgs(0) {} 

      sub not_found :Chained(root) PathPart('') Args {
        my ($self, $c, @args) = @_;
        $c->detach_error(404);
      }

    sub end :Does(RenderErrors) { }

    __PACKAGE__->config(namespace=>'');
    __PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

A set of L<Catalyst> plugins, views and action roles to streamline handling of HTTP
error responses.   Creates a standard way to return 4xx and 5xx HTTP errors using
proper content negotiation.   Out of the box it support returning errors in HTML,
JSON and Text, with errors in a number of common languages.   Patches to support more
languages and media types welcomed.

I wrote this to encapsulate a common pattern I noted emerging in many of my applications.
Hopefully this will reduce boilerplate setup and speed your initial work.  Also its never
bad to have rational ways to do common things.

There is a very basic example application in C</example> for your review.  This distribution
doesn't have a ton of test cases and I reserve the right to make breaking changes should a 
better paradigm for this use case emerge.  You should review the docs for each class in
this distribution for more info.

You should see the plugin for API method documentation: L<Catalyst::Plugin::Errors>.

B<NOTE>: The use case this is aimed at is proper handling of HTTP exception conditions resulting
from the actual HTTP routing and negotiation (page not found, not authorized, etc) and for
wrapping up any server side exceptions that get generated unexpectedly (such as data issues).
I don't really intend this to return error responses for something like invalid HTML forms for
example (althought you can use it for something like returning a generic 'bad request' in
response to an invalidly formed POST (such as an invalid CSRF token)).

=head1 EXCEPTION CLASSES

There are times when you need to throw an exception that should be properly interpreted at
the L<Catalyst> level.  For example you have exception conditions being throw from code outside your
main web framework code (such as in L<DBIx::Class>).  You can take two approaches.  One is to capture and test $c->errors
in you final end action.  Or you can consume the role  L<CatalystX::Utils::DoesHttpException> and annotate
how you want L<Catalyst::ActionRole::RenderErrors> to convert it to a Catalyst response. This
is not either or BTW, and both approaches may be needed (for example you might be using a distribution
like L<DBIx::Class> that doesn't let you control the errors object).  For example:

    package MyApp::Exception::NoCoffee;

    use Moose;
    extends 'CatalystX::Utils::DoesHttpException';

    sub status_code { 418 }
    sub error { 'Coffee not allowed' }
    sub additional_headers { [ 'X-Error-Code' => '200101' ] }

See L<CatalystX::Utils::DoesHttpException> and L<CatalystX::Utils::HttpException> for more details
and examples.

B<Note>: It's best of the action role L<Catalyst::ActionRole::RenderErrors> is the last role added
to the action so that your error handling happens first.

=head1 SEE ALSO
 
L<Catalyst>, L<Catalyst::Plugin::Errors>, L<Catalyst::View::Errors::HTML>,
L<Catalyst::View::Errors::Text>,  L<Catalyst::View::Errors::JSON>, 
L<Catalyst::ActionRole::RenderErrors>.

=head1 AUTHOR
 
    John Napiorkowski L<email:jjnapiork@cpan.org>
    
=head1 COPYRIGHT & LICENSE
 
Copyright 2022, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
