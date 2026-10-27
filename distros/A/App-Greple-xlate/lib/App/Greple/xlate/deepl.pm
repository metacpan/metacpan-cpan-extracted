package App::Greple::xlate::deepl;

our $VERSION = "2.03";

use v5.14;
use warnings;
use Encode;
use Data::Dumper;

use List::Util qw(sum);
use Command::Run;

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

sub deepl_command {
    my @tags = @_;
    my $glossary = $App::Greple::xlate::glossary;
    my @c = ('deepl', 'text');
    push @c, ('--to', $lang_to);
    push @c, ('--from', $lang_from) if $lang_from ne 'ORIGINAL';
    push @c, ('--auth-key', $auth_key) if $auth_key;
    push @c, ('--glossary-id', $glossary) if $glossary;
    if (@tags) {
        # Marker placeholders are self-closing XML tags.  Tell DeepL to
        # preserve their tag names and id attributes instead of treating
        # them as ordinary translatable text.
        push @c, '--tag-handling', 'xml',
            '--non-splitting-tags', join(',', @tags);
    }
    if (my @contexts = @{$opt{contexts}}) {
        push @c, '--context' => join "\n", @contexts;
    }
    @c;
}

sub _xml_wrap {
    my $text = shift;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s{
        &lt;([a-z][a-z0-9_]*)\s+([a-z0-9_]+)="(\d+)"\s*/&gt;
    }{<$1 $2="$3"/>}gx;
    "<xlate>$text</xlate>";
}

sub _marker_tags {
    my $text = shift;
    my %tag;
    $tag{$1} = 1 while $text =~ m{
        <([a-z][a-z0-9_]*)\s+[a-z0-9_]+="\d+"\s*/>
    }gx;
    sort keys %tag;
}

sub _xml_unwrap {
    my($text, $source) = @_;
    $text =~ s/\A<xlate>//
        or die "DeepL XML response has no opening wrapper.\n";
    $text =~ s{</xlate>\r?\n?\z}{}
        or die "DeepL XML response has no closing wrapper.\n";
    $text =~ s{
        <([a-z][a-z0-9_]*)\s+([a-z0-9_]+)=["'](\d+)["']\s*/>
    }{<$1 $2="$3" />}gx;
    $text =~ s{
        <([a-z][a-z0-9_]*)\s+([a-z0-9_]+)=["'](\d+)["']\s*>\s*</\1>
    }{<$1 $2="$3" />}gx;
    $text =~ s/&lt;/</g;
    $text =~ s/&gt;/>/g;
    $text =~ s/&amp;/&/g;
    while ($source =~ m{
        (<[a-z][a-z0-9_]*\s+[a-z0-9_]+="\d+"\s*/>)
        (\s+)
        (?=(<[a-z][a-z0-9_]*\s+[a-z0-9_]+="\d+"\s*/>))
    }gx) {
        my($left, $space, $right) = ($1, $2, $3);
        $text =~ s/\Q$left$right\E/$left$space$right/g;
    }
    $text;
}

sub deepl {
    state $deepl = Command::Run->new;
    my $text = shift;
    my @tags = _marker_tags($text);
    my @command = deepl_command(@tags);
    my $source = $text;
    $text = _xml_wrap($text) if @tags;
    my $data = $deepl->command(@command, $text)->update->data;
    @tags ? _xml_unwrap($data, $source) : $data;
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
