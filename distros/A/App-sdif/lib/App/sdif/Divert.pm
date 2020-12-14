package App::sdif::Divert;

use v5.14;
use warnings;
use utf8;
use Encode;
use Carp;
use Data::Dumper;

sub new {
    my $class = shift;
    my %obj = (BUFFER => '', @_);
    open $obj{FH}, ">:encoding(utf8)", \$obj{BUFFER} or die;
    $obj{STDOUT} = select $obj{FH} or die;
    bless \%obj, $class;
}

sub fh {
    my $obj = shift;
    $obj->{FH};
}

sub buffer {
    my $obj = shift;
    \$obj->{BUFFER};
}

sub flush {
    my $obj = shift;
    $obj->fh->flush;
}

sub clear {
    my $obj = shift;
    $obj->flush;
    seek $obj->fh, 0, 0;
    $obj->fh->truncate(0);
    $obj->{BUFFER} = '';
}

sub DESTROY {
    my $obj = shift;
    $obj->fh->close;
    select $obj->{STDOUT};
    $obj->{BUFFER} // return;
    if (my $final = $obj->{FINAL}) {
	do { $final->() } for $obj->{BUFFER};
    }
    print decode 'utf8', $obj->{BUFFER};
}

1;
