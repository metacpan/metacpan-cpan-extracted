use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 9;
}
use Data::Stag qw(:all);
use Data::Stag::BaseGenerator;
use FileHandle;

my $p = Data::Stag::BaseGenerator->new;
my $h = Data::Stag->getformathandler('sxpr');
$p->handler($h);

sub go {
    my $p = shift;
    $p->start_event('foo');
    $p->evbody('');
    $p->event(bar=>'1');
    $p->end_event('foo');
}

go($p);

$p = Data::Stag::BaseGenerator->new;
go($p);
print stag_xml($p->handler->tree);

