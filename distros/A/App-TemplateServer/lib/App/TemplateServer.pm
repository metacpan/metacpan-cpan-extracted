package App::TemplateServer;
use 5.010;
use feature ':5.10';

use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Types::Path::Class qw(File);

use HTTP::Daemon;
use HTTP::Headers;
use HTTP::Request;
use HTTP::Response;

use App::TemplateServer::Types;
use App::TemplateServer::Provider::TT;
use App::TemplateServer::Page::Index;
use App::TemplateServer::Context;

use Package::FromData;
use Method::Signatures;
use URI::Escape;
use YAML::Syck qw(LoadFile);

our $VERSION = '0.04';
our $AUTHORITY = 'cpan:JROCKWAY';

with 'MooseX::Getopt';

has 'port' => (
    is       => 'ro',
    isa      => 'Port',
    default  => '4000',
);

has 'docroot' => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    default  => sub { [$ENV{PWD}] },
    coerce   => 1,
    lazy     => 1,
);

has 'datafile' => ( # mocked data for the templates to use
    isa      => File,
    is       => 'ro',
    coerce   => 1,
    required => 0,
);

has '_raw_data' => ( 
    isa     => 'HashRef',
    is      => 'ro',
    default => sub { eval { LoadFile($_[0]->datafile) } || {} },
    lazy    => 1,
);

has '_data' => (
    isa     => 'HashRef',
    is      => 'ro',
    default => sub {
        my $self = shift;
        my $raw_data    = $self->_raw_data;
        my $package_def = delete $raw_data->{packages};
        create_package_from_data($package_def) if $package_def;

        my $to_instantiate = delete $raw_data->{instantiate};
        foreach my $var (keys %{$to_instantiate||{}}){
            my $class = $to_instantiate->{$var};
            given(ref $class){
                when('HASH'){
                    my ($package, $method) = %$class;
                    $raw_data->{$var} = $package->$method;
                }
                default {
                    $raw_data->{$var} = $class->new;
                }
            }
        }

        return $raw_data;
    },
    lazy => 1,
);

coerce 'ClassName'
  => as 'Str'
  => via { # so much code for nothing.  oh well :)
      my $loaded;
      for ($_, "App::TemplateServer::Provider::$_"){
          eval {
              if(Class::MOP::load_class($_)){
                  return $loaded = $_;
              }
          } and last;
      }
      return $loaded || die "failed to coerce $_ to a provider class";
  };

has 'provider_class' => (
    metaclass  => 'MooseX::Getopt::Meta::Attribute',
    cmd_arg    => 'provider',
    is         => 'ro',
    isa        => 'ClassName',
    default    => 'App::TemplateServer::Provider::TT',
    coerce     => 1,
);

has 'provider' => (
    metaclass => 'NoGetopt',
    is        => 'ro',
    isa       => 'Provider',
    lazy      => 1,
    default   => sub {
        my $self = shift; 
        $self->provider_class->new(docroot => $self->docroot);
    },
);

has '_daemon' => (
    is       => 'ro',
    isa      => 'HTTP::Daemon',
    lazy     => 1,
    default  => sub { 
        return HTTP::Daemon->new(ReuseAddr => 1, LocalPort => shift->port);
    },
);

method run {
    print "Server started at: ". $self->_daemon->url. "\n";
    $self->_main_loop;
};

method _main_loop {
    local $SIG{CHLD} = 'IGNORE';
  app:
    while(my $c = $self->_daemon->accept){
        if(!fork){
          req:
            while (my $req = $c->get_request){
                my $res = $self->_req_handler($req);
                $c->send_response($res);
            }
            $c->close;
            exit; # exit child
        }
    }
};

method _req_handler($req) {
    my $res = eval {
        given($req->uri){
            when(m{^/(?:index(?:[.]html?)?)?$}){
                return $self->_render_index($req);
            }
            when(m{^/favicon.ico$}){
                return $self->_render_favicon($req);
            }
            default {
                return $self->_render_template($req);
            }
        }
    };
    if($@ || !$res){
        my $h = HTTP::Headers->new;
        $res = HTTP::Response->new(500, 'Internal Server Error', $h, $@);
    }
    
    return $res;
};

sub _success {
    my $content = shift;
    my $headers = HTTP::Headers->new;

    # set up utf8
    $headers->header('content-type' => 'text/html; charset=utf8');
    utf8::upgrade($content); # kill latin1
    utf8::encode($content);

    return HTTP::Response->new(200, 'OK', $headers, $content);
}

method _mk_context($req) {
    return App::TemplateServer::Context->new(
        data    => $self->_data,
        request => $req,
        server  => $self->_daemon,
    );
};

method _render_template($req) {
    my $context = $self->_mk_context($req);
    my $template = uri_unescape($req->uri->path);
    $template =~ s{^/}{};
    my $content = $self->provider->render_template($template, $context);
    return _success($content);
};

method _render_index($req) {

    my $index = App::TemplateServer::Page::Index->new(
        provider => $self->provider,
    );
    my $context = $self->_mk_context($req);
    my $content = $index->render($context);
    return _success($content);
};

method _render_favicon($req){
    return HTTP::Response->new(404, 'Not found');
};

1;
__END__

=head1 NAME

App::TemplateServer - application to serve processed templates

=head1 SYNOPSIS

   template-server --docroot project/templates --data project/test_data.yml

=head1 DESCRIPTION

Occasionally you need to give HTML templates to someone to edit
without setting up a full perl environment for them.  You can use this
application to serve templates to the browser and provide those
templates with sample data to operate on.  The template editor will
need Perl, but not a database, Apache, Catalyst, etc.  (You can build
a PAR and then they won't need Perl either.)

It's also useful for experimenting with new templating engines.  You
can start writing templates right away, without having to setup Apache
or a Catalyst application first.  Interfacing C<App::TemplateServer>
to a new templating system is a quick matter of writing a few lines of
code.  (See L<App::TemplateServer::Provider> for details.)

As a user, you'll be interacting with C<App::TemplateServer> via the
included C<template-server> script.

=head1 METHODS

=head2 run

Start the server.  This method never returns.

=head1 ATTRIBUTES

=head2 port

The port to bind the server to.  Defaults to 4000.

=head2 docroot

The directory containing templates.  Defaults to the current
directory.

=head2 provider_class

The class name of the Provider to use.  Defaults to
C<App::TemplateServer::Provider::TT>, but you can get others from the
CPAN (for using templating systems other than TT).

As of version 0.02, you can omit the
C<App::TemplateServer::Provider::> prefix if you prefer.  The literal
class you pass will be loaded first; if that fails then the
C<App::TemplateServer::Provider::> prefix is added.  Failing that, an
exception is thrown.

=head2 datafile

The YAML file containing the package and variable definitions.  For
example:

    ---
    foo: "bar"
    packages:
      Test:
        constructors: ["new"]
        methods:
          map_foo_bar:
            - ["foo"]
            - "bar"
            - ["bar"]
            - "foo"
            - "INVALID INPUT"
    instantiate:
      test_instance: "Test"
      another_test_instance:
        Test: "new"

This makes the variables C<foo>, C<test_instance>, and
C<another_test_instance> available in the templates.  It also creates
a package called C<Test> and adds a constructor called C<new>, and a
method called C<map_foo_bar> that returns "bar" when the argument is
"foo", "foo" when the argument is "bar", and "INVALID INPUT"
otherwise.

=head3 DESCRIPTION

Any key/value pair other than C<packages> and C<instantiate> is
treated as a literal variable to make available in the template.

C<packages> is passed to L<Package::FromData> and is used to
dynamically create data, methods, static methods, and constructors
inside packages.  See L<Package::FromData> for more details.

C<instantiate> is a list of variables to populate with instantiated
classes.  The key is the variable name, the value is either a class
name to call new on, or a hash containing a single key/value pair
which is treated like C<< class => method >>.  This allows you to use
the constructors that L<Package::FromData> made for you.

=head1 AUTHOR

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2008 Jonathan Rockway.  You may redistribute this module
under the same terms as Perl itself.


