package App::Workflow::Lint::Formatter;

use strict;
use warnings;
use Carp qw(croak carp);
use JSON::PP;

#----------------------------------------------------------------------
# format($format, \@diagnostics)
#
# Supported formats:
#   human  - plain text
#   json   - JSON array of diagnostics
#   sarif  - SARIF 2.1.0 output
#----------------------------------------------------------------------

sub format {
    my ($class, $format, $diags) = @_;

    croak "format() requires diagnostics arrayref"
        unless ref $diags eq 'ARRAY';

    if ($format eq 'human') {
        return _format_human($diags);
    }
    elsif ($format eq 'json') {
        return _format_json($diags);
    }
    elsif ($format eq 'sarif') {
        return _format_sarif($diags);
    }

    croak "Unknown output format '$format'";
}

#----------------------------------------------------------------------
# Human-readable output
#----------------------------------------------------------------------

sub _format_human {
    my ($diags) = @_;

    my @out;
    for my $d (@$diags) {
        push @out, sprintf(
            "%s: %s (%s) at %s",
            $d->{level},
            $d->{message},
            $d->{rule},
            $d->{path},
        );
    }

    return join("\n", @out) . "\n";
}

#----------------------------------------------------------------------
# JSON output
#----------------------------------------------------------------------

sub _format_json {
    my ($diags) = @_;
    return JSON::PP->new->pretty->encode($diags);
}

#----------------------------------------------------------------------
# SARIF output (Static Analysis Results Interchange Format)
#----------------------------------------------------------------------

sub _format_sarif {
    my ($diags) = @_;

    my @results;

    for my $d (@$diags) {
        push @results, {
            ruleId   => $d->{rule},
            level    => _sarif_level($d->{level}),
            message  => { text => $d->{message} },
            locations => [
                {
                    physicalLocation => {
                        artifactLocation => {
                            uri => $d->{file} // 'workflow.yml',
                        },
                        region => {
                            startLine => 1,   # We don't have line numbers yet
                        },
                    },
                }
            ],
        };
    }

    my $sarif = {
        version   => "2.1.0",
        '$schema'   => "https://json.schemastore.org/sarif-2.1.0.json",
        runs      => [
            {
                tool => {
                    driver => {
                        name            => "App::Workflow::Lint",
                        informationUri  => "https://metacpan.org/pod/App::Workflow::Lint",
                        rules           => [],
                    },
                },
                results => \@results,
            }
        ],
    };

    return JSON::PP->new->pretty->encode($sarif);
}

#----------------------------------------------------------------------
# Map our levels to SARIF levels
#----------------------------------------------------------------------

sub _sarif_level {
    my ($lvl) = @_;

    return 'error'   if $lvl eq 'error';
    return 'warning' if $lvl eq 'warning';
    return 'note';   # info, etc.
}

1;

