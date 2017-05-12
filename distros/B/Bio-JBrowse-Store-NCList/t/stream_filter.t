use strict;
use warnings;

use Test::More;

use lib 't/lib';
use FileSlurping 'slurp_stream';

my @test_features = (
    { seq_id => 'ctgB', start => 20,   end => 20 },
    { seq_id => 'ctgA', start => 43,   end => 70 },
    { seq_id => 'ctgA', start => 4102, end => 4800, biggie => 'smalls' },
    { seq_id => 'ctgA', start => 42,   end => 64,   noggin => 'fogbat',
      subfeatures => [
          { start => 44, end => 44 }
      ]
    },
);

use_ok( 'Bio::JBrowse::FeatureStream::Filter' );

{
    my @f = @test_features;
    my $test_stream = sub { shift @f };
    my $filtered = Bio::JBrowse::FeatureStream::Filter->new(
        $test_stream,
        sub {
            return $_[0]->{start} == 44;
        });
    my @result = slurp_stream( $filtered );
    is_deeply(
        \@result,
        [
            { end => 44, start => 44 }
        ]) or diag explain \@result;

}

{
    my @f = @test_features;
    my $test_stream = sub { shift @f };
    my @results = slurp_stream(
        Bio::JBrowse::FeatureStream::Filter->new(
            $test_stream,
            sub {
                return $_[0]->{end} == 70 || $_[0]->{start} == 44;
            }
        )
    );

    is_deeply(
        \@results,
        [
          { seq_id => 'ctgA', start => 43,   end => 70 },
          { start => 44, end => 44 }
        ]) or diag explain \@results;

}

done_testing;
