# ================================================================
package App::iTan::Command::Delete;
# ================================================================
use utf8;
use Moose;
use 5.0100;

use MooseX::App::Command;
with qw(App::iTan::Utils);

sub execute {
    my ( $self, $opts, $args ) = @_;

    say 'All unused iTANs have been deleted';

    $self->dbh->do('DELETE FROM itan
        WHERE valid = 0
        AND used IS NULL')
        or die "ERROR: Cannot execute: " . $self->dbh->errstr();

    return;
}

__PACKAGE__->meta->make_immutable;
1;

=pod

=encoding utf8

=head1 NAME

App::iTan::Command::Delete - Delete all invalid iTANs

=head1 SYNOPSIS

 itan delete

=head1 DESCRIPTION

Delete all invalid iTANs that have not been used yet

=cut