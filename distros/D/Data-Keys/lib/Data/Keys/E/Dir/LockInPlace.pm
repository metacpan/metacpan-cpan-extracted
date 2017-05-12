package Data::Keys::E::Dir::LockInPlace;

=head1 NAME

Data::Keys::E::Dir::LockInPlace - place locks directly on the stored files

=head1 DESCRIPTION

Uses F<flock> directly on the storage files.

=cut

use warnings;
use strict;

our $VERSION = '0.04';

use Moose::Role;
use Fcntl qw(:DEFAULT :flock);

has '_lock_inplace_data' => ( isa => 'HashRef', is => 'rw', default => sub { {} });

=head1 METHODS

=cut

sub _lock_mode {
    my $self   = shift;
    my $key    = shift;
    my $mode   = shift;
    my $create = shift;

    my ($new_key, $filename) = $self->_make_filename($key);

    my $lock_fh = IO::File->new();
    $lock_fh->open($filename, ($create ? '+>>' : '<'))
        or die 'failed to lock "'.$filename.'" - '.$!;
    
    flock($lock_fh, $mode)
        or die 'failed to lock "'.$filename.'" - '.$!;

    $self->_lock_inplace_data->{$key}->{'fh'} = $lock_fh;
}

=head2 lock_ex

C<LOCK_EX> on a target key file.

=cut

sub lock_ex {
    my $self   = shift;
    my $key    = shift;
    my $create = shift;
    $self->_lock_mode($key, LOCK_EX, $create);
}

=head2 lock_sh

C<LOCK_SH> on a target key file.

=cut

sub lock_sh {
    my $self   = shift;
    my $key    = shift;
    my $create = shift;
    $self->_lock_mode($key, LOCK_SH, $create);
}

=head2 unlock

Release lock from the target key file.

=cut

sub unlock {
    my $self = shift;
    my $key  = shift;

    close delete $self->_lock_inplace_data->{$key}->{'fh'};
    delete $self->_lock_inplace_data->{$key};
}

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
