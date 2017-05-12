use 5.008;
use strict;
use warnings;

package CSS::Squish;

$CSS::Squish::VERSION = '0.10';

# Setting this to true will enable lots of debug logging about what
# CSS::Squish is doing
$CSS::Squish::DEBUG = 0;

use File::Spec;
use Scalar::Util qw(blessed);
use URI;
use URI::file;

=head1 NAME

CSS::Squish - Compact many CSS files into one big file

=head1 SYNOPSIS

  use CSS::Squish;
  my $concatenated = CSS::Squish->concatenate(@files);

  my $squisher = CSS::Squish->new( roots => ['/root1', '/root2'] );
  my $concatenated = $squisher->concatenate(@files);

=head1 DESCRIPTION

This module takes a list of CSS files and concatenates them, making sure
to honor any valid @import statements included in the files.

The benefit of this is that you get to keep your CSS as individual files,
but can serve it to users in one big file, saving the overhead of possibly
dozens of HTTP requests.

Following the CSS 2.1 spec, @import statements must be the first rules in
a CSS file.  Media-specific @import statements will be honored by enclosing
the included file in an @media rule.  This has the side effect of actually
I<improving> compatibility in Internet Explorer, which ignores
media-specific @import rules but understands @media rules.

It is possible that future versions will include methods to compact
whitespace and other parts of the CSS itself, but this functionality
is not supported at the current time.

=cut

#
# This should be a decently close CSS 2.1 compliant parser for @import rules
#
# XXX TODO: This does NOT deal with comments at all at the moment.  Which
# is sort of a problem.
# 

my @ROOTS = qw( );

my @MEDIA_TYPES = qw(all aural braille embossed handheld print
                     projection screen tty tv);
my $MEDIA_TYPES = '(?:' . join('|', @MEDIA_TYPES) . ')';
my $MEDIA_LIST  = qr/$MEDIA_TYPES(?:\s*,\s*$MEDIA_TYPES)*/;

my $AT_IMPORT = qr/^\s*                     # leading whitespace
                    \@import\s+             # @import
                        (?:url\(            #   url(
                        \s*                 #   optional whitespace
                        (?:"|')?            #   optional " or '
                      |                     # or
                        (?:"|'))            #   " or '
                      (.+?)                 # the filename
                        (?:(?:"|')?         #   optional " or '
                        \s*                 #   optional whitespace
                        \)                  #   )
                      |                     # or
                        (?:"|'))            #   " or '
                    (?:\s($MEDIA_LIST))?    # the optional media list
                    \;                      # finishing semi-colon
                   \s*$                     # trailing whitespace
                  /x;

=head1 COMMON METHODS

=head2 new( [roots=>[...]] )

A constructor. For backward compatibility with versions prior to 0.06
you can still call everything as a class method, but should remember
that roots are shared between all callers in this case.

if you're using persistent environment (like mod_perl) then it's very
recomended to use objects.

=cut

sub new {
    my $proto = shift;
    return bless {@_}, ref($proto) || $proto;
}

=head2 concatenate( @files )

Takes a list of files to concatenate and returns the results as one big scalar.

=head2 concatenate_to( $dest, @files )

Takes a filehandle to print to and a list of files to concatenate.
C<concatenate> uses this method with an C<open>ed scalar.

=cut

sub concatenate {
    my $self   = shift;
    my $string = '';
    
    $self->_debug("Opening scalar as file");
    
    open my $fh, '>', \$string or die "Can't open scalar as file! $!";
    $self->concatenate_to($fh, @_);

    $self->_debug("Closing scalar as file");
    close $fh;

    return $string;
}

sub concatenate_to {
    my $self = shift;
    my $dest = shift;

    $self->_debug("Looping over list of files: ", join(", ", @_), "\n");

    my %seen = ();
    while ( my $file = shift @_ ) {

        next if $seen{ $file }{'all'}++;

        my $fh = $self->file_handle( $file );
        unless ( defined $fh ) {
            $self->_debug("Skipping '$file'...");
            print $dest qq[/* WARNING: Unable to find/open file '$file' */\n];
            next;
        }
        $self->_concatenate_to( $dest, $fh, $file, \%seen );
    }
}

sub _concatenate_to {
    my $self = shift;
    my $dest = shift;
    my $fh   = shift;
    my $file = shift;
    my $seen = shift || {};

    while ( my $line = <$fh> ) {
        if ( $line =~ /$AT_IMPORT/o ) {
            my $import = $1;
            my $media  = $2;

            $self->_debug("Processing import '$import'");

            # resolve URI against the current file and get the file path
            # which is always relative to our root(s)
            my $path = $self->resolve_uri( $import, $file );
            unless ( defined $path ) {
                $self->_debug("Skipping import because couldn't resolve URL");
                print $dest $line;
                next;
            }

            if ( $seen->{ $path }{'all'} ) {
                $self->_debug("Skipping import as it was included for all media types");
                print $dest "/** Skipping: \n", $line, "  */\n\n";
                next;
            }

            if ( $media ) {
                my @list = sort map lc, split /\s*,\s*/, ($media||'');
                if ( grep $_ eq 'all', @list ) {
                    @list = ();
                }
                $media = join ', ', @list;
            }
            if ( $seen->{ $path }{ $media || 'all' }++ ) {
                $self->_debug("Skipping import as it's recursion");
                print $dest "/** Skipping: \n", $line, "  */\n\n";
                next;
            }

            # Look up the new file in root(s), so we can leave import
            # if something is wrong
            my $new_fh = $self->file_handle( $path );
            unless ( defined $new_fh ) {
                $self->_debug("Skipping import of '$import'");

                print $dest qq[/* WARNING: Unable to find import '$import' */\n];
                print $dest $line;
                next;
            }

            print $dest "\n/**\n  * From $file: $line  */\n\n";

            if ( defined $media ) {
                print $dest "\@media $media {\n";
                $self->_concatenate_to($dest, $new_fh, $path, $seen);
                print $dest "}\n";
            }
            else {
                $self->_concatenate_to($dest, $new_fh, $path, $seen);
            }

            print $dest "\n/** End of $import */\n\n";
        }
        else {
            print $dest $line;
            last if not $line =~ /^\s*$/;
        }
    }
    $self->_debug("Printing the rest");
    local $_;
    print $dest $_ while <$fh>;
    close $fh;
}

=head1 RESOLVING METHODS

The following methods help map URIs to files and find them on the disk.

In common situation you control CSS and can adopt it to use imports with
relative URIs and most probably only have to set root(s).

However, you can subclass these methods to parse css files before submitting,
implement advanced mapping of URIs to file system and other things.

Mapping works in the following way. When you call concatenate method we get
content of file using file_handle method which as well lookup files in roots.
If roots are not defined then files are treated as absolute paths or relative
to the current directory. Using of absolute paths is not recommended as
unhide server dirrectory layout to clients in css comments and as well don't
allow to handle @import commands with absolute URIs. When files is found we
parse its content for @import commands. On each URI we call resolve_uri method
that convert absolute and relative URIs into file paths.

Here is example of processing:

    roots: /www/overlay/, /www/shared/

    $squisher->concatenate('/css/main.css');
    
    ->file_handle('/css/main.css');
        ->resolve_file('/css/main.css');
        <- '/www/shared/css/main.css';
    <- handle;

    content parsing
    find '@import url(nav.css)'
    -> resolve_uri('nav.css', '/css/main.css');
    <- '/css/nav.css';
        ... recursivly process file
    find '@import url(/css/another.css)'
    -> resolve_uri('/css/another.css', '/css/main.css');
    <- '/css/another.css'
    ...

=head2 roots( @dirs )

A getter/setter for paths to search when looking for files.

The paths specified here are searched for files. This is useful if
your server has multiple document roots or document root doesn't match
the current dir.

See also 'resolve_file' below.

=cut

sub roots {
    my $self = shift;
    my @res;
    unless ( blessed $self ) {
        @ROOTS = @_ if @_;
        @res = @ROOTS;
    } else {
        $self->{'roots'} = [ grep defined, @_ ] if @_;
        @res = @{ $self->{'roots'} };
    }
    $self->_debug("Roots are: ". join ", ", map "'$_'", @res);
    return @res;
}

=head2 file_handle( $file )

Takes a path to a file, resolves (see resolve_file) it and returns a handle.

Returns undef if file couldn't be resolved or it's impossible to open file.

You can subclass it to filter content, process it with templating system or
generate it on the fly:

    package My::CSS::Squish;
    use base qw(CSS::Squish);

    sub file_handle {
        my $self = shift;
        my $file = shift;
        
        my $content = $self->my_prepare_content($file);
        return undef unless defined $content;

        open my $fh, "<", \$content or warn "Couldn't open handle: $!";
        return $fh;
    }

B<Note> that the file is not resolved yet and is relative to the root(s), so
you have to resolve it yourself or call resolve_file method.

=cut

sub file_handle {
    my $self = shift;
    my $file = shift;

    my $path = $self->resolve_file( $file );
    unless ( defined $path ) {
        $self->_debug("Couldn't find '$file' in root(s)");
        return undef;
    }

    my $fh;
    unless ( open $fh, '<', $path ) {
        $self->_debug("Skipping '$file' ($path) due to error: $!");
        return undef;
    }
    return $fh;
}

=head2 resolve_file( $file )

Lookup file in the root(s) and returns first path it found or undef.

When roots are not set just checks if file exists.

=cut

sub resolve_file {
    my $self = shift;
    my $file = shift;

    $self->_debug("Looking for '$file'");
    my @roots = $self->roots;
    unless ( @roots ) {
        return undef unless -e $file;
        return $file;
    }

    foreach my $root ( @roots ) {
        $self->_debug("Searching in '$root'");
        my @spec = File::Spec->splitpath( $root, 1 );
        my $path = File::Spec->catpath( @spec[0,1], $file );

        return $path if -e $path;
    }
    return undef;
}

=head2 _resolve_file( $file, @roots )

DEPRECATED. This private method is deprecated and do nothing useful except
maintaining backwards compatibility. If you were using it then most probably
to find files in roots before submitting them into concatenate method. Now,
it's not required and this method returns back file path without changes.

=cut

sub _resolve_file {
    my ($self, $file, @roots) = @_;
    require Carp;
    Carp::carp("You called ->_resolve_file($file, ...). The method is deprecated!");
    return $file;
}

=head2 resolve_uri( $uri_string, $base_file )

Takes an URI and base file path and transforms it into new
file path.

=cut

sub resolve_uri {
    my $self = shift;
    my $uri_str = shift;
    my $base_file = shift;

    my $uri = URI->new( $uri_str, 'http' );

    if ( defined $uri->scheme || defined $uri->authority ) {
        $self->_debug("Skipping uri because it's external");
        return undef;
    }

    my $strip_leading_slash = 0;
    unless ( $base_file =~ m{^/} ) {
        $base_file = '/'. $base_file;
        $strip_leading_slash = 1;
    }
    my $base_uri = URI::file->new( $base_file );

    my $path = $uri->abs( $base_uri )->path;
    $path =~ s{^/}{} if $strip_leading_slash;
    return $path;
}

sub _debug {
    my $self = shift;
    warn( ( caller(1) )[3], ": ", @_, "\n") if $CSS::Squish::DEBUG;
}

=head1 BUGS AND SHORTCOMINGS

At the current time, comments are not skipped.  This means comments happening
before @import statements at the top of a file will cause the @import rules
to not be parsed.  Make sure the @import rules are the very first thing in
the file (and only one per line).  Processing of @import rules stops as soon
as the first line that doesn't match an @import rule is encountered.

All other bugs should be reported via
L<http://rt.cpan.org/Public/Dist/Display.html?Name=CSS-Squish>
or L<bug-CSS-Squish@rt.cpan.org>.

=head1 AUTHOR

Thomas Sibley <trs@bestpractical.com>, Ruslan Zakirov <ruz@bestpractical.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

