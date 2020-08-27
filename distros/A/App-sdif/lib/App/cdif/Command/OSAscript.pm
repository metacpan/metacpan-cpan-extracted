package App::cdif::Command::OSAscript;

use parent "App::cdif::Command";

use v5.14;
use warnings;
use utf8;
use Carp;
use Data::Dumper;

sub new {
    my($class, %opt) = @_;
    my @command = qw(osascript);
    if (my $lang = delete $opt{LANG}) {
	push @command, "-l", $lang;
    }
    my $obj = $class->SUPER::new(%opt);
    $obj->command("@command");
    $obj;
}

sub exec {
    my $obj = shift;
    my $script = shift;
    $obj->setstdin($script)->update->data;
}

1;
