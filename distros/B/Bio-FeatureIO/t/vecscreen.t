# -*-Perl-*- Test Harness script for Bioperl
# $Id: FeatureIO.t 15112 2008-12-08 18:12:38Z sendu $

use strict;
use warnings;
use Bio::Root::Test;
use Bio::FeatureIO;

{
    my @expected_features =
    (
        {
         'seq_id' => 'C02HBa0072A04.1',
         'primary_tag' => 'moderate_match',
         'end' => '60548',
         'start' => '60522'
        },
        {
         'seq_id' => 'SL_FOS91h17_SP6_0',
         'primary_tag' => 'strong_match',
         'end' => '122',
         'start' => '60'
        },
        {
         'seq_id' => 'SL_FOS91h18_T7_0',
         'primary_tag' => 'strong_match',
         'end' => '102',
         'start' => '35'
        },
        {
         'seq_id' => 'SL_FOS91h18_T7_0',
         'primary_tag' => 'moderate_match',
         'end' => '103',
         'start' => '76'
        },
        {
         'seq_id' => 'SL_FOS91h18_T7_0',
         'primary_tag' => 'weak_match',
         'end' => '104',
         'start' => '82'
        },
        {
         'seq_id' => 'SL_FOS91h18_T7_0',
         'primary_tag' => 'suspect_origin',
         'end' => '34',
         'start' => '1'
        },
        {
         'seq_id' => 'SL_FOS91i01_SP6_0',
         'primary_tag' => 'strong_match',
         'end' => '110',
         'start' => '46'
        },
        {
         'seq_id' => 'SL_FOS91i01_SP6_0',
         'primary_tag' => 'suspect_origin',
         'end' => '45',
         'start' => '1'
        },
        {
         'seq_id' => 'SL_FOS92b12_T7_0',
         'primary_tag' => 'strong_match',
         'end' => '108',
         'start' => '41'
        },
        {
         'seq_id' => 'SL_FOS92b12_T7_0',
         'primary_tag' => 'moderate_match',
         'end' => '109',
         'start' => '82'
        },
        {
         'seq_id' => 'SL_FOS92b12_T7_0',
         'primary_tag' => 'weak_match',
         'end' => '110',
         'start' => '88'
        },
        {
         'seq_id' => 'SL_FOS92b12_T7_0',
         'primary_tag' => 'weak_match',
         'end' => '1329',
         'start' => '1313'
        },
        {
         'seq_id' => 'SL_FOS92b12_T7_0',
         'primary_tag' => 'suspect_origin',
         'end' => '40',
         'start' => '1'
        },
        {
         'seq_id' => 'SL_FOS92b12_T7_0',
         'primary_tag' => 'suspect_origin',
         'end' => '1334',
         'start' => '1330'
        }
    );
    my @vs_features;
    my $vs_in = Bio::FeatureIO->new( -file => test_input_file('vecscreen_simple.test_output'),
                     -format => 'vecscreen_simple',
                   );
    ok( $vs_in );
    while(my $feat = $vs_in->next_feature) {
      push @vs_features,$feat;
    }
  
    #convert the array of feature objects to something that can more easily be checked with is_deeply
    @vs_features = map {
        my $f = $_;
        my $rec = { map {$_ => $f->$_()} qw/start end primary_tag seq_id/ };
    } @vs_features;
  
    is_deeply(\@vs_features,\@expected_features,'vecscreen_simple gets the correct features');
}

done_testing();

exit;
