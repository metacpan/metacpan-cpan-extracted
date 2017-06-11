# ================================================================
package App::iTan::Command::Get;
# ================================================================
use utf8;
use Moose;
use 5.0100;

use MooseX::App::Command;
with qw(App::iTan::Utils);

option 'next' => (
    is      => 'ro',
    isa     => 'Bool',
    documentation => q[Get the next available iTAN],
);

option 'index' => (
    is      => 'ro',
    isa     => 'Int',
    documentation => q[iTAN index number that should be fetched],
);

option 'lowerinvalid' => (
    is      => 'ro',
    isa     => 'Bool',
    documentation => q[Mark all iTANs with a lower index as invalid (only in combination with --index)],
);

option 'memo' => (
    is      => 'ro',
    isa     => 'Str',
    documentation => q[Optional memo on iTAN usage],
);

sub execute {
    my ( $self, $opts, $args ) = @_;

    my $index;
    if ($self->next) {
        ($index) = $self->dbh->selectrow_array("SELECT tindex
            FROM itan
            WHERE used IS NULL
            AND valid = 1
            ORDER BY tindex
            LIMIT 1");

        unless (defined $index) {
            say 'No more iTANs left';
            return;
        }
    } else {
        $index = $self->index;
    }

    unless (defined $index) {
        say 'Option --index or --next must be set';
    } else {
        my $tan_data = $self->get($index);
        my $itan = $self->decrypt_string($tan_data->{itan});
        say 'iTAN '.$index.' marked as used';
        say 'iTAN '.$itan;

        eval {
            if ($^O eq 'darwin') {
                Class::Load::load_class('Mac::Pasteboard');
                my $pb = Mac::Pasteboard->new();
                $pb->clear;
                $pb->copy($itan);
            } else {
                Class::Load::load_class('Clipboard');
                Clipboard->copy($itan);
            }
            say 'iTan has been coppied to the clipboard';
        };

        $self->mark($index,$self->memo);
        if ($self->lowerinvalid) {
            $self->dbh->do('UPDATE itan SET valid = 0 WHERE tindex < '.$index)
                 or die "ERROR: Cannot execute: " . $self->dbh->errstr();
        }
    }

    return;
}

__PACKAGE__->meta->make_immutable;
1;

=pod

=encoding utf8

=head1 NAME

App::iTan::Command::Get - Fetches selected iTAN

=head1 SYNOPSIS

 itan get [--next] OR [--index INDEX [--lowerinactive]]  [--memo MEMO]

=head1 DESCRIPTION

Fetches an iTan an marks it as used. If possible the iTAN is also copied
to the clipboard.

You will be prompted a password to decrypt the selected iTan.

=head1 OPTIONS

=head2 next

Get the next available iTAN

=head2 index

iTAN index number that should be fetched

=head2 lowerinvalid

Mark all iTANs with a lower index as invalid (only in combination with
--index)

=head2 memo

Optional memo on iTAN usage

=cut