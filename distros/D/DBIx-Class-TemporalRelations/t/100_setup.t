use Test2::V0;
use Test2::Plugin::Times;
use Test2::Plugin::ExitSummary;
use Test2::Plugin::NoWarnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib 't/lib';

plan(1);

use TestSchema;
my $schema = TestSchema->connect();
my $info   = $schema->source('Human')->source_info;
like(
    $info,
    {
        temporal_relationships => {
            contraptions => [
                {
                    temporal_column => 'purchase_dt',
                    verb            => 'purchased',
                }
            ],
            doodads => [
                {
                    temporal_column => 'created_dt',
                    verb            => 'created',
                },
            ],
            doodads_modified_rel => [
                {
                    temporal_column => 'modified_dt',
                    verb            => 'modified',
                }
            ],
            doohickies_modified_rel => [
                {
                    temporal_column => 'modified_dt',
                    verb            => 'modified',
                    singular        => 'doohickey',
                }
            ],
            doohickies_purchased_rel => [
                {
                    temporal_column => 'purchase_dt',
                    verb            => 'purchased',
                    singular        => 'doohickey',
                    plural          => 'doohickees',
                }
            ]
        }
    },
    'Temporal relationships properly established using all methods'
);

exit;
