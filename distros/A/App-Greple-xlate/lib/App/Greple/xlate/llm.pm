package App::Greple::xlate::llm;

our $VERSION = "2.01";

=encoding utf-8

=head1 NAME

App::Greple::xlate::llm - common backend for llm-based translation engines

=head1 DESCRIPTION

This module provides the shared machinery for translation engines built
on the C<llm> command line tool (L<https://llm.datasette.io/>): command
construction, JSON array protocol, batching, progress display, and
failure diagnosis.  Engine modules such as
L<App::Greple::xlate::llm::gpt5> only define the model name, prompt,
and model options.

=head1 SEE ALSO

L<App::Greple::xlate>, L<App::Greple::xlate::llm::gpt5>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.14;
use warnings;
use utf8;
use Data::Dumper;
{
    no warnings 'redefine';
    *Data::Dumper::qquote = sub { qq["${\(shift)}"] };
    $Data::Dumper::Useperl = 1;
}

use Command::Run;
use JSON;

use App::Greple::xlate qw(%opt &opt);
use App::Greple::xlate::Lang qw(%LANGNAME);

my $json = JSON->new->canonical->pretty;
my $json_flat = JSON->new->canonical;

our $CONTEXT_MAX = 8000;          # total rendered context limit
our $CONTEXT_SOURCE_MIN = 500;    # slice floor while truncating

sub _progress {
    print STDERR @_ if opt('progress');
}

##
## Assemble the system prompt: expand %s to the target language name
## and append --xlate-context entries.  Phase 2 (context-aware
## differential translation) extends this function.
##
sub build_system {
    my $param = shift;
    my $prompt = opt('prompt') || $param->{prompt};
    my @vars = do {
        if ($prompt =~ /%s/) {
            $LANGNAME{$param->{lang_to}} // die "$param->{lang_to}: unknown lang.\n";
        } else {
            ();
        }
    };
    my $system = sprintf($prompt, @vars);
    if (my @contexts = @{$opt{contexts}}) {
        $system .= "\n\nTranslation context:\n" . join("\n", map "- $_", @contexts);
    }
    if (defined(my $tre = App::Greple::xlate::template_regex())) {
        $system .= "\n\nThe input contains template expressions"
                 . " (such as {{ ... }} or {% ... %})."
                 . " Treat them as opaque placeholders: copy each one"
                 . " to the output unchanged, byte for byte.";
    }
    $system .= context_sections();
    $system;
}

sub _pairs_json {
    $json_flat->encode(
        [ map { +{ source => $_->[0], translation => $_->[1] } } @_ ]);
}

##
## Render the three context sections from $call_context, trimming to
## $CONTEXT_MAX in the spec's priority order: far flank pairs, source
## slices (down to $CONTEXT_SOURCE_MIN per side), near flank pairs,
## then old pairs from the far end.
##
sub context_sections {
    my $ctx = $App::Greple::xlate::call_context or return '';
    my @before = @{$ctx->{hits_before} // []};   # near to far
    my @after  = @{$ctx->{hits_after}  // []};   # near to far
    my @old    = @{$ctx->{old_pairs}   // []};   # document order
    my $sb = $ctx->{source_before} // '';
    my $sa = $ctx->{source_after}  // '';

    my $render = sub {
        my $out = '';
        if (length $sb or length $sa) {
            $out .= "\n\nSurrounding document source, shown for context only.\n"
                  . "Do NOT translate or output any of it. The passage you will be\n"
                  . "asked to translate sits at the [...] marker:\n"
                  . "$sb\[...]\n$sa";
        }
        if (@before or @after) {
            $out .= "\n\nReference translations from the surrounding document.\n"
                  . "Match their style, tone, and terminology:\n"
                  . _pairs_json(reverse(@before), @after);
        }
        if (@old) {
            $out .= "\n\nPrevious version of the passage you are about to translate\n"
                  . "(source and translation before the source was edited).\n"
                  . "Where the new source text is unchanged from this previous\n"
                  . "version, keep the previous translation's wording exactly;\n"
                  . "change only what the source changes require:\n"
                  . _pairs_json(@old);
        }
        $out;
    };

    my @trim = (
        sub {
            if    (@before > 1) { pop @before; 1 }
            elsif (@after  > 1) { pop @after;  1 }
            else  { 0 }
        },
        sub {
            if (length($sb) > $CONTEXT_SOURCE_MIN) {
                $sb = substr($sb, -$CONTEXT_SOURCE_MIN);
                $sb =~ s/\A[^\n]*\n//;
                return 1;
            }
            if (length($sa) > $CONTEXT_SOURCE_MIN) {
                $sa = substr($sa, 0, $CONTEXT_SOURCE_MIN);
                $sa =~ s/(?<=\n)[^\n]*\z//;
                return 1;
            }
            0;
        },
        sub {
            if    (@before) { pop @before; 1 }
            elsif (@after)  { pop @after;  1 }
            else  { 0 }
        },
        sub { @old ? do { pop @old; 1 } : 0 },
    );
    my $text = $render->();
    STEP: for my $step (@trim) {
        while (length($text) > $CONTEXT_MAX) {
            $step->() or next STEP;
            $text = $render->();
        }
        last;
    }
    $text;
}

sub llm_command {
    my($param, $system) = @_;
    my @command = ('llm', '-m' => $param->{model}, '-s' => $system);
    for my $kv (@{$param->{options} // []}) {
        push @command, '-o', @$kv;
    }
    push @command, '--no-stream', '--no-log';
    @command;
}

sub _llm_in_path {
    grep { -x "$_/llm" } split /:/, $ENV{PATH} // '';
}

sub _not_found {
    "llm: command not found.\n" .
    "Install llm <https://llm.datasette.io/> with " .
    "\"pip install llm\" or \"pipx install llm\".\n";
}

sub run_llm {
    state $run = Command::Run->new;
    my($param, $text) = @_;
    ##
    ## Check PATH before forking: Command::Run's forked child has no
    ## exit guard after a failed exec, so reaching that path would let
    ## the child escape into the caller's code.
    ##
    _llm_in_path() or die _not_found();
    my @command = llm_command($param, build_system($param));
    warn Dumper \@command if opt('debug');
    my $result = $run->command(@command)
                     ->run(stdin => $text, stderr => 'capture');
    if ($result->{result} != 0) {
        die diagnose($param, $result);
    }
    print STDERR $result->{error} if $result->{error};
    $result->{data};
}

##
## Called when the llm command fails: figure out why and return a
## message useful to the user.
##
sub diagnose {
    my($param, $result) = @_;
    my $stderr = $result->{error} // '';
    if (! _llm_in_path()) {
        return _not_found();
    }
    my $model = $param->{model};
    my $models = Command::Run->new->command('llm', 'models')
        ->run(stderr => 'capture')->{data} // '';
    if ($models !~ /\Q$model\E/) {
        return "llm does not know model \"$model\".\n" .
               "Upgrade llm (\"pip install -U llm\") or register the model " .
               "in extra-openai-models.yaml.\n" .
               ($stderr ? "\n$stderr" : "");
    }
    return "llm failed:\n$stderr";
}

sub xlate_each {
    my $param = shift;
    my @count = map { int tr/\n/\n/ } @_;
    _progress("From:\n", map s/^/\t< /mgr, @_);
    my @in = map { m/.*\n/mg } @_;
    my $out = run_llm($param, $json->encode(\@in));
    my $obj = eval { $json->decode($out) };
    ref $obj eq 'ARRAY'
        or die "Invalid JSON response:\n\n$out\n";
    my @out = map { s/(?<!\n)\z/\n/r } @$obj;
    _progress("To:\n", map s/^/\t> /mgr, @out);
    if (@out < @in) {
        my $to = join '', @out;
        die sprintf("Unexpected response (%d < %d):\n\n%s\n",
                    int(@out), int(@in), $to);
    }
    map { join '', splice @out, 0, $_ } @count;
}

##
## Public entry point for engine modules: batch the blocks up to the
## maxlen/maxline limits and translate each batch in one llm call.
##
sub xlate_with {
    my $param = shift;
    my @from = map { /\n\z/ ? $_ : "$_\n" } @_;
    my @to;
    my $max = $App::Greple::xlate::max_length || $param->{max} // die;
    my $maxline = $App::Greple::xlate::max_line;
    if (my @len = grep { $_ > $max } map length, @from) {
        die "Contain lines longer than max length (@len > $max).\n";
    }
    while (@from) {
        my @tmp;
        my $len = 0;
        while (@from) {
            my $next = length $from[0];
            last if $len + $next > $max;
            $len += $next;
            push @tmp, shift @from;
            last if $maxline > 0 and @tmp >= $maxline;
        }
        @tmp > 0 or die "Probably text is longer than max length ($max).\n";
        push @to, xlate_each($param, @tmp);
    }
    @to;
}

1;
