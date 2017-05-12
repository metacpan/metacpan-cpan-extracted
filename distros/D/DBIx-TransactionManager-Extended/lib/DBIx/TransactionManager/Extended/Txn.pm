package DBIx::TransactionManager::Extended::Txn;
use strict;
use warnings;

use DBIx::TransactionManager; ## XXX: it includes '::ScopeGuard' package

sub new {
    my ($class, $manager, %args) = @_;
    $args{caller} = [caller(1)] unless $args{caller};
    my $guard = DBIx::TransactionManager::ScopeGuard->new($manager => %args);
    return bless [$guard, $manager] => $class;
}

sub rollback { shift->[0]->rollback }
sub commit   { shift->[0]->commit }

sub context_data              { shift->[1]->context_data                  }
sub add_hook_after_commit     { shift->[1]->add_hook_after_commit(@_)     }
sub add_hook_before_commit    { shift->[1]->add_hook_before_commit(@_)    }
sub remove_hook_after_commit  { shift->[1]->remove_hook_after_commit(@_)  }
sub remove_hook_before_commit { shift->[1]->remove_hook_before_commit(@_) }

1;
__END__

=pod

=encoding utf-8

=head1 NAME

DBIx::TransactionManager::Extended::Txn - transaction object

=head1 SYNOPSIS

    use DBI;
    use DBIx::TransactionManager::Extended;

    my $dbh = DBI->connect('dbi:SQLite:');
    my $tm = DBIx::TransactionManager::Extended->new($dbh);

    # create transaction object
    my $txn = $tm->txn_scope;

        # execute query
        $dbh->do("insert into foo (id, var) values (1,'baz')");
        # And you can do multiple database operations here

        for my $data (@data) {
            push @{ $txn->context_data->{data} } => $data;
            $txn->add_hook_after_commit(sub {
                my $context_data = shift; # with the current (global) transaction
                my @data = @{ $context_data->{data} };
                return unless @data;

                ...

                $context_data->{data} = [];
            });
        }

    # and commit it.
    $txn->commit;


=head1 DESCRIPTION

This module provides shortcut for L<DBIx::TransactionManager::Extended> and L<DBIx::TransactionManager::ScopeGuard>.

=head1 EXTENDED METHODS

=head2 context_data

This is a accessor for a context data.
The context data is a associative array about a current transaction's context data.

=head2 add_hook_before_commit

Adds hook that run at before the commit all transactions.

=head2 add_hook_after_commit

Adds hook that run at after the commit all transactions.

=head2 remove_hook_before_commit

Removes hook that run at before the commit all transactions.

=head2 remove_hook_after_commit

Removes hook that run at after the commit all transactions.

=head1 SEE ALSO

L<DBIx::TransactionManager>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
