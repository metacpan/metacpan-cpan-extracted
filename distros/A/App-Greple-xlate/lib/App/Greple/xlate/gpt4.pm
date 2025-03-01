package App::Greple::xlate::gpt4;

our $VERSION = "0.9906";

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
    gpt3 => { engine => 'gpt-3.5-turbo', temp => '0.0', max => 3000, sub => \&gpty,
	      prompt => 'Translate following entire text into %s, line-by-line.',
	  },
    gpt4 => { engine => 'gpt-4-turbo', temp => '0.0', max => 3000, sub => \&gpty,
	      prompt => "Translate following entire text into %s, line-by-line.\n"
		      . "Leave XML style tag as it is.\n"
		      ,
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
    _progress("From:\n", map s/^/\t< /mgr, @_);
    my $to = $call->(join '', @_);
    my @out = $to =~ /^.+\n/mg;
    _progress("To:\n", map s/^/\t> /mgr, @out);
    if (@out < sum @count) {
	die "Unexpected response:\n\n$to\n";
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
