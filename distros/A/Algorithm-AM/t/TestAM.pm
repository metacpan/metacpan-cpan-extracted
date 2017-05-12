# provide some helper functions for use throughout the other test files
# helps to keep commonly-used data (chapter 3) in one place
package t::TestAM;
use strict;
use warnings;
use Algorithm::AM;
use Exporter::Easy (
    OK => [qw(
        chapter_3_project
        chapter_3_data
        chapter_3_train
        chapter_3_test)]
);

# return a dataset containing training items from chapter 3
sub chapter_3_train {
    my $train = Algorithm::AM::DataSet->new(cardinality => 3);
    for my $datum(chapter_3_data()){
        $train->add_item(
            features => $datum->[0],
            class => $datum->[1],
            comment => $datum->[2]
        );
    }
    return $train;
}

# return the data set used for training in chapter 3
sub chapter_3_test {
    my $test = Algorithm::AM::DataSet->new(cardinality => 3);
    $test->add_item(
        features => [qw(3 1 2)],
        class => 'r',
        comment => 'test item comment'
    );
    return $test;
}

# return a list of array refs containing the items from chapter 3
sub chapter_3_data {
    return (
        [[qw(3 1 0)], 'e', 'myFirstCommentHere'],
        [[qw(2 1 0)], 'r', 'mySecondCommentHere'],
        [[qw(0 3 2)], 'r', 'myThirdCommentHere'],
        [[qw(2 1 2)], 'r', 'myFourthCommentHere'],
        [[qw(3 1 1)], 'r', 'myFifthCommentHere']
    );
}

1;
