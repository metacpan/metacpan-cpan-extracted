package App::Greple::xlate::gpt4;

our $VERSION = "0.9923";

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
    gpt4 => { engine => 'gpt-4.1', temp => '0.0', max => 3000, sub => \&gpty,
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
    my @command = (
	'gpty',
	-e => $param->{engine},
	-t => $param->{temp},
	-s => $system,
    );
    if (my @contexts = @{$opt{contexts}}) {
	push @command, map { (-s => "Translation context: $_") } @contexts;
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
