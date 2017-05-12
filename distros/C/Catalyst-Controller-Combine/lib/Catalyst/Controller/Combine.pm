package Catalyst::Controller::Combine;
{
  $Catalyst::Controller::Combine::VERSION = '0.15';
}

use Moose;
# w/o BEGIN, :attrs will not work
BEGIN { extends 'Catalyst::Controller' }

use Path::Class ();
use File::stat;
use List::Util qw(max);
use Text::Glob qw(match_glob);
use DateTime;

has dir       => (is => 'rw',
                  default => sub { 'static/' . shift->action_namespace },
                  lazy => 1);

has extension => (is => 'rw',
                  default => sub { shift->action_namespace },
                  lazy => 1);

has depend    => (is => 'rw',
                  default => sub { return {} });

has mimetype  => (is => 'rw',
                  default => sub {
                                    my $ext = shift->extension;
                                    return $ext eq 'js'  ? 'application/javascript'
                                         : $ext eq 'css' ? 'text/css'
                                         : 'text/plain';
                                 },
                  lazy => 1);

has replace   => (is => 'rw',
                  default => sub { {} },
                  lazy => 1,
                  predicate => 'has_replacement');

has include   => (is => 'rw',
                  default => sub { [] },
                  lazy => 1,
                  predicate => 'has_include');

has minifier  => (is => 'rw',
                  default => 'minify');

has expire    => (is => 'rw',
                  default => 0);

has expire_in => (is => 'rw',
                  default => 60 * 60 * 24 * 365 * 3); # 3 years


=head1 NAME

Catalyst::Controller::Combine - Combine JS/CSS Files

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    # use the helper to create your Controller
    script/myapp_create.pl controller Js Combine

    # or:
    script/myapp_create.pl controller Css Combine

    # DONE. READY FOR USE.

    # Just use it in your template:
    # will deliver all JavaScript files concatenated (in Js-Controller)
    <script type="text/javascript" src="/js/file1/file2/.../filex.js"></script>

    # will deliver all CSS files concatenated (in Css-Controller)
    <link rel="stylesheet" type="text/css" href="/css/file1/file2/.../filex.css" />

    # in the generated controller you may add this to allow minification
    # the trick behind is the existence of a sub named 'minify'
    # inside your Controller.

    use JavaScript::Minifier::XS qw(minify);
        # or:
    use CSS::Minifier::XS qw(minify);


=head1 DESCRIPTION

Catalyst Controller that concatenates (and optionally minifies) static files
like JavaScript or CSS into a single request. Depending on your configuration,
files are also auto-added with a simple dependency-management.

The basic idea behind concatenation is that all files one Controller should
handle reside in a common directory.

Assuming you have a directory with JavaScript files like:

    root/static/js
     |
     +-- prototype.js
     |
     +-- helpers.js
     |
     +-- site.js

Then you could combine all files in a single tag (assuming your directory for
the Controller is set to 'static/js' -- which is the default):

    <script type="text/javascript" src="/js/prototype/helpers/site.js"></script>

If you add a dependency into your Controller's config like:

    __PACKAGE__->config(
        ...
        depend => {
            helpers => 'prototype',
            site    => 'helpers',
        },
        ...
    );

Now, the URI to retrieve the very same JavaScript files can be shortened:

    <script type="text/javascript" src="/js/site.js"></script>

=head1 CONFIGURATION

A simple configuration of your Controller could look like this:

    __PACKAGE__->config(
        # the directory to look for files
        # defaults to 'static/<<action_namespace>>'
        dir => 'static/js',

        # the (optional) file extension in the URL
        # defaults to action_namespace
        extension => 'js',

        # optional dependencies
        depend => {
            scriptaculous => 'prototype',
            builder       => 'scriptaculous',
            effects       => 'scriptaculous',
            dragdrop      => 'effects',
            slider        => 'scriptaculous',
            myscript      => [ qw(slider dragdrop) ],
        },

        # name of the minifying routine (defaults to 'minify')
        # will be used if present in the package
        minifier => 'minify',

        # should a HTTP expire header be set? This usually means, 
        # you have to change your filenames, if there a was change!
        expire => 1,

        # time offset (in seconds), in which the file will expire
        expire_in => 60 * 60 * 24 * 365 * 3, # 3 years

        # mimetype of response if wanted
        # will be guessed from extension if possible and not given
        # falls back to 'text/plain' if not guessable
        mimetype => 'application/javascript',
    );

=head2 CONFIGURATION OPTIONS

TODO: writeme...

=head1 METHODS

=head2 do_combine :Action

the C<do_combine> Action-method may be used like this (eg in YourApp:Controller:Js):

    sub default :Path {
        my $self = shift;
        my $c = shift;

        $c->forward('do_combine');
    }

However, a predeclared C<default> method like this is already present -- see
below.

All files in the remaining URL will be concatenated to a single resulting
stream and optionally minified if a sub named 'minify' in your Controller's
package namespace exists.

Thus, inside your Controller a simple

    # for JavaScript you may do
    use JavaScript::Minifier::XS qw(minify);

    # for CSS quite similar:
    use CSS::Minifier::XS qw(minify);

will do the job and auto-minify the stream.

If you specify an C<include> configuration option you also could recursively
include other files into the generated stream. (Think about @import in css files).

=cut

sub do_combine :Action {
    my $self = shift;
    my $c = shift;

    $self->_collect_files($c, @_);

    #
    # concatenate
    #
    my $mtime = 0;
    my $response = '';
    foreach my $file (@{$self->{files}}) {
        my $file_content = $self->_file_contents($file, \$mtime);
        
        if (exists($self->{replacement_for}->{$file})) {
            my @replacement = (
                # poor man's deep-copy, splice below is destructive
                @{$self->{replacement_for}->{$file}}
            );
            while (my ($regex, $replace) = splice(@replacement,0,2)) {
                $file_content =~ s{$regex}{qq{qq{$replace}}}gmsee;
            }
        }
        
        $response .= $file_content;
    }

    die 'no files given for combining' if !$mtime;

    #
    # deliver -- at least an empty line to make catalyst happy ;-)
    #
    my $minifier = $self->can($self->minifier)
        || \&_do_not_modify;
    $c->response->headers->content_type($self->mimetype)
        if $self->mimetype;
    $c->response->headers->last_modified($mtime)
        if $mtime;
    # $c->response->headers->expires(time() + $self->expire_in)
    # looks complicated but makes this routine testable...
    $c->response->headers->expires(DateTime->now->add(seconds => $self->expire_in)->epoch)
        if $self->expire && $self->expire_in;

    $c->response->body($minifier->($response) . "\n");
}

sub _do_not_modify { $_[0] };

sub _file_contents {
    my $self = shift;
    my $file = shift;
    my $mtime_ref = shift;
    
    my $file_contents = $file->slurp;
    $$mtime_ref = max($$mtime_ref, (stat $file)->mtime);
    
    if ($self->has_include) {
        $file_contents =~ s{$_}{ $self->_file_contents($file->dir->file($1), $mtime_ref) }exmsg
            for @{$self->include}
    }
    
    return $file_contents;
}

=head2 default :Path

a standard handler for your application's controller

maps to the path_prefix of your actual controller and consumes the entire URI

=cut

sub default :Path {
    my $self = shift;
    my $c = shift;

    $c->forward('do_combine');
}

=head2 uri_for :Private

handle uri_for requests (not intentionally a Catalyst-feature :-) requires a
patched C<uri_for> method in your app! my one looks like the sub below.

If this method is used, the URI will only contain files that will not
automatically get added in by dependency resolution. Also, a simple
GET-parameter is added that reflects the unix-timestamp of the most resent
file that will be in the list of combined files. This helps the browser
to do proper caching even if files will change. Admittedly this is most of
the time needed during development.

    # in my app.pm:
    sub uri_for {
        my $c = shift;
        my $path = shift;
        my @args = @_;

        if (blessed($path) && $path->class && $path->class->can('uri_for')) {
            #
            # the path-argument was a component that can help
            # let the controller handle this for us
            #   believe me, it can do it!
            #
            return $c->component($path->class)->uri_for($c, $path, @args);
        }

        #
        # otherwise fall back into the well-known behavior
        #
        $c->next::method($path, @args);
    }

    # alternatively, using Catalyst 5.8 you may do this:
    around 'uri_for' => sub {
        my $orig = shift;
        my $c = shift;
        my $path = shift;
        my @args = @_;

        if (blessed($path) && $path->class && $path->class->can('uri_for')) {
            #
            # let the controller handle this for us
            #   believe me, it can do it!
            #
            return $c->component($path->class)->uri_for($c, $path, @args);
        }

        return $c->$orig($path, @args);
    };

=cut

sub uri_for :Private {
    my $self = shift;
    my $c = shift;
    my $path = shift; # actually an action...
    my @args = @_;

    my $actual_path = $c->dispatcher->uri_for_action($path);
    $actual_path = '/' if $actual_path eq '';

    #
    # generate max mtime as query value for the uri
    #
    $self->_collect_files($c, @args);
    my $mtime = max map { (stat $_)->mtime } @{$self->{files}};

    #
    # get rid of redundancies as dependency rules will
    # add them in at fulfilment of the real request...
    #
    my @parts = grep {!$self->{seen}->{$_}} @{$self->{parts}};
    $parts[-1] .= '.' . $self->extension if (scalar(@parts));

    #
    # CAUTION: $actual_path must get stringified!
    # otherwise bad loops and misbehavior would occur.
    #

    $c->uri_for("$actual_path", @parts, {m => $mtime});
}

#
# collect all files
#
sub _collect_files {
    my $self = shift;
    my $c = shift;

    my $ext = $self->extension;
    $self->{parts} = [];            # list of plain file names
    $self->{files} = [];            # list of full paths
    $self->{replacement_for} = {};  # replacements for every full path
    $self->{seen}  = {}; # easy lookup of parts and count of dependencies
    foreach my $file (@_) {
        my $base_name = $file;
        $base_name =~ s{\.$ext\z}{}xms;

        $self->_check_dependencies($c, $base_name, ['', ".$ext"]);
    }

    return;
}

#
# check dependencies on files
#
sub _check_dependencies {
    my $self = shift;
    my $c = shift;
    my $base_name = shift;
    my $extensions = shift;
    my $depends = shift || 0;

    my $dependency_for = $self->depend;

    #
    # check if we already saw this file. Update dependency flag
    #
    if (exists($self->{seen}->{$base_name})) {
        $self->{seen}->{$base_name} ||= $depends;
        return;
    }

    if ($dependency_for &&
        ref($dependency_for) eq 'HASH' &&
        exists($dependency_for->{$base_name})) {
        #
        # we have a dependency -- resolve it.
        #
        my @depend_on = ref($dependency_for->{$base_name}) eq 'ARRAY'
                        ? @{$dependency_for->{$base_name}}
                        : $dependency_for->{$base_name};
        $self->_check_dependencies($c, $_, $extensions, 1)
            for @depend_on;
    }

    #
    # add the file if existing
    #
    my $dir = $c->path_to('root', $self->dir)->resolve;
    foreach my $file_path (map { $dir->file("$base_name$_") } @{$extensions}) {
        next if (!-f $file_path);
        
        # the file we want exists. Time to do a security check
        # hint: a call to resolve() will die under windows
        #       if the path requested does not exist on the filesystem.
        #       therefore, we check as late as possible
        $dir->subsumes($file_path->resolve)
            or die 'security violation - tried to access file outside of: '
                   . $self->dir();
        
        # looks like we are secure -- are there any secret unicodes
        # we forgot to double-check? *g*
        push @{$self->{parts}}, $base_name;
        push @{$self->{files}}, $file_path;
        $self->{seen}->{$base_name} = $depends;
        
        # check replacements
        return if (!$self->replace 
                || ref($self->replace) ne 'HASH' 
                || !scalar(keys(%{$self->replace})));
        foreach my $glob (keys(%{$self->replace})) {
            next if (!match_glob($glob, $base_name));
            my $replacements = $self->replace->{$glob};
            next if (!$replacements 
                  || ref($replacements) ne 'ARRAY' 
                  || !scalar(@{$replacements}));
            push @{$self->{replacement_for}->{$file_path}}, @{$replacements};
        }
        
        # done
        return;
    }

    $c->log->warn("$base_name.* --> NOT EXISTING, ignored");
    return;
}

=head1 GOTCHAS

Please do not use C<namespace::autoclean> if you intend to enable a minifier.
The black magic behind the scenes tries to determine your intention to minify
by searching for a sub called C<minify> inside the controller's package.
However, this sub is imported by eg C<JavaScript::Minifier::XS> and will be
kicked out of the controller by C<namespace::autoclean>.

=head1 AUTHOR

Wolfgang Kinkeldei, E<lt>wolfgang@kinkeldei.deE<gt>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
