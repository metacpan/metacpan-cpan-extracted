# ================================================================
package App::iTan::Command::Reset;
# ================================================================
use utf8;
use Moose;
use 5.0100;

use MooseX::App::Command;
with qw(App::iTan::Utils);

sub execute {
    my ( $self, $opts, $args ) = @_;

    say 'All unused iTANs have been marked as invalid';

    $self->dbh->do('UPDATE itan SET valid = 0')
         or die "ERROR: Cannot execute: " . $self->dbh->errstr();

    return;
}

__PACKAGE__->meta->make_immutable;
1;

=pod

=encoding utf8

=head1 NAME

App::iTan::Command::Reset - Reset unused iTANs

=head1 SYNOPSIS

 itan reset

=head1 DESCRIPTION

Mark all unused iTANs as invalid

=cut
