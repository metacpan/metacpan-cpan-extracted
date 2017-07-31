package AI::XGBoost::Booster;

use strict;
use warnings;
use utf8;

our $VERSION = '0.008';    # VERSION

# ABSTRACT: XGBoost main class for training, prediction and evaluation

use Moose;
use AI::XGBoost::CAPI qw(:all);

has _handle => ( is       => 'rw',
                 init_arg => undef, );

sub update {
    my $self = shift;
    my %args = @_;
    my ( $iteration, $dtrain ) = @args{qw(iteration dtrain)};
    XGBoosterUpdateOneIter( $self->_handle, $iteration, $dtrain->handle );
    return $self;
}

sub boost {
    my $self = shift;
    my %args = @_;
    my ( $dtrain, $grad, $hess ) = @args{qw(dtrain grad hess)};
    XGBoosterBoostOneIter( $self->_handle, $dtrain, $grad, $hess );
    return $self;
}

sub predict {
    my $self        = shift;
    my %args        = @_;
    my $data        = $args{'data'};
    my $result      = XGBoosterPredict( $self->_handle, $data->handle );
    my $result_size = scalar @$result;
    my $matrix_rows = $data->num_row;
    if ( $result_size != $matrix_rows && $result_size % $matrix_rows == 0 ) {
        my $col_size = $result_size / $matrix_rows;
        return [ map { [ @$result[ $_ * $col_size .. $_ * $col_size + $col_size - 1 ] ] } 0 .. $matrix_rows - 1 ];
    }
    return $result;
}

sub set_param {
    my $self = shift;
    my ( $name, $value ) = @_;
    XGBoosterSetParam( $self->_handle, $name, $value );
    return $self;
}

sub set_attr {
    my $self = shift;
    my ( $name, $value ) = @_;
    XGBoosterSetAttr( $self->_handle, $name, $value );
    return $self;
}

sub get_attr {
    my $self = shift;
    my ($name) = @_;
    XGBoosterGetAttr( $self->_handle, $name );
}

sub attributes {
    my $self = shift;
    return { map { $_ => $self->get_attr($_) } @{ XGBoosterGetAttrNames( $self->_handle ) } };
}

sub TO_JSON {
    my $self = shift;
    my $trees = XGBoosterDumpModelEx( $self->_handle, "", 1, "json" );
    return "[" . join( ',', @$trees ) . "]";
}

sub BUILD {
    my $self = shift;
    my $args = shift;
    $self->_handle( XGBoosterCreate( [ map { $_->handle } @{ $args->{'cache'} } ] ) );
}

sub DEMOLISH {
    my $self = shift();
    XGBoosterFree( $self->_handle );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

AI::XGBoost::Booster - XGBoost main class for training, prediction and evaluation

=head1 VERSION

version 0.008

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

=head1 DESCRIPTION

Booster objects control training, prediction and evaluation

Work In Progress, the API may change. Comments and suggestions are welcome!

=head1 METHODS

=head2 update

Update one iteration

=head3 Parameters

=over 4

=item iteration

Current iteration number

=item dtrain

Training data (AI::XGBoost::DMatrix)

=back

=head2 boost

Boost one iteration using your own gradient

=head3 Parameters

=over 4

=item dtrain

Training data (AI::XGBoost::DMatrix)

=item grad

Gradient of your objective function (Reference to an array)

=item hess

Hessian of your objective function, that is, second order gradient (Reference to an array)

=back

=head2 predict

Predict data using the trained model

=head3 Parameters

=over 4

=item data

Data to predict

=back

=head2 set_param

Set booster parameter

=head3 Example

    $booster->set_param('objective', 'binary:logistic');

=head2 set_attr

Set a string attribute

=head2 get_attr

Get a string attribute

=head2 attributes

Returns all attributes of the booster as a HASHREF

=head2 TO_JSON

Serialize the booster to JSON.

This method is to be used with the option C<convert_blessed> from L<JSON>.
(See L<https://metacpan.org/pod/JSON#OBJECT-SERIALISATION>)

Warning: this API is subject to changes

=head2 BUILD

Use new, this method is just an internal helper

=head2 DEMOLISH

Internal destructor. This method is called automatically

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Pablo Rodríguez González.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
