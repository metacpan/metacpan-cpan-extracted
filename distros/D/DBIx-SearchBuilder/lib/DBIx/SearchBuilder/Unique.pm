package DBIx::SearchBuilder::Unique;
use base 'Exporter';
our @EXPORT = qw(AddRecord);
our $VERSION = "0.01";
use strict;
use warnings;



sub AddRecord {
    my $self = shift;
    my $record = shift;

    # We're a mixin, so we can't override _CleanSlate, but if an object
    # gets reused, we need to clean ourselves out.  If there are no items,
    # we're clearly doing a new search
    $self->{"dbix_sb_unique_cache"} = {} unless (@{$self->{'items'}}[0]);
    return if $self->{"dbix_sb_unique_cache"}->{$record->id}++;
    push @{$self->{'items'}}, $record;
}

1;

=head1 NAME

DBIx::SearchBuilder::Unique - Ensure uniqueness of records in a collection

=head1 SYNOPSIS

    package Foo::Collection;
    use base 'DBIx::SearchBuilder';

    use DBIx::SearchBuilder::Unique; # mixin

    my $collection = Foo::Collection->New();
    $collection->SetupComplicatedJoins;
    $collection->OrderByMagic;
    
    while (my $thing = $collection->Next) {
        # $thing is going to be distinct
    }

=head1 DESCRIPTION

Currently, DBIx::SearchBuilder makes exceptions for databases which
cannot handle both C<SELECT DISTINCT> and ordering in the same
statement; it drops the C<DISTINCT> requirement. This, of course, means
that you can get the same row twice, which you might not want. If that's
the case, use this module as a mix-in, and it will provide you with an
C<AddRecord> method which ensures that a record will not appear twice in
the same search.

=head1 AUTHOR

Simon Cozens.

=head1 COPYRIGHT

Copyright 2005 Best Practical Solutions, LLC

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

