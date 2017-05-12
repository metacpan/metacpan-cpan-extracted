package Dancer::Plugin::DirectoryView;

=head1 NAME

Dancer::Plugin::DirectoryView - Browse directory contents in Dancer web apps

=cut

use strict;

use Cwd 'abs_path';
use Dancer ':syntax';
use Dancer::Engine;
use Dancer::MIME;
use Dancer::Plugin;
use DirHandle;
use File::ShareDir;
use File::Spec::Functions qw(catfile);
use HTTP::Date;
use URI::Escape;

our $VERSION = '0.02';

# Distribution-level shared data directory
my $dist_dir = File::ShareDir::dist_dir('Dancer-Plugin-DirectoryView');

my $settings = plugin_setting;
my $path_prefix = $settings->{path_prefix} || '/dancer-directory-view';
# Need a leading slash
if ($path_prefix !~ m!^/!) {
    $path_prefix = '/' . $path_prefix;
}

my $mime = Dancer::MIME->instance();

my $builtin_tpl = {};

sub directory_view {
    my $options;
    
    if (@_ == 1 || (@_ == 2 && UNIVERSAL::isa($_[1], 'HASH'))) {
        #
        # Called from the application
        #
        my ($root_url, $options) = @_;
        
        my $root_dir = $options->{root_dir};
        
        # Public directory
        my $public_dir = abs_path(setting('public'));
        
        if (defined $root_dir) {
            # Root directory is set explicitly -- is it an absolute path?
            if (!File::Spec->file_name_is_absolute($root_dir)) {
                # No -- we assume it's relative to the public directory
                $root_dir = abs_path(catfile($public_dir, $root_dir));
            }
        }
        else {
            # Root directory not set -- assume it's the same as root URL,
            # relative to the public directory
            $root_dir = catfile($public_dir, split('/', $root_url));
        }
        
        $options->{root_dir} = $root_dir;
        
        my $re_root = quotemeta($root_url);
        
        # Does the root URL have a trailing slash?
        if ($root_url !~ m!/$!) {
            # Add slash
            $root_url =~ s!([^/])$!$1/!;
            
            # Add a redirection route
            get qr{$re_root} => sub {
                redirect $root_url;
            };
        }

        my $re_path = quotemeta($root_url) . '(.*)';
        
        get qr{$re_path} => sub {
            my ($path) = splat;
            
            return directory_view(%$options, path => $path);
        };
    }
    else {
        #
        # Called from a route handler
        #
        return _serve_files(@_);
    }
}
    
sub _serve_files {    
    my (%options) = @_;
    
    # Root directory
    my $root_dir = $options{root_dir} || '.';
    # Are system paths allowed?
    my $system_path = $options{system_path} || 0;
    # Template to use (if set to 0, a primitive built-in template is used)
    my $template = $options{template} || 'basic';
    # Should hidden files be included in the directory listing?
    my $show_hidden_files = $options{show_hidden_files} || 0;
    
    # Current path
    my $path = $options{path};
    
    # Views directory
    my $views_dir = abs_path(setting('views'));
    
    # Strip off unwanted leading/trailing slashes
    $root_dir =~ s!/$!!;
    $path =~ s!^/!!;
    
    # If root_dir is not absolute, assume it is relative to public directory
    if (!File::Spec->file_name_is_absolute($root_dir)) {
        $root_dir = abs_path(catfile(abs_path(setting('public')), $root_dir));
    }
    
    my $real_path = abs_path(catfile($root_dir, $path));
    $real_path =~ s!/$!!;

    if (index($real_path, abs_path(setting('public'))) != 0 && !$system_path) {
        # The requested file/directory lies outside of the public directory, but
        # system paths are not allowed
        return send_error("Not allowed", 403);
    }
    
    # Make sure we're inside root_dir. This shouldn't actually be necessary, as
    # Dancer takes care of potentially dangerous paths (e.g., containing "..")
    # and we should be safe at this point, but let's do the check anyway in case
    # the application is deployed in some weird insecure way or something.
    if (index($real_path, $root_dir) != 0) {
        return send_error("Not allowed", 403);
    }
    
    if (-f $real_path) {
        #
        # Regular file
        #
        send_file($real_path, system_path => $system_path);
    }
    elsif (-d $real_path) {
        #
        # Directory -- show contents
        #
        my @files = ();
        
        if ($real_path ne $root_dir) {
            push(@files, {
                url => "../",
                name => "Up to parent directory",
                size => '',
                mime_type => '',
                mtime => '',
                class => 'parent-directory'
            });
        }
        
        my $dh = DirHandle->new($real_path);
        my @entries;
        while (defined(my $entry = $dh->read)) {
            next if $entry eq '.' || $entry eq '..';
            next if $entry =~ /^\./ && !$show_hidden_files;
            push @entries, $entry;
        }
        
        # Mapping of MIME types to CSS class names
        my %classes = (
            'directory' => 'directory',
            'application/javascript' => 'file-application-javascript',
            'application/pdf' => 'file-application-pdf',
            'application/vnd.ms-excel' => 'file-application-vnd-ms-excel',
            'application/vnd.oasis.opendocument.spreadsheet' => 
                'file-application-vnd-oasis-opendocument-spreadsheet',
            'application/vnd.oasis.opendocument.text' => 
                'file-application-vnd-oasis-opendocument-text',
            'application/x-httpd-php' => 'file-application-x-php',
            'application/x-msword' => 'file-application-msword',
            'application/x-perl' => 'file-application-x-perl',
            'application/xml' => 'file-application-xml',
            'application/zip' => 'file-application-zip',
            'image/jpeg' => 'file-image-x-generic',
            'image/png' => 'file-image-x-generic',
            'text/html' => 'file-text-html',
            'text/plain' => 'file-text-plain',
            'text/x-csrc' => 'file-text-x-csrc'
        );
        
        for my $name (sort { $a cmp $b } @entries) {
            my $file = catfile($real_path, $name);
            my $url = $name;
            $url = join '/', map { uri_escape($_) } split m!/!, $url;
            
            my $is_dir = -d $file;
            my @stat = stat(_);
            
            if ($is_dir) {
                $name .= '/';
                $url .= '/';
            }
            
            my $mime_type = $is_dir ? 'directory' : $mime->for_file($name) 
                || '';
                
            push(@files, {
                url => $url,
                name => $name,
                size => $is_dir ? '' : _format_size($stat[7]),
                mime_type => $mime_type,
                mtime => HTTP::Date::time2str($stat[9]),
                class => $classes{$mime_type} || 'file-unknown'
            });
        }

        if ($template) {
            # Get a new instance of Dancer::Template::Simple
            my $template_simple = Dancer::Engine->build(template => 'simple');
            $template_simple->start_tag('<%');
            $template_simple->stop_tag('%>');

            my $template_dir;

            # Look for the template files in the application's views directory
            if (-d catfile($views_dir, $template)) {
                $template_dir = catfile($views_dir, $template);
            }
            # Then, try the plugin's views directory
            elsif (-d catfile($dist_dir, 'views', $template)) {
                $template_dir = catfile($dist_dir, 'views', $template);
            }
            else {
                # TODO: Template not found -- handle error
            }
            
            my $file_tpl = catfile($template_dir, 'file.tt');
            my $listing_tpl = catfile($template_dir, 'listing.tt');
            my $layout_tpl = catfile($template_dir, 'layout.tt');
            
            # Render the list of files
            my $files_html = '';
            for my $file (@files) {
                $files_html .= $template_simple->render($file_tpl,
                    { file => $file });
            }
            
            # Insert the rendered list into the listing container
            my $listing_html = $template_simple->render($listing_tpl,
                { path => '/' . $path, files => $files_html });
            
            if ($options{layout}) {
                # Is there a corresponding layout file in the views directory?
                if (-f catfile($views_dir, 'layouts',
                    my $layout_file = $options{layout}))
                {
                    # Display the directory listing using the specified layout
                    # file
                    return $template_simple->apply_layout($listing_html, {}, {
                        layout => $layout_file });
                }
                else {
                    # Use the application's default layout
                    return $template_simple->apply_layout($listing_html);
                }
            }
            else {
                # Display the listing in the template's layout
                return $template_simple->render($layout_tpl,
                    { listing => $listing_html, path => '/' . $path,
                        path_prefix => $path_prefix, request => request,
                        template => 'default' });
            }
        }
        else {
            #
            # Use a basic built-in template
            #
            my $files_html = '';
            for my $file (@files) {
                my $file_html = $builtin_tpl->{file};
                $file_html =~ s/\[%\s*file.(\S*)\s*%\]/$file->{$1}/eg;
                $files_html .= $file_html;
            }
            my $listing_html = $builtin_tpl->{listing};
            $listing_html =~ s/\[%\s*path\s*%\]/"\/".$path/eg;
            $listing_html =~ s/\[%\s*files\s*%\]/$files_html/eg;
        
            if ($options{layout}) {
                # Get the application's template engine
                my $template = engine 'template';
                if (-f catfile($views_dir, 'layouts', 
                    my $layout_file = $options{layout}))
                {
                    # Display the directory listing using the specified layout
                    # file
                    return $template->apply_layout($listing_html, {},
                        { layout => $layout_file });
                }
                else {
                    # Use the default application layout
                    return $template->apply_layout($listing_html);
                } 
            }
            else {
                # Use a primitive layout
                (my $html = $builtin_tpl->{layout}) =~
                    s/\[%\s*content\s*%\]/$listing_html/eg;
                $html =~ s/\[%\s*path\s*%\]/"\/".$path/eg;
                return $html;
            }
        }
    }
};

my $path_prefix_re = quotemeta($path_prefix);

get qr{^$path_prefix_re/.*} => sub {
    (my $path = request->path_info) =~ s!^$path_prefix_re/!!;
    
    send_file(catfile($dist_dir, 'public', split('/', $path)),
        system_path => 1);
};

if (exists $settings->{url}) {
    directory_view $settings->{url} => $settings;
}

if (exists $settings->{directories}) {
    for my $url (keys %{$settings->{directories}}) {
        directory_view $url => $settings->{directories}->{$url} || {};
    }
}

register 'directory_view' => \&directory_view;

register_plugin;

sub _format_size {
    my ($size) = @_;
    $size ||= 0;
    
    if ($size > 1024**3) {
        return sprintf("%.2f GB", $size / 1024**3);
    }
    elsif ($size > 1024**2) {
        return sprintf("%.2f MB", $size / 1024**2);
    }
    elsif ($size > 1024) {
        return sprintf("%.0f KB", $size / 1024);
    }
    else {
        return sprintf("%d B", $size);
    }
}

# This piece of HTML is borrowed from Plack::App::Directory, which admits to
# have stolen it from rack/directory.rb. The world of open-source is full of
# thieves.
$builtin_tpl->{layout} = <<END;
<html><head>
  <title>[% path %]</title>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  <style type="text/css">
table { width: 100%; }
.name { text-align:left; }
.size, .mtime { text-align:right; }
.type { width:11em; }
.mtime { width:15em; }
  </style>
</head><body>
[% content %]
</body></html>
END
$builtin_tpl->{listing} = <<END;
<h1>[% path %]</h1>
<hr />
<table>
  <tr>
    <th class="name">Name</th>
    <th class="size">Size</th>
    <th class="type">Type</th>
    <th class="mtime">Last Modified</th>
  </tr>
[% files %]
</table>
<hr />
END
$builtin_tpl->{file} = <<END;
<tr>
  <td class="name"><a href="[% file.url %]">[% file.name %]</a></td>
  <td class="size">[% file.size %]</td>
  <td class="type">[% file.mime_type %]</td>
  <td class="mtime">[% file.mtime %]</td>
</tr>
END

1; # End of Dancer::Plugin::DirectoryView
__END__

=pod

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    use Dancer::Plugin::DirectoryView;

    # Allow browsing of public/files/share
    directory_view '/files/share';
    
    # Browse /some/other/directory (located outside of public) as /files/other
    directory_view '/files/other' => { root_dir => '/some/other/directory',
                                       system_path => 1 };

    # Call directory_view in a route handler
    get qr{/files/secret/(.*)} => sub {
        my ($path) = splat;
        
        # Check if the user has permissions to access these files
        if (...) {
            return directory_view(root_dir => '/some/secret/directory',
                                  path => $path,
                                  system_path => 1);
        }
        else {
            return send_error("Access denied!", 403);
        }
    };

=head1 DESCRIPTION

Dancer::Plugin::DirectoryView provides an easy way to allow the users of your
web application to browse the contents of specific directories on the server. It
generates directory index pages to navigate through the directories, in a
similar fashion as Apache's mod_autoindex and Plack::App::Directory, but in
contrast to those solutions, it does not depend on how your application is
deployed.

=head1 CONFIGURATION

Put the plugin's settings in the configuration file of your application, under
C<plugins>. If there's just one directory that you want to make accessible, set
its URL with the C<url> option:

    plugins:
        DirectoryView:
            url: /pub/files
            root_dir: /some/directory
            show_hidden_files: 1
            system_path: 1

If you want to configure more than one directory, use the C<directories> option
to set a different set of options for each directory:

    plugins:
        DirectoryView:
            directories:
                "/pub/files":
                    root_dir: /some/directory
                    show_hidden_files: 1
                    system_path: 1
                "/pub/documents":
                    root_dir: /other/directory
                    system_path: 1

You can also enable directory browsing by calling the C<directory_view> function
in your app. The first parameter passed to the function is a string that defines
the URL at which the directory contents will be available, the second is a
reference to a hash with options. Example:

    directory_view '/pub/photos' => { root_dir => '/home/mike/photos',
                                      system_path => 1 };
                                       
    directory_view '/pub/documents' => { root_dir => '/usr/share/doc',
                                         system_path => 1 };

The available configuration options are listed below.

=head2 directories

Used to configure multiple directories.

=head2 layout

If set to C<1>, the directory listing is displayed in the application's default
layout (instead of the layout defined by the C<template>). If set to a name of
a file under C<views/layouts>, that file is used as the layout.

=head2 path

The current path to browse/display, relative to C<root_dir>. Required when
C<directory_view> is called in a route handler.

=head2 root_dir

The root directory which will be available to the users. If it's a relative
path, it is assumed to be located under C<public>. It must be specified when
C<directory_view> is called in a route handler. If C<directory_view> is called
outside a route handler, then C<root_dir> may be omitted, and it will be assumed
to be the same as the base URL and relative to C<public>.

=head2 show_hidden_files

If set to C<1>, hidden files (with names starting with C<.>) are included in the
directory listing.

Default: C<0>

=head2 system_path

If set to C<1>, directories and files outside the C<public> directory can be
accessed. This is required if C<root_dir> itself is located outside of
C<public>.

Default: C<0>

=head2 template

The template to use. It is the name of a directory containing three template
files:

=over 4

=item * C<layout.tt> - The layout in which the directory listing is displayed
(the HTML document that wraps the listing)

=item * C<listing.tt> - The template for the directory listing container (e.g.,
a table header/footer)

=item * C<file.tt> - The template for a single file in the listing (e.g., a
table row)

=back

The plugin first looks for this directory in the application's C<views>
directory, then in its own C<views> directory.

Default: C<"basic">

=head2 url

The URL at which the root directory will be accessible.

=head1 EXAMPLES

=head2 Directory under C<public>

In the simplest example, the root directory is located under the C<public>
directory of the application, so it's already intended to be world-accessible
and you don't have to worry about C<system_path> and permissions. Assuming that
the directory is C<public/files/docs>, you can enable it either with the
following entries in the configuration file:

    plugins:
        DirectoryView:
            url: /files/docs

or with this call in your application:

    directory_view '/files/docs';

=head2 Directory under C<public> with a different URL

If you want to make the directory accessible, but with a different URL than the
system path, provide both the C<url> and the C<root_dir> options in the
configuration file: 

    plugins:
        DirectoryView:
            url: /documents
            root_dir: files/docs

Or, call C<directory_view> like this:
    
    directory_view '/documents' => { root_dir => 'files/docs' };
    
=head2 Directory outside C<public>

When the root directory is located outside of C<public>, you need to enter both
the desired C<url> and C<root_dir>, as well as enable the C<system_path> option
to allow access to files not within the C<public> directory. Example
configuration:

    DirectoryView:
        url: /holiday-photos
        root_dir: /home/user/photos/holidays
        system_path: 1

Example call:

    directory_view '/holiday-photos' => { root_dir => '/home/user/photos/holidays',
                                          system_path => 1 };

=head2 Directory outside C<public> with relative path

Using a relative path in C<root_dir>, you can also access directories above
the C<public> directory of your application. For example, if for some reason you
would like to let users view your application's logs, you could use this
configuration:

    plugins:
        DirectoryView:
            url: /logs
            root_dir: ../logs
            system_path: 1

Or this call:

    directory_view: '/logs' => { root_dir => '../logs', system_path => 1 };

=head1 AUTHOR

Michal Wojciechowski, C<< <odyniec at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-directoryview at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer-Plugin-DirectoryView>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::DirectoryView


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-DirectoryView>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-DirectoryView>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-DirectoryView>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-DirectoryView/>

=back


=head1 ACKNOWLEDGEMENTS

Some parts of the code were heavily inspired by Tatsuhiko Miyagawa's
L<Plack::App::Directory>.

Used icons from the Oxygen Icons project (L<http://www.oxygen-icons.org/>).

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Michal Wojciechowski.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
