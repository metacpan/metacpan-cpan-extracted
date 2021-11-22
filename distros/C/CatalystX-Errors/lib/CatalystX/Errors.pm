package CatalystX::Errors;

our $VERSION = '0.001007';
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

=head1 EXCEPTION CLASSES

There are times when you need to throw an exception that should be properly interpreted at
the L<Catalyst> level.  You can take two approaches.  One is to capture and test $c->errors
in you final end action.  Or you can subclass L<CatalystX::Utils::HttpException> and annotate
how you want L<Catalyst::ActionRole::RenderErrors> to convert it to a Catalyst response. This
is not either or BTW, and both approaches may be needed (for example you might be using a distribution
like L<DBIx::Class> that doesn't let you control the errors object).  For example:

    package Catalyst::ActionRole::RenderView::Utils::NoView;
     
    use Moose;
    use namespace::clean -except => 'meta';
      
    extends 'CatalystX::Utils::HttpException';
    
    has '+status' => (is=>'ro', init_arg=>undef, default=>sub {500});
    has '+errors' => (
      is=>'ro',
      init_arg=>undef, 
      default=>sub { ["No View can be found to render."] },
    );
     
    __PACKAGE__->meta->make_immutable;

When you throw this exception it will render as a 500 error to your users but the message
"No View can be found to render." will go to the errors log.  You can add custom attributes and override
the message builder method as well:

    package Catalyst::ActionRole::Verbs::Utils::MethodNotAllowed;
     
    use Moose;
    use namespace::clean -except => 'meta';
      
    extends 'CatalystX::Utils::HttpException';
    
    has resource => (is=>'ro', required=>1);
    has allowed_methods => (is=>'ro', isa=>'ArrayRef[Str]', required=>1);
    has attempted_method => (is=>'ro', isa=>'Str', required=>1);

    has '+status' => (is=>'ro', init_arg=>undef, default=>sub {405});
    has '+errors' => (
      is=>'ro',
      init_arg=>undef, 
      default=>sub { ["HTTP Method '@{[ $_[0]->attempted_method ]}' not permitted for resource '@{[ $_[0]->resource ]}'.  Can only be: @{[ join ', ', @{$_[0]->allowed_methods||[]} ]}"] },
    );
     
    __PACKAGE__->meta->make_immutable;

In this case the user would get a 405 error and the message will go to the error logs for tracking.

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
