package Dancer::Plugin::Preprocess::Sass;

use strict;
use warnings;

# ABSTRACT: Generate CSS files from Sass/SCSS files

our $VERSION = '0.031'; # VERSION

use Cwd 'abs_path';
use Dancer ':syntax';
use Dancer::Plugin;
use File::Spec::Functions qw(catfile);
use Text::Sass;

my $settings = plugin_setting;
my $paths;

my $sass = Text::Sass->new;
my $public_dir = abs_path(setting('public') || '');

if (exists $settings->{paths}) {
    $paths = $settings->{paths};
}
else {
    $paths = ['css'];
}

# Translate URL paths to filesystem paths
my @fs_paths = map { catfile(split('/'), "") } @$paths;

if ($settings->{save}) {
    # Check if the directories are writable
    for my $path (@fs_paths) {
        my $full_path = catfile($public_dir, $path);
        if (!-w $full_path) {
            warning __PACKAGE__ . ": Can't write to $full_path";
        }
    }
}

# Make a regular expression to match URL paths
my $paths_re = join '|', map {
    my $s = $_;
    $s =~ s{^[^/]}{/$&};    # Add leading slash, if missing
    $s =~ s{/$}{};          # Remove trailing slash
    quotemeta $s;
} reverse sort @$paths;

sub _process_sass_file {
    my $sass_file = shift;
    my $method;
    
    if ($sass_file =~ /\.sass$/) {
        $method = 'sass2css';
    }
    elsif ($sass_file =~ /\.scss$/) {
        $method = 'scss2css';
    }
    else {
        return;
    }
    
    open (my $f, '<', $sass_file);
    my $contents;
    {
        local $/;
        $contents = <$f>;
    }
    close($f);
    
    return $sass->$method($contents);
}

hook before_file_render => sub {
    # If saving is not enabled, then there's nothing for us to do (since we
    # won't be able to save the generated CSS rules in a file, duh)
    return if !$settings->{save};
    
    my $path = abs_path(shift);
    
    # Build a regular expression to match filesystem paths
    my $fs_paths_re = join '|', map { quotemeta } @fs_paths;
    
    my $path_re = '^' . quotemeta(catfile($public_dir, "")) .
        '(?:' . $fs_paths_re . ')';

    if ($path =~ qr{$path_re} && $path =~ qr{\.css$}) {
        (my $filename = $path) =~ s/\.css$//;
        my $input_file;
        
        if ((-f ($input_file = $filename . '.sass') ||
            -f ($input_file = $filename . '.scss')) &&
            (stat($path))[9] < (stat($input_file))[9])
        {
            # There is a Sass/Scss file newer than the CSS file
            my $css = _process_sass_file($input_file);
            
            if (defined $css) {
                # Save the generated CSS data
                open(my $f, '>', $path);
                print {$f} $css;
                close($f);
            }
        }
    }
};

get qr{($paths_re)/([^/]*\.css)} => sub {
    my ($path, $css_file) = splat;

    # Prepend the path to the CSS file name
    $path = catfile(split('/', $path));
    $css_file = catfile($path, $css_file);
    
    # Prepend public directory location
    my $css_file_abs = catfile($public_dir, $css_file);
    
    (my $filename = $css_file_abs) =~ s/\.css$//;
    my $input_file;

    if (-f ($input_file = $filename . '.sass') ||
        -f ($input_file = $filename . '.scss'))
    {
        # Sass/Scss file exists
        my $css = _process_sass_file($input_file);
        
        if ($settings->{save}) {
            # Saving enabled -- save the generated CSS as the requested file
            open(my $f, '>', $css_file_abs);
            print {$f} $css;
            close($f);
        }
        
        header 'content-type' => 'text/css';
        return $css;
    }
    else {
        # Check if the CSS file exists. Probably not, because if it does exist,
        # then Dancer should have already served it as a static file, and we
        # shouldn't even end up in this route handler. Still, we'll do this
        # check in case we're in some wacky parallel universe where route
        # handlers are run before static files.
        if (-f $css_file_abs) {
            return send_file($css_file);
        }
        else {
            return send_error("Not found", 404);
        }
    }
};

register_plugin;

1; # End of Dancer::Plugin::Preprocess::Sass

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Plugin::Preprocess::Sass - Generate CSS files from Sass/SCSS files

=head1 VERSION

version 0.031

=head1 SYNOPSIS

Dancer::Plugin::Preprocess::Sass adds support for Sass/SCSS files in a Dancer
web application.

Add the plugin to your application:

    use Dancer::Plugin::Preprocess::Sass;

Configure its settings in the YAML configuration file:

    plugins:
      "Preprocess::Sass":
        save: 1
        paths:
          - css
          - subdir/css

=head1 DESCRIPTION

Dancer::Plugin::Preprocess::Sass adds support for Sass/SCSS files in a Dancer
web application.

When a request is received for a CSS file, the plugin looks for a Sass/SCSS file
with the same name, and transforms it into CSS. The generated CSS file may then
be saved and served as a regular static file. Every time the source Sass/SCSS
file gets modified, the corresponding CSS file is regenerated.

=head1 CONFIGURATION

The available configuration settings are described below.

=head2 save

If set to C<0>, then the CSS files are generated on-the-fly with every request.
If set to C<1>, the files are generated once and saved, then served as static
files later on.

CSS files are saved in the same directory as the Sass/SCSS files, so the system
user that the web application is running as must be allowed to write to that
directory.

Default: C<0>

=head2 paths

A list of paths to serve CSS files from. Each path is relative to the C<public>
directory of the application.

    plugins:
      "Preprocess::Sass":
        paths:
          - css
          - subdir/css

Default: C<'css'>

=head1 SEE ALSO

=over 4



=back

* L<http://sass-lang.com/> - Sass website

=head1 ACKNOWLEDGEMENTS

The plugin uses Roger Pettett's L<Text::Sass> module. 

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/odyniec/p5-Dancer-Plugin-Preprocess-Sass/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/odyniec/p5-Dancer-Plugin-Preprocess-Sass>

  git clone https://github.com/odyniec/p5-Dancer-Plugin-Preprocess-Sass.git

=head1 AUTHOR

Michal Wojciechowski <odyniec@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Michal Wojciechowski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
