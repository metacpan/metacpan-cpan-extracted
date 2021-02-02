package CatalystX::Errors;

our $VERSION = '0.001003';
$VERSION = eval $VERSION;
 
1;

=head1 NAME

CatalystX::Errors - Standard error handling with content negotiation

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
properly content negotiation.   Out of the box it support returning errors in HTML,
JSON and Text, with errors in a number of common languages.   Patches to support more
languages and media types welcomed.

I wrote this to encapsulate a common pattern I noted emerging in many of my applications.
Hopefully this will reduce boilerplate setup and speed your initial work.  Also its never
bad to have rational ways to do common things.

There is a very basic example application in C</example> for your review.  This distribution
doesn't have a ton of test cases and I reserve the right to make breaking changes should a 
better paradigm for this use case emerge.  You should review the docs for each class in
this distribution for more info.

=head1 SEE ALSO
 
L<Catalyst>. L<Catalyst::Plugin::Errors>, L<Catalyst::View::Errors::HTML>,
L<Catalyst::View::Errors::Text>,  L<Catalyst::View::Errors::JSON>, 
L<Catalyst::ActionRole::RenderErrors>.

=head1 AUTHOR
 
    John Napiorkowski L<email:jjnapiork@cpan.org>
    
=head1 COPYRIGHT & LICENSE
 
Copyright 2021, John Napiorkowski L<email:jjnapiork@cpan.org>
 
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
