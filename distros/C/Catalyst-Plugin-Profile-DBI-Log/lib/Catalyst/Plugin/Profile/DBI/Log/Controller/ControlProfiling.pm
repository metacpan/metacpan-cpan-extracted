# ABSTRACT: Control profiling within your application
package Catalyst::Plugin::Profile::DBI::Log::Controller::ControlProfiling;

our $VERSION = '0.02'; # VERSION (maintained by DZP::OurPkgVersion)
#
use Moose;
use Path::Tiny qw(path);
use namespace::autoclean;

use File::stat;
use HTML::Entities;
 
BEGIN { extends 'Catalyst::Controller' }
 

# FIXME: how am I going to share this from the Catalyst::Plugin plugin code
# to this controller code nicely?  Need both to get default values and be
# able to override in app config
my $dbilog_output_dir = 'dbilog_output';


sub index : Local {
    my ($self, $c) = @_;
    # ICK ICK ICK, get this in a nice template
    my $html = <<HTML;
<h1>DBI::Log management</h1>

<style>
table {
  border-collapse: collapse;
  font-size: 11px;
  font-family: Source Code Pro, monospace;
}
table td {
    padding: 3px;
}
</style>

<h2>Profiled requests...</h2>

<table border="1" cellspacing="5">
<tr>
<th>Method</th>
<th>Path</th>
<th>Total query time</th>
<th>Longest query</th>
<th>Query count</th>
<th>Datetime</th>
<th>IP</th>
<th>View</th>
</tr>
HTML

    opendir my $outdir, $dbilog_output_dir
        or die "Failed to opendir $dbilog_output_dir - $!";
    my @files = grep { $_ !~ /^(\.|html)/ } readdir $outdir;
    file:
    for my $file (
        grep { 
            -s path($dbilog_output_dir, $_) 
        } sort {
            (stat path($dbilog_output_dir, $b))->ctime
            <=>
            (stat path($dbilog_output_dir, $a))->ctime
        } @files
    ) {
        my $title = $file;
        $title =~ s{_s_}{/}g;
        my $stats = get_stats(path($dbilog_output_dir, $file));

        # We delete logs for requests that didn't have any queries at the
        # end of the request, but seemingly that doesn't /always/ happen
        # - so bail now if we don't have any queries to report.
        next file unless $stats->{query_count};

        my $datetime = scalar localtime( (stat path($dbilog_output_dir, $file))->ctime);
        my $path = format_path($stats->{path_query});

        $html .= <<ROW;
<tr><td>$stats->{method}</td><td>$path</td>
<td>$stats->{total_query_time}s</td>
<td>$stats->{slowest_query}s</td>
<td>$stats->{query_count}</td>
<td>$datetime</td>
<td>$stats->{ip}</td>
<td><a href="/dbi/log/show/$file">View</a></td>
</tr>
ROW
    }

    $html .= "</table>";

    $c->response->body($html);
    $c->response->status(200);
}


# Turn URL path into HTML to display the path part before the query more
# prominently, and potentially truncate long query strings. 
sub format_path {
    my $in = shift;
    my ($path, $query) = split /\?/, $in, 2;
    my $out = qq{<span class="path" style="font-weight:bold">$path</span>};
    if ($query) {
        # check if too long
        my $reveal_js;
        my $display_query = $query;
        if (length $query > 100) {
            $display_query = substr($query, 0, 100) . "...";
            # FIXME probably need to be careful here in case the query contains
            # quotes.  Just encode entities first?
            $reveal_js = qq{onclick="this.textContent = '$query'" title="Click to display all"};
        }
        $display_query = HTML::Entities::encode_entities($display_query);
        
        $out .= qq{?<span class="querystring" $reveal_js>$display_query</span>};
    }
    return $out;

}


sub get_stats {
    my $file = shift;
    my @json_lines = path($file)->lines;

    my %stats;
    # The file is line-delimited JSON, where each line is a separate
    # JSON object, so we need to read each line as JSON separately.
    # The first line is our metadata describing the HTTP request which was
    # being processed.
    my $metadata_json = shift @json_lines;
    %stats = %{ JSON::from_json($metadata_json) };

    for my $line (@json_lines) {
        my $line_data = JSON::from_json($line);
        $stats{query_count}++;
        $stats{total_query_time} += $line_data->{time_taken};
        $stats{slowest_query} = $line_data->{time_taken} 
            if $line_data->{time_taken} > $stats{slowest_query};
    }
    return \%stats;
    
}

sub show :Local Args(1) {
    my ($self, $c, $profile) = @_;

    my ($method, $path ,$timestamp, $uuid) = split '_', $profile, 4;

    my $profile_path = Path::Tiny::path(
        $dbilog_output_dir,
        $profile
    );
    my $datetime = scalar localtime($profile_path->stat->ctime);

    my $stats = get_stats($profile_path);

    # It makes sense for GET request URLs to be clickable - not so much for
    # PUT/POST, so work it out:
    my $path_maybe_link = $stats->{method} eq 'GET'
        ? qq{<a href="$stats->{path_query}">$stats->{path_query}</a>}
        : $stats->{path_query};

my $html = <<HTML;

<script type="text/javascript" src="https://unpkg.com/sql-formatter\@latest/dist/sql-formatter.min.js"></script>
<script type="text/javascript" src="https://unpkg.com/jquery"></script>

<h1>DBI log for request $method $path at $datetime</h1>

<p>$stats->{method} $path_maybe_link</p>

<p>Total time querying DB: $stats->{total_query_time}s</p>


<table border="1">
<tr>
<th>Query</th>
<th>Took</th>
<th>Stack</th>
</tr>
HTML

    for my $json_line ($profile_path->lines) {
        my $data = JSON::from_json($json_line);

        # Find first useful line of the stack (knowing about DBIx internals
        # isn't that helpful) 
        # TODO: add a click to view the full stack trace feature.
        my $first_frame = (
            grep {
                $_->{file} !~ m{(DBIx/Class|Try/Tiny|Context/Preserve)}
            } @{ $data->{stack} }
        )[-1];

        my $stack_summarised = sprintf "%s @ %s L%d",
            @$first_frame{qw(sub file line)};

        $html .= <<ROW;
<tr>
<td><pre class="query">$data->{query}</pre></td>
<td>$data->{time_taken}</td>
<td>$stack_summarised</td>
</tr>
ROW
    }

    $html .= <<'END';
</table>

<script>
$('.query').each(function (i) {
    let formatted = sqlFormatter.format($(this).text(), { language: 'postgresql' });
    console.log(`Format ${ $(this).text() } to ${ formatted }`);
    $(this).text( formatted );
});
</script>
END

    $c->response->body($html);


}

sub generate_stack_trace_html {
    my $stack_data = shift;

    my $html .= <<STACKTRACETABLESTART;

<h2>Stack trace</h2>

<table>
<tr>
<th>File</th>
<th>Line</th>
<th>Sub</th>
</tr>

STACKTRACETABLESTART

    for my $frame (@{ $stack_data }) {
        $html .= <<STACKROW;
<tr>
<td>$frame->{file}</td>
<td>$frame->{line}</td>
<td><tt>$frame->{sub}</tt></td>
</tr>
STACKROW
    }

    $html .= "</table>";

    return $html;

}


1;

=head1 NAME

Catalyst::Plugin::Profile::DBI::Log::Controller::ControlProfiling

=head1 DESCRIPTION

Provides the route handlers to list profiled HTTP requests, and
inspect the DB queries they executed.

See the base L<Catalyst::Plugin::Profile::DBI::Log> documentation for
more details.

=head1 AUTHOR

David Precious (BIGPRESH) C<< <davidp@preshweb.co.uk> >>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2024 by David Precious

This library is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut


__END__
