package App::Greple::xlate::null;

our $VERSION = "0.9908";

use v5.14;
use warnings;
use Encode;
use Data::Dumper;

use App::Greple::xlate qw(opt);
use App::Greple::xlate::Lang qw(%LANGNAME);

sub xlate {
    @_;
}

1;

__DATA__

option default -Mxlate --xlate-engine=null
