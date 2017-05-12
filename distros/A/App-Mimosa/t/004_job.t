use Test::Most tests => 6;
use strict;
use warnings;

use lib 't/lib';
use App::Mimosa::Test;
use Test::DBIx::Class;

fixtures_ok 'basic_ss';

BEGIN{ use_ok 'App::Mimosa::Job' }

my $job = App::Mimosa::Job->new( db_basename => "foo", alphabet => 'protein', job_id => 42 );
isa_ok $job, 'App::Mimosa::Job';

can_ok $job, qw/program input_file output_file run db_basename alphabet config alignment_view/;

throws_ok {
    my $job = App::Mimosa::Job->new( db_basename => "foo", alphabet => 'protein' );

} qr/Attribute \(job_id\) is required/, 'creating a job without a job_id blows up';

lives_ok{
    App::Mimosa::Job->new( db_basename=> "foo", program => "tblastx", job_id => 42, alphabet => 'protein' );
} 'tblastx is a valid program';
