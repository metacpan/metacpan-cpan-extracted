package Collection::Mem;

=head1 NAME

Collection::Mem - class for collections of data, stored in memory.

=head1 SYNOPSIS

    use Collection::Mem;
    my $meta = new Collection::Mem:: mem=>$hash1;

=head1 DESCRIPTION

Class for collection of data, stored in memory.

=head1 METHODS

=cut

use Collection;
use Collection::Utl::Base;
use Collection::Utl::Item;
use Data::Dumper;
use Test::More;
use Collection::Utl::ActiveRecord;

use strict;
use warnings;

our @ISA     = qw(Collection);
our $VERSION = '0.01';

attributes qw/ _mem_cache /;

sub _init {
    my $self = shift;
    my %args = @_;
    $self->_mem_cache( $args{mem} || {} );
    $self->SUPER::_init();
    return 1;
}

sub _delete {
    my $self = shift;
    my @ids  = @_;
    my $coll = $self->_mem_cache;
    delete @{$coll}{@ids};
    [@ids];
}

sub _create {
    my $self = shift;
    my $coll = $self->_mem_cache;
    if ( @_ > 1 ) {
        my %new_keys_vals = @_;
        my %res           = ();

        # resolve hash refs to new hashes
        while ( my ( $key, $val ) = each %new_keys_vals ) {
            %{ $coll->{$key} } = %$val;
            $res{$key} = $coll->{$key};
        }
        return \%res;
    }
    my %res   = ();
    my $attrs = shift;

    if ( ref($attrs) eq 'HASH' ) {

        #merge with already exists
        # resolve hash refs to new hashes
        while ( my ( $key, $val ) = each %$attrs ) {
            %{ $coll->{$key} } = %$val;
            $res{$key} = $coll->{$key};
        }

    }
    else {
        foreach my $value (@$attrs) {
            my ($max) = sort { $b <=> $a } keys %$coll;
            $coll->{ ++$max } = $value;
            $res{$max} = $value;
        }
    }
    return \%res;
}

sub _fetch {
    my $self = shift;
    my @ids  = @_;
    my $coll = $self->_mem_cache;
    my %res;
    for (@ids) {
        $res{$_} = $coll->{$_} if exists $coll->{$_};
    }
    return \%res;
}

sub _prepare_record {
    my ( $self, $key, $ref ) = @_;
    my %hash;
    tie %hash, 'Collection::Utl::ActiveRecord', hash => $ref;
    return \%hash;
}

sub _fetch_all {
    my $self = shift;
    return [ keys %{ $self->_mem_cache } ];
}

sub _store {
    my $self = shift;
}

sub commit {
    my $self = shift;
}

sub list_ids {
    my $self = shift;
    return [ keys %{ $self->_mem_cache } ];
}

1;
__END__

=head1 SEE ALSO

MetaStore, Collection,README

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2008 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

