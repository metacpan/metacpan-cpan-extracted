package App::Greple::xlate::gpt4o;

our $VERSION = "0.9905";

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
    gpt4o => { engine => 'gpt-4o-mini', temp => '0.0', max => 3000, sub => \&gpty,
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
