# $Id: CVS.pm,v 1.35 2003/12/07 00:00:37 barbee Exp $

=head1 NAME

Apache::CVS - method handler provide a web interface to CVS repositories

=head1 SYNOPSIS

    <Location /cvs>
        SetHandler perl-script
        PerlHandler Apache::CVS::HTML
        PerlSetVar CVSRoots cvs1=>/usr/local/CVS
    </Location>

=head1 DESCRIPTION

C<Apache::CVS> is a method handler that provide a web interface to CVS
repositories. Please see L<"CONFIGURATION"> to see what configuration options
are available. To get started you'll at least need to set CVSRoots to your
local CVS Root directory.

C<Apache::CVS> is does not output the contents of your CVS repository on its
own. Rather, it is meant to be subclassed. A subclass that yields HTML output
is provided with C<Apache::CVS::HTML>. Please see L<"SUBCLASSING"> for details
on creating your own subclass.

=head1 CONFIGURATION

Please see C<Apache::CVS::HTML> for some extra configuration parameters specific to HTML display. 

=item CVSRoots

    Location of the CVS Roots.  Set this like you would hash.  This
    variable is required.

    PerlSetVar CVSRoots cvs1=>/path/to/cvsroot1,cvs2=>/path/to/cvsroot2

=item RCSExtension

    File extension of RCS files.  Defaults to ',v'.

    PerlSetVar RCSExtension ,yourextension

=item WorkingDirectory

    A directory to keep temporary files.  Defaults to /var/tmp.
    Apache::CVS will try to clean up after itself and message to the
    error log if it couldn't.

    PerlSetVar WorkingDirectory /usr/tmp

=item BinaryDirectory

    The directory of the rcs binaries.  Defaults to /usr/bin.

    PerlSetVar BinaryDirectory /usr/local/bin

=item DiffStyles

    The different types of diffs you want to provide to users.
    The values will be passed to cvs diff as arguments. If not
    set users will see a unified diff.

    PerlSetVar DiffStyles unified=>ua,side-by-side=>ya

=item DefaultDiffStyle

    The default diff style. The value must be a valid predefined
    DiffStyle.  If not set or set incorrectly Apache::CVS will default to
    the first DiffStyle.

    PerlSetVar DefaultDiffStyle unified

=cut

package Apache::CVS;

use strict;

use Apache::URI();
use Apache::CVS::RcsConfig();
use Apache::CVS::PlainFile();
use Apache::CVS::Directory();
use Apache::CVS::File();
use Apache::CVS::Revision();
use Apache::CVS::Diff();
eval "use Apache::CVS::Graph();";
if ($@) {
    $Apache::CVS::Graph = 0;
} else {
    $Apache::CVS::Graph = 1;
}

$Apache::CVS::VERSION = '0.10';

=head1 SUBCLASSING

Override any or all of the following to customize the display.
Some of these method will take a $uri_base as an argument. It is the URI for
the current item that is being displayed. For example, if a directory is
being displayed, the base URI is the URI to that directory. If a revision is
being displayed, the base URI is the URI to that file.

=over 4

=item $self->print_http_header()

Prints the HTTP headers. If you override this you should set the
http_headers_sent flag with $self->http_headers_sent(1).

=cut

sub print_http_header {
    my $self = shift;
    return if $self->http_headers_sent();
    $self->request()->content_type($self->content_type());
    $self->request()->send_http_header;
    $self->http_headers_sent(1);
}

=item print_error

This method takes a string that contains the error.

=cut

sub print_error {
    return;
}

=item print_page_header

No arguments. If you override this you should set the page_headers_sent flag
with $self->page_headers_sent().

=cut

sub print_page_header {
    return;
}

=item print_page_footer

No arguments.

=cut

sub print_page_footer {
    return;
}

=item print_root_list_header

No arguments.

=cut

sub print_root_list_header {
    return;
}

=item print_root

A root as a string, defined by your CVSRoots configuration.

=cut

sub print_root {
    return;
}

=item print_root_list_footer

No arguments.

=cut

sub print_root_list_footer {
    return;
}

=item print_directory_list_header

Takes a base uri, the sort criterion, and the sort direction (1 for ascending).
Overriding method should check B<file_sorting_available()> to see if sorting
controls should be provided.

=cut

sub print_directory_list_header {
    return;
}

=item print_directory

Takes a base uri, an Apache::CVS::Directory object, and a row number.

=cut

sub print_directory {
    return;
}

=item print_file

Takes a base uri, an Apache::CVS::File object, and a row number.

=cut

sub print_file {
    return;
}

=item sort_files

Takes a reference to a list of Apache::CVS::Files, a criterion, and a sort
direction (1 for ascending). This is called before printing.

=cut

sub sort_files {
    return $_[1]
}

=item print_plain_file

Takes a base uri, an Apache::CVS::PlainFile object, and a row number.

=cut

sub print_plain_file {
    return;
}

=item print_directory_list_footer

No arguments.

=cut

sub print_directory_list_footer {
    return;
}

=item print_file_list_header

Takes a base uri, the sort criterion, and the sort direction (1 for ascending).
Overriding method should check B<revision_sorting_available()> to see if sorting
controls should be provided.

=cut

sub print_file_list_header {
    return;
}

=item print_revision

Takes a base uri, an Apache::CVS::Revision object, a row number  and the
revision number of a revision that has been selected for diffing, if such
exists.

=cut

sub print_revision {
    return;
}

=item sort_revisions

Takes a reference to a list of Apache::CVS::Revisions and a sort criterion.
This is called before sorting.

=cut

sub sort_revisions {
    return $_[1];
}

=item print_file_list_footer

No arguments.

=cut

sub print_file_list_footer {
    return;
}

=item print_text_revision

Takes the content of the revision as a string.

=cut

sub print_text_revision {
    return;
}

=item print_diff

Takes an Apache::CVS::Diff object and a base uri.

=cut

sub print_diff {
    return;
}

=item print_graph

Takes a base uri and an Apache::CVS::Graph object. Only avaiable if built with
--graph passed to Makefile.PL.

=cut

sub print_graph {
    return;
}

=back

=head1 OBJECT METHODS

Here are some other methods that might be useful.

=over 4

=cut

sub _get_roots {
    my $request = shift;
    my %cvsroots = split /\s*(?:=>|,)\s*/, $request->dir_config('CVSRoots');
    return \%cvsroots;
}

sub _get_rcs_config {
    my $request = shift;
    return Apache::CVS::RcsConfig->new($request->dir_config('RCSExtension'),
                                       $request->dir_config('WorkingDirectory'),
                                       $request->dir_config('BinaryDirectory'));
}

sub _get_diff_styles {
    my $request = shift;
    my %styles = split /\s*(?:=>|,)\s*/, $request->dir_config('DiffStyles');

    # default style
    $styles{unified} = 'ua' unless scalar keys %styles;
    return \%styles;
}

sub _get_default_diff_style {
    my $request = shift;
    my $styles = shift;
    my $default = $request->dir_config('DefaultDiffStyle');

    # if directive not set or style is not set up then grab a style
    # from the list
    unless ($default && exists($styles->{$default})) {
        if (scalar keys %{ $styles} == 1) {
            # if there is only one style we can stop here
            $default = (keys %{ $styles})[0];
        } else {
            # otherwise parse the DiffStyles directive for the first style
            $request->dir_config('DiffStyles') =~ /([^\s=,]*)/;
            $default = $1;
        }
    }
    # we absolutely must have a valid default, so we should check our
    # work
    unless (exists(${$styles}{$default})) {
        # alright, so we screwed up somewhere, fallback to the first
        # style
        $default = (keys %{ $styles})[0];
    }
    return $default;
}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $request = shift;
    my $self;

    $self->{request} = $request;
    $self->{rcs_config} = _get_rcs_config($self->{request});
    $self->{roots} = _get_roots($self->{request});
    $self->{content_type} = 'text/html';
    $self->{http_headers_sent} = 0;
    $self->{page_headers_sent} = 0;
    $self->{current_root} = undef;
    $self->{path} = undef;
    $self->{diff_styles} = _get_diff_styles($self->{request});
    $self->{default_diff_style} =
        _get_default_diff_style($self->{request}, $self->{diff_styles});
    $self->{file_sorting_available} = 0;
    $self->{revision_sorting_available} = 0;
    bless ($self, $class);
    return $self;
}

=item $self->request()

Returns the Apache request object.

=cut

sub request {
    my $self = shift;
    $self->{request} = shift if scalar @_;
    return $self->{request};
}

=item $self->rcs_config()

Returns the C<Apache::CVS:RcsConfig> object that holds the Rcs configuration.

=cut

sub rcs_config {
    my $self = shift;
    return $self->{rcs_config};
}

=item $self->content_type()

Set or get the content_type.

=cut

sub content_type {
    my $self = shift;
    $self->{content_type} = shift if scalar @_;
    return $self->{content_type};
}

=item $self->http_headers_sent()

Set or get this flag which indicates if the HTTP have been sent or not.

=cut

sub http_headers_sent {
    my $self = shift;
    $self->{http_headers_sent} = shift if scalar @_;
    return $self->{http_headers_sent};
}

=item $self->page_headers_sent()

Set or get this flag which indicates if the page headers have been sent or not.

=cut

sub page_headers_sent {
    my $self = shift;
    $self->{page_headers_sent} = shift if scalar @_;
    return $self->{page_headers_sent};
}

=item $self->path()

Set or get the path of to the file or directory requested.

=cut

sub path {
    my $self = shift;
    if (scalar @_) {
        $self->{path} = shift;
        my $real_file_path = $self->{path} . $self->rcs_config()->extension();
        unless (-d $self->{path}  || -r $real_file_path) {
            die "File or directory ($self->{path} or $real_file_path) does " .
                "not exist.";
        }
    }

    return $self->{path};
}

=item $self->current_root()

Set or get the CVS Root of the files being requested.

=cut

sub current_root {
    my $self = shift;
    $self->{current_root} = shift if scalar @_;
    return $self->{current_root};
}

=item $self->roots()

Returns the configured CVS Roots as a hash references.

=cut

sub roots {
    my $self = shift;
    return $self->{roots};
}

=item $self->diff_styles()

Returns the different styles of diff that will be available.

=cut

sub diff_styles {
    my $self = shift;
    $self->{diff_styles} = shift if scalar @_;
    return $self->{diff_styles};
}

=item $self->default_diff_style()

Returns the default diff styles.

=cut

sub default_diff_style {
    my $self = shift;
    $self->{default_diff_style} = shift if scalar @_;
    return $self->{default_diff_style};
}   

=item $self->current_root_path()

Returns the path of the CVS Root of the files being requested.
This is equivalent to $self->roots()->{$self->current_root()}.

=cut

sub current_root_path {
    my $self = shift;
    return $self->roots()->{$self->current_root()};
}

=item $self->file_sorting_available()

Returns true if file sorting (in a directory) is implemented. Subclasses must 
set this to true or false where as necessary.

=cut

sub file_sorting_available {
    my $self = shift;
    $self->{file_sorting_available} = shift if scalar @_;
    return $self->{file_sorting_available};
}

=item $self->revision_sorting_available()

Returns true if revision sorting (in a file) is implemented. Subclasses must 
set this to true or false where as necessary.

=cut

sub revision_sorting_available {
    my $self = shift;
    $self->{revision_sorting_available} = shift if scalar @_;
    return $self->{revision_sorting_available};
}

=back

=cut

sub handle_root {
     my $self = shift;
     $self->print_root($_) foreach ( keys %{ $self->roots()} );
 }

sub handle_directory {
    my $self = shift;
    my $row_counter = 0;
    my ($uri_base, $sort_criterion, $sort_direction) = @_;
    $self->print_directory_list_header($uri_base, $sort_criterion,
                                       $sort_direction);
    my $directory = Apache::CVS::Directory->new($self->path(),
                                                $self->rcs_config());
    $directory->load();
    foreach ( @{ $directory->directories() } ) {
        $self->print_directory($uri_base, $_, $row_counter);
        $row_counter++;
    }

    my $sorted_files = $directory->files();
    if ($self->file_sorting_available()) {
        $sorted_files = $self->sort_files($directory->files(), $sort_criterion,
                                          $sort_direction);
    }
    foreach ( @{ $sorted_files } ) {
        $self->print_file($uri_base, $_, $row_counter);
        $row_counter++;
    }

    foreach ( @{ $directory->plain_files() } ) {
        $self->print_plain_file($_);
        $row_counter++;
    }
    $self->print_directory_list_footer();
}

sub handle_file {
    my $self = shift;
    my ($uri_base, $diff_revision, $sort_criterion, $sort_direction) = @_;
    my $file = Apache::CVS::File->new($self->path(), $self->rcs_config());
    my $row_counter = 0;

    $uri_base .= $file->name();
    $self->print_file_list_header($uri_base, $sort_criterion, $sort_direction);

    # if sorting available, go with new behavior
    if ($self->revision_sorting_available()) {
        my $sorted_revisions = $self->sort_revisions($file->revisions(),
                                                     $sort_criterion,
                                                     $sort_direction);
        foreach ( @{ $sorted_revisions }) {
            $self->print_revision($uri_base, $_, $row_counter, $diff_revision);
            $row_counter++;
        }
    # otherwise, just use old behavior where we iterate through revisions
    } else {
        while ( my $revision = $file->revision('prev') ) {
            $self->print_revision($uri_base, $revision, $row_counter,
                                  $diff_revision);
            $row_counter++;
        }
    }
    $self->print_file_list_footer();
}

sub handle_revision {
    my $self = shift;
    my ($uri_base, $revision_num) = @_;
    
    my $file = Apache::CVS::File->new($self->path(), $self->rcs_config());
    my $revision = $file->revision($revision_num);

    eval {
        if ($revision->is_binary()) {
            my $subrequest =
                $self->request()->lookup_file($revision->co_file());
            $self->content_type($subrequest->content_type);
            $self->print_http_header();
            $self->request()->send_fd($revision->filehandle());
            close $revision->filehandle();
        } else {
            $self->print_http_header();
            $self->print_page_header();
            $self->print_text_revision($revision->content());
        }
    };
    if ($@) {
        $self->request()->log_error($@);
        $self->print_error("Unable to get revision.\n$@");
        return;
    }
}

sub handle_diff {
    my $self = shift;
    my ($source_version, $target_version, $diff_style, $uri_base) = @_;

    my $file = Apache::CVS::File->new($self->path(), $self->rcs_config());
    my $source = $file->revision($source_version);
    my $target = $file->revision($target_version);
    $diff_style ||= $self->default_diff_style();
    my $diff = Apache::CVS::Diff->new($source, $target,
                                      $self->diff_styles()->{$diff_style});
    $self->print_diff($diff, $uri_base . $file->name());
}

sub handle_graph {
    return unless $Apache::CVS::Graph;
    my $self = shift;
    my $uri_base = shift;
    my $file = Apache::CVS::File->new($self->path(), $self->rcs_config());
    my $graph = Apache::CVS::Graph->new($file);
    $self->print_graph($uri_base, $file->name(), $graph);
}

sub handler_internal {
    my $self = shift;

    my $path_info = $self->request()->path_info;

    my $is_real_root = 1 unless ( $path_info and $path_info ne '/' );

    if ( $is_real_root ) {

        $self->print_http_header();
        $self->print_page_header();
        $self->handle_root();
        return;
    }

    # strip off the cvs root id from the front
    $path_info =~ s#/([^/]+)/?##;
    $self->current_root($1);

    # determine current path
    my $is_cvsroot;
    unless ( $path_info and $path_info ne '/' ) {

        $self->path($self->current_root_path());
        $is_cvsroot = 1;
    } else {

        $self->path($self->current_root_path() . q(/) .  $path_info);
    }

    my %query = $self->request()->args;
    my $is_revision = exists $query{'r'};

    my $uri_base = $self->request()->parsed_uri->rpath() . q(/) .
                   $self->current_root() . q(/) .  $path_info;

    if ( -d $self->path() ) {

        $self->print_http_header();
        $self->print_page_header();
        $uri_base .= q(/) unless $uri_base =~ /\/$/;
        $self->handle_directory($uri_base, $query{'o'}, $query{'asc'});
    } else {

        $uri_base =~ s/[^\/]*$//;

        my %query = $self->request()->args;
        if ( $query{'ds'} && $query{'dt'} ) {
            $self->print_http_header();
            $self->print_page_header();
            $self->handle_diff($query{'ds'}, $query{'dt'}, $query{'dy'},
                               $uri_base);
        } elsif ( $is_revision ) {
            $self->handle_revision($uri_base, $query{'r'});
        } elsif ( $Apache::CVS::Graph and exists($query{'g'}) ) {
            $self->print_http_header();
            $self->print_page_header();
            $self->handle_graph($uri_base, $query{'r'});
        } else {
            $self->print_http_header();
            $self->print_page_header();
            $self->handle_file($uri_base, $query{'ds'}, $query{'o'},
                               $query{'asc'});
        }
    }
}

sub handler($$) {

    my ($self, $request) = @_;

    delete $ENV{'PATH'};

    $self = $self->new($request) unless ref $self;

    eval {
        $self->handler_internal();
    };

    if ($@) {
        $self->request()->log_error($@);
        $self->print_error($@);
    }
}

=head1 SEE ALSO

L<Apache::CVS::HTML>, L<Rcs>

=head1 AUTHOR

John Barbee <F<barbee@veribox.net>>

=head1 COPYRIGHT

Copyright 2001-2002 John Barbee

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
