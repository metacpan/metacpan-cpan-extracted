package App::Greple::xlate::deepl;

our $VERSION = "0.02";

use v5.14;
use warnings;

use App::cdif::Command;

our $lang_from = 'ORIGINAL';
our $lang_to = 'JA';
our $auth_key;

sub xlate {
    state $deepl = App::cdif::Command->new;
    state $command = [ 'deepl', 'text',
		       '--to' => $lang_to,
		       $auth_key ? ('--auth-key' => $auth_key) : () ];
    my $from = shift;
    my $to = $deepl->command([@$command, $from])->update->data;
    return $to;
}

1;

__DATA__

option default -Mxlate --xlate-engine=deepl
