#!/usr/bin/env perl 

use strict;
use warnings;
use utf8;

use JSON;
use Path::Tiny;
use Text::Template;
use Scalar::Util;

my $trace_name = shift;

my $plotly_base_path = '../plotly.js';
my $example_template = path("template/example_template.tmpl")->slurp_utf8();
my $plotly_js_path = path($plotly_base_path);
my $plotly_mocks = $plotly_js_path->child("test/image/mocks");

for my $mock_json ($plotly_mocks->children(qr/.*\Q$trace_name\E.*\.json$/)) {
    print "Processing: $mock_json ...";
    my $chart_struct = from_json($mock_json->slurp_utf8);
    
    my $path_for_git = $mock_json->stringify;
    $path_for_git =~ s|\Q$plotly_base_path\E/||;
    my $commit = `git -C $plotly_base_path log -1 --pretty=format:"%H" $path_for_git`;
    my $comment = '# Example from https://github.com/plotly/plotly.js/blob/' . $commit . '/' . $path_for_git;


    my $file = path($mock_json->basename('.json') . ".pl");

    my $data = $chart_struct->{data};

    my %traces_packages;
    my @traces_declarations;
    my $list_of_traces = '';
    my $trace_counter = 1;
    for my $trace (@{$data}) {
        my $type = delete $trace->{type};
        if (not defined $type) {
            $type = 'scatter';
        }
        my $trace_package = 'Chart::Plotly::Trace::' . ucfirst($type);
        $traces_packages{$type} = "use $trace_package;";
        my $trace_content = DumpTrace($trace);
        my $trace_name = '$trace' . $trace_counter;
        push @traces_declarations, 'my ' . $trace_name . ' = ' .
            $trace_package . '->new('
            . $trace_content
        . ");\n";
        $list_of_traces .= $trace_name . ", ";
        $trace_counter += 1;
    }
    
    my $layout = $chart_struct->{layout};
    if (not defined $layout) {
        $layout = {};
    }
    
    my $contents = 
        Text::Template::fill_in_string($example_template, HASH => {
            comment => $comment,
            traces_packages => join("\n", values %traces_packages),
            traces_declaration => join("\n", @traces_declarations),
            list_of_traces => $list_of_traces,
            layout  => DumpTrace($layout)
        });
    $file->spew_utf8($contents);
    print " Done!\n";
}

sub DumpTrace {
    my $trace = shift;
    my $trace_content = '';

    my $type = ref $trace;
    if (defined $type ) {
        if ($type eq '') {
            # SCALAR
            if (Scalar::Util::looks_like_number($trace)) {
                $trace_content .= $trace;
            } else {
                $trace_content .= "'$trace'";
            }
        } elsif ($type eq 'HASH') {
            $trace_content .= "{";
            for my $key (keys %$trace) {
                my $value = $trace->{$key};
                if (defined $value) {
                    $trace_content .= DumpTrace($key) . " => " . DumpTrace($value) . ", ";
                }
            }
            $trace_content .= "}";

        } elsif ($type eq 'ARRAY') {
            $trace_content .= "[";
            for my $element (@$trace) {
                $trace_content .= DumpTrace($element) . ", ";
            }
            $trace_content .= "]";

        } else {
            # JSON Objects
            if ($type =~ /JSON/) {
                if (JSON::is_bool($trace)) {
                    if ($trace) {
                        $trace_content .= 'JSON::true';
                    } else {
                        $trace_content .= 'JSON::false';
                    }
                }
            }
        }
    } else {
        # Undefined 
        die ("Trace content can't be undefined");
    }

    return $trace_content;
}



