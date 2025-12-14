package App::Greple::xlate::gpt4o;

our $VERSION = "0.9920";

use v5.14;
use warnings;
use utf8;
use Encode;
use Data::Dumper;

use List::Util qw(sum);
use App::cdif::Command;

use App::Greple::xlate qw(opt);
use App::Greple::xlate::Lang qw(%LANGNAME);

our $lang_from //= 'ORIGINAL';
our $lang_to   //= 'JA';
our $auth_key;
our $method = __PACKAGE__ =~ s/.*://r;

my %param = (
    gpt4o => { engine => 'gpt-4o-mini', temp => '0.0', max => 10000, sub => \&gpty,
	      prompt => <<END
Translate the following text into %s, preserving the line structure.
For each input line, output only the corresponding translated line in the same line position.
Leave blank lines and any XML-style tags (e.g., <m id=1 />, <tag>, </tag>) unchanged and do not translate them.
Do not output the original (pre-translation) text under any circumstances.
The number and order of output lines must always match the input exactly: output line n must correspond to input line n.
Output only the translated lines or unchanged tags/blank lines.
**Before finishing, carefully check that there are absolutely no omissions or duplicate content of any kind in your output.**
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
	'-',
    );
    warn Dumper \@command if opt('debug');
    $gpty->command(\@command)->setstdin($text)->update->data;
}

sub _progress {
    print STDERR @_ if opt('progress');
}

sub xlate_each {
    my $call = $param{$method}->{sub} // die;
    my @count = map { int tr/\n/\n/ } @_;
    my $lines = sum @count;
    _progress("From:\n", map s/^/\t< /mgr, @_);
    my $to = $call->(join '', @_);
    if ((my @to = split /(?<=\n)\n+/, $to) > 1) {
	$to = join '', map { /(.+\n)\z/ ? $1 : die } @to;
    }
    my @out = $to =~ /^.+\n/mg;
    _progress("To:\n", map s/^/\t> /mgr, @out);
    if ($lines == 1 and @out > 1) {
	@out = ( join "", splice @out );
    }
    if (@out != $lines) {
	die sprintf("\nUnexpected response: [ %d != %d ]\n\n%s\n",
		    @out+0, $lines, $to);
    }
    map { join '', splice @out, 0, $_ } @count;
}

sub xlate {
    my @from = map { /\n\z/ ? $_ : "$_\n" } @_;
    my @to;
    my $maxsize = $App::Greple::xlate::max_length || $param{$method}->{max} // die;
    my $maxline = $App::Greple::xlate::max_line || 1;
    if (my @len = grep { $_ > $maxsize } map length, @from) {
	die "Contain lines longer than max length (@len > $maxsize).\n";
    }
    while (@from) {
	my @tmp;
	my $len = 0;
	while (@from) {
	    my $next = length $from[0];
	    last if $len + $next > $maxsize;
	    $len += $next;
	    push @tmp, shift @from;
	    last if $maxline > 0 and @tmp >= $maxline;
	}
	@tmp > 0 or die "Probably text is longer than max length ($maxsize).\n";
	push @to, xlate_each @tmp;
    }
    @to;
}

1;

__DATA__

# set in &initialize()
# option default -Mxlate --xlate-engine=gptN
