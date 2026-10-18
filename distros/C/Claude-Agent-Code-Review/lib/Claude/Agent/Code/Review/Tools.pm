package Claude::Agent::Code::Review::Tools;

use 5.020;
use strict;
use warnings;

use Claude::Agent qw(tool create_sdk_mcp_server);
use Path::Tiny;
use File::Glob qw(:bsd_glob);

sub create_server {
    my ($class) = @_;

    return create_sdk_mcp_server(
        name    => 'code_review',
        version => '1.0.0',
        tools   => [
            $class->_get_file_context_tool(),
            $class->_search_codebase_tool(),
            $class->_check_tests_tool(),
            $class->_get_dependencies_tool(),
            $class->_analyze_complexity_tool(),
        ],
    );
}

sub _get_file_context_tool {
    return tool(
        'get_file_context',
        'Get surrounding context for a specific line in a file',
        {
            type       => 'object',
            properties => {
                file => {
                    type        => 'string',
                    description => 'File path',
                },
                line => {
                    type        => 'integer',
                    description => 'Line number',
                },
                before => {
                    type        => 'integer',
                    description => 'Lines of context before (default: 5)',
                },
                after => {
                    type        => 'integer',
                    description => 'Lines of context after (default: 5)',
                },
            },
            required => ['file', 'line'],
        },
        sub {
            my ($args) = @_;

            my $file   = $args->{file};
            my $line   = $args->{line};
            my $before = $args->{before} // 5;
            my $after  = $args->{after} // 5;

            my $file_path = path($file);
            unless (-f $file_path) {
                return {
                    content  => [{ type => 'text', text => "File not found: $file" }],
                    is_error => 1,
                };
            }

            my $fh = eval { $file_path->openr_utf8 };
            unless ($fh) {
                return {
                    content  => [{ type => 'text', text => "Cannot open file: $file" }],
                    is_error => 1,
                };
            }

            my $safe_path = eval { $file_path->realpath };
            my $base_dir = path('.')->realpath;
            unless ($safe_path && $base_dir->subsumes($safe_path)) {
                close $fh;
                return {
                    content  => [{ type => 'text', text => "Access denied: $file" }],
                    is_error => 1,
                };
            }

            my @lines = map { chomp; $_ } <$fh>;
            close $fh;
            my $total = scalar @lines;

            my $start = $line - $before - 1;
            my $end   = $line + $after - 1;

            $start = 0 if $start < 0;
            $end = $total - 1 if $end >= $total;

            my @context;
            for my $i ($start .. $end) {
                my $ln = $i + 1;
                my $marker = ($ln == $line) ? '>>>' : '   ';
                push @context, sprintf "%s %4d: %s", $marker, $ln, $lines[$i];
            }

            return {
                content => [{
                    type => 'text',
                    text => join("\n", @context),
                }],
            };
        }
    );
}

sub _search_codebase_tool {
    return tool(
        'search_codebase',
        'Search for patterns across the codebase',
        {
            type       => 'object',
            properties => {
                pattern => {
                    type        => 'string',
                    description => 'Text or pattern to search for',
                },
                literal => {
                    type        => 'boolean',
                    description => 'If true, treat pattern as literal text (safer, default). If false, treat as regex.',
                },
                file_pattern => {
                    type        => 'string',
                    description => 'File glob pattern (e.g., "*.pm", "lib/**/*.pl")',
                },
                max_results => {
                    type        => 'integer',
                    description => 'Maximum results to return (default: 20)',
                },
            },
            required => ['pattern'],
        },
        sub {
            my ($args) = @_;

            my $pattern      = $args->{pattern};
            my $literal      = $args->{literal} // 1;
            my $file_pattern = $args->{file_pattern} // '**/*.{pm,pl,t}';
            my $max_results  = $args->{max_results} // 20;

            if ($file_pattern =~ /\.\./) {
                return {
                    content  => [{ type => 'text', text => "Invalid file pattern: '..' not allowed" }],
                    is_error => 1,
                };
            }

            my @results;
            my $re;

            if ($literal) {
                $re = qr/\Q$pattern\E/i;
            } else {

                if (length($pattern) > 500) {
                    return {
                        content  => [{ type => 'text', text => "Pattern too long (max 500 chars)" }],
                        is_error => 1,
                    };
                }

                if ($pattern =~ /\([^)]*[+*][^)]*\)[+*?]/ ||
                    $pattern =~ /\(\?[^)]*[+*][^)]*\)[+*?]/) {
                    return {
                        content  => [{ type => 'text', text => "Unsafe regex: nested quantifiers not allowed (ReDoS risk)" }],
                        is_error => 1,
                    };
                }

                eval {
                    if ($^O ne 'MSWin32') {
                        local $SIG{ALRM} = sub { die "regex compilation timeout\n" };
                        alarm(2);
                        $re = qr/$pattern/i;
                        alarm(0);
                    } else {
                        $re = qr/$pattern/i;
                    }
                };
                alarm(0) if $^O ne 'MSWin32';
                if ($@) {
                    return {
                        content  => [{ type => 'text', text => "Invalid or unsafe regex: $@" }],
                        is_error => 1,
                    };
                }
            }

            my $base_dir = path('.')->realpath;

            my @files = bsd_glob($file_pattern, GLOB_BRACE);
            unless (@files) {
                my $ext_pattern = '\.(?:pm|pl|t)$';
                if ($file_pattern =~ /\*\.(\w+)$/) {
                    $ext_pattern = '\.' . quotemeta($1) . '$';
                } elsif ($file_pattern =~ /\*\.\{([^}]+)\}$/) {
                    my $exts = join('|', map { quotemeta($_) } split(/,/, $1));
                    $ext_pattern = '\.(?:' . $exts . ')$';
                }
                my $ext_re = qr/$ext_pattern/;
                path('.')->visit(sub {
                    push @files, $_->stringify if $_->is_file && $_->stringify =~ $ext_re;
                }, { recurse => 1 });
            }

            FILE: for my $file (@files) {
                next unless -f $file;
                my $path = path($file);

                my $safe_path = eval { $path->realpath };
                next unless $safe_path && $base_dir->subsumes($safe_path);

                my $line_num = 0;
                for my $line ($safe_path->lines_utf8({ chomp => 1 })) {
                    $line_num++;
                    next if length($line) > 10_000;
                    if ($line =~ $re) {
                        push @results, sprintf "%s:%d: %s", $safe_path, $line_num, $line;
                        last FILE if @results >= $max_results;
                    }
                }
            }

            my $text = @results
                ? join("\n", @results)
                : "No matches found for pattern: $pattern";

            return {
                content => [{ type => 'text', text => $text }],
            };
        }
    );
}

sub _check_tests_tool {
    return tool(
        'check_tests',
        'Check if tests exist for a module or function',
        {
            type       => 'object',
            properties => {
                module => {
                    type        => 'string',
                    description => 'Module name (e.g., My::Module)',
                },
                function => {
                    type        => 'string',
                    description => 'Function name to check (optional)',
                },
            },
            required => ['module'],
        },
        sub {
            my ($args) = @_;

            my $module   = $args->{module};
            my $function = $args->{function};

            my $module_path = $module;
            $module_path =~ s/::/-/g;
            $module_path =~ s/([*?\[\]{}])/\\$1/g;

            my @test_patterns = (
                "t/*$module_path*.t",
                "t/**/*$module_path*.t",
                "xt/*$module_path*.t",
            );

            my @found_tests;
            for my $pattern (@test_patterns) {
                push @found_tests, bsd_glob($pattern, GLOB_BRACE);
            }

            my $base_dir = path('.')->realpath;

            my @results;
            if (@found_tests) {
                push @results, "Found test files for $module:";
                for my $test (@found_tests) {
                    push @results, "  - $test";

                    if ($function && !-l $test) {
                        my $test_path = eval { path($test)->realpath };
                        next unless $test_path && $base_dir->subsumes($test_path);
                        my $content = eval { $test_path->slurp_utf8 } // '';
                        my $safe_func = quotemeta($function);
                        if ($content =~ /\b$safe_func\b/) {
                            push @results, "    (mentions '$function')";
                        }
                    }
                }
            }
            else {
                push @results, "No test files found for $module";
                push @results, "Consider creating tests in t/$module_path.t";
            }

            return {
                content => [{ type => 'text', text => join("\n", @results) }],
            };
        }
    );
}

sub _get_dependencies_tool {
    return tool(
        'get_dependencies',
        'Get module dependencies for a file',
        {
            type       => 'object',
            properties => {
                file => {
                    type        => 'string',
                    description => 'File path to analyze',
                },
            },
            required => ['file'],
        },
        sub {
            my ($args) = @_;

            my $file = $args->{file};
            my $file_path = path($file);

            unless (-f $file_path) {
                return {
                    content  => [{ type => 'text', text => "File not found: $file" }],
                    is_error => 1,
                };
            }

            my $fh = eval { $file_path->openr_utf8 };
            unless ($fh) {
                return {
                    content  => [{ type => 'text', text => "Cannot open file: $file" }],
                    is_error => 1,
                };
            }

            my $safe_path = eval { $file_path->realpath };
            my $base_dir = path('.')->realpath;
            unless ($safe_path && $base_dir->subsumes($safe_path)) {
                close $fh;
                return {
                    content  => [{ type => 'text', text => "Access denied: $file" }],
                    is_error => 1,
                };
            }

            my $content = do { local $/; <$fh> };
            close $fh;

            my @use_statements;
            my @require_statements;

            while ($content =~ /^\s*use\s+([\w:]+)(?:\s|;)/gm) {
                push @use_statements, $1 unless $1 =~ /^(strict|warnings|v?\d|parent|base|lib|constant|if|feature)$/;
            }

            while ($content =~ /^\s*require\s+([\w:]+)/gm) {
                my $mod = $1;
                next if $mod =~ /^v?\d/;
                push @require_statements, $mod;
            }

            my @results;
            push @results, "Dependencies for $file:";
            push @results, "";

            if (@use_statements) {
                push @results, "use statements:";
                push @results, "  - $_" for sort @use_statements;
            }

            if (@require_statements) {
                push @results, "";
                push @results, "require statements:";
                push @results, "  - $_" for sort @require_statements;
            }

            unless (@use_statements || @require_statements) {
                push @results, "  (no external dependencies found)";
            }

            return {
                content => [{ type => 'text', text => join("\n", @results) }],
            };
        }
    );
}

sub _analyze_complexity_tool {
    return tool(
        'analyze_complexity',
        'Analyze cyclomatic complexity of a subroutine',
        {
            type       => 'object',
            properties => {
                file => {
                    type        => 'string',
                    description => 'File path',
                },
                function => {
                    type        => 'string',
                    description => 'Function/subroutine name',
                },
            },
            required => ['file', 'function'],
        },
        sub {
            my ($args) = @_;

            my $file     = $args->{file};
            my $function = $args->{function};
            my $file_path = path($file);

            unless (-f $file_path) {
                return {
                    content  => [{ type => 'text', text => "File not found: $file" }],
                    is_error => 1,
                };
            }

            my $fh = eval { $file_path->openr_utf8 };
            unless ($fh) {
                return {
                    content  => [{ type => 'text', text => "Cannot open file: $file" }],
                    is_error => 1,
                };
            }

            my $safe_path = eval { $file_path->realpath };
            my $base_dir = path('.')->realpath;
            unless ($safe_path && $base_dir->subsumes($safe_path)) {
                close $fh;
                return {
                    content  => [{ type => 'text', text => "Access denied: $file" }],
                    is_error => 1,
                };
            }

            my $content = do { local $/; <$fh> };
            close $fh;

            my $safe_func = quotemeta($function);
            my $sub_re = qr/sub\s+$safe_func\s*\{/;
            unless ($content =~ $sub_re) {
                return {
                    content => [{ type => 'text', text => "Subroutine '$function' not found in $file" }],
                };
            }

            my $sub_body;
            if ($content =~ /sub\s+$safe_func\s*\{/) {
                my $pos = $+[0] - 1;
                my $depth = 0;
                my $start = $pos;
                for my $i ($pos .. length($content) - 1) {
                    my $char = substr($content, $i, 1);
                    if ($char eq '{') {
                        $depth++;
                    } elsif ($char eq '}') {
                        $depth--;
                        if ($depth == 0) {
                            $sub_body = substr($content, $start, $i - $start + 1);
                            last;
                        }
                    }
                }
            }

            unless ($sub_body) {
                return {
                    content => [{ type => 'text', text => "Could not extract body of '$function'" }],
                };
            }

            my $code_only = $sub_body;
            $code_only =~ s/#.*$//gm;
            $code_only =~ s/'(?:[^'\\]|\\.)*'//g;
            $code_only =~ s/"(?:[^"\\]|\\.)*"//g;
            $code_only =~ s/<<['"]?(\w+)['"]?.*?\n\1//gs;

            my $complexity = 1;

            $complexity += () = $code_only =~ /\b(if|elsif|unless|while|until|for|foreach)\b/g;
            $complexity += () = $code_only =~ /\b(and|or)\b/g;
            $complexity += () = $code_only =~ /(\?\s*:)/g;
            $complexity += () = $code_only =~ /(\|\||\&\&)/g;

            my $assessment;
            if ($complexity <= 5) {
                $assessment = "Low complexity - well structured";
            }
            elsif ($complexity <= 10) {
                $assessment = "Moderate complexity - acceptable";
            }
            elsif ($complexity <= 20) {
                $assessment = "High complexity - consider refactoring";
            }
            else {
                $assessment = "Very high complexity - refactoring recommended";
            }

            my @results = (
                "Complexity analysis for $function in $file:",
                "",
                "  Cyclomatic complexity: $complexity",
                "  Assessment: $assessment",
            );

            return {
                content => [{ type => 'text', text => join("\n", @results) }],
            };
        }
    );
}


1;

__END__

=head1 NAME

Claude::Agent::Code::Review::Tools - Custom MCP tools for code review

=head1 SYNOPSIS

    use Claude::Agent::Code::Review::Tools;

    my $server = Claude::Agent::Code::Review::Tools->create_server();

    # Use in Claude::Agent::Options
    my $options = Claude::Agent::Options->new(
        mcp_servers   => { review => $server },
        allowed_tools => $server->tool_names,
    );

=head1 DESCRIPTION

Provides custom MCP tools to enhance code review capabilities.

=head1 METHODS

=head2 create_server

    my $server = Claude::Agent::Code::Review::Tools->create_server();

Creates an MCP server with all review tools.

=cut

=head1 AVAILABLE TOOLS

=head2 get_file_context

Get surrounding context for a specific line in a file.

Parameters: C<file> (required), C<line> (required), C<before> (default: 5), C<after> (default: 5)

=head2 search_codebase

Search for text or patterns across the codebase.

Parameters:

=over 4

=item * C<pattern> (required) - Text or regex pattern to search for

=item * C<literal> (default: true) - If true, treats pattern as literal text (safe).
If false, treats as regex with ReDoS protection (rejects nested quantifiers).

=item * C<file_pattern> (default: '**/*.{pm,pl,t}') - Glob pattern for files to search

=item * C<max_results> (default: 20) - Maximum number of results to return

=back

=head2 check_tests

Check if tests exist for a module or function.

Parameters: C<module> (required), C<function> (optional)

=head2 get_dependencies

Get module dependencies for a file.

Parameters: C<file> (required)

=head2 analyze_complexity

Analyze cyclomatic complexity of a subroutine.

Parameters: C<file> (required), C<function> (required)

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under The Artistic License 2.0 (GPL Compatible).

=cut
