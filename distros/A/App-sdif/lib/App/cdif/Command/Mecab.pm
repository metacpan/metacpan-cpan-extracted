package App::cdif::Command::Mecab;

use parent "App::cdif::Command";

use strict;
use warnings;
use utf8;
use Carp;
use Data::Dumper;

our $debug;

sub wordlist {
    my $obj = shift;
    my $text = shift;

    my $eos = "EOS" . "000";
    $eos++ while $text =~ /$eos/;
    my $mecab = [ 'mecab', '--node-format', '%M\\n', '--eos-format', "$eos\\n" ];
    my $result = $obj->command($mecab)->setstdin($text)->update->data;
    warn $result =~ s/^/MECAB: /mgr if $debug;
    do {
	map  { $_ eq $eos ? "\n" : $_ }
	grep { length }
	$result =~ /^(\s*)(\S+)\n/mg;
    };
}

1;
