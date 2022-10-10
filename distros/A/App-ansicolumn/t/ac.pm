package ac;

use parent "App::cdif::Command";

use v5.14;
use warnings;
use utf8;
use Carp;
use Data::Dumper;

$ENV{PERL5LIB} = join ':', @INC;

sub new {
    my $class = shift;
    my $obj = $class->SUPER::new();
    $obj->command([ $^X, qw(-Ilib script/ansicolumn), @_ ]);
    $obj;
}

sub exec {
    my $obj = shift;
    my $stdin = shift;
    $obj->setstdin($stdin) if defined $stdin;
    my $result = $obj->update->data;
    $result =~ s/ +$//mg;
    $result;
}

1;
