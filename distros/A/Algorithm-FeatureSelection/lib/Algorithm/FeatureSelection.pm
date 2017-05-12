package Algorithm::FeatureSelection;
use strict;
use warnings;
use List::Util qw(sum);

our $VERSION = '0.02';

sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
    return $self;
}

sub pmi {
    my $self = shift;
    $self->pairewise_mutual_information(@_);
}

sub ig {
    my $self = shift;
    $self->information_gain(@_);
}

sub igr {
    my $self = shift;
    $self->information_gain_ratio(@_);
}

sub pairwise_mutual_information {
    my $self     = shift;
    my $features = shift;

    ## -----------------------------------------------------------------
    ##
    ## The argument is expected as below.
    ##
    ## $features = {
    ##     feature_1 => {
    ##         class_a => 10,
    ##         class_b => 2,
    ##     },
    ##     feature_2 => {
    ##         class_b => 11,
    ##         class_d => 32
    ##     },
    ##           .
    ##           .
    ##           .
    ## };
    ##
    ## -----------------------------------------------------------------
    ##
    ## Pairewise Mutual Information
    ##
    ## PMI(w, c) = log ( P( Xw = 1, C = c ) / P( Xw=1 )P( C=c ) )
    ##
    ##    c.f.  w = feature
    ##          c = Class
    ##
    ## -----------------------------------------------------------------

    my $feature_count;
    my $class_count;
    my $co_occur_count;
    my $all_features_num;
    while ( my ( $feature, $ref ) = each %$features ) {
        while ( my ( $class, $count ) = each %$ref ) {
            $feature_count->{$feature}                    += $count;
            $class_count->{$class}                        += $count;
            $co_occur_count->{ $class . "\t" . $feature } += $count;
            $all_features_num                             += $count;
        }
    }

    my $PMI;

    for ( keys %$co_occur_count ) {
        my $f12 = $co_occur_count->{$_};
        my ( $class, $feature ) = split "\t", $_;
        my $f1 = $feature_count->{$feature};
        my $f2 = $class_count->{$class};

        my $pmi_score = _log2( ( $f12 / $all_features_num )
            / ( ( $f1 / $all_features_num ) * ( $f2 / $all_features_num ) ) );

        $PMI->{$feature}->{$class} = $pmi_score;
    }

    return $PMI;
}

sub information_gain {
    my $self     = shift;
    my $features = shift;

    ## -----------------------------------------------------------------
    ##
    ## The argument is expected as below.
    ##
    ## $features = {
    ##     feature_1 => {
    ##         class_a => 10,
    ##         class_b => 2,
    ##     },
    ##     feature_2 => {
    ##         class_b => 11,
    ##         class_d => 32
    ##     },
    ##           .
    ##           .
    ##           .
    ## };
    ##
    ## -----------------------------------------------------------------
    ##
    ## Information Gain
    ##
    ## IG(w) = H(C) - ( P(Xw = 1) H(C|Xw = 1) + P(Xw = 0) H(C|Xw = 0) )
    ##
    ##    c.f. w = feature
    ##         C = class
    ##
    ## -----------------------------------------------------------------

    my $IG;

    my $classes;
    my $classes_sum;
    my $all_features_num;
    while ( my ( $feature, $ref ) = each %$features ) {
        while ( my ( $class, $count ) = each %$ref ) {
            $classes->{$class}->{$feature} += $count;
            $classes_sum->{$class}         += $count;
            $all_features_num              += $count;
        }
    }

    my @array;
    while ( my ( $class, $ref ) = each %$classes ) {
        my $sum     = sum( values %$ref );
        my $p_class = $sum / $all_features_num;
        push @array, $p_class;
    }
    my $entropy = $self->entropy( \@array );

    while ( my ( $feature, $ref ) = each %$features ) {

        my $sum = sum( values %$ref );

        # H ( C | Xw = 1)
        my $on_entropy;
        {
            my @array;
            while ( my ( $class, $count ) = each %$ref ) {
                my $p_class_feature = $count / $sum;
                push @array, $p_class_feature;
            }

            $on_entropy = $self->entropy( \@array ) || 0;
        }

        # H ( C | Xw = 0)
        my $off_entropy;
        {
            my @array;
            while ( my ( $class, $count ) = each %$ref ) {

                my $p_class_feature = ( $classes_sum->{$class} - $count )
                    / ( $all_features_num - $sum );
                push @array, $p_class_feature;
            }

            $off_entropy = $self->entropy( \@array ) || 0;
        }

        # Information Gain
        my $ig
            = $entropy
            - ( ( $sum / $all_features_num ) 
            * $on_entropy
                + ( ( $all_features_num - $sum ) / $all_features_num )
                * $off_entropy );

        $IG->{$feature} = $ig;
    }

    return $IG;
}

sub information_gain_ratio {
    my $self = shift;
    my $data = shift;

    my $SI = $self->split_information($data);
    my $IG = $self->information_gain($data);
    my $IGR;
    for ( sort { $IG->{$b} <=> $IG->{$a} } keys %$IG ) {
        if ( my $ratio = $IG->{$_} / $SI ) {
            $IGR->{$_} = $ratio if $ratio > 0;
        }
    }
    return $IGR;
}

sub entropy {
    my $self = shift;
    my $data = shift;

    my @ratio;
    if ( ref $data eq 'HASH' ) {
        @ratio = _ratio( [ values %$data ] );
    }
    elsif ( ref $data eq 'ARRAY' ) {
        my $s = sum(@$data) || 0;
        if ( $s == 1 ) {
            @ratio = @$data;
        }
        else {
            @ratio = _ratio($data);
        }
    }

    my $entropy;
    for my $p (@ratio) {
        if ( $p <= 0 ) {
            $p = 0.000000000000000000000001;
        }

        $entropy += -$p * _log2($p);
    }
    return $entropy;

}

sub split_information {
    my $self = shift;
    my $data = shift;

    my $all = int keys %$data;
    my $s;
    while ( my ( $w, $ref ) = each %$data ) {
        for my $category ( keys %$ref ) {
            $s->{$category}++;
        }
    }
    my @array;
    while ( my ( $category, $num ) = each %$s ) {
        push @array, $num / $all;
    }
    my $SI = $self->entropy( \@array );
    return $SI;
}

sub _ratio {
    my $arrayref = shift;
    my @ratio;
    my $sum = sum(@$arrayref);
    for (@$arrayref) {
        next if $_ <= 0;
        eval { push @ratio, $_ / $sum; };
        if ($@) {
            use Data::Dumper;
            print Dumper $arrayref;
            die($@);
        }
    }
    return @ratio;
}

sub _log2 {
    my $n = shift;
    log($n) / log(2);
}

1;
__END__

=head1 NAME

Algorithm::FeatureSelection -

=head1 SYNOPSIS

  use Algorithm::FeatureSelection;
  my $fs = Algorithm::FeatureSelection->new();

  # feature-class data structure ...
  my $features = {
    feature_1 => {
        class_a => 10,
        class_b => 2,
    },
    feature_2 => {
        class_b => 11,
        class_d => 32
    },
          .
          .
          .
  };

  # get pairwise-mutula-information
  my $pmi = $fs->pairwise_mutual_information($features);
  my $pmi = $fs->pmi($features); # same above

  # get information-gain 
  my $ig = $fs->information_gain($features);
  my $ig = $fs->ig($features); # same above



=head1 DESCRIPTION

This library is an perl implementation of 'Pairwaise Mutual Information' and 'Information Gain' 
that are used as well-known method of feature selection on text mining fields.

=head1 METHOD

=head2 new()

=head2 information_gain( $features )

  my $features = {
    feature_1 => {
        class_a => 10,
        class_b => 2,
    },
    feature_2 => {
        class_b => 11,
        class_d => 32
    },
          .
          .
          .
  };
  my $fs = Algorithm::FeatureSelection->new();
  my $ig = $fs->information_gain($features);

=head2 ig( $features )

short name of information_gain()

=head2 information_gain_ratio( $features )

  my $features = {
    feature_1 => {
        class_a => 10,
        class_b => 2,
    },
    feature_2 => {
        class_b => 11,
        class_d => 32
    },
          .
          .
          .
  };
  my $fs = Algorithm::FeatureSelection->new();
  my $igr = $fs->information_gain_ratio($features);

=head2 igr( $features )

short name of information_gain_ratio()

=head2 pairwise_mutual_information( $features )

  my $features = {
    feature_1 => {
        class_a => 10,
        class_b => 2,
    },
    feature_2 => {
        class_b => 11,
        class_d => 32
    },
          .
          .
          .
  };
  my $fs = Algorithm::FeatureSelection->new();
  my $pmi = $fs->pairwise_mutual_information($features);

=head2 pmi( $features )

short name of pairwise_mutual_information()

=head2 entropy(HASH|ARRAY)

calcurate entropy. 

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
