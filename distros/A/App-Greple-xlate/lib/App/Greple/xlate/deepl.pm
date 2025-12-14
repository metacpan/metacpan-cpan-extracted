package App::Greple::xlate::deepl;

our $VERSION = "0.9920";

use v5.14;
use warnings;
use Encode;
use Data::Dumper;

use List::Util qw(sum);
use App::cdif::Command;

use App::Greple::xlate qw(%opt &opt);
use App::Greple::xlate::Lang qw(%LANGNAME);

our $lang_from //= 'ORIGINAL';
our $lang_to   //= 'JA';
our $auth_key;
our $method //= 'deepl';

my %param = (
    deepl     => { max => 128 * 1024, sub => \&deepl },
    clipboard => { max => 5000,       sub => \&clipboard },
    );

sub deepl {
    state $deepl = App::cdif::Command->new;
    state $command = do {
	my $glossary = $App::Greple::xlate::glossary;
	my   @c = ('deepl', 'text');
	push @c,  ('--to', $lang_to);
	push @c,  ('--from', $lang_from) if $lang_from ne 'ORIGINAL';
	push @c,  ('--auth-key', $auth_key) if $auth_key;
	push @c,  ('--glossary-id', $glossary) if $glossary;
	if (my @contexts = @{$opt{contexts}}) {
	    push @c, '--context' => join "\n", @contexts;
	}
	\@c;
    };
    $deepl->command([@$command, +shift])->update->data;
}

sub clipboard {
    require Clipboard and import Clipboard unless state $called++;
    my $from = shift;
    my $length = length $from;
    Clipboard->copy($from);
    STDERR->printflush(
	"$length characters stored in the clipboard.\n",
	"Translate it to \"$lang_to\" and clip again.\n",
	"Then hit enter: ");
    if (open my $fh, "/dev/tty" or die) {
	my $answer = <$fh>;
    }
    my $to = Clipboard->paste;
    $to = decode('utf8', $to) if not utf8::is_utf8($_);
    return $to;
}

sub _progress {
    print STDERR @_ if opt('progress');
}

sub xlate_each {
    my $call = $param{$method}->{sub} // die;
    my @count = map { int tr/\n/\n/ } @_;
    _progress("From:\n", map s/^/\t< /mgr, @_);
    my $to = $call->(join '', @_);
    my @out = $to =~ /.*\n/g;
    _progress("To:\n", map s/^/\t> /mgr, @out);
    if (@out < sum @count) {
	die "Unexpected response:\n\n$to\n";
    }
    map { join '', splice @out, 0, $_ } @count;
}

sub xlate {
    my @from = @_;
    my @to;
    my $max = $App::Greple::xlate::max_length || $param{$method}->{max} // die;
    while (@from) {
	my @tmp;
	my $len = 0;
	while (@from) {
	    my $next = length $from[0];
	    last if $len + $next > $max;
	    $len += $next;
	    push @tmp, shift @from;
	}
	push @to, xlate_each @tmp;
    }
    @to;
}

1;

__DATA__

option default -Mxlate --xlate-engine=deepl
