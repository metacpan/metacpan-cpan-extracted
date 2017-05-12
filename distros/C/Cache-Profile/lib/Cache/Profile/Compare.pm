package Cache::Profile::Compare;
# ABSTRACT: Compare several caches

our $VERSION = '0.06';

use Moose;
use Carp qw(croak);
use Cache::Profile::CorrelateMissTiming;
use namespace::autoclean;

has profile_class => (
    isa => "ClassName",
    is  => "ro",
    default => "Cache::Profile::CorrelateMissTiming",
    required => 1,
);

has caches => (
    traits => [qw(Array)],
    isa => "ArrayRef[Object]",
    predicate => "has_caches",
    handles => {
        caches => "elements",
    },
);

has profiles => (
    traits => [qw(Array)],
    isa => "ArrayRef[Object]",
    lazy_build => 1,
    handles => {
        profiles => "elements",
    },
);

sub _build_profiles {
    my $self = shift;

    croak "'caches' or 'profiles' are required" unless $self->has_caches;

    [ map { $self->wrap_cache($_) } $self->caches ];
}

sub wrap_cache {
    my ( $self, $cache ) = @_;

    $self->profile_class->new( cache => $cache );
}

sub get { shift->_first_def( get => @_ ) }
sub compute { shift->_first_def( compute => @_ ) }

sub _first_def {
    my $self = shift;
    my $method = shift;

    my @all_rets;

    foreach my $cache ( $self->profiles ) {
        my @ret;
        if ( wantarray ) {
            @ret = $cache->$method(@_);
        } else {
            $ret[0] = $cache->$method(@_);
        }
        push @all_rets, \@ret;
    }

    if ( wantarray ) {
        return @{ $all_rets[0] };
    } else {
        foreach my $ret ( map { $_->[0] } @all_rets ) {
            return $ret if defined $ret;
        }

        return undef;
    }
}

sub AUTOLOAD {
    my $self = shift;

    my ( $method ) = ( our $AUTOLOAD =~ /([^:]+)$/ );

    $_->$method(@_) for $self->profiles;
}

sub report {
    my $self = shift;

    my ( $fastest ) = $self->by_speedup;
    my ( $best_rate ) = $self->by_hit_rate;

    return join("\n",
        "Best speedup: " . $fastest->moniker,
        $fastest->report,
        "",
        "Best hit rate: " . $best_rate->moniker,
        $best_rate->report
    );
}

sub by_hit_rate {
    my $self = shift;

    sort { $b->hit_rate <=> $a->hit_rate } grep { defined $_->hit_rate } $self->profiles;
}

sub by_speedup {
    my $self = shift;

    sort { $a->speedup <=> $b->speedup } grep { defined $_->speedup } $self->profiles;
}

__PACKAGE__->meta->make_immutable;

# ex: set sw=4 et:

__PACKAGE__;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cache::Profile::Compare - Compare several caches

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    my $c = Cache::Profile::Compare->new(
        caches => [
            Cache::Bounded->new({ interval => 256, size => 1024 }),
            Cache::Ref::LRU->new( size => 1024 ),
            Cache::Ref::CART->new( size => 1024 ),
        ],
    );

    # use normally
    $c->get("foo");
    $c->set("foo" => 42);

    # reports which cache had the best hit rate, and which provided the best
    # speedup
    $c->report;

=head1 DESCRIPTION

This module lets you compare several profiles.

=head1 ATTRIBUTES

=over 4

=item caches

The caches to profile

=item profiles

A lazy built list of L<Cache::Profile> or
L<Cache::Profile::CorrelateMissTiming> objects based on C<caches>.

=for stopwords profiler

Can be provided explicitly if you want to create your own profiler objects.

=item profile_class

Defaults to L<Cache::Profile::CorrelateMissTiming>.

=back

=head1 METHODS

=over 4

=item report

Prints the reports of the cache with the largest speedup and the cache with the
best hit rate.

=item by_speedup

Returns the caches sorted by speedup.

=item by_hit_rate

Returns the caches sorted by hit rate.

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Cache-Profile>
(or L<bug-Cache-Profile@rt.cpan.org|mailto:bug-Cache-Profile@rt.cpan.org>).

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2010 by יובל קוג'מן (Yuval Kogman).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
