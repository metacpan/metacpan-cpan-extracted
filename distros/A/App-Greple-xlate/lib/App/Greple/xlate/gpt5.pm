package App::Greple::xlate::gpt5;

our $VERSION = "0.9915";

=head1 NAME

App::Greple::xlate::gpt5 - GPT-5 translation engine for greple xlate module

=head1 SYNOPSIS

    greple -Mxlate --xlate-engine=gpt5 --xlate=ja file.txt

=head1 DESCRIPTION

This module provides GPT-5 translation support for the App::Greple::xlate module.
GPT-5 is OpenAI's latest language model released in 2025, offering enhanced
reasoning capabilities and improved translation quality.

=head1 GPT-5 API SPECIFICATIONS

=head2 Model Variants

GPT-5 is available in three sizes:

=over 4

=item * B<gpt-5> - Full model with maximum capabilities

=item * B<gpt-5-mini> - Smaller, faster variant

=item * B<gpt-5-nano> - Minimal variant for lightweight tasks

=back

=head2 Token Limits

=over 4

=item * B<Input limit>: 272,000 tokens

=item * B<Output limit>: 128,000 tokens (including reasoning tokens)

=item * B<Total context window>: 400,000 tokens (272,000 input + 128,000 output)

=back

=head2 Input/Output Support

=over 4

=item * B<Input>: Text and images

=item * B<Output>: Text only

=back

=head2 New API Parameters

GPT-5 introduces several new parameters for fine-grained control:

=head3 reasoning_effort

Controls the model's thinking time and reasoning depth:

=over 4

=item * B<minimal> - Minimal reasoning for fast responses, suitable for deterministic tasks

=item * B<low> - Low reasoning effort, prioritizes speed

=item * B<medium> - Balanced reasoning (default)

=item * B<high> - Maximum reasoning effort, prioritizes quality

=back

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
output tokens and is the recommended approach for GPT-5.

=head2 Enhanced Features

=head3 Reduced Hallucinations

GPT-5 is significantly less likely to hallucinate compared to previous models:

=over 4

=item * 45% fewer factual errors compared to GPT-4o

=item * 80% fewer factual errors compared to OpenAI o3 when reasoning is enabled

=back

=head3 Custom Tools Support

GPT-5 supports custom tools that can receive plaintext payloads instead
of JSON, enabling more flexible integration with external systems.

=head3 Context-Free Grammar (CFG)

Allows strict output constraints to match predefined syntax rules,
useful for ensuring valid format generation.

=head2 Pricing (2025)

=head3 GPT-5 Series

=over 4

=item * B<gpt-5>: $1.25/1M input tokens, $10/1M output tokens

=item * B<gpt-5-mini>: $0.25/1M input tokens, $2/1M output tokens

=item * B<gpt-5-nano>: $0.05/1M input tokens, $0.40/1M output tokens

=item * B<Cached input>: $0.125/1M tokens (90% discount on cached input tokens)

=back

=head3 GPT-4 Series (for comparison)

=over 4

=item * B<gpt-4.1>: $2.00/1M input tokens, $8.00/1M output tokens (1M token context)

=item * B<gpt-4.1-mini>: $0.40/1M input tokens, $1.60/1M output tokens (1M token context)

=item * B<gpt-4.1-nano>: $0.10/1M input tokens, $0.40/1M output tokens (1M token context)

=item * B<gpt-4o>: $3.00/1M input tokens, $10.00/1M output tokens

=item * B<gpt-4o-mini>: $0.15/1M input tokens, $0.60/1M output tokens

=item * B<gpt-4o with audio>: $5/1M input tokens, $20/1M output tokens (text), $100/1M input tokens, $200/1M output tokens (audio)

=back

Note: GPT-4.1 models feature 1,000,000 token context window and prompt caching (25% input cost for cached prefixes).

GPT-4.1 is approximately 26% cheaper than GPT-4o for median queries.

GPT-4o represents an 83% price drop for output tokens and 90% drop for input tokens compared to original GPT-4.

=head1 CONFIGURATION

This module uses the following default parameters:

=over 4

=item * B<engine>: gpt-5

=item * B<temperature>: 1 (fixed for GPT-5)

=item * B<max_length>: 3000 characters per batch

=item * B<reasoning_effort>: minimal (for translation tasks)

=item * B<max_completion_tokens>: 4000

=back

=head1 ENVIRONMENT VARIABLES

=over 4

=item * B<OPENAI_API_KEY> - Required OpenAI API key

=item * B<XLATE_DEBUG> - Enable debug output

=item * B<XLATE_MAXLEN> - Override maximum batch length

=back

=head1 DEPENDENCIES

=over 4

=item * L<App::Greple::xlate>

=item * L<App::cdif::Command> - For gpty command execution

=item * L<JSON> - For JSON array processing

=back

=head1 SEE ALSO

=over 4

=item * L<App::Greple::xlate>

=item * L<App::Greple::xlate::deepl>

=item * L<App::Greple::xlate::gpt3>

=item * L<App::Greple::xlate::gpt4>

=item * L<App::Greple::xlate::gpt4o>

=item * OpenAI GPT-5 Documentation: L<https://openai.com/gpt-5/>

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2024-2025 Kazumasa Utashiro.

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
use App::cdif::Command;

use App::Greple::xlate qw(%opt &opt);
use App::Greple::xlate::Lang qw(%LANGNAME);

our $lang_from //= 'ORIGINAL';
our $lang_to   //= 'JA';
our $auth_key;
our $method = __PACKAGE__ =~ s/.*://r;

my %param = (
    gpt5 => { engine => 'gpt-5', temp => '1', max => 3000, sub => \&gpty,
              reasoning_effort => 'minimal', verbosity => 'low', max_completion_tokens => 4000,
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
    state $gpty = App::cdif::Command->new;
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
    $gpty->command(\@command)->setstdin($text)->update->data;
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
