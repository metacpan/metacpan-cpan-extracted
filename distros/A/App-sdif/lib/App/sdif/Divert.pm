package App::sdif::Divert;

use v5.14;
use warnings;
use utf8;
use Encode;
use Carp;

sub new {
    my $class = shift;
    my %obj = @_;
    open $obj{FH}, ">:encoding(utf8)", \$obj{BUFFER} or die;
    $obj{STDOUT} = select $obj{FH} or die;
    bless \%obj, $class;
}

sub DESTROY {
    my $obj = shift;
    close $obj->{FH};
    select $obj->{STDOUT};
    $obj->{BUFFER} // return;
    if (my $final = $obj->{FINAL}) {
	do { $final->() } for $obj->{BUFFER};
    }
    print decode 'utf8', $obj->{BUFFER};
}

1;
