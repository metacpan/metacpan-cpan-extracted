package Catalyst::View::Xslate;
use Moose;
use Moose::Util::TypeConstraints qw(coerce from where via subtype);
use Encode;
use Text::Xslate;
use namespace::autoclean;
use Scalar::Util qw/blessed weaken/;
use File::Find ();

our $VERSION = '0.00019';

extends 'Catalyst::View';

with 'Catalyst::Component::ApplicationAttribute';

has catalyst_var => (
    is => 'rw',
    isa => 'Str',
    default => 'c'
);

has template_extension => (
    is => 'rw',
    isa => 'Str',
    default => '.tx'
);

has content_charset => (
    is => 'rw',
    isa => 'Str',
    default => 'UTF-8'
);

has encode_body => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
);

my $clearer = sub { $_[0]->clear_xslate };

has path => (
    is => 'rw',
    isa => 'ArrayRef',
    trigger => $clearer,
    lazy => 1, builder => '_build_path',
);

sub _build_path { return [ shift->_app->path_to('root') ] }

has cache_dir => (
    is => 'rw',
    isa => 'Str',
    trigger => $clearer,
);

has cache => (
    is => 'rw',
    isa => 'Int',
    default => 1,
    trigger => $clearer,
);

has function => (
    is => 'rw',
    isa => 'HashRef',
    default => sub { +{} },
    trigger => $clearer,
);

has footer => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { +[] },
    trigger => $clearer
);

has header => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { +[] },
    trigger => $clearer
);

has module => (
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { +[] },
    trigger => $clearer,
);

has input_layer => (
    is => 'rw',
    isa => 'Str',
    trigger => $clearer,
);

has syntax => (
    is => 'rw',
    isa => 'Str',
    trigger => $clearer,
);

has escape => (
    is => 'rw',
    isa => 'Str',
    trigger => $clearer,
);

has type => (
    is => 'rw',
    isa => 'Str',
    trigger => $clearer,
);

has suffix => (
    is => 'rw',
    isa => 'Str',
    trigger => $clearer,
    default => '.tx',
);

has verbose => (
    is => 'rw',
    isa => 'Int',
    trigger => $clearer,
);

has xslate => (
    is => 'rw',
    isa => 'Text::Xslate',
    clearer => 'clear_xslate',
    lazy => 1, builder => '_build_xslate',
);

has [qw/line_start tag_start tag_end/] => (is=>'rw', isa=>'Str');
has [qw/warn_handler die_handler pre_process_handler/] => (is=>'rw', isa=>'CodeRef');


my $expose_methods_tc = subtype 'HashRef', where { $_ };
coerce $expose_methods_tc,
  from 'ArrayRef',
  via {
    my %values = map { $_ => $_ } @$_;
    return \%values;
  };

has expose_methods => (
    is => 'ro',
    isa => $expose_methods_tc,
    predicate => 'has_expose_methods',
    coerce => 1,
);

has preload => (
    is => 'ro',
    isa => 'Bool',
    default => 1,
);

sub _build_xslate {
    my $self = shift;

    my $app = $self->_app;
    my $name = $app;
    $name =~ s/::/_/g;

    my %args = (
        path      => $self->path,
        cache_dir => $self->cache_dir || File::Spec->catdir(File::Spec->tmpdir, $name),
        map { ($_ => $self->$_) }
            qw( cache footer function header module )
    );

    # optional stuff
    foreach my $field ( qw( input_layer syntax escape verbose suffix type line_start tag_start tag_end warn_handler die_handler pre_process_handler) ) {
        if (defined(my $value = $self->$field)) {
            $args{$field} = $value;
        }
    }

    return Text::Xslate->new(%args);
}

sub BUILD {
    my $self = shift;
    if ($self->preload) {
        $self->preload_templates();
    }
}

sub preload_templates {
    my $self = shift;
    my ( $paths, $suffix ) = ( $self->path, $self->suffix );
    my $xslate = $self->xslate;
    foreach my $path (@$paths) {
        File::Find::find( sub {
            if (/\Q$suffix\E$/) {
                my $file = $File::Find::name;
                $file =~ s/\Q$path\E .//xsm;
                $xslate->load_file($file);
            }
        }, $path);
    }
}

sub process {
    my ($self, $c) = @_;

    my $stash = $c->stash;
    my $template = $stash->{template} || $c->action . $self->template_extension;

    if (! defined $template) {
        $c->log->debug('No template specified for rendering') if $c->debug;
        return 0;
    }

    my $output = eval {
        $self->render( $c, $template, $stash );
    };
    if (my $err = $@) {
        return $self->_rendering_error($c, $err);
    }

    my $res = $c->response;
    if (! $res->content_type) {
        $res->content_type('text/html; charset=' . $self->content_charset);
    }

    if ( $self->encode_body ) {
        $res->body( encode($self->content_charset, $output) );
    }
    else {
        $res->body( $output );
    }

    return 1;
}

sub build_exposed_method {
    my ( $self, $ctx, $code ) = @_;
    my $weak_ctx = $ctx;
    weaken $weak_ctx;

    return sub { $self->$code($weak_ctx, @_) };
}

sub render {
    my ($self, $c, $template, $vars) = @_;

    $vars = $vars ? $vars : $c->stash;

    if ($self->has_expose_methods) {
        foreach my $exposed_method( keys %{$self->expose_methods} ) {
            if(my $code = $self->can( $self->expose_methods->{$exposed_method} )) {
                $vars->{$exposed_method} = $self->build_exposed_method($c, $code);
            } else {
                Catalyst::Exception->throw( "$exposed_method not found in Xslate view" );
            }

        }
    }

    local $vars->{ $self->catalyst_var } =
        $vars->{ $self->catalyst_var } || $c;

    if(ref $template eq 'SCALAR') {
        return $self->xslate->render_string( $$template, $vars );
    } else {
        return $self->xslate->render($template, $vars );
    }
}

sub _rendering_error {
    my ($self, $c, $err) = @_;
    my $error = qq/Couldn't render template "$err"/;
    $c->log->error($error);
    $c->error($error);
    return 0;
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Catalyst::View::Xslate - Text::Xslate View Class

=head1 SYNOPSIS

    package MyApp::View::Xslate;
    use Moose;
    extends 'Catalyst::View::Xslate';

    1;

=head1 VIEW CONFIGURATION

You may specify the following configuration items in from your config file
or directly on the view object.

=head2 catalyst_var

The name used to refer to the Catalyst app object in the template

=head2 template_extension

The suffix used to auto generate the template name from the action name
(when you do not explicitly specify the template filename);

Do not confuse this with the C<suffix> option, which is passed directly to
the Text::Xslate object instance. This option works on the filename used
for the initial request, while C<suffix> controls what C<cascade> and
C<include> directives do inside Text::Xslate.

=head2 content_charset

The charset used to output the response body. The value defaults to 'UTF-8'.

=head2 encode_body

By default, output will be encoded to C<content_charset>.
You can set it to 0 to disable this behavior.
(you need to do this if you're using C<Catalyst::Plugin::Unicode::Encoding>)

B<NOTE> Starting with L<Catalyst> version 5.90080 Catalyst will automatically
encode to UTF8 any text like body responses.  You should either turn off the
body encoding step in this view using this attribute OR disable this feature
in the application (your subclass of Catalyst.pm).

    MyApp->config(encoding => undef);

Failure to do so will result in double encoding.

=head2 Text::Xslate CONFIGURATION

The following parameters are passed to the Text::Xslate constructor.
When reset during the life cyle of the Catalyst app, these parameters will
cause the previously created underlying Text::Xslate object to be cleared

=head2 path

=head2 cache_dir

=head2 cache

=head2 header

=head2 escape

=head2 type

=head2 footer

=head2 function

=head2 input_layer

=head2 module

=head2 syntax

=head2 verbose

=head2 line_start

=head2 tag_start

=head2 tag_end

=head2 warn_handler

=head2 die_handler

=head2 pre_process_handler

=head2 suffix


Use this to enable TT2 compatible variable methods via Text::Xslate::Bridge::TT2 or Text::Xslate::Bridge::TT2Like

    package MyApp::View::Xslate;
    use Moose;
    extends 'Catalyst::View::Xslate';

    has '+module' => (
        default => sub { [ 'Text::Xslate::Bridge::TT2Like' ] }
    );

=head1 preload

Boolean flag indicating if templates should be preloaded. By default this is enabled.

Preloading templates will basically cutdown the cost of template compilation for the first hit.

=head2 expose_methods

Use this option to specify methods from the View object to be exposed in the
template. For example, if you have the following View:

    package MyApp::View::Xslate;
    use Moose;
    extends 'Catalyst::View::Xslate';

    sub foo {
        my ( $self, $c, @args ) = @_;
        return ...; # do something with $self, $c, @args
    }

then by setting expose_methods, you will be able to use $foo() as a function in
the template:

    <: $foo("a", "b", "c") # calls $view->foo( $c, "a", "b", "c" ) :>

C<expose_methods> takes either a list of method names to expose, or a hash reference, in order to alias it differently in the template.

    MyApp::View::Xslate->new(
        # exposes foo(), bar(), baz() in the template
        expose_methods => [ qw(foo bar baz) ]
    );

    MyApp::View::Xslate->new(
        # exposes $foo_alias(), $bar_alias(), $baz_alias() in the template,
        # but they will in turn call foo(), bar(), baz(), on the view object.
        expose_methods => {
            foo => "foo_alias",
            bar => "bar_alias",
            baz => "baz_alias",
        }
    );

NOTE: you can mangle the process of building the exposed methods, see C<build_exposed_method>.

=head1 METHODS

=head1 C<$view->process($c)>

Called by Catalyst.

=head2 C<$view->render($c, $template, \%vars)>

Renders the given C<$template> using variables \%vars.

C<$template> can be a template file name, or a scalar reference to a template
string.

    $view->render($c, "/path/to/a/template.tx", \%vars );

    $view->render($c, \'This is a xslate template!', \%vars );

=head2 C<$view->preload_templates>

Preloads templates in $view-E<gt>path.

=head2 C<$view->build_exposed_method>

Hook point for mangling the building process of exposed methods.

=head1 AUTHOR

Copyright (c) 2010 Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 LICENSE 

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
