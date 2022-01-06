package Chart::GGPlot::ScalesList;

# ABSTRACT: Encapsulation multiple scale objects

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;

our $VERSION = '0.002000'; # VERSION

use List::AllUtils qw(pairmap pairkeys);
use Types::Standard qw(Any ArrayRef Object);
use Type::Params;
use PDL::Primitive qw(which);

use Chart::GGPlot::Aes::Functions qw(aes_to_scale);
use Chart::GGPlot::Scale::Functions qw(find_scale);
use Chart::GGPlot::Types qw(:all);
use Chart::GGPlot::Util qw(:all);


has scales => ( is => 'ro', default => sub { [] } );


sub find {
    state $check = Type::Params::compile( Object,
        ArrayRef->plus_coercions(ArrayRefFromAny) );
    my ( $self, $aesthetic ) = $check->(@_);

    return pdl(
        [
            map { $_->aesthetics->intersect($aesthetic)->length > 0 }
              @{ $self->scales }
        ]
    );
}


method has_scale ($aesthetic) {
    return !!( $self->find($aesthetic)->any );
}

method add ($scale) {
    return unless $scale;

    my $prev_aes = $self->find( $scale->aesthetics );
    if ( $prev_aes->any ) {
        my $aes_name =
          $self->scales->slice( [ $prev_aes->at(0) ] )->aesthetics->[0];
        my $message =
          sprintf( "Scale for '%s' is already present. "
              . "Adding another scale for '%s', which will replace the existing scale.",
            $aes_name, $aes_name );
        warn($message);

        # Remove old scale for this aesthetic (if it exists)
        $self->scales = $self->scales->slice( !$prev_aes );
    }
    push @{$self->scales}, $scale;
    return;
}


method length () { $self->scales->length; }

method input () {
    return $self->scales->map( sub { @{ $_->aesthetics } } );
}

method non_position_scales () {
    my $class   = ref($self);
    my @indices = which( !$self->find('x') & !$self->find('y') )->flatten;
    return $class->new( scales => $self->scales->slice( \@indices ) );
}


method get_scales ($aesthetic) {
    my $indexes = which( $self->find($aesthetic) );
    return undef if ( $indexes->isempty );
    return $self->scales->at( $indexes->at(0) );
}

method isempty () { $self->length == 0 }


method train_df ($df, $drop=false) {
    return [] if ( $df->isempty or $self->isempty );

    return $self->scales->map( sub { $_->train_df($df) } );
}


method map_df ($df) {
    return $df if ( $df->isempty or $self->isempty );

    my $mapped = $self->scales->map(
        sub {
            my $x = $_->map_df($df);
            return defined $x ? $x->flatten : ();
        }
    );
    return Data::Frame->new(
        columns => [
            @$mapped,
            $df->names->setdiff( [ pairkeys @$mapped ] )
              ->map( sub { $_ => $df->at($_) } )->flatten
        ]
    );
}

# Transform values to cardinal representation
method transform_df ($df) {
    return $df if ( $df->isempty or $self->isempty );

    my $transformed =
      $self->scales->map( sub { $_->transform_df($df)->flatten } );
    my @transformed_vars = pairkeys @$transformed;
    my $new = Data::Frame->new(
        columns => [
            @$transformed,
            $df->names->setdiff( \@transformed_vars )
              ->map( sub { $_ => $df->at($_) } )->flatten
        ]
    );
    return $new;
}

# aesthetics: a list of aesthetic-variable mappings. The name of each
#  item is the aesthetic, and the value of each item is the variable in data.
method add_defaults ($data, $aesthetics) {
    return if ( $aesthetics->isempty );

    $aesthetics = $aesthetics->rename(\&aes_to_scale);
    my $new_aesthetics = $aesthetics->names->setdiff( $self->input );

    # No new aesthetics, so no new scales to add
    return if ( $new_aesthetics->isempty );

    state $skip_aes = {
        group => 1,
    };

    my %datacols = pairmap { $a => $data->eval_tidy($b) }
        ( $aesthetics->hslice($new_aesthetics)->flatten );
    for my $aes ( sort grep { not $skip_aes->{$_} } keys %datacols ) {
        my ( $scale_f, $func_name ) = find_scale( $aes, $datacols{$aes} );
        unless ( defined $scale_f ) {
            # some aesthetics do not have scale functions
            if ( List::AllUtils::any { $aes eq $_ } (qw(weight width label)) ) {
                next;
            }
            else {
                die sprintf(
"Cannot find scale for aes %s. Missing a function of name %s",
                    $aes, $func_name );
            }
        }
        $log->debugf(
            "ScalesList::add_defaults : Got scale function %s for aes %s",
            $func_name, $aes )
          if $log->is_debug;
        $self->add( $scale_f->() );
    }
}

# Add missing but required scales. $aes_names is typically [qw(x y)].
method add_missing ($aes_names) {
    state $check =
      Type::Params::compile( ArrayRef->plus_coercions(ArrayRefFromAny) );
    ($aes_names) = $check->($aes_names);

    for my $aes ( @{ $aes_names->setdiff( $self->input ) } ) {
        my $scale_name = "scale_${aes}_continuous";
        no strict 'refs';
        my $scale_f = \&{"Chart::GGPlot::Scale::Functions::$scale_name"};
        $self->add( $scale_f->() );
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::ScalesList - Encapsulation multiple scale objects

=head1 VERSION

version 0.002000

=head1 ATTRIBUTES

=head2 scales

Returns an arrayref of L<Chart::GGPlot::Scale> objects.

=head1 METHODS

=head2 find

    find(ArrayRef $aes_names)
    find(Str $aes_name)

Returns an arrayref of indices in the C<scales> attr, for the given
aesthetics names.

=head2 has_scale

    has_scale(ArrayRef $aes_names)
    has_scale(Str $aes_name)

=head2 length

    length()

Size of the C<scales> attribute.

=head2 get_scales

    get_scales(ArrayRef $aes_names)
    get_scales(Str $aes_name)

Returns the first scale object found.

=head2 train_df

    train_df($df)

Train scales from a dataframe.
Returns an arrayref of scale objects.

=head2 map_df

    map_df($df)

Map values from a data frame.
Returns a new data frame whose columns processed to map to the scales'
limits.

=head1 SEE ALSO

L<Chart::GGPlot::Scale>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2021 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
