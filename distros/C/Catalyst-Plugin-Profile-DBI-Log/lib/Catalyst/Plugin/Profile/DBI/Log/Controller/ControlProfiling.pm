# ABSTRACT: Control profiling within your application
package Catalyst::Plugin::Profile::DBI::Log::Controller::ControlProfiling;

our $VERSION = '0.03'; # VERSION (maintained by DZP::OurPkgVersion)
#
use Moose;
use Path::Tiny qw(path);
use namespace::autoclean;

use File::stat;
use HTML::Entities;
use JSON;

BEGIN { extends 'Catalyst::Controller' }
 

# Read the configured output dir, falling back to the default.
# The plugin sets this in setup_finalize; we read it from the app config.
sub _dbilog_output_dir {
    my $self = shift;
    my $c = ref($_[-1]) && $_[-1]->isa('Catalyst::Context') ? pop : undef;
    my $conf = $c ? $c->config->{'Plugin::Profile::DBI::Log'} : {};
    return $conf->{dbilog_out_dir} || 'dbilog_output';
}

sub _css {
    return <<'CSS';
* { box-sizing: border-box; margin: 0; padding: 0; }
body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    background: #f0f2f5;
    color: #1a1a2e;
    line-height: 1.6;
    padding: 2rem;
}
.container { max-width: 1200px; margin: 0 auto; }
h1 {
    font-size: 1.6rem;
    font-weight: 700;
    margin-bottom: 1.5rem;
    color: #16213e;
}
a { color: #0066cc; text-decoration: none; }
a:hover { text-decoration: underline; }
.table-wrap {
    background: #fff;
    border-radius: 8px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.08);
    overflow-x: auto;
}
table { width: 100%; border-collapse: collapse; font-size: 0.85rem; }
th {
    background: #e8edf2;
    font-weight: 600;
    text-align: left;
    padding: 0.75rem 1rem;
    color: #444;
    border-bottom: 2px solid #d0d7de;
    white-space: nowrap;
}
td {
    padding: 0.6rem 1rem;
    border-bottom: 1px solid #eef0f3;
    vertical-align: top;
}
tr:hover td { background: #f6f8fa; }
.method {
    display: inline-block;
    padding: 2px 8px;
    border-radius: 4px;
    font-weight: 700;
    font-size: 0.75rem;
    letter-spacing: 0.5px;
}
.method-GET    { background: #dafbe1; color: #116329; }
.method-POST   { background: #ddf4ff; color: #0550ae; }
.method-PUT    { background: #fff8c5; color: #7d5a00; }
.method-PATCH  { background: #fff1e5; color: #953800; }
.method-DELETE { background: #ffebe9; color: #82071e; }
.query-path { font-weight: 600; }
.query-string {
    color: #6e7781;
    cursor: pointer;
    display: inline-block;
    max-width: 400px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    vertical-align: bottom;
}
.query-string:hover { color: #0066cc; }
.stat { font-variant-numeric: tabular-nums; }
.view-btn {
    display: inline-block;
    padding: 3px 10px;
    background: #0066cc;
    color: #fff !important;
    border-radius: 4px;
    font-size: 0.8rem;
    font-weight: 500;
}
.view-btn:hover { background: #0052a3; text-decoration: none; }
.summary-cards {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
    margin-bottom: 1.5rem;
}
.summary-row {
    display: flex;
    gap: 0.75rem;
}
.summary-row > .card:first-child { flex: 3; }
.summary-row > .card:last-child { flex: 1; }
.card {
    background: #fff;
    border-radius: 8px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.08);
    padding: 1rem 1.5rem;
    flex: 1;
}
.card-label { font-size: 0.75rem; color: #6e7781; text-transform: uppercase; letter-spacing: 0.5px; }
.card-value { font-size: 1.4rem; font-weight: 700; color: #16213e; }
.query-table td:first-child { max-width: 500px; }
.query-table pre {
    margin: 0;
    white-space: pre-wrap;
    word-break: break-word;
    font-size: 0.8rem;
    line-height: 1.5;
    background: #f6f8fa;
    padding: 0.5rem;
    border-radius: 4px;
}
.stack-trace { color: #6e7781; font-size: 0.8rem; }
.back-link { display: inline-block; margin-bottom: 1rem; color: #0066cc; }
.empty-state {
    text-align: center;
    padding: 3rem;
    color: #6e7781;
    background: #fff;
    border-radius: 8px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.08);
}
CSS
}


sub index : Local {
    my ($self, $c) = @_;
    my $dbilog_output_dir = $self->_dbilog_output_dir($c);
    my $css = $self->_css;

    opendir my $outdir, $dbilog_output_dir
        or do {
            $c->response->status(500);
            $c->response->body("Failed to open $dbilog_output_dir: $!");
            return;
        };
    my @files = grep { $_ !~ /^(\.|html)/ } readdir $outdir;

    my @rows;
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
        my $stats = get_stats(path($dbilog_output_dir, $file));
        next file unless $stats->{query_count};

        my $datetime = scalar localtime( (stat path($dbilog_output_dir, $file))->ctime);
        my $path = format_path($stats->{path_query});
        my $method = HTML::Entities::encode_entities($stats->{method});
        my $file_enc = HTML::Entities::encode_entities($file);

        push @rows, <<ROW;
<tr>
<td><span class="method method-$method">$method</span></td>
<td>$path</td>
<td class="stat">@{[ HTML::Entities::encode_entities($stats->{total_query_time}) ]}s</td>
<td class="stat">@{[ HTML::Entities::encode_entities($stats->{slowest_query}) ]}s</td>
<td class="stat">@{[ HTML::Entities::encode_entities($stats->{query_count}) ]}</td>
<td>@{[ HTML::Entities::encode_entities($datetime) ]}</td>
<td>@{[ HTML::Entities::encode_entities($stats->{ip}) ]}</td>
<td><a href="/dbi/log/show/$file_enc" class="view-btn">View</a></td>
</tr>
ROW
    }

    my $table_body = @rows
        ? join("\n", @rows)
        : '<tr><td colspan="8" class="empty-state">No profiled requests found.</td></tr>';

    my $html = <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>DBI::Log Profiled Requests</title>
<style>$css</style>
</head>
<body>
<div class="container">
<h1>DBI::Log &mdash; Profiled Requests</h1>
<div class="table-wrap">
<table>
<thead>
<tr>
<th>Method</th>
<th>Path</th>
<th>Total Query Time</th>
<th>Slowest Query</th>
<th>Queries</th>
<th>Datetime</th>
<th>IP</th>
<th></th>
</tr>
</thead>
<tbody>
$table_body
</tbody>
</table>
</div>
</div>
</body>
</html>
HTML

    $c->response->body($html);
    $c->response->status(200);
}


# Turn URL path into HTML to display the path part before the query more
# prominently, and potentially truncate long query strings. 
sub format_path {
    my $in = shift;
    my ($path, $query) = split /\?/, $in, 2;
    my $out = qq{<span class="query-path">$path</span>};
    if ($query) {
        my $reveal_js;
        my $title_attr = qq{title="@{[ HTML::Entities::encode_entities($query) ]}"};
        my $display_query = $query;
        if (length $query > 100) {
            $display_query = substr($query, 0, 100) . "...";
            my $js_safe = $query;
            $js_safe =~ s{\\}{\\\\}g;
            $js_safe =~ s{"}{&quot;}g;
            $js_safe =~ s{\n}{\\n}g;
            $js_safe =~ s{\r}{\\r}g;
            $reveal_js = qq{onclick="this.textContent = \\"$js_safe\\"" };
        }
        $display_query = HTML::Entities::encode_entities($display_query);

        $out .= qq{?<span class="query-string" ${reveal_js}${title_attr}>$display_query</span>};
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
    my $dbilog_output_dir = $self->_dbilog_output_dir($c);

    # Guard against path traversal attempts
    if ($profile =~ m{(\.\.|/|\\)}) {
        $c->response->status(400);
        $c->response->body("Invalid profile name");
        return;
    }

    my (undef, $path) = split '_', $profile, 4;

    my $profile_path = Path::Tiny::path(
        $dbilog_output_dir,
        $profile
    );
    my $datetime = scalar localtime($profile_path->stat->ctime);

    my $stats = get_stats($profile_path);

    # It makes sense for GET request URLs to be clickable - not so much for
    # PUT/POST, so work it out:
    my $encoded_path_query = HTML::Entities::encode_entities($stats->{path_query});
    my $path_maybe_link = $stats->{method} eq 'GET'
        ? qq{<a href="$encoded_path_query">$encoded_path_query</a>}
        : $encoded_path_query;

    my $method = HTML::Entities::encode_entities($stats->{method});
    my $css = $self->_css;

    my @query_rows;
    for my $json_line ($profile_path->lines) {
        my $data = JSON::from_json($json_line);

        my $first_frame = (
            grep {
                $_->{file} !~ m{(DBIx/Class|Try/Tiny|Context/Preserve)}
            } @{ $data->{stack} }
        )[-1];

        my $stack_summarised = sprintf "%s @ %s L%d",
            @$first_frame{qw(sub file line)};

        push @query_rows, <<ROW;
<tr>
<td><pre class="query">@{[ HTML::Entities::encode_entities($data->{query}) ]}</pre></td>
<td class="stat">@{[ HTML::Entities::encode_entities($data->{time_taken}) ]}</td>
<td class="stack-trace">@{[ HTML::Entities::encode_entities($stack_summarised) ]}</td>
</tr>
ROW
    }

    my $query_count = scalar @query_rows;

    my $html = <<"HTML";
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>DBI::Log &mdash; $method $path</title>
<style>$css</style>
<script src="https://unpkg.com/jquery\@3.7.1/dist/jquery.min.js"></script>
<script src="https://unpkg.com/sql-formatter\@2.6.3/dist/sql-formatter.min.js"></script>
</head>
<body>
<div class="container">
<a href="/dbi/log/index" class="back-link">&larr; Back to all requests</a>
<h1>DBI::Log &mdash; Request Detail</h1>

<div class="summary-cards">
<div class="summary-row">
<div class="card">
<div class="card-label">Request</div>
<div class="card-value"><span class="method method-$method">$method</span> $path_maybe_link</div>
</div>
<div class="card">
<div class="card-label">Recorded</div>
<div class="card-value" style="font-size:1rem">@{[ HTML::Entities::encode_entities($datetime) ]}</div>
</div>
</div>
<div class="summary-row">
<div class="card">
<div class="card-label">Total DB Time</div>
<div class="card-value">@{[ HTML::Entities::encode_entities($stats->{total_query_time}) ]}s</div>
</div>
<div class="card">
<div class="card-label">Queries</div>
<div class="card-value">$query_count</div>
</div>
</div>
</div>

<div class="table-wrap">
<table class="query-table">
<thead>
<tr>
<th>Query</th>
<th>Took</th>
<th>Stack</th>
</tr>
</thead>
<tbody>
@{[ join("\n", @query_rows) ]}
</tbody>
</table>
</div>
</div>

<script>
\$('.query').each(function (i) {
    let formatted = sqlFormatter.format(\$(this).text(), { language: 'postgresql' });
    \$(this).text( formatted );
});
</script>
</body>
</html>
HTML

    $c->response->body($html);


}

sub generate_stack_trace_html {
    my $stack_data = shift;

    my $html = <<STACKTRACETABLESTART;

<h2>Stack trace</h2>

<table class="query-table">
<thead>
<tr>
<th>File</th>
<th>Line</th>
<th>Sub</th>
</tr>
</thead>
<tbody>
STACKTRACETABLESTART

    for my $frame (@{ $stack_data }) {
        $html .= <<STACKROW;
<tr>
<td>@{[ HTML::Entities::encode_entities($frame->{file}) ]}</td>
<td class="stat">@{[ HTML::Entities::encode_entities($frame->{line}) ]}</td>
<td class="stack-trace">@{[ HTML::Entities::encode_entities($frame->{sub}) ]}</td>
</tr>
STACKROW
    }

    $html .= "</tbody></table>";

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
