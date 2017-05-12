package Algorithm::ContextVector;
use strict;
use warnings;

our $VERSION = 0.01;

=head1 NAME

Algorithm::ContextVector - Simple implementation based on Data::CosineSimilarity

=head1 SYNOPSIS

 my $cv = Algorithm::ContextVector->new( top => 300 );

 $cs->add_instance( label => 'label1', attributes => { feature1 => 3, feature2 => 1, feature3 => 10 } );
 $cs->add_instance( label => [ 'label2', 'label3' ], attributes => { ... } );
 $cs->add_instance( label => ..., attributes => ... );
 ...

 $cv->train;

 my $results = $cv->predict( attributes => { ... } );

=head1 DESCRIPTION

Simple implementation based on Data::CosineSimilarity

=head2 $class->new( top => ... )

During the training, keeps the $top most heavy weighted features.
Keeps the complete feature set if omitted.

=cut

use Data::CosineSimilarity;
use Storable;

sub new {
    my $class = shift;
    my %opts = @_;
    return bless {
        top => $opts{top},
        labels => {},
    }, $class;
}

=head2 $class->new_from_file( $filename )

Returns the instance of Algorithm::ContextVector stored in $filename.

=cut

sub new_from_file {
    my $class = shift;
    my ($file) = @_;
    return retrieve($file);
}

=head2 $self->save_to_file( $filename )

Save the $self to $filename using Storable.

=cut

sub save_to_file {
    my $self = shift;
    my ($file) = @_;
    store($self, $file);
}

sub _add_hashrefs {
    my $self = shift;
    my @list = @_;
    my %r;
    for my $h (@list) {
        for my $key (keys %$h) {
            $r{$key} ||= 0;
            $r{$key} = $r{$key} + $h->{$key};
        }
    }
    return \%r;
}

=head2 $self->add_instance( label => [ ... ], attributes => { ... } )

=cut

sub add_instance {
    my $self = shift;
    my %args = @_;

    my $attr = $args{attributes} or die 'attributes required';
    return unless keys %$attr;

    my $labels = $args{label} or die 'label required';
    $labels = [ $labels ] unless ref $labels;

    for $_ (@$labels) {
        $self->{labels}{$_}{features} ||= {};
        $self->{labels}{$_}{features} = $self->_add_hashrefs(
            $self->{labels}{$_}{features}, $attr
        );
    }
}

sub _norm_features {
    my $self = shift;
    my ($features) = @_;
    my $norm = 0;
    $norm += $_**2 for values %$features;
    $norm = sqrt($norm);
   
    $_ = $_ / $norm for values %$features;

    return $features;
}

sub _cut_features {
    my $self = shift;
    my ($features) = @_;
    my $top = $self->{top};
    return $features unless defined $top;

    my @sorted =
        sort { $b->[1] <=> $a->[1] } 
        map { [ $_, $features->{$_} ] }
        keys %$features;

    my @keep = splice @sorted, 0, $top;

    my $r = { map { $_->[0] => $_->[1] } @keep };

    return $r;
}

# IDEA dead code for now
sub _cut_features_avg {
    my $features = shift; 
    my $sum = 0;
    $sum += $_ for values %$features;
    my $count = scalar keys %$features;
    my $cut = $sum / $count; # hum cut at the avg
    for (keys %$features) {
        delete $features->{$_} if $features->{$_} < $cut;
    }
    return $features;
}

=head2 $self->train

Keeps the best features (top N) and norms the vectors.

=cut

sub train {
    my $self = shift;
    for $_ (keys %{ $self->{labels} }) {
        $self->{labels}{$_}{features} = $self->_cut_features( $self->{labels}{$_}{features} );
        $self->{labels}{$_}{features} = $self->_norm_features( $self->{labels}{$_}{features} );
    }
}

=head2 $self->predict( attributes => { ... } )

Returns a hashref with the labels as the keys and the cosines as the values.

=cut

sub predict {
    my $self = shift;
    my %args = @_;

    my $attr = $args{attributes} or die 'attributes required';
   
    my $cs = Data::CosineSimilarity->new( normed => 1 );

    for my $label (keys %{ $self->{labels} }) {
        $cs->add( $label => $self->{labels}{$label}{features} );
    }
    
    $cs->add( __my_test => $self->_norm_features( $self->_cut_features( $attr ) ) );

    my @all = $cs->all_for_label('__my_test');
    my %r;
    for (@all) {
        my (undef, $label) = $_->labels;
        $r{$label} = $_->cosine;
    }
    return \%r;
}

=head1 AUTHOR

Antoine Imbert, C<< <antoine.imbert at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
