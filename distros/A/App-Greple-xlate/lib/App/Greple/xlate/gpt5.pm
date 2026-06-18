package App::Greple::xlate::gpt5;

our $VERSION = "1.0202";

=head1 NAME

App::Greple::xlate::gpt5 - GPT-5.5 translation engine for greple xlate module

=head1 SYNOPSIS

    greple -Mxlate --xlate-engine=gpt5 --xlate=ja file.txt

=head1 DESCRIPTION

This module provides GPT-5.5 translation support for the App::Greple::xlate
module. GPT-5.5 is OpenAI's latest language model, offering enhanced reasoning
capabilities and improved translation quality. The engine name remains C<gpt5>
for backward compatibility, while the default model is C<gpt-5.5>.

=head1 GPT-5.5 API SPECIFICATIONS

=head2 Model

=over 4

=item * B<gpt-5.5> - Full model with maximum capabilities (snapshot: C<gpt-5.5-2026-04-23>)

=back

Unlike the GPT-5 series, GPT-5.5 is offered as a single model with no
C<mini>/C<nano> variants.

=head2 Token Limits

=over 4

=item * B<Context window>: 1,050,000 tokens

=item * B<Output limit>: 128,000 tokens (including reasoning tokens)

=back

Prompts exceeding 272,000 input tokens are billed at 2x input and 1.5x output
rates for the full session.

=head2 Input/Output Support

=over 4

=item * B<Input>: Text and images

=item * B<Output>: Text only

=back

=head2 New API Parameters

The GPT-5 family introduces several new parameters for fine-grained control:

=head3 reasoning_effort

Controls the model's thinking time and reasoning depth:

=over 4

=item * B<none> - Reasoning effectively disabled; the model behaves like a non-reasoning model for the fastest latency, suitable for deterministic tasks such as translation

=item * B<low> - Low reasoning effort, prioritizes speed while keeping some planning

=item * B<medium> - Balanced reasoning (default)

=item * B<high> - High reasoning effort, prioritizes quality

=item * B<xhigh> - Maximum reasoning effort

=back

Note: GPT-5.5 replaces the GPT-5 C<minimal> level with C<none>, and adds the
C<xhigh> level. The default is C<medium>. This engine uses C<none> for
translation to favor speed and cost.

=head3 verbosity

Controls the length and detail of responses:

=over 4

=item * B<low> - Minimal, terse responses

=item * B<medium> - Balanced detail level

=item * B<high> - Comprehensive, verbose responses

=back

=head3 max_completion_tokens

Specifies the maximum number of completion tokens in the response.
Unlike the legacy max_tokens parameter, this specifically controls
output tokens and is the recommended approach for GPT-5.5.

=head2 Enhanced Features

=head3 Reduced Hallucinations

The GPT-5 family is significantly less likely to hallucinate compared to
previous generations of models, which improves the factual reliability of
translations.

=head3 Custom Tools Support

The GPT-5 family supports custom tools that can receive plaintext payloads
instead of JSON, enabling more flexible integration with external systems.

=head3 Context-Free Grammar (CFG)

Allows strict output constraints to match predefined syntax rules,
useful for ensuring valid format generation.

=head2 Pricing

=over 4

=item * B<Input>: $5.00/1M tokens

=item * B<Cached input>: $0.50/1M tokens

=item * B<Output>: $30.00/1M tokens

=back

Note: prompts exceeding 272,000 input tokens are billed at 2x input and 1.5x
output rates for the full session (applies to standard, batch, and flex).

=head1 CONFIGURATION

This module uses the following default parameters:

=over 4

=item * B<engine>: gpt-5.5

=item * B<temperature>: 1 (fixed for GPT-5.5)

=item * B<max_length>: 3000 characters per batch

=item * B<reasoning_effort>: none (for translation tasks; fastest)

=item * B<max_completion_tokens>: 16000

=back

=head1 ENVIRONMENT VARIABLES

=over 4

=item * B<OPENAI_API_KEY> - Required OpenAI API key, read by the C<gpty> command

=back

=head1 RELATED OPTIONS

Batching and debugging are controlled through the standard
L<App::Greple::xlate> command-line options, not environment variables:

=over 4

=item * B<--xlate-maxlen>=I<chars> - Maximum characters sent per request
(defaults to this engine's value of 3000 when unset)

=item * B<--xlate-maxline>=I<n> - Maximum lines sent per request
(default 0 = unlimited); useful as a safety valve if a large batch causes a
response element-count mismatch

=item * B<--xlate-debug> - Dump the C<gpty> command and parameters

=back

=head1 DEPENDENCIES

=over 4

=item * L<App::Greple::xlate>

=item * L<Command::Run> - For gpty command execution

=item * L<JSON> - For JSON array processing

=back

=head1 SEE ALSO

=over 4

=item * L<App::Greple::xlate>

=item * L<App::Greple::xlate::deepl>

=item * L<App::Greple::xlate::gpt3>

=item * L<App::Greple::xlate::gpt4o>

=item * OpenAI GPT-5.5 Documentation: L<https://developers.openai.com/api/docs/models/gpt-5.5>

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2024-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use v5.14;
use warnings;
use utf8;
use Encode;
use Data::Dumper;
{
    no warnings 'redefine';
    *Data::Dumper::qquote = sub { qq["${\(shift)}"] };
    $Data::Dumper::Useperl = 1;
}

use List::Util qw(sum);
use Command::Run;

use App::Greple::xlate qw(%opt &opt);
use App::Greple::xlate::Lang qw(%LANGNAME);

our $lang_from //= 'ORIGINAL';
our $lang_to   //= 'JA';
our $auth_key;
our $method = __PACKAGE__ =~ s/.*://r;

my %param = (
    gpt5 => { engine => 'gpt-5.5', temp => '1', max => 3000, sub => \&gpty,
              reasoning_effort => 'none', verbosity => 'low', max_completion_tokens => 16000,
	      prompt => <<END
Translate the following JSON array into %s.
For each input array element, output only the corresponding translated element at the same array index.
If an element is a blank string or an XML-style marker tag (e.g., "<m id=1 />"), leave it unchanged and do not translate it.
Do not output the original (pre-translation) text under any circumstances.
The number and order of output elements must always match the input exactly: output element n must correspond to input element n.
Output only the translated elements or unchanged tags/blank strings as a JSON array.
Do not leave any unnecessary spaces or tabs at the end of any array element in your output.
Before finishing, carefully check that there are absolutely no omissions, duplicate content, or trailing spaces of any kind in your output.

Return the result as a JSON array and nothing else.
Your entire output must be valid JSON.
Do not include any explanations, code blocks, or text outside of the JSON array.
If you cannot produce a valid JSON array, return an empty JSON array ([]).
END
	  },
);

sub initialize {
    my($mod, $argv) = @_;
    $mod->setopt(default => "-Mxlate --xlate-engine=$method");
}

sub gpty {
    state $gpty = Command::Run->new;
    my $text = shift;
    my $param = $param{$method};
    my $prompt = opt('prompt') || $param->{prompt};
    my @vars = do {
	if ($prompt =~ /%s/) {
	    $LANGNAME{$lang_to} // die "$lang_to: unknown lang.\n"
	} else {
	    ();
	}
    };
    my $system = sprintf($prompt, @vars);
    # Add context information directly to the main system prompt
    if (my @contexts = @{$opt{contexts}}) {
	$system .= "\n\nTranslation context:\n" . join("\n", map "- $_", @contexts);
    }
    my @command = (
	'gpty',
	'--engine' => $param->{engine},
	'--system' => $system,
    );
    # Add temperature if specified and supported
    if (defined $param->{temp}) {
	push @command, '--temperature' => $param->{temp};
    }
    # Add GPT-5/O1 specific parameters if they exist
    if (defined $param->{max_completion_tokens}) {
	push @command, '--max-completion-tokens' => $param->{max_completion_tokens};
    }
    if (defined $param->{reasoning_effort}) {
	push @command, '--reasoning-effort' => $param->{reasoning_effort};
    }
    if (defined $param->{verbosity}) {
	push @command, '--verbosity' => $param->{verbosity};
    }
    push @command, '-';
    warn Dumper \@command if opt('debug');
    $gpty->command(@command)->with(stdin => $text)->update->data;
}

sub _progress {
    print STDERR @_ if opt('progress');
}

use JSON;
my $json = JSON->new->canonical->pretty;

sub xlate_each {
    my $call = $param{$method}->{sub} // die;
    my @count = map { int tr/\n/\n/ } @_;
    _progress("From:\n", map s/^/\t< /mgr, @_);
    my($in, $out);
    my @in = map { m/.*\n/mg } @_;
    my $obj = $json->decode($out = $call->($in = $json->encode(\@in)));
    my @out = map { s/(?<!\n)\z/\n/r } @$obj;
    _progress("To:\n", map s/^/\t> /mgr, @out);
    if (@out < @in) {
	my $to = join '', @out;
	die sprintf("Unexpected response (%d < %d):\n\n%s\n",
		    int(@out), int(@in), $to);
    }
    map { join '', splice @out, 0, $_ } @count;
}

sub xlate {
    my @from = map { /\n\z/ ? $_ : "$_\n" } @_;
    my @to;
    my $max = $App::Greple::xlate::max_length || $param{$method}->{max} // die;
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
	push @to, xlate_each @tmp;
    }
    @to;
}

1;

__DATA__

# set in &initialize()
# option default -Mxlate --xlate-engine=gptN
