package App::cdif::Command::Mecab;

use parent "App::cdif::Command";

use v5.14;
use warnings;
use utf8;
use Carp;
use Data::Dumper;

our $debug;

sub wordlist {
    my $obj = shift;
    my $text = shift;

    ##
    ## mecab ignores trailing spaces.
    ##
    my $removeme = sub {
	local *_ = shift;
	return sub { 0 } unless /[ \t]+$/m;
	my $magic = "15570"."67583";
	$magic++ while /$magic/;
	s/[ \t]+\K$/$magic/mg;
	sub { $_ eq $magic };
    }->(\$text);

    my $eos = "EOS" . "000";
    $eos++ while $text =~ /$eos/;
    my $is_newline = sub { $_ eq $eos };

    my $mecab = [ 'mecab', '--node-format', '%M\\n', '--eos-format', "$eos\\n" ];
    my $result = $obj->command($mecab)->setstdin($text)->update->data;
    warn $result =~ s/^/MECAB: /mgr if $debug;
    do {
	map  { $is_newline->() ? "\n" : $_ }
	grep { not $removeme->() }
	grep { length }
	$result =~ /^(\s*)(\S+)\n/amg;
    };
}

1;
