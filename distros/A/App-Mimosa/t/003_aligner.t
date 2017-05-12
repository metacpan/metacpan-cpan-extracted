use Test::Most tests => 4;
use strict;
use warnings;

use lib 't/lib';
use App::Mimosa::Test;
use Test::DBIx::Class;

fixtures_ok 'basic_ss';

BEGIN{ use_ok 'App::Mimosa::Aligner' }

my $aligner = App::Mimosa::Aligner->new;
isa_ok $aligner, 'App::Mimosa::Aligner';

can_ok $aligner, qw/evalue program substitution_matrix sequence_database/;
