package Data::Verifier::Nested;
$Data::Verifier::Nested::VERSION = '0.63';
use Moose;

# ABSTRACT: Nested profile based data verification with Moose type constraints.

extends 'Data::Verifier';


## private helper functions

my $_is_profile_spec = sub {
    my $spec = shift;
    return 0 unless ref $spec eq 'HASH';
    my @keys = grep { ref $spec->{ $_ } eq 'HASH' } keys %$spec;
    ($_ eq 'dependent') && return 1 foreach @keys;
    return 0 if @keys;
    return 1;
};

my $_collapse_profile;
$_collapse_profile = sub {
    my ($profile, $acc, $prefix) = @_;
    foreach my $k ( keys %$profile ) {
        my $full_k = join '.' => ($prefix || (), $k);
        if ( $_is_profile_spec->( $profile->{ $k } ) ) {
            $acc->{ $full_k } = $profile->{ $k }
        }
        else {
            (ref $profile->{ $k } eq 'HASH')
                || die "Can only collapse HASH refs";
            $_collapse_profile->( $profile->{ $k }, $acc, $full_k  );
        }
    }
};

my $collapse_profile = sub {
    my ($profile) = @_;
    my $acc = {};
    $_collapse_profile->( $profile, $acc );
    $acc;
};

my $_collapse_data_for_profile;
$_collapse_data_for_profile = sub {
    my ($profile, $data, $acc, $prefix) = @_;
    foreach my $k ( keys %$data ) {
        my $full_k = join '.' => ($prefix || (), $k);
        if ( exists $profile->{ $full_k } ) {
            $acc->{ $full_k } = $data->{ $k }
        }
        else {
            (ref $data->{ $k } eq 'HASH')
                || die "Can only collapse HASH refs";
            $_collapse_data_for_profile->( $profile, $data->{ $k }, $acc, $full_k );
        }
    }
};

my $collapse_data_for_profile = sub {
    my ($profile, $data) = @_;
    my $acc = {};
    $_collapse_data_for_profile->( $profile, $data, $acc );
    $acc;
};

# now to the subclass ...

sub BUILDARGS {
    my $self   = shift;
    my $params = $self->SUPER::BUILDARGS( @_ );
    # NOTE:
    # this is required, but we don't want to
    # make assumptions, if it is not here, then
    # it will die later on with the right error
    # so we can just process it if we have it.
    # - SL
    $params->{'profile'} = $collapse_profile->( $params->{'profile'} )
        if exists $params->{'profile'};
    $params;
}

sub verify {
    my ($self, $params, $members) = @_;
    $self->SUPER::verify(
        $collapse_data_for_profile->(
            $self->profile,
            $params
        ),
        $members
    );
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Verifier::Nested - Nested profile based data verification with Moose type constraints.

=head1 VERSION

version 0.63

=head1 SYNOPSIS

    use Data::Verifier::Nested;

    my $dv = Data::Verifier::Nested->new(
        filters => [ qw(trim) ],
        profile => {
            name => {
                first_name => { type => 'Str', required => 1 },
                last_name  => { type => 'Str', required => 1 },
            },
            age  => { type => 'Int' },
            sign => { required => 1 },
        }
    );

    # Pass in a hash of data
    my $results = $dv->verify({
        name => { first_name => 'Cory', last_name => 'Watson' }, age => 'foobar'
    });

    $results->success; # no

    $results->is_invalid('name.first_name'); # no
    $results->is_invalid('name.last_name'); # no
    $results->is_invalid('age');  # yes

    $results->is_missing('name.first_name'); # no
    $results->is_invalid('name.last_name'); # no
    $results->is_missing('sign'); # yes

    $results->get_original_value('name.first_name'); # Unchanged, original value
    $results->get_value('name.first_name'); # Filtered, valid value
    $results->get_value('age');  # undefined, as it's invalid

=head1 DESCRIPTION

Data::Verifier allows you verify data that is in a flat hash, but sometimes
this is not enough, this is where Data::Verifier::Nested comes in. It is a
subclass of Data::Verifier that can work with nested data structures.

=head1 CONTRIBUTORS

Stevan Little

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
