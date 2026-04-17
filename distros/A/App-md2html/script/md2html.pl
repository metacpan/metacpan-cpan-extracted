#!/usr/bin/env perl

use Object::Pad ':experimental(:all)';

package md2html::cli;

class md2html::cli;

use lib 'lib';

use v5.40;

use Getopt::Long qw(GetOptionsFromArray :config no_ignore_case);
use Syntax::Keyword::Defer;
use Const::Fast;
use Path::Tiny;
use IPC::Nosh::Common;
use List::Util qw'any first';
use App::md2html;

const our $NO_FILENAME => '-';

field $infile  : reader : param(in)  = [];
field $outfile : reader : param(out) = [];
field $cliopt  : reader;

field $parser : reader;
field $done;

ADJUSTPARAMS($param) {
    $cliopt = $param;
    $parser = App::md2html->new(%$cliopt);
    dmsg $self
}

method run ( $infile, $outfile ) {
    push @$infile, $STDIN unless scalar @$infile;

    foreach my $file (@$infile) {
        state $i = 0;
        defer { $i++ };

        my $instr;

        if ( !-t STDIN ) {
            my @lines = <STDIN>;
            $instr = join "", @lines;
        }
        else {
            if ( !$file || $file eq $NO_FILENAME ) {
                fatal "No input provided.";
            }
            my $file = path($file);
            $instr = $file->slurp_raw;
        }

        my $body = $self->parser->to_html($instr);

        # TODO: create output file from mask string
        if ( my $outfile = $$outfile[$i] ) {
            path($outfile)->spew($body);
        }
        else {
            say $body if $body;
        }
    }
}

method cli : common ( $argv = \@ARGV ) {
    my %cliopt = ( in => [], out => [] );

    GetOptionsFromArray(
        $argv,
        \%cliopt,

        'outfile=s{,}'
        ,    # If this is empty should we enable --embedded|no-header|fragment

        'encoding_in|charset|charset-in|encoding|inencoding=s',
        'encoding_out|outcharset|outencoding|outencode|charset-out=s',

        # 'css|stylesheeet:s',

        # 'toc:s',

        'htmldoc|full-html|html-page!',

        #'doctype:s',
        #'header:s',
        'embedded|fragment',

        # 'html-ver=s',
        # 'xhtml',
        # 'html5',

        #'minify:s',
        'minify!',

        #'passthrough=s',    # TODO: passthrough based on file ext
        'debug+',
        'verbose+',
        '<>' => sub ($infile) {
            push $cliopt{in}->@*, $infile;
        }
    );

    my $in  = delete $cliopt{in};
    my $out = delete $cliopt{out};

    my $md2html = $class->new(%cliopt);
    $md2html->run( $in, $out );
}

md2html::cli->cli( \@ARGV )
