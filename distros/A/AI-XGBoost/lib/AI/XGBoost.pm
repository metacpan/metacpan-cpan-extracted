package AI::XGBoost;
use strict;
use warnings;

use AI::XGBoost::Booster;
use Exporter::Easy ( OK => ['train'] );

our $VERSION = '0.11';    # VERSION

# ABSTRACT: Perl wrapper for XGBoost library L<https://github.com/dmlc/xgboost>

sub train {
    my %args = @_;
    my ( $params, $data, $number_of_rounds ) = @args{qw(params data number_of_rounds)};

    my $booster = AI::XGBoost::Booster->new( cache => [$data] );
    if ( defined $params ) {
        while ( my ( $name, $value ) = each %$params ) {
            $booster->set_param( $name, $value );
        }
    }
    for my $iteration ( 0 .. $number_of_rounds - 1 ) {
        $booster->update( dtrain => $data, iteration => $iteration );
    }
    return $booster;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

AI::XGBoost - Perl wrapper for XGBoost library L<https://github.com/dmlc/xgboost>

=head1 VERSION

version 0.11

=head1 SYNOPSIS

 use 5.010;
 use aliased 'AI::XGBoost::DMatrix';
 use AI::XGBoost qw(train);
 
 # We are going to solve a binary classification problem:
 #  Mushroom poisonous or not
 
 my $train_data = DMatrix->From(file => 'agaricus.txt.train');
 my $test_data = DMatrix->From(file => 'agaricus.txt.test');
 
 # With XGBoost we can solve this problem using 'gbtree' booster
 #  and as loss function a logistic regression 'binary:logistic'
 #  (Gradient Boosting Regression Tree)
 # XGBoost Tree Booster has a lot of parameters that we can tune
 # (https://github.com/dmlc/xgboost/blob/master/doc/parameter.md)
 
 my $booster = train(data => $train_data, number_of_rounds => 10, params => {
         objective => 'binary:logistic',
         eta => 1.0,
         max_depth => 2,
         silent => 1
     });
 
 # For binay classification predictions are probability confidence scores in [0, 1]
 #  indicating that the label is positive (1 in the first column of agaricus.txt.test)
 my $predictions = $booster->predict(data => $test_data);
 
 say join "\n", @$predictions[0 .. 10];

 use aliased 'AI::XGBoost::DMatrix';
 use AI::XGBoost qw(train);
 use Data::Dataset::Classic::Iris;
 
 # We are going to solve a multiple classification problem:
 #  determining plant species using a set of flower's measures 
 
 # XGBoost uses number for "class" so we are going to codify classes
 my %class = (
     setosa => 0,
     versicolor => 1,
     virginica => 2
 );
 
 my $iris = Data::Dataset::Classic::Iris::get();
 
 # Split train and test, label and features
 my $train_dataset = [map {$iris->{$_}} grep {$_ ne 'species'} keys %$iris];
 my $test_dataset = [map {$iris->{$_}} grep {$_ ne 'species'} keys %$iris];
 
 sub transpose {
 # Transposing without using PDL, Data::Table, Data::Frame or other modules
 # to keep minimal dependencies
     my $array = shift;
     my @aux = ();
     for my $row (@$array) {
         for my $column (0 .. scalar @$row - 1) {
             push @{$aux[$column]}, $row->[$column];
         }
     }
     return \@aux;
 }
 
 $train_dataset = transpose($train_dataset);
 $test_dataset = transpose($test_dataset);
 
 my $train_label = [map {$class{$_}} @{$iris->{'species'}}];
 my $test_label = [map {$class{$_}} @{$iris->{'species'}}];
 
 my $train_data = DMatrix->From(matrix => $train_dataset, label => $train_label);
 my $test_data = DMatrix->From(matrix => $test_dataset, label => $test_label);
 
 # Multiclass problems need a diferent objective function and the number
 #  of classes, in this case we are using 'multi:softprob' and
 #  num_class => 3
 my $booster = train(data => $train_data, number_of_rounds => 20, params => {
         max_depth => 3,
         eta => 0.3,
         silent => 1,
         objective => 'multi:softprob',
         num_class => 3
     });
 
 my $predictions = $booster->predict(data => $test_data);

=head1 DESCRIPTION

Perl wrapper for XGBoost library. 

The easiest way to use the wrapper is using C<train>, but beforehand 
you need the data to be used contained in a C<DMatrix> object

This is a work in progress, feedback, comments, issues, suggestion and
pull requests are welcome!!

XGBoost library is used via L<Alien::XGBoost>. That means downloading,
compiling and installing if it's not available in your system.

=head1 FUNCTIONS

=head2 train

Performs gradient boosting using the data and parameters passed

Returns a trained AI::XGBoost::Booster used

=head3 Parameters

=over 4

=item params

Parameters for the booster object. 

Full list available: https://github.com/dmlc/xgboost/blob/master/doc/parameter.md 

=item data

AI::XGBoost::DMatrix object used for training

=item number_of_rounds

Number of boosting iterations

=back

=head1 ROADMAP

The goal is to make a full wrapper for XGBoost.

=head2 VERSIONS

=over 4

=item 0.2 

Full C API "easy" to use, with PDL support as L<AI::XGBoost::CAPI>

Easy means clients don't have to use L<FFI::Platypus> or modules dealing
with C structures

=item 0.25

Alien package for libxgboost.so/xgboost.dll

=item 0.3

Object oriented API Moose based with DMatrix and Booster classes

=item 0.4

Complete object oriented API

=item 0.5

Use perl signatures (L<https://metacpan.org/pod/distribution/perl/pod/perlexperiment.pod#Subroutine-signatures>)

=back

=head1 SEE ALSO

=over 4

=item L<AI::MXNet>

=item L<FFI::Platypus>

=item L<NativeCall>

=back

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2017 by Pablo Rodríguez González.

=head1 CONTRIBUTOR

=for stopwords Ruben

Ruben <me@ruben.tech>

=cut
