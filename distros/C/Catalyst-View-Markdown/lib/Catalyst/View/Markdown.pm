package Catalyst::View::Markdown;

use strict;
use warnings;

use base qw/Catalyst::View/;
use Text::Markdown;
use File::Find;
use MRO::Compat;
use Scalar::Util qw/blessed weaken/;

our $VERSION = '0.01';
$VERSION = eval $VERSION;

__PACKAGE__->mk_accessors('markdown_filename');
__PACKAGE__->mk_accessors('include_path');

*paths = \&include_path;

=head1 NAME

Catalyst::View::Markdown - Markdown View Class

=head1 SYNOPSIS

# use the helper to create your View

    myapp_create.pl view MD Markdown

# add custom configration in View/MD.pm

    __PACKAGE__->config(
        # any Markdown configuration items go here
        FILENAME_EXTENSION => '.md',
        empty_element_suffix => '/>',
        tab_width => 4,
        trust_list_start_value => 1,
    );

# add include path configuration in MyApp.pm

    __PACKAGE__->config(
        'View::MD' => {
            INCLUDE_PATH => [
                __PACKAGE__->path_to( 'root', 'src' ),
                __PACKAGE__->path_to( 'root', 'lib' ),
            ],
        },
    );

# render view from lib/MyApp.pm or lib/MyApp::Controller::SomeController.pm

    sub message : Global {
        my ( $self, $c ) = @_;
        $c->stash->{markdown_filename} = 'message';
        $c->forward( $c->view('MD') );
    }

=cut

sub _coerce_paths {
    my ( $paths, $dlim ) = shift;
    return () if ( !$paths );
    return @{$paths} if ( ref $paths eq 'ARRAY' );

    # tweak delim to ignore C:/
    unless ( defined $dlim ) {
        $dlim = ( $^O eq 'MSWin32' ) ? ':(?!\\/)' : ':';
    }
    return split( /$dlim/, $paths );
}

sub new {
    my ( $class, $c, $arguments ) = @_;
    my $config = {
        FILENAME_EXTENSION => '',
        CLASS              => 'Text::Markdown',
        %{ $class->config },
        %{$arguments},
    };
    if ( ! (ref $config->{INCLUDE_PATH} eq 'ARRAY') ) {
        my $delim = $config->{DELIMITER};
        my @include_path
            = _coerce_paths( $config->{INCLUDE_PATH}, $delim );
        if ( !@include_path ) {
            my $root = $c->config->{root};
            my $base = Path::Class::dir( $root, 'base' );
            @include_path = ( "$root", "$base" );
        }
        $config->{INCLUDE_PATH} = \@include_path;
    }

    if ( $c->debug && $config->{DUMP_CONFIG} ) {
        $c->log->debug( "Markdown Config: ", CORE::dump($config) );
    }

    my $self = $class->next::method(
        $c, { %$config },
    );

    # Set base include paths. Local'd in render if needed
    $self->include_path($config->{INCLUDE_PATH});

    $self->config($config);

    # Creation of template outside of call to new so that we can pass [ $self ]
    # as INCLUDE_PATH config item, which then gets ->paths() called to get list
    # of include paths to search for templates.

    # Use a weakend copy of self so we dont have loops preventing GC from working
    my $copy = $self;
    Scalar::Util::weaken($copy);
    $config->{INCLUDE_PATH} = [ sub { $copy->paths } ];

    $self->{markdown} =
        $config->{CLASS}->new($config) || do {
            my $error = $config->{CLASS}->error();
            $c->log->error($error);
            $c->error($error);
            return undef;
        };


    return $self;
}

sub process {
    my ( $self, $c ) = @_;

    my $mdfile = $c->stash->{markdown_filename}
      ||  $c->action . $self->config->{FILENAME_EXTENSION};

    unless (defined $mdfile) {
        $c->log->debug('No Markdown file specified for rendering') if $c->debug;
        return 0;
    }

    local $@;
    my $output = eval { $self->render($c, $mdfile) };

    unless ( $c->response->content_type ) {
        $c->response->content_type('text/html; charset=utf-8');
    }

    $c->response->body($output);

    return 1;
}

sub render {
    my ($self, $c, $mdfile, $args) = @_;

    $c->log->debug(qq/Rendering Markdown file "$mdfile"/) if $c && $c->debug;

    my $mdtext;
    if ( ref $mdfile eq 'SCALAR' ) {
        $mdtext = $$mdfile;
    }
    else {

        my $filename;
        # Find the first readable file with the right filename under the include paths
        find(
             sub { $filename = $File::Find::name if !$filename && $_ eq $mdfile && -r $File::Find::name},
            @{$self->include_path}
        );

        # If we found a match...
        if ($filename) {
            open my $in,  '<',  $filename;
            $mdtext = join '', do { local $/; <$in> }; # slurp!
            close $in;
        };
    };

    return $self->{markdown}->markdown($mdtext) if $mdtext;

    my $error = qq/Couldn't find Markdown file "$mdfile"/;
    $c->log->error($error);
    $c->error($error);
    return 0;
}

1;

__END__

=head1 DESCRIPTION

This is the Catalyst view class for L<Markdown|Text::Markdown>.
Your application should define a view class which is a subclass of
this module. Throughout this manual it will be assumed that your application
is named F<MyApp> and you are creating a Markdown view named F<MD>; these names
are placeholders and should always be replaced with whatever name you've
chosen for your application and your view. The easiest way to create a Markdown
view class is through the F<myapp_create.pl> script that is created along
with the application:

    $ script/myapp_create.pl view MD Markdown

This creates a F<MyApp::View::MD.pm> module in the F<lib> directory (again,
replacing C<MyApp> with the name of your application) which looks
something like this:

    package FooBar::View::MD;
    use Moose;

    extends 'Catalyst::View::Markdown';

    __PACKAGE__->config(DEBUG => 'all');

Now you can modify your action handlers in the main application and/or
controllers to forward to your view class.  You might choose to do this
in the end() method, for example, to automatically forward all actions
to the Markdown view class.

    # In MyApp or MyApp::Controller::SomeController

    sub end : Private {
        my( $self, $c ) = @_;
        $c->forward( $c->view('MD') );
    }

But if you are using the standard auto-generated end action, you don't even need
to do this!

    # in MyApp::Controller::Root
    sub end : ActionClass('RenderView') {} # no need to change this line

    # in MyApp.pm
    __PACKAGE__->config(
        ...
        default_view => 'MD',
    );

This will Just Work.  And it has the advantages that:

=over 4

=item *

If you want to use a different view for a given request, just set 
<< $c->stash->{current_view} >>.  (See L<Catalyst>'s C<< $c->view >> method
for details.

=item *

<< $c->res->redirect >> is handled by default.  If you just forward to 
C<View::MD> in your C<end> routine, you could break this by sending additional
content.

=back

See L<Catalyst::Action::RenderView> for more details.

=head2 CONFIGURATION

There are a three different ways to configure your view class.  The
first way is to call the C<config()> method in the view subclass.  This
happens when the module is first loaded.

    package MyApp::View::MD;
    use Moose;
    extends 'Catalyst::View::Markdown';

    __PACKAGE__->config({
        tab_width => 4,
    });

You may also override the configuration provided in the view class by adding
a 'View::MD' section to your application config.

This should generally be used to inject the include paths into the view to
avoid the view trying to load the application to resolve paths.

    .. inside MyApp.pm ..
    __PACKAGE__->config(
        'View::MD' => {
            INCLUDE_PATH => [
                __PACKAGE__->path_to( 'root', 'markdown', 'lib' ),
                __PACKAGE__->path_to( 'root', 'markdown', 'src' ),
            ],
        },
    );

You can also configure your view from within your config file if you're
using L<Catalyst::Plugin::ConfigLoader>. This should be reserved for
deployment-specific concerns. For example:

    # MyApp_local.conf (Config::General format)

    <View MD>
      INCLUDE_PATH __path_to('root/markdown/custom_site')__
      INCLUDE_PATH __path_to('root/markdown')__
    </View>

might be used as part of a simple way to deploy different instances of the
same application with different themes.

=head2 DYNAMIC INCLUDE_PATH

Sometimes it is desirable to modify INCLUDE_PATH for your templates at run time.

If you need to add paths to the end of INCLUDE_PATH, there is an
include_path() accessor available:

    push( @{ $c->view('MD')->include_path }, qw/path/ );

Note that if you use include_path() to add extra paths to INCLUDE_PATH, you
MUST check for duplicate paths. Without such checking, the above code will add
"path" to INCLUDE_PATH at every request, causing a memory leak.

A safer approach is to use include_path() to overwrite the array of paths
rather than adding to it. This eliminates both the need to perform duplicate
checking and the chance of a memory leak:

    @{ $c->view('MD')->include_path } = qw/path another_path/;

=head2 RENDERING VIEWS

The view plugin renders the template specified in the C<markdown_filename>
item in the stash.

    sub message : Global {
        my ( $self, $c ) = @_;
        $c->stash->{markdown_filename} = 'message.md';
        $c->forward( $c->view('MD') );
    }

If a stash item isn't defined, then it instead uses the
stringification of the action dispatched to (as defined by $c->action)
in the above example, this would be C<message>, but because the default
is to append '.md', it would load C<root/message.md>.

The output generated by the file is stored in C<< $c->response->body >>.

=head2 CAPTURING FILE OUTPUT

If you wish to use the output of a Markdown file for some other purpose than
displaying in the response, e.g. for sending an email, this is possible using
L<Catalyst::Plugin::Email> and the L<render> method:

  sub send_email : Local {
    my ($self, $c) = @_;

    $c->email(
      header => [
        To      => 'me@localhost',
        Subject => 'A Markdown Email',
      ],
      body => $c->view('MD')->render($c, 'email.md'),
    );
  # Redirect or display a message
  }

=head2 METHODS

=head2 new

The constructor for the Markdown view. Sets up the Markdown provider,
and reads the application config.

=head2 process($c)

Renders the template specified in C<< $c->stash->{markdown_filename} >> or
C<< $c->action >> (the private name of the matched action).  Calls L<render> to
perform actual rendering. Output is stored in C<< $c->response->body >>.

It is possible to forward to the process method of a Markdown view from inside
Catalyst like this:

    $c->forward('View::MD');

N.B. This is usually done automatically by L<Catalyst::Action::RenderView>.

=head2 render($c, $md_filename)

Renders the given file and returns output. Throws a L<Template::Exception>
object upon error.

If $md_filename is a scalar reference, the value will be use as Markdown text
instead of searching for a file - this allows Markdown to be easily stored in
other systems, e.g. a database table.

To use the render method outside of your Catalyst app, just pass a undef
context.  This can be useful for tests, for instance.

=head2 config

This method allows your view subclass to pass additional settings to
the Markdown configuration hash, or to set the options as below:

=head2 INCLUDE_PATH

The list of paths Markdown will look for files in. The first matching file will be used.

=head2 C<CLASS>

Allows you to specify a custom class to use as the template class instead of
L<Text::Markdown>.

    package MyApp::View::MD;
    use Moose;
    extends 'Catalyst::View::Markdown';

    use Text::MultiMarkdown;

    __PACKAGE__->config({
        CLASS => 'Text::MultiMarkdown',
    });

This is useful if you want to use your own subclasses of L<Markdown>.

=head2 HELPERS

The L<Catalyst::Helper::View::Markdown> helper module is provided to create
your view module.  There are invoked by the F<myapp_create.pl> script:

    $ script/myapp_create.pl view Web Markdown

The L<Catalyst::Helper::View::Markdown> module creates a basic Markdown view
module.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Helper::View::Markdown>,
L<Template::Manual>

=head1 AUTHORS

Richard Wallman, C<wallmari@bossolutions.co.uk>

=head1 COPYRIGHT

This program is free software. You can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
