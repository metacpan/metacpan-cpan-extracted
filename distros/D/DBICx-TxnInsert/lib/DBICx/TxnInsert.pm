package DBICx::TxnInsert;
use warnings;
use strict;
use base 'DBIx::Class::Row';

=head1 NAME

DBICx::TxnInsert - wrap all inserts into transaction

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This component wrap all inserts into transactions.

    package My::Schema::Entity;
    __PACKAGE__->load_components(qw/DBICx::TxnInsert Core/);
    ...

=head1 WARNING

This module uses DBIx::Class internals, may be not compatible with future versions of DBIx::Class.

You need to use it only in one case: last_insert_id should be called in same transaction as insert itself.
For example in case you config is Application(DBIx::Class) <-> pgbouncer <-> postgresql server. 

=head1 METHODS

=head2 insert

see DBIx::Class::Row::insert

=cut

sub insert {
    my $self = shift;
    my $source = $self->result_source;
    $source ||= $self->result_source( $self->result_source_instance ) if $self->can('result_source_instance');
    $self->throw_exception("No result_source set on this object; can't insert") unless $source;
    
    my $rollback_guard = $source->storage->txn_scope_guard;

    my $ret = $self->next::method(@_);

    $rollback_guard->commit;

    return $ret;
}

=head1 AUTHOR

Vladimir Timofeev, C<< <vovkasm at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbicx-txninsert at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBICx-TxnInsert>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBICx::TxnInsert

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBICx-TxnInsert>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBICx-TxnInsert>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBICx-TxnInsert>

=item * Search CPAN

L<http://search.cpan.org/dist/DBICx-TxnInsert/>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Vladimir Timofeev, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of DBICx::TxnInsert
