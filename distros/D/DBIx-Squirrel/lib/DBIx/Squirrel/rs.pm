use strict;
use warnings;
use 5.010_001;

package    # hide from PAUSE
    DBIx::Squirrel::rs;

=head1 NAME

DBIx::Squirrel::rs - Statement results iterator class

=head1 SYNOPSIS


=head1 DESCRIPTION

This module subclasses L<DBIx::Squirrel::it> to provides another type of
statement results iterator. 

While it may be used in exactly the same way as L<DBIx::Squirrel::it>,
it also abstracts away the implementation details of the underlying
statement results. Results are returned as objects of a class that is
dynamically created for each statement results iterator, and column
data is accessed via accessor methods that are also dynamically
created. Thus, the user need not be concerned with whether the
underlying statement results are arrayrefs or hashrefs, or even
what case is used for the column names.

=cut

use Scalar::Util 'weaken';
use Sub::Name 'subname';
use namespace::clean;

BEGIN {
    require DBIx::Squirrel
        unless keys %DBIx::Squirrel::;
    *DBIx::Squirrel::rs::VERSION = *DBIx::Squirrel::VERSION;
    @DBIx::Squirrel::rs::ISA     = 'DBIx::Squirrel::it';
}

sub DESTROY {
    return if DBIx::Squirrel::util::global_destruct_phase();
    my $self = shift;
    local( $., $@, $!, $^E, $?, $_ );
    my $row_class = $self->row_class;
    no strict 'refs';    ## no critic
    $self->_autoloaded_accessors_unload if %{ $row_class . '::' };
    undef &{ $row_class . '::rs' };
    undef &{ $row_class . '::rset' };
    undef &{ $row_class . '::results' };
    undef &{ $row_class . '::resultset' };
    undef *{$row_class};
    return $self->SUPER::DESTROY;
}

sub _autoloaded_accessors_unload {
    my $self = shift;
    no strict 'refs';    ## no critic
    undef &{$_} for @{ $self->row_class . '::AUTOLOAD_ACCESSORS' };
    return $self;
}

sub _result_preprocess {
    my $self = shift;
    return ref $_[0] ? $self->_rebless(shift) : shift;
}

sub _rebless {
    my $self       = shift;
    my $row_class  = $self->row_class;
    my $results_fn = $row_class . '::results';
    no strict 'refs';    ## no critic
    unless ( defined &{$results_fn} ) {
        my $resultset_fn = $row_class . '::resultset';
        my $rset_fn      = $row_class . '::rset';
        my $rs_fn        = $row_class . '::rs';
        undef &{$resultset_fn};
        undef &{$rset_fn};
        undef &{$rs_fn};
        *{$resultset_fn} = *{$results_fn} = *{$rset_fn} = *{$rs_fn} = do {
            weaken( my $results = $self );
            subname( $results_fn => sub { $results } );
        };
        @{ $row_class . '::ISA' } = ( $self->result_class );
    }
    return $row_class->new(shift);
}

sub result_class {
    return 'DBIx::Squirrel::rc';
}

BEGIN {
    *row_base_class = *result_class;
}

sub row_class {
    my $self = shift;
    return sprintf( '%s::Ox%x', ref $self, 0+ $self );
}

sub slice {
    no strict 'refs';    ## no critic
    my( $attr, $self ) = shift->_private_state;
    my $slice = shift;
    my $old   = defined $attr->{slice} ? $attr->{slice} : '';
    $self->SUPER::slice($slice);
    if ( my $new = defined $attr->{slice} ? $attr->{slice} : '' ) {
        if ( ref $new ne ref $old ) {
            $self->_autoloaded_accessors_unload if %{ $self->row_class . '::' };
        }
    }
    return $self;
}

=head1 AUTHORS

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

The DBIx::Squirrel module is Copyright (c) 2020-2025 Iain Campbell.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl 5.10.0 README file.

=head1 SUPPORT / WARRANTY

DBIx::Squirrel is free Open Source software. IT COMES WITHOUT WARRANTY OF ANY
KIND.

=cut

1;
