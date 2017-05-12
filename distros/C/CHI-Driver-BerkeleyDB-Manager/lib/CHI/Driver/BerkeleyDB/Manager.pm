package CHI::Driver::BerkeleyDB::Manager;

use warnings;
use strict;
use BerkeleyDB::Manager;
use Moo;
use CHI::Constants qw(CHI_Max_Time);
extends 'CHI::Driver';

my @BERKELEYDB_PARAMS = qw(
    home
    create
    lock
    deadlock_detection
    lk_detect
    readonly
    transactions
    autocommit
    auto_checkpoint
    checkpoint_kbyte
    checkpoint_min
    recover
    multiversion
    snapshot
    read_uncomitted
    log_auto_remove
    sync
    dup
    dupsort
    db_class
    env_flags
    db_properties
    open_dbs
    chunk_size
);

has _bdb_manager => ( is => 'rw', lazy => 1, builder => 1 );

has _bdb_manager_args => ( is => 'rw' );

#has _bdb => ( is => 'rw', lazy => 1, builder => 1 );

=head1 NAME

CHI::Driver::BerkeleyDB::Manager - The great new CHI::Driver::BerkeleyDB::Manager!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use CHI::Driver::BerkeleyDB::Manager;

    my $foo = CHI::Driver::BerkeleyDB::Manager->new();
    ...

=head1 SUBROUTINES/METHODS


=head2 _build__bdb_manager

    builds the BerkeleyDB::Manager object from the args pass to the driver

=cut

sub _build__bdb_manager {
    my ($self) = @_;
    return BerkeleyDB::Manager->new(%{$self->_bdb_manager_args});
}

=head2 _build__bdb

    builds the BerkeleyDB::Manager object from the args pass to the driver


sub _build__bdb {
    my ($self) = @_;
    return $self->_bdb_manager->open_db( file => $self->namespace );
}
=cut

sub _bdb {
    my ($self) = @_;
    return $self->_bdb_manager->open_db( file => $self->namespace );
}

=head2 BUILD

    Creates a hash of the BerkeleyDB::Manager arguements

=cut

sub BUILD {
    my ($self, $options) = @_;
    my @foundkeys = grep { exists $options->{$_} } @BERKELEYDB_PARAMS;
    my %tmp;
    @tmp{@foundkeys} = delete @{$options}{@foundkeys};
    $self->_bdb_manager_args(\%tmp);
}

=head2 store

=cut

sub store {
    my ( $self, $key, $data, $expires_in ) = @_;
    die "must specify key" unless defined $key;
    return $self->_bdb_manager->txn_do( sub { $self->_bdb->db_put($key,$data) } );
}

=head2 fetch

=cut

sub fetch {
    my ( $self, $key ) = @_;
    die "must specify key" unless defined $key;
    my $val;
    $self->_bdb_manager->txn_do( sub { $self->_bdb->db_get($key,$val) } );
    return $val;
}

=head2 remove

=cut

sub remove {
    my ( $self, $key ) = @_;
    die "must specify key" unless defined $key;
    return $self->_bdb_manager->txn_do( sub { $self->_bdb->db_del($key) } );
}

=head2 get_keys


=cut

sub get_keys {
    my ( $self )  = @_;
    my $s = $self->_bdb_manager->cursor_stream( db => $self->_bdb, 'keys' => 1);
    my @items = $s->items;
    return @items;
}

=head1 AUTHOR

James Rouzier, C<< <rouzier at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-chi-driver-berkeleydb_managerdb at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CHI-Driver-BerkeleyDB::Manager>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CHI::Driver::BerkeleyDB::Manager


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CHI-Driver-BerkeleyDB::Manager>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CHI-Driver-BerkeleyDB::Manager>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CHI-Driver-BerkeleyDB::Manager>

=item * Search CPAN

L<http://search.cpan.org/dist/CHI-Driver-BerkeleyDB::Manager/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 James Rouzier.

This program is free software; you can berkeleydb_managertribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of CHI::Driver::BerkeleyDB::Manager
