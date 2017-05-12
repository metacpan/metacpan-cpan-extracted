use strict;
use warnings;

use Test::More tests => 2;

use Brat::Handler;
use Brat::Handler::File;

my $brat = Brat::Handler->new();
ok( defined($brat) && ref $brat eq 'Brat::Handler',     'Brat::Handler->new() works' );

my $bratfile = Brat::Handler::File->new();
ok( defined($bratfile) && ref $bratfile eq 'Brat::Handler::File',     'Brat::Handler::File->new() works' );

