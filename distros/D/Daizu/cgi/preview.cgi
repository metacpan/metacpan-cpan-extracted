#!/usr/bin/perl
# TODO - update libdatetime-format-builder-perl to latest version to avoid taint mode problems, and put -T back
use warnings;
use strict;

=head1 NAME

preview.cgi - dynamic preview of Daizu output

=head1 DESCRIPTION

The I<cgi/preview.cgi> script distributed with Daizu
generates content using Daizu generator classes in exactly the same way as
it would be if you were publishing it, and then presents it to your browser.
However, for HTML and CSS content it also adjusts any links it can find
to point to the preview versions of them, so you can use it to look at
a whole website as it will appear when published.

Currently this makes it useful for testing changes to templates, but not
much else.  It will be a lot more useful when Daizu allows content to be
edited in the database.

To use it, set up Apache to run CGI scripts and make sure that the script
can find the Daizu configuration file and Daizu libraries.  You might
need to add some settings to the Apache configuration like this:

=for syntax-highlight apache

   SetEnv PERL5LIB /.../Daizu/lib
   SetEnv DAIZU_CONFIG /.../config.xml

Once it's up and running you should be able to load I<preview.cgi> in
your browser, without any arguments.  It will try to find and URLs which
look like the homepages of websites, and give you links to them so that
you can start testing your site.

If you request a preview of a URL which would be a redirect or is marked
'gone', then this script will show you information about the URL rather
than actually redirecting you.

=head1 PARAMETERS

This CGI script accepts two parameters in its query string, which you
can adjust by hand if necessary:

=over

=item url

The full URL of the page (or other file) you wish to preview.
Without this the script will show you an introductory page.

=item wc

The ID number of the working copy you wish to preview content from.
You can set this by hand if you want to preview a working copy on a
branch (if you're making large-scale changes to your site and want to
keep the changes from going live until they're all finished).

Defaults to the live working copy.

If not the default value then the value will be preserved in any links
you follow on the pages you're previewing.

=back

=cut

use CGI qw( param );
use CGI::Carp;
use Carp::Assert qw( assert DEBUG );
use Encode qw( encode );
use Daizu;
use Daizu::HTML qw(
    html_escape_text
);
use Daizu::Preview qw( output_preview script_link );
use Daizu::Util qw(
    db_row_exists db_row_id db_select
);

my $cms = Daizu->new;
do_everything($cms);
if ($@) {
    my $error = encode('UTF-8', $@);
    return_page($cms, undef, 'Error', qq{
        <p class="Error">Something went wrong:<br>
         $error
        </p>
    });
}

sub do_everything
{
    my ($cms) = @_;

    my $wc_id = param('wc');
    if (defined $wc_id && $wc_id =~ /^(\d+)$/) {
        $wc_id = $1;
    }
    else {
        $wc_id = $cms->{live_wc_id};
    }
    unless (db_row_exists($cms->db, working_copy => $wc_id)) {
        return_page($cms, undef, 'No working copy', qq{
            <p class="Error">Error: working copy $wc_id does not exist.</p>
        });
    }

    my $url = param('url');
    if ($url) {
        do_url_preview($cms, $wc_id, $url);
    }
    else {
        do_intro_page($cms, $wc_id);
    }
}

sub do_intro_page
{
    my ($cms, $wc_id) = @_;

    # Get the URLs which are the most likely to be homepages.  They are
    # the shortest ones which don't have a shorter one as a prefix.
    # I can't think of any SQL to do this reliably without looking through
    # the whole lot.
    my $sth = $cms->db->prepare(q{
        select url
        from url
        where wc_id = ?
          and status = 'A'
          and content_type like 'text/%'
        order by length(url);
    });
    $sth->execute($wc_id);

    my @homepage;
    while (my ($url) = $sth->fetchrow_array) {
        if (!@homepage) {
            # First one must be a homepage.
            push @homepage, $url;
        }
        else {
            my $found;
            for (@homepage) {
                next unless substr($url, 0, length $_) eq $_;
                $found = 1;
                last;
            }

            push @homepage, $url
                unless $found;
        }
    }

    if (!@homepage) {
        return_page($cms, $wc_id, 'No URLs', q{
            <p class="Error">There aren't any URLs in this working copy.</p>
        });
    }
    else {
        my $list = '';
        for (@homepage) {
            my $url = html_escape_text($_);
            my $link = script_link($cms, $wc_id, url => $_);
            $list .= qq{<li><a href="$link">$url</a></li>\n};
        }

        return_page($cms, $wc_id, 'Homepage URLs', qq{
            <p>You need to provide a URL to preview.  You can do so
             by adding a <code>url</code> query parameter to this
             CGI script.</p>
            <p>The following URLs look like homepages which might
             be a good starting point for you to preview:</p>
            <ul>\n$list</ul>
        });
    }
}

sub do_url_preview
{
    my ($cms, $wc_id, $url) = @_;

    my ($guid_id, $gen_class, $method, $argument, $type, $status, $redir_id) =
        db_select($cms->db,
            url => { wc_id => $wc_id, url => $url },
            qw( guid_id generator method argument
                content_type status redirect_to_id ),
        );

    if (!defined $guid_id) {
        my $esc_url = html_escape_text($url);
        return_page($cms, $wc_id, 'URL not found', qq{
            <p class="Error">This URL was not found in this working copy:<br>
             <code>$esc_url</code></p>
        });
    }

    if ($status eq 'G') {
        my $url_info = url_info_html($cms, $wc_id, $url);
        return_page($cms, $wc_id, 'URL not found', qq{
            <p>This URL was once active, but is now marked
             &#8216;gone&#8217;.</p>
            $url_info
            <p>A gone URL usually results from its file being deleted, but
             can also occur if a file's URL changed and the new URL was
             not of the same kind (different generator class, method, or
             argument) so that a redirect would be inappropriate.</p>
        });
    }

    if ($status eq 'R') {
        my ($redir_url) = db_select($cms->db, url => $redir_id, 'url');
        my $link = script_link($cms, $wc_id, url => $redir_url);
        $redir_url = html_escape_text($redir_url);
        my $url_info = url_info_html($cms, $wc_id, $url);
        return_page($cms, $wc_id, 'URL not found', qq{
            <p>This URL was once active, but should now redirect to here:
             <a href="$link"><code>$redir_url</code></a></p>
            $url_info
        });
    }

    my ($file_id) = db_row_id($cms->db, 'wc_file',
        wc_id => $wc_id, guid_id => $guid_id,
    );
    die "URL '$url' marked active, but it's content no longer exists\n"
        unless defined $file_id;
    my $file = Daizu::File->new($cms, $file_id);

    my $generator = $file->generator;
    die "generator '$gen_class' for '$url' is missing method '$method'\n"
        unless $generator->can($method);
    print "Content-Type: $type\n\n";
    output_preview($cms, $url, $file, $generator, $method, $argument, $type,
                   \*STDOUT);
    exit;
}

sub return_page
{
    my ($cms, $wc_id, $title, $content) = @_;

    my $wc_info = '';
    if (defined $wc_id) {
        $wc_info = "<hr>\n<p><small>Current working copy: $wc_id";
        $wc_info .= ' (live working copy)'
            if $wc_id == $cms->{live_wc_id};
        $wc_info .= "<br>\n";

        my ($cur_revnum, $branch_path) = $cms->db->selectrow_array(q{
            select wc.current_revision, b.path
            from working_copy wc
            inner join branch b on b.id = wc.branch_id
            where wc.id = ?
        }, undef, $wc_id);
        $branch_path = html_escape_text($branch_path);
        $wc_info .= "Current revision: $cur_revnum<br>\n" .
                    "Branch path: $branch_path</p>\n";
    }

    $title = html_escape_text($title);

    print "Content-Type: text/html\n\n";
    print <<"EOF";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
 <head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
  <title>$title</title>
  <style type="text/css">
   .Error {
       border: 2px solid red;
       padding: 1ex;
   }
  </style>
 </head>
 <body>
  <h1>$title</h1>
  $content
  $wc_info
 </body>
</html>
EOF
    exit;
}

sub url_info_html
{
    my ($cms, $wc_id, $url) = @_;

    my $url_info = $cms->{db}->selectrow_hashref(q{
        select *
        from url
        where url = ?
    }, undef, $url);
    assert(defined $url_info) if DEBUG;

    my ($file_id, $file_path) = $cms->{db}->selectrow_array(q{
        select id, path
        from wc_file
        where wc_id = ?
          and guid_id = ?
    }, undef, $wc_id, $url_info->{guid_id});
    my $file_html;
    if (defined $file_id) {
        $file_html =
            " <dt>Current file</dt>\n" .
            " <dd>$file_id, " . html_escape_text($file_path) . "</dd>\n";
    }
    else {
        $file_html =
            " <dt>Current file</dt>\n" .
            " <dd>Doesn't exist</dd>\n";
    }

    my $argument_html = '';
    if ($url_info->{argument} ne '') {
        $argument_html =
            " <dt>Argument</dt>\n" .
            " <dd>" . html_escape_text($url_info->{argument}) . "</dd>\n";
    }
    my $html = "<dl>\n" .
        " <dt><acronym>URL</acronym></dt>\n" .
        " <dd>" . html_escape_text($url_info->{url}) . "</dd>\n" .
        " <dt><acronym>GUID</acronym> <acronym>ID</acronym></dt>\n" .
        " <dd>$url_info->{guid_id}</dd>\n" .
        " <dt>Generator</dt>\n" .
        " <dd>" . html_escape_text($url_info->{generator}) . "</dd>\n" .
        " <dt>Method</dt>\n" .
        " <dd>" . html_escape_text($url_info->{method}) . "</dd>\n" .
        $argument_html .
        " <dt>Content type</dt>\n" .
        " <dd>" . html_escape_text($url_info->{content_type}) . "</dd>\n" .
        " <dt>Status</dt>\n" .
        " <dd>" . html_escape_text($url_info->{status}) . "</dd>\n" .
        $file_html .
        "</dl>\n";
}

=head1 COPYRIGHT

This software is copyright 2006 Geoff Richards E<lt>geoff@laxan.comE<gt>.
For licensing information see this page:

L<http://www.daizucms.org/license/>

=cut

# vi:ts=4 sw=4 expandtab
