package Blog::Blosxom;

use warnings;
use strict;

use FindBin;
use FileHandle;
use File::Find;
use File::Spec;
use File::stat;
use Time::localtime;

use List::Util qw(min);

=head1 NAME

Blog::Blosxom - A module version of the apparently inactive blosxom.cgi

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

    use Blog::Blosxom;

    ...

    my $blog = Blog::Blosxom->new(%params);
    $blog->run($path, $flavour);

A path comes in from somewhere - usually an HTTP request. This is applied to the
blog directory. A configurable file extension is added to the path and if it matches
a file that file is served as the matched entry. If the path matches a directory,
all entries in that directory and in subdirectories are served. If the path looks
like a date, all posts that match that date are served. A string is returned, which
is usually printed back to CGI. The string is the matched entries, served in the
specified output format, or flavour. The flavour is determined by the file extension
on the incoming path, or a GET parameter, or a configured default.

=head1 DESCRIPTION

Blosxom is a blog engine. It is a rewrite of a CGI script found at www.blosxom.com.
Blosxom uses the filesystem as the database for blog entries. Blosxom's run() 
method takes two parameters: the path and the flavour.

The CGI script that ships with the module is an example of how to use this module
to reproduce the behaviour of the original Blosxom script, but the idea here is 
that it is up to you how to get this data.

Every file that ends in a configurable file extension and is placed somewhere within
the blog root directory is, in the default situation, served up on a big page, in
date order, having been processed and turned into blog posts. The set of files chosen
for display is pared down by specifying a path to limit the set to only entries under
that path, the narrowest possible filter of course being when the path actually
matches a single blog entry.

Alternatively, the path may be a date in the format YYYY[/MM[/DD]], with the brackets
denoting an optional section. This will be used to filter the posts by date instead
of by location. All posts under the blog root are candidates for being returned. A
TODO is to concatenate a date-style filter and a directory-style filter.

The module is designed to be extensible. That is, there are several methods in it
that are designed to be overridden by subclasses to extend the functionality of
Blog::Blosxom. You can see the L<PLUGINS> section below for details on these, and
examples.

=head1 TERMS

=head2 entry

Entry is used to mean both the individual article (its title, content and any 
metadata) and the file that contains that data. The entry is a filename with a
customisable file extension. The file name and file extension have two differnent
purposes.

The file extension is used to decide what is a blog post and what isn't. Files that
have the defined file extension will be found by the blog engine and displayed, so
long as they are within the filter.

The entry's filename is used to find a single entry. The path you provide to 
C<run()> is given the file extension defined for blog entries and then applied to the
root directory. If this is a file, that is served. If not, it is tested without the
file extension to be a directory. If it is a directory, all files ending with this
extension and within that directory are served.

=head2 story

The story is the formatted version of an entry. The file story.$flavour is used to
insert the various parts of the blog entry into a template, which is then concatenated
to a string which is itself returned from the C<run> method. See below for what I
mean by $flavour.

=head2 flavour

The flavour of the blog is simply the format in which the blog entry is served as a
story. The flavour is determined by you. The CGI script takes the file extension
from the request URI, or the C<flav> GET parameter.

If neither is provided, the default flavour is used. This is passed as a parameter
to C<new> and defaults to C<html>.

=head2 component

A component is one of the five (currently) sections of the page: head, foot, story,
date and content-type. The story and date components appear zero-to-many times on
each page and the other three appear exactly once.

=head2 template

A template is a flavoured component. It is defined as a file in the blog root whose
filename is the component and whose extension is the flavour. E.g. C<head.html> is
the HTML-flavoured head component's template.

=head1 METHODS

=head2 new(%params)

Create a new blog. Parameters are provided in a hash and are:

=over

=item blog_title

This will be available in your templates as $blog_title, and by default appears in the
page title and at the top of the page body.

This parameter is required.

=item blog_description

This will be available in your templates as $blog_description. This does not appear in
the default templates.

=item blog_language

This is used for the RSS feed, as well as any other flavours you specify that have a
language parameter.

=item datadir

This is where blosxom will look for the blog's entries. A relative path will be relative
to the script that is using this module.

This parameter is required.

=item url

This will override the base URL for the blog, which is automatic if you do not provide.

=item depth

This is how far down subdirectories of datadir to look for more blog entries. 0 is the
default, which means to look down indefinitely. 1, therefore, means to look only in the
datadir itself, up to n, which will look n-1 subdirectories down.

=item num_entries

This is the maximum number of stories to display when multiple are found in the filter.

=item file_extension

By default, Blosxom will treat .txt files as blog entries. Change this to use a
different file extension. Do not provide the dot that separates the filename and the
file extension.

=item default_flavour

The flavour simply determines which set of templates to use to draw the blog. This 
defines which flavour to use by default. Vanilla blosxom has HTML and RSS flavours,
of which RSS sucks really hard so really only HTML is available by default.

=item show_future_entries

This is a bit of a strange one, since by default, having a future date on an entry
is a filesystem error, but if you want to override how the date of a template is
defined, this will be helpful to you.

=item plugin_dir

Tells blosxom where to look for plugins. This is empty by default, which means it won't
look for plugins. Relative paths will be taken relative to the script that uses this
module.

=item plugin_state_dir

Some plugins wish to store state. This is where the state data will be stored. It will
need to be writable. Defaults to plugin_dir/state if you specify a plugin_dir.

=item static_dir

Blosxom can publish your files statically, which means you run the script and it creates
HTML files (for example) for each of your entries, instead of loading them dynamically.
This defines where those files should go. I haven't actually implemented this because I
don't really want to.

=item static_password

You have to provide a password if you want to use static rendering, as a security
measure or something.

=item static_flavours

An arrayref of the flavours that Blosxom should generate statically. By default this is
html and rss.

=item static_entries

Set this to a true value to turn on static generation of individual entries. Generally
there is no point because your entries are static files already, but you may be using a
plugin to alter them before rendering.

=back

=cut

sub new {
    my ($class, %params) = @_;

    for (qw(blog_title datadir)) {
        die "Required parameter $_ not provided to Blog::Blosxom->new"
            unless exists $params{$_} && $params{$_};
    }

    die $params{datadir} . " does not exist!" unless -d $params{datadir};

    my %defaults = (
        blog_description    => "",
        blog_language       => "en",
        url                 => "",
        depth               => 0,
        num_entries         => 40,
        file_extension      => "txt",
        default_flavour     => "html",
        show_future_entries => 0,
        plugin_dir          => "",
        plugin_state_dir    => "",
        static_dir          => "",
        static_password     => "",
        static_flavours     => [qw(html rss)],
        static_entries      => 0,
        require_namespace   => 0,
    );

    %params = (%defaults, %params);

    $params{plugin_state_dir} ||= $params{plugin_dir} if $params{plugin_dir};

    # Absolutify relative paths
    for my $key (qw(plugin_dir datadir static_dir plugin_state_dir)) {
        my $dir = $params{$key};

        unless (File::Spec->file_name_is_absolute( $dir )) {
            $dir = File::Spec->catdir($FindBin::Bin, $dir);
        }

        $params{$key} = $dir;
    }

    my $self = bless \%params, $class;
    $self->_load_plugins;
    $self->_load_templates;

    return $self;
}

=head2 run ($path, $flavour)

It is now the responsibility of the user to provide the correct path and 
flavour. That is because there are several ways that you can gain this
information, and it is not up to this engine to decide what they are. That is,
this information comes from the request URL and, possibly, the parameter string,
POST, cookies, what-have-you.

Therefore:

=over

=item

The path is the entire path up to the filename. The filename shall not include
a file extension. The filename is optional, and if omitted, the directory given
will be searched for all entries and an index page generated.

=item

The flavour can be gathered in any manner you desire. The original Blosxom
script would use either a parameter string, C<?flav=html>, or simply by using
the flavour as the file extension for the requested path.

=back

No flavour provided will result in the default being used, obviously. No path
being provided will result in the root path being used, since these are 
equivalent.

=cut

sub run {
    my ($self, $path, $flavour) = @_;

    $path ||= "";
    $flavour ||= $self->{default_flavour};

    $path =~ s|^/||;

    my @entries;

    $self->{path_info} = $path;
    $self->{flavour} = $flavour;

    # Build an index page for the path
    @entries = $self->entries_for_path($path);
    @entries = $self->filter(@entries);
    @entries = $self->sort(@entries);

    @entries = @entries[0 .. min($#entries, $self->{num_entries}-1) ];

    $self->{entries} = [];

    # A special template. The user is going to need to know this, but not print it.
    $self->{content_type} = $self->template($path, "content_type", $flavour);

    my @templates;

    my $date = "";
    for my $entry (@entries) {
        # TODO: Here is an opportunity to style the entries in the style
        # of the subdir they came from.
        my $entry_data = $self->entry_data($entry);
        push @{$self->{entries}}, $entry_data;

        my $entry_date = join " ", @{$entry_data}{qw(da mo yr)}; # To create a date entry when it changes.

        if ($date ne $entry_date) {
            $date = $entry_date;
            my $date_data = { map { $_ => $entry_data->{$_} } qw( yr mo mo_num dw da hr min ) };

            push @templates, $self->interpolate($self->template($path, "date", $flavour), $date_data);
        }

        push @templates, $self->interpolate($self->template($path, "story", $flavour), $entry_data);
    }

    # If we do head and foot last, we let plugins use data about the contents in them.
    unshift @templates, $self->interpolate($self->template($path, "head", $flavour), $self->head_data());
    push @templates, $self->interpolate($self->template($path, "foot", $flavour), $self->foot_data());

    # A skip plugin will stop processing just before anything is output.
    # Not sure why.
    return if $self->_check_plugins('skip');

    return join "\n", @templates;
}

=head2 template($path, $component, $flavour)

Returns a chunk of markup for the requested component in the requested flavour 
for the requested path. The path will be the one given to C<run>. 

By default the template file chosen is the file C<$component.$flavour> within 
the C<$path> provided, and if not found, upwards from there to the blog root.

The templates used are I<content_type>, I<head>, I<story>, I<date> and I<foot>,
so the HTML template for the head would be C<head.html>.

=cut

sub template {
    my ($self, $path, $comp, $flavour) = @_;

    my $template;

    unless ($template = $self->_check_plugins('template', @_)) {
        my $fn = File::Spec->catfile($self->{datadir}, $path, "$comp.$flavour");

        while (1) {
            # Return the contents of this template if the file exists. If it is empty,
            # we have defaults set up.
            if (-e $fn) {
                open my $fh, "<", $fn;
                $template = join '', <$fh>;
            }

            # Stop looking when there is no $path to go between datadir and the
            # template file. For portability, we can't check whether it is a "/"
            last if !$path or $path eq File::Spec->rootdir;

            # Look one dir higher and go again.
            my @dir = File::Spec->splitdir($path);
            pop @dir;
            $path = File::Spec->catdir(@dir);
            $fn = File::Spec->catfile($self->{datadir}, $path, "$comp.$flavour");
        }
    }

    $template ||= $self->{template}{$flavour}{$comp} || $self->{template}{error}{$comp};

    return $template;
}

=head2 entries_for_path

Given a path, find the entries that should be returned. This may be overridden
by a plugin defining the function "entries", or this "entries_for_path" function.
They are synonymous. See L<PLUGINS> for information on overriding this method.

The path will not include C<datadir>.

It implements two behaviours. If the path requested is a real path then it is
searched for all blog entries, honouring the depth parameter that limits how far
below the C<datadir> we should look for blog entries.

If it is not then it is expected to be a date, being in 1, 2 or 3 parts, in one
true date ISO format. This version will return all entries filtered by this date
specification. See also L<date_of_post>, which determines the date on which the
post was made and can be overridden in plugins.

=cut

sub entries_for_path {
    my ($self, $path) = @_;
    
    my @entries;

    return @entries if @entries = $self->_check_plugins('entries', @_);

    my $abs_path = File::Spec->catdir( $self->{datadir}, $path );

    # If this is an entry, return it.
    if (-f $abs_path . "." . $self->{file_extension}) {
        my $date = $self->date_of_post($abs_path . "." . $self->{file_extension});
        return [ $path . "." . $self->{file_extension}, { date => $date } ];
    }

    if (-d $abs_path) {
        # We use File::Find on a real path
        my $find = sub {
            return unless -f;

            my $rel_path = File::Spec->abs2rel( $File::Find::dir, $self->{datadir} );
            my $curdepth = File::Spec->splitdir($rel_path);

            my $fex = $self->{file_extension};

            # not specifying a file extension is a bit silly.
            if (!$fex || /\.$fex$/) {
                no warnings "once"; # File::Find::name causes a warning.

                my $rel_file = File::Spec->catfile( $rel_path, $_ );
                $rel_file = File::Spec->canonpath($rel_file); # This removes any artefacts like ./
                my $date = $self->date_of_post($File::Find::name);
                my $file_info = { date => $date };

                push @entries, [$rel_file, $file_info ];
            }

            $File::Find::prune = ($self->{depth} && $curdepth > $self->{depth});
        };

        File::Find::find( $find, $abs_path );
    }
    else {
        # We use date stuff on a fake path.
        # TODO: see whether we can split the path into a date section and a real section.
        my @ymd = File::Spec->splitdir( $path );
        my @all_entries = $self->entries_for_path( "" );

        my @entries = grep {
            my $post_date = localtime( $_->[1]{date} );
            
            # requested year                                                                              
            ($ymd[0]  == ($post_date->year+1900)) 
            and 
            # matches month, or moth not requested
            (!$ymd[1] || $ymd[1] == ($post_date->mon+1))
            and
            # matches day, or day not rquested
            (!$ymd[2] || $ymd[2] == $post_date->mday)

            ? $_ : () 

        } @all_entries;
    }

    return @entries;
}

=head2 date_of_post ($fn)

Return a unix timestamp defining the date of the post. The filename provided to
the method is an absolute filename.

=cut

sub date_of_post {
    my ($self, $fn) = @_;

    my $dop;
    return $dop if $dop = $self->_check_plugins("date_of_post", @_);

    return stat($fn)->mtime;
}

=head2 filter (@entries)

This function returns only the desired entries from the array passed in. By
default it just returns the array back, so is just a place to check for plugins.

This can be overridden by plugins in order to alter the way the module filters
the files. See L<PLUGINS> for more details.

=cut

sub filter {
    my ($self, @entries) = @_;

    my @remaining_files = $self->_check_plugins("filter", @_);

    return @remaining_files || @entries;
}

=head2 sort (@entries) 

Sort @entries and return the new list.

Default behaviour is to sort by date.

=cut

sub sort {
    my ($self, @entries) = @_;

    my @sorted_entries;
    return @sorted_entries if @sorted_entries = $self->_check_plugins("sort", @_);

    @sorted_entries = sort { $a->[1]->{date} <=> $b->[1]->{date} } @entries;
    return @sorted_entries;
}

=head2 static_mode($password, $on)

Sets static mode. Pass in the password to turn it on. Turns it off if it is already on.

=cut

sub static_mode {
    my ($self, $password, $on) = @_;

    die "No static dir defined" unless $self->{static_dir};
    die "No static publishing password defined" unless $self->{static_password};

    # Set it to toggle if we don't specify.
    $on = !$self->{static_mode} if !defined $on;

    if ($self->{static_mode} && !$on) {
        $self->{static_mode} = 0;
        $blosxom::static_or_dynamic = 'dynamic';
        return;
    }
    
    if ($on && $password eq $self->{static_password}) {
        $self->{static_mode} = 1;
        $blosxom::static_or_dynamic = 'static';
    }
}

=head2 interpolate($template, $extra_data) 

Each template is interpolated, which means that variables are swapped out if
they exist. Each template may have template-specific variables; e.g. the story
template has a title and a body. Those are provided in the extra data, which is
a hashref with the variable name to be replaced (without the $) as the key, and
the corresponding value as the value.

By default, a different set of variables are available to each template:

=head3 All templates

These are defined by you when you provide them to new() or run()

=over

=item blog_title
 
=item blog_description

=item blog_language

=item url

=item path_info

=item flavour

=back

=head3 Story (entry) template

These are defined by the entry.

=over

=item title

Post title

=item body

The body of the post

=item yr

=item mo

=item mo_num

=item da

=item dw

=item hr

=item min

Timestamp of entry. mo = month name; dw = day name

=item path

The folder in which the post lives, relative to the blog's base URL.

=item fn

The filename of the post, sans extension.

=back

=head3 Head template

=over

=item title

This method can be overridden by a plugin.

=cut

sub interpolate {
    my ($self, $template, $extra_data) = @_;
 
    my $done;
    return $done if $done = $self->_check_plugins("interpolate", @_);

    for my $var (keys %$extra_data){
        if($self->{require_namespace}) {
            $template =~ s/\$blosxom::$var\b/$extra_data->{$var}/g;
        }
        else {
            $template =~ s/\$(?:blosxom::)?$var\b/$extra_data->{$var}/g;
        }
    }

    # The blosxom docs say these are global vars, so let's mimic that.
    for my $var (qw(blog_title blog_description blog_language url path_info flavour)) {
        # You can set this option so that only $blosxom::foo variables are interpolated
        if($self->{require_namespace}) {
            $template =~ s/\$blosxom::$var\b/$self->{$var}/g;
        }
        else {
            $template =~ s/\$(?:blosxom::)?$var\b/$self->{$var}/g;
        }
    }

    {
        no strict 'vars';
        # Non-blosxom:: variables must be namespaced. I can't be bothered
        # making it work with more than one :: in it just yet, sorry.
        $template =~ s/\$(\w+::\w+)/"defined \$$1 ? \$$1 : '\$$1'"/gee;
    }

    return $template;
}

=head2 entry_data ($entry) 

Provided with the entry data, which is an arrayref with the entry filename,
relative to datadir, in the first slot and a hashref in the second. The hashref
will have at least a date entry, being a UNIX timestamp for the entry. See
the section on plugin entries.

Returns a hashref containing the following keys:

=over

=item title

Post title

=item body

The body of the post

=item yr

=item mo

=item mo_num

=item da

=item dw

=item hr

=item min

Timestamp of entry. mo = month name; dw = day name

=item path

The folder in which the post lives, relative to the blog's base URL.

=item fn

The filename of the post, sans extension.

=back

These should be returned such that it is true that

  $path . "/" . $fn . "." . $flavour eq $request_url

i.e. these components together are what was originally asked for. (Note that
flavour is a variable available to templates but not returned by this method.)

=cut

sub entry_data {
    my ($self, $entry) = @_;

    my $entry_data = {};

    my $fn = $entry->[0];

    {
        open my $fh, "<", File::Spec->catfile($self->{datadir}, $fn);
        my $title = <$fh>; chomp $title;
        $entry_data->{title} = $title;

        $entry_data->{body} = join "", <$fh>;
        close $fh;
    }
    
    {
        my @path = (File::Spec->splitpath($fn));
        $fn = pop @path;
        $fn =~ s/\.$self->{file_extension}$//;
        $entry_data->{fn} = $fn;
        $entry_data->{path} = File::Spec->catpath(@path);
    }

    {
        my $i = 1;
        my %month2num = map {$_, $i++} qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
        my $c_time = ctime($entry->[1]->{date});

        my($dw,$mo,$da,$hr,$min,$yr) = ( $c_time =~ /(\w{3}) +(\w{3}) +(\d{1,2}) +(\d{2}):(\d{2}):\d{2} +(\d{4})$/ );

        $da = sprintf("%02d", $da);
        my $mo_num = $month2num{$mo};
        $mo_num = sprintf("%02d", $mo_num);

        @{$entry_data}{qw(dw mo da yr mo_num hr min)} = ($dw, $mo, $da, $yr, $mo_num, $hr, $min);

        # Keep track of the latest date we find.
        $self->{latest_entry_date} = 0 if !exists $self->{latest_entry_date};
        $self->{latest_entry_date} = $entry->[1]->{date} 
            if $entry->[1]->{date} > $self->{latest_entry_date};
    }

    return $entry_data;
}

=head2 head_data ()

Return the data you want to be available to the head template. The head is
attached to the top of the output I<after> the entries have been run through,
so you have the data for all the entry data available to you in the arrayref
$self->{entries}.

Example:

    my $self = shift;
    my $data = {};
    if(@{$self->{entries}} == 1) {
        $data->{title} = $self->{entries}->[0]->{title}
    }
    return $data;

=cut

sub head_data {
    +{};
}

=head2 foot_data () 

Return the data you want to be available in your foot template. This is attached
to the output after everything else, as you'd expect.

=cut

sub foot_data {
    +{};
}

## PRIVATE FUNCTIONS
#  Purposely not in the POD

## _load_plugins
#  Trawl the plugins directory and look for plugins. Put them in the object hash.

sub _load_plugins {
    my $self = shift;

    my $dir = $self->{plugins_dir};
    return unless $dir;

    opendir my($plugins), $dir;

    # blosxom docs say modules ending in _ will not be loaded.
    for my $plugin (grep { /^\w+$/ && !/_$/ && -f File::Spec->join($dir, $_) }
                    sort readdir $plugins) {
        # blosxom docs say you can order modules by prefixing numbers.
        $plugin =~ s/^\d+//;

        # This will blow up if your package name is not the same as your file name.
        require "$dir/$plugin";
        if ($plugin->start()) {
            $self->{active_plugins}->{$plugin} = 1;

            $self->{plugins_ordered} ||= [];
            push @{$self->{plugins_ordered}}, $plugin;
        }
    }

    closedir $plugins;
}

## _load_templates
#  Read the default templates from DATA. Later the plugins get an opportunity to
#  override what happens when the real templates are read in, so we don't do that here.

sub _load_templates {
    my $self = shift;

    while (<DATA>) {
      last if /^(__END__)?$/;
      my($flavour, $comp, $txt) = /^(\S+)\s(\S+)\s(.*)$/;
      $txt =~ s/\\n/\n/mg;
      $self->{template}{$flavour}{$comp} = $txt;
    }

}

## _check_plugins
#  Look for plugins that can do the first arg, and pass them the rest of the args.
#  Return the first value returned by a plugin.

sub _check_plugins {
    my ($self, $method, @underscore) = @_;

    return unless $self->{plugins_ordered};
    return if $self->{no_plugins};

    for my $plugin (@{$self->{plugins_ordered}}) {
        local $self->{no_plugins} = 1;
        my @return;
        @return = $plugin->$method($self, @underscore) if $plugin->can($method);

        return @return if @return;
    }
}

=head1 USAGE

=head2 Quick start

To quick start, first you need to create a Blosxom object. You have to provide
three parameters to the C<new> method:

    datadir
    blog_title
    blog_description

The latter is likely to be dropped as a requirement soon.

Then you need to find some way of collecting a path and a flavour from the user.
The original script used the URL provided by the web server. You provide these
to the C<run> method.

    use Blog::Blosxom;
    use CGI qw(standard);

    my $blog = Blog::Blosxom->new(
        datadir => '/var/www/blosxom/entries',
        blog_title => 'Descriptive blog title.',
        blog_description => 'Descriptive blog description.',
    );

    my $path = path_info() || param('path');
    my ($flavour) = $path =~ s/(\.\w+)$// || param('flav');

    print header,
          $blog->run($path, $flavour);

The above is a complete CGI script that will run your blog. Note that C<header>
is a CGI function. Don't print that if you're not using CGI!

Now that we know how to run Blosxom we can look at how to make entries.

=head2 Entries

To create an entry, create a plaintext file in your C<datadir> with the .txt
extension. The first line of this file is the title of the post and the rest
is the body.

This post will be displayed if it is somewhere under the C<$path> you provided
to C<run>, unless it is the 41st such file, because by default only 40 are
displayed at once.

The C<txt> part of all this is configurable in C<new>.

=head2 Flavour

The flavour that you provide determines which set of templates are used to 
compose the output blog.

You may be wondering about the fact that the blog entry ends with .txt, but in
the CGI script we have used the extension to determine the flavour. The file 
extension is ignored when mapping the path to the file system, so your path
could feasibly match a single entry, which will of course be served on its own.

The template to be chosen is a file whose file extension is the current flavour
and whose file name is the template in question. Have a look at the docs for the
C<template> function.

Writing these templates is the primary way you make your blog entries show up
as decent stories. The other way is when you override the C<entry_data> method
and have the content of your entries moulded into some slightly better markup.

=head2 More information

The best source of information on this is the documentation for the methods
themselves. Therefore, we provide the execution order so you can see exactly
what is going on and figure stuff out that way.

=over

=item new

Blosxom is an object-oriented thing now. This is so that you can subclass it to
override any or all of the default functionality, which is kind of the point
of Blosxom in the first place.

=item run

The original script found the path and flavour for you but this one lets you
decide where they should come from, so you can integrate them into other
applications if you wish.

=item entries_for_path

The next thing that happens is the path is searched for all entries, and this
function simply returns them all. This function returns an array of each entry's
filename and a bit of extra data alongside.

=item date_of_post

C<entries_for_path> calls C<date_of_post> to get that little bit of extra data.

=item filter

Then the entries list is filtered. This function is empty by default, intended
to be overridden by plugins or subclasses.

=item sort

The remaining list is sorted. This is done by date by default, the date being
ascertained during C<entries_for_path>.

=item entry_data

This is one of the more powerful functions to reimplement. It returns as much
data about the provided entry as is necessary for your use of Blosxom. The
required return data are defined in the docs for this function; see also the
PLUGINS section.

This is called for each entry that remains after C<filter> is done and C<sort>
has ordered them.

=item template

This is called to get the data to give to C<interpolate>. It simply returns the
contents of the template file. 

=item interpolate

This is the second of the more powerful functions. In this function, the raw
templates have their variables replaced with their values. How that works is
documented in the method's own documentation!

Each entry's data is given to its template through this function; occasionally
while this is happening the date template is also given its data too.

=item head_data

This gets data to give to C<interpolate> for the C<head> template.

=item foot_data

This gets data to give to C<interpolate> for the C<foot> template.

=back

The interpolated templates are aggregated into an array, onto which the head
and foot templates are added at the end, allowing info about the whole page to
be available to both the top and bottom of the page.

=head1 PLUGINS

Writing plugins for this new version of Blosxom is easy. If you know exactly
what you want from your plugin, you can simply subclass this one and override
the methods below. Alternatively, you can create files in some directory, and
then configure your Blosxom object to use that directory as your plugins
directory.

In order to use a plugin directory, the package name in the plugin file must
be identical to the filename itself. That is because the blosxom engine uses
the filename to know which package to give to C<require>. The only thing that
deviates from this rule is that you can prepend the filename with any number of
digits, and these will be used to load the plugins in order. The order is that
returned by the sort function, so it is recommended all your numbers have the
same number of digits.

In order to disable a plugin, simply alter its C<start> subroutine to return a
false value instead of a true one.

=head2 Starting a plugin

As mentioned, it is necessary that your plugin's filename is the same as the
package defined in the plugin. Please also include a bit of a comment about
what your plugin does, plus author information. The community would appreciate
it if you would use an open licence for your copyrighting, since the community
is built on this attitude. However, the licence you use is, of course, up to 
you.

The smallest possible plugin (comments aside) is shown below, and its filename
would be C<myplugin>.

  ## Blosxom plugin myplugin
  ## Makes blosxom not suck
  ## Author: Altreus
  ## Licence: X11/MIT

  package myplugin;

  sub start{1}

  1;

=head2 Hooks

Every single hook in the plugin will be passed the I<Blosxom> object as the
first argument, effectively running the function as a method on the object
itself. This is shown as the C<$self> argument.

In all cases, the first plugin that defines a hook is the one that gets to do
it. For this reason you may find that you want to use the method above to
decide the order in which the plugins are loaded.

Also in all cases, except where a true/false value is expected, simply not
returning anything is the way to go about deciding you don't want to alter the
default behaviour. For example, if you wanted to take the date of a post from
the filename, then in the cases where the filename does not define a date, you
can simply C<return;> and processing will continue as if it had not defined 
this functionality in the first place.

Also also in all cases, you can get the return value of the default method by
simply calling $self->method. This is helpful if you want to slightly but not
wildly alter the output, such as adding extra information to the same set of
data. Obviously this is not true of C<start> and C<skip>, since these are not
methods on the class in the first place.

=head3 start ($self)

The C<start> subroutine is required in your module and will return either a
true or a false value to decide whether the plugin should be used.

You can use the values on the Blosxom object if you need to make a decision.

  sub start {
      return shift->{static_mode}; # Only active in static mode
  }

=head3 template ($self, $path, $comp, $flavour)
    
    $path:    path of request, filename removed
    $comp:    component e.g. head, story
    $flavour: quite obviously the flavour of the request

This returns the template to use in the given path for the given component for
the given flavour. The requested filename will not be part of the path, if the
requested path matched an individual entry.

The default template procedure is to check the given path and all parent
directories of that path, up to the blog root, for the file $comp.$flavour,
and to use the first one found.

Since it is pretty easy to find this file based on just the filename, you'd
think this method has something a bit more difficult to do. In fact this 
function returns the I<content> of that file, ready for interpolation.

This function implements the functionality of both the C<template> hook in the
original blosxom script, as well as the hooks for the individual templates
themselves. That means that if your original plugin defined a new template for,
e.g., the date.html in certain situations, this is where you should now return
that magic HTML.

=head3 entries_for_path ($self, $path)

    $path: The path as provided to run()

This returns an array of items. Each item is itself an arrayref, whose first
entry is the filename and whose second entry is a hashref. The hashref is
required to contain the 'date' key, which specifies the date of the file. 

That's pretty complicated. Here's some more info. When Blosxom is converting
entries into stories it needs to know what entries exist under a given path, 
and the date of each entry. It therefore needs an array of arrayrefs, each 
arrayref representing one of the entries found under the given path, in the 
format C<[$filename, $date]>.

However, since it is envisioned you might want to add more metadata about the
entry, the C<date> part is a hashref, so you can add more stuff to it if you
want to. So now the format is C<[$filename, { date => $date }]>.

The filename returned is the I<path and filename> of the entry file, I<relative
the datadir>. The input $path is not necessarily relative to anything, because
it will be the path the user requested. Thus, please note, it may contain the
year, month and day of the requested post(s) and not a path to any real file or
directory at all.

It is worth noting that you can override how Blosxom decides the date of the
file by implementing the C<date_of_post> method instead of this one.

=head3 date_of_post ($self, $post)

    $post: path and filename relative to blog root

You should return an arrayref where [0] is the 4-digit year, [1] is the 2-digit
month, and [2] is the 2-digit day. This is not checked for validity but will 
probably cause something to blow up somewhere if it is not a real date.

=head3 filter ($self, @entries)
    
    @entries: an array of all entries, exactly as returned by entries_for_path

This function does nothing by default and is a hook by which you can 
scrupulously filter out posts one way or another. You are given the output of
the C<entries_for_path> method above, and you should return an array in exactly
the same format, except having removed any entries you do not want to show up on
the generated page.

=head3 sort ($self, @entries)

    @entries: an array of all entries, exactly as returned by entries_for_path

You can override the default sorting mechanism, which is by date by default,
by implementing this method. It is advisable to empty your date template if
you do this, because the date template is inserted every time the date changes
as processing goes down the list.

A future release may see the date template replaced by a divider template, which
would be configurable and merely default to the date.

=head3 skip

The skip function is a feature from the original blosxom. Setting it to return
a true value will cause the Blosxom object to stop just before anything is
actually output. That is, it will find all the entries and pull in the templates
but not do anything with them if any active plugin makes this function return 
true. This is useful if, e.g., your plugin issues a redirect header.

=head3 interpolate ($self, $template, $extra_data)

This is where you can override the default way in which the variables are
interpolated into the template.

The extra data will be a hashref of var => val, var being the variable name to
interpolate, without its $.

If you don't call the parent function for this, be aware that there is an
option called $self->{require_namespace}, which means that only fully-qualified
variables will be interpolated. You should honour this if you intend anyone
else to use your plugin.

The three functions C<entry_data>, C<head_data> and C<foot_data> return simple
hashrefs that are interpolated in this function.

You should also be aware that there are several "global" variables, available
to all templates, that are not returned by any of those functions. They are
hard-coded in the default implementation of C<interpolate>, so it is probably
for the best if you defer to this method.

The section on usage will probably help here.

=head3 entry_data ($entry)

This is provided with an arrayref as returned by entries_for_path, and should
return a hashref with the keys as described above, in the method's own
documentation. Briefly, they are 

 title body yr mo mo_name da dw hr min path fn

You may also provide any extra keys that your own templates may want. It is
recommended that you use next::method to get the default hashref, and add more
things to it.

See the section on usage for how all this works and thus to get a better idea
of what you should or should not be overriding.

=head3 head_data

This function is called to get the data required for the head template. By
default, only the global variables are available in the head template.

You may override any global variable by returning it as a key in this hashref,
or you can add to the set of available variables instead. See the section on
usage for how all this works.

=head3 foot_data

This function is called to provide data to the foot template. By default it
returns an empty hashref.

You may override any global variable by returning it as a key in this hashref,
or you can add to the set of available variables instead.

See the section on usage for how all this works.

=head1 AUTHOR

Altreus, C<< <altreus at perl.org> >>

=head1 TODO

Most existing plugins won't work because I've changed the way it works to the
extent that the same functions don't necessarily exist. However, existing
plugins should be fairly easy to tailor to the new plugin system. I didn't
think this was too important a feature because a good number of the plugins at
the blosxom plugin repository are 404s anyway.

The plugin system is like the original blosxom's, where the first plugin to
define a function is the boss of that function. Some functions may benefit
from the combined effort of all plugins, such as filtering. That is something
to think about in the future.

Static rendering is not yet implemented. Frankly I don't think I can be 
bothered.

A comment system is common on many blogs and I think I will write a separate
plugin to make this easy.

=head1 BUGS

Bug reports on github, please! http://github.com/Altreus/Blog-Blosxom/issues

You can also get the latest version from here.

=head1 SUPPORT

You are reading the only documentation for this module.

You should check out the examples folder. If you don't know where that is, 
either check $HOME/.cpan/build or browse/clone the Git repository
http://github.com/Altreus/Blog-Blosxom

If you're brave you can see if I'm around in #perl on irc.freenode.com. Your
use case will help me refine the module, since in its initial state it was
merely a rewrite of the original script for my own sanity.

=head1 ACKNOWLEDGEMENTS

Thanks to the original author of blosxom.cgi for writing it and giving me code
to do much of the stuff it did.

http://blosxom.com

Thanks to f00li5h on that irc.freenode.com (and many others!) for being the 
first person I mean cat other than me to use it and therefore have lots of 
things to say about it.

=head1 LICENSE AND COPYRIGHT

This module is released under the X11/MIT licence, which is the one where you
use it as you wish and don't blame me for it. I hope the author of the original
script does not take this badly; if the author sees this and wishes me to 
change the licence I am happy to do so.

=cut

1; 

__DATA__
html content_type text/html
html head <html><head><link rel="alternate" type="application/rss+xml" title="RSS" href="$url/index.rss" /><title>$blog_title $path_info_da $path_info_mo $path_info_yr</title></head><body><h1>$blog_title</h1><p>$path_info_da $path_info_mo $path_info_yr</p>
html story <h2><a name="$fn">$title</a></h2><p>$body</p><p>posted at: $ti | path: <a href="$url$path">$path</a> | <a href="$url/$yr/$mo_num/$da#$fn">permanent link to this entry</a></p>\n
html date <h3>$dw, $da $mo $yr</h3>\n
html foot <p><a href="http://www.blosxom.com/"><img src="http://www.blosxom.com/images/pb_blosxom.gif" border="0" /></a></p></body></html>
rss content_type text/xml
rss head <?xml version="1.0"?>\n<!-- name="generator" content="blosxom/$version" -->\n<!DOCTYPE rss PUBLIC "-//Netscape Communications//DTD RSS 0.91//EN" "http://my.netscape.com/publish/formats/rss-0.91.dtd">\n\n<rss version="0.91">\n  <channel>\n    <title>$blog_title $path_info_da $path_info_mo $path_info_yr</title>\n    <link>$url</link>\n    <description>$blog_description</description>\n    <language>$blog_language</language>\n
rss story   <item>\n    <title>$title</title>\n    <link>$url/$yr/$mo_num/$da#$fn</link>\n    <description>$body</description>\n  </item>\n
rss date \n
rss foot   </channel>\n</rss>
error content_type text/html
error head <html><body><p><font color="red">Error: I'm afraid this is the first I've heard of a "$flavour" flavoured Blosxom.  Try dropping the "/+$flavour" bit from the end of the URL.</font>\n\n
error story <p><b>$title</b><br />$body <a href="$url/$yr/$mo_num/$da#fn.$default_flavour">#</a></p>\n
error date <h3>$dw, $da $mo $yr</h3>\n
error foot </body></html>
