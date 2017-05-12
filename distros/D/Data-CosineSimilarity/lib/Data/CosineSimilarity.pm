package Data::CosineSimilarity;
use strict;
use warnings;

our $VERSION = 0.02;

=head1 NAME

Data::CosineSimilarity - Compute the Cosine Similarity

=head1 SYNOPSIS

 $cs = Data::CosineSimilarity->new;
 $cs->add( label1 => { feature1 => 3, feature2 => 1, feature3 => 10 } );
 $cs->add( label2 => ... );
 $cs->add( label3 => ... );

 # computes the cosine similarity
 my $r = $cs->similarity( 'label1', 'label2' );

 # the result object
 my $cosine = $r->cosine;
 my $radian = $r->radian;
 my $degree = $r->degree;
 my ($label1, $label2) = $r->labels;

 # computes all the cosine similarity between 'label1' and the others.
 my @all = $cs->all_for_label('label1');

 # computes all, and returns the best
 my ($best_label, $r) = $cs->best_for_label('label2');

 # computes all, and returns the worst
 my ($worst_label, $r) = $cs->worst_for_label('label2');

=head1 DESCRIPTION

Compute the cosine similarities between a set of vectors.

=head2 $class->new( %opts )

If all the feature vectors are normed then the computation of the cosine
becomes just the dot product of the vectors. In this case, specify the
option normed => 1, the performance will be greatly improved.

=cut

sub new {
    my $class = shift;
    my %opts = @_;
    return bless {
        normed => $opts{normed} ? 1 : 0,
        labels => {},
    }, $class;
}

=head2 $self->add( label => $features )

=cut

sub add {
    my $self = shift;
    my ($label, $features) = @_;
    die 'label required' unless $label;
    die 'features required' unless $features;
    die 'features must be a hashref'
        unless ref $features eq 'HASH';
    die 'features must contain terms'
        unless keys %$features;

    my $norm = $self->{normed} ? 1 : _euclidean_norm($features);

    die 'euclidean norm is null' if $norm == 0;

    $self->{labels}{$label} = {
        features => $features,
        norm => $norm,
    };
}

sub _euclidean_norm {
    my ($features) = @_;
    my $sum = 0;
    $sum += $_**2 for values %$features;
    return sqrt $sum;
}

sub _scalar_product {
    my ($features1, $features2) = @_;
    my $product = 0;
    for (keys %$features1) {
        my $c1 = $features1->{$_};
        my $c2 = $features2->{$_} or next;
        $product += $c1 * $c2;
    }
    return $product;
}

=head2 $self->similarity( $label1, $label2 )

=cut

sub similarity {
    my $self = shift;
    my ($label1, $label2) = @_;

    my $product = _scalar_product(
        $self->{labels}{$label1}{features},
        $self->{labels}{$label2}{features}
    );

    my $cosine;
    if ($self->{normed}) {
        $cosine = $product;
    }
    else {
        $cosine = $product / ( $self->{labels}{$label1}{norm} * $self->{labels}{$label2}{norm} );
    }

    return Data::CosineSimilarity::Result->_new(
        labels => [ $label1, $label2 ],
        cosine => $cosine,
    );
}

=head2 $self->all_for_label( $label )

=cut

sub all_for_label {
    my $self = shift;
    my ($label) = @_;
    my @result;
    for (keys %{ $self->{labels} }) {
        next if $_ eq $label;
        push @result, $self->similarity($label, $_);
    }
    return sort { $b->cosine <=> $a->cosine } @result;
}

=head2 $self->best_for_label( $label )

=cut

sub best_for_label {
    my $self = shift;
    my ($label) = @_;
    my @sorted = $self->all_for_label($label);
    my $r = shift @sorted;
    my (undef, $best) = $r->labels;
    return ($best, $r);
}

=head2 $self->worst_for_label( $label )

=cut

sub worst_for_label {
    my $self = shift;
    my ($label) = @_;
    my @sorted = $self->all_for_label($label);
    my $r = pop @sorted;
    my (undef, $worst) = $r->labels;
    return ($worst, $r);
}

package Data::CosineSimilarity::Result;
use strict;
use warnings;

use Math::Trig;

sub _new {
    my $class = shift;
    my %args = @_;
    return bless \%args, $class;
}

sub labels { @{ $_[0]->{labels} } }

sub cosine { $_[0]->{cosine} }

sub radian { acos( $_[0]->cosine ) }

sub degree { rad2deg( $_[0]->radian ) }

=head1 AUTHOR

Antoine Imbert, C<< <antoine.imbert at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
