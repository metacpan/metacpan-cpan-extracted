package Catalyst::Plugin::CDBI::Transaction;

use strict;
use base 'Class::Data::Inheritable';

__PACKAGE__->mk_classdata('cdbi_models');

our $VERSION = '0.03';

=head1 NAME

Catalyst::Plugin::CDBI::Transaction - Simple transaction handling for Catalyst 
apps that use Class::DBI models

=head1 SYNOPSIS

    # ... in your application class:
    package MyApp;

    use Catalyst qw/CDBI::Transaction/;

    # ... in a controller class:
    package MyApp::Controller::Foo;

    sub create_in_transaction : Local  {
        my ( $self, $c ) = @_;

        $c->transaction( sub { 
            MyApp::M::CDBI::Sometable->create({
                field_1 => 'value 1',
                field_2 => 'value 2',
            }); 
        } )
            or $c->log->error("Transaction failed: " . $c->error->[-1]);
    }

=head1 DESCRIPTION

Handle L<Catalyst::Model::CDBI> database operations inside a transaction

=head1 METHODS

=over 4

=item $c->transaction

=item $c->trans

=item $c->atomic
  
Pass a coderef to $c->transaction, and it will be executed atomically (inside
of a transaction):

    $c->transaction( $ref_to_anonymous_subroutine );

Returns true and commits the transaction if all the statements inside the 
coderef were successful.  Upon failure, adds the error message to $c->error,
returns false and automatically rolls back the transaction.

This method was adapted from the idiom presented in the L<Class::DBI>
documentation, under the TRANSACTIONS heading.

=cut

*trans  = \&transaction;
*atomic = \&transaction;    # Because it just sounds cooler

sub transaction {
    my ( $c, $coderef ) = @_;

    my @cdbi = @{ $c->_cdbi_models };
    die "Couldn't find a CDBI component" unless @cdbi;

    # Stash away previous AutoCommit values for CDBI classes
    my %ac_prev;
    for my $cdbi ( map { ref $_ } @cdbi ) {
        # Only touch models that don't have AutoCommit set to zero.
        $ac_prev{$cdbi} = $cdbi->db_Main->{AutoCommit} || next;
        $cdbi->db_Main->{AutoCommit} = 0;
    }
    $_->db_Main->{AutoCommit} = 0 for keys %ac_prev;

    # Execute the code in $coderef inside a transaction
    eval { $coderef->() };
    my $error;
    if ( $@ ) {
        $error = $@;
        # dbi_rollback might die too
        eval { 
            $_->dbi_rollback or 
                $c->log->error("dbi_rollback failed in $_: $!") for @cdbi; 
        };
        $c->error($error);
    }
   
    # Restore previous AutoCommit values for each model class.
    # Will trigger a commit() if AutoCommit was previously true.
    $_->db_Main->{AutoCommit} = $ac_prev{$_} for keys %ac_prev;

    return $error ? 0 : 1;
}

=item $c->_cdbi_models

Called internally by $c->transaction to search all laoded components and
return those that have a db_Main() method and where AutoCommit is not explicitly
disabled.  Caches the search result for subsequent calls.  Returns an arrayref
containing all the found components, or undef if none found.

=cut

sub _cdbi_models {
    my $c = shift;

    return $c->cdbi_models if $c->cdbi_models;
    my @models;
    for my $class ( keys %{ $c->components } ) {
        if ( $class->can('db_Main') && $class->columns ) {
            push @models, $c->comp($class) unless
                exists $c->comp($class)->db_Main->{AutoCommit} &&
                !$c->comp($class)->db_Main->{AutoCommit};
        }
    }
    return @models ? $c->cdbi_models(\@models) : undef;
}

=back

=head1 NOTES/CAVEATS

All loaded model components used in the coderef passed to $c->transaction must
have AutoCommit set to a true value.  If AutoCommit is off for a connection,
$c->transaction will not trigger commits or rollbacks on that connection, and you
will need to take care of the commit yourself.

This plugin is intended for running the occasional transaction on a database
connection that normally runs in AutoCommit mode.  If you choose to run with
AutoCommit off, then you probably should handle your transactions manually rather
than with Catalyst::Plugin::CDBI::Transaction.

This plugin currently only works with Class::DBI models.  It has been tested with
Catalyst::Model::CDBI and Catalyst::Model::CDBI::Sweet.

Be careful when running this plugin under mod_perl.  If the coderef passed to
$c->transaction is from a named subroutine, mod_perl won't recompile that
subroutine on each request, and thus will ignore future changes to the lexical
variables outside the subroutine.  This is probably not what you want.  In
summary, always pass an I<anonymous> subroutine to $c->transaction, like in the
SYNOPSIS above.  And check your error logs for the infamous "won't stay shared"
message.  See the mod_perl docs, specifically "Understanding Closures", for
more details.

=head1 SEE ALSO

L<Class::DBI> (especially the TRANSACTIONS section), L<Catalyst>

=head1 AUTHOR

Brian Cooke, C<mrkoffee@saltedsnail.com>

=head1 LICENSE

This plugin is free software.  You may redistribute or modify it under the same
terms as Perl itself.

=cut

1;
