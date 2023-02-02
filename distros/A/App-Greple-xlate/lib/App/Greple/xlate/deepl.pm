package App::Greple::xlate::deepl;

our $VERSION = "0.03";

use v5.14;
use warnings;
use Data::Dumper;

use App::cdif::Command;

our $lang_from = 'ORIGINAL';
our $lang_to = 'JA';
our $auth_key;
our $max_length = 128 * 1024;

sub xlate {
    $DB::single = 1;
    state $deepl = App::cdif::Command->new;
    state $command = [ 'deepl', 'text',
		       '--to' => $lang_to,
		       $auth_key ? ('--auth-key' => $auth_key) : () ];
    my @from = map { /\n\z/ ? $_ : "$_\n" } @_;
    my $from = join '', @from;
    my $to = $deepl->command([@$command, $from])->update->data;
    wantarray ? $to =~ /.+\n/g : $to;
}

1;

__DATA__

option default -Mxlate --xlate-engine=deepl
