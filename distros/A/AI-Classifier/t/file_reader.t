use strict;
use warnings;

use Test::More;
use AI::Classifier::Text::FileLearner;
use File::Spec;
use Data::Dumper;

{
    my $iterator = AI::Classifier::Text::FileLearner->new( 
        training_dir => File::Spec->catdir( qw( something something else ) ) 
    );
    is( 
        $iterator->get_category( File::Spec->catdir( qw( something something else aaa bbb ) ) ),
        'aaa',
        'get_category' 
    );
}

my @training_dirs = qw( t data training_set_ordered );
my $iterator = AI::Classifier::Text::FileLearner->new( 
    training_dir => File::Spec->catdir( @training_dirs ) );


my %hash;
while( my $doc = $iterator->next ){
    $hash{$doc->{file}} = $doc;
}
my $target = {
    File::Spec->catfile( @training_dirs, 'spam', '1' ) => {
        'features' => { ccccc => 1, NO_URLS => 2 },
        'file' => File::Spec->catfile( @training_dirs, 'spam', '1' ),
        'categories' => [ 'spam' ]
    },
    File::Spec->catfile( @training_dirs, 'ham', '2' ) => {
        'features' => { ccccc => 1, aaaa => 1, NO_URLS => 2 },
        'file' => File::Spec->catfile( @training_dirs, 'ham', '2' ),
        'categories' => [ 'ham' ]
    }
};
is_deeply( \%hash, $target );

my $classifier = AI::Classifier::Text::FileLearner->new( training_dir => File::Spec->catdir( @training_dirs ) )->classifier;

ok( $classifier, 'Classifier created' );
ok( $classifier->classifier->model()->{prior_probs}{ham}, 'ham prior probs' );
ok( $classifier->classifier->model()->{prior_probs}{spam}, 'spam prior probs' );
{
    my $iterator = AI::Classifier::Text::FileLearner->new( training_dir => File::Spec->catdir( qw( t data training_initial_features ) ) );

    my %hash;
    while( my $doc = $iterator->next ){
        $hash{$doc->{file}} = $doc;
    }
    my $target = {
        File::Spec->catfile( qw( t data training_initial_features ham 1 ) ) => {
            'file' => File::Spec->catfile( qw( t data training_initial_features ham 1 ) ),
            'categories' => [ 'ham' ],
            features => { trala => 1, some_tag => 3, NO_URLS => 2 }
        },
    };
    is_deeply( \%hash, $target );
}

{
    {
        package TestLearner;

        sub new { bless { examples => [] } };
        sub add_example {
            my ( $self, @example ) = @_;
            push @{ $self->{examples} }, \@example;
        }

    }

    my $internal_learner = TestLearner->new();
    my $learner = AI::Classifier::Text::FileLearner->new( 
        training_dir => File::Spec->catdir( @training_dirs ),
        learner => $internal_learner
    );
    $learner->teach_it;
    my $weights;
    if( $internal_learner->{examples}[0][1]{aaaa} ){
        $weights = $internal_learner->{examples}[1][1];
    }
    else{
        $weights = $internal_learner->{examples}[0][1];
    }
    ok( abs( $weights->{ccccc} - 0.44 ) < 0.01
            and 
        abs( $weights->{NO_URLS} - 0.9 ) < 0.01 )
        or warn Dumper( $weights );
    
    $internal_learner = TestLearner->new();
    $learner = AI::Classifier::Text::FileLearner->new( 
        training_dir => File::Spec->catdir( @training_dirs ),
        learner => $internal_learner,
        term_weighting => 'n',
    );
    $learner->teach_it;
    if( $internal_learner->{examples}[0][1]{aaaa} ){
        $weights = $internal_learner->{examples}[1][1];
    }
    else{
        $weights = $internal_learner->{examples}[0][1];
    }
    ok( abs( $weights->{ccccc} - 0.75 ) < 0.01 );
    ok( abs( $weights->{NO_URLS} - 1 ) < 0.01 );
#    warn Dumper( $internal_learner ); use Data::Dumper;
}

done_testing;

