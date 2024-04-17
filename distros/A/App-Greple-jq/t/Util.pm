use strict;
use warnings;
use utf8;
use File::Spec;
use open IO => ':utf8', ':std';
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use lib 't/runner';
use Runner qw(get_path);

my $greple_path = get_path('greple', 'App::Greple') or die Dumper \%INC;

sub has_jq {
    my @path = grep { -x } map { "$_/jq" } split /:+/, $ENV{PATH} or do {
	warn "jq command is not available.\n";
	return 0;
    };
    my $version = `$path[0] --version`;
    if ($? == 0) {
	warn "$version";
	return 1;
    } else {
	warn "jq command execution error.\n";
	return 0;
    }
}

my $module = has_jq() ? 'jq' : 'jq::set(noif)';

sub greple {
    Runner->new($greple_path, @_);
}

sub jq {
    greple "-M$module", @_;
}

sub run {
    greple(@_)->run;
}

sub line {
    my($text, $line, $comment) = @_;
    like($text, qr/\A(.*\n){$line}\z/, $comment//'');
}

1;
