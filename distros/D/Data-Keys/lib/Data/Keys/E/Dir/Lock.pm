package Data::Keys::E::Dir::Lock;

=head1 NAME

Data::Keys::E::Dir::Lock - uses additional folder to lock files

=head1 DESCRIPTION

Places file locks in a different folder.

=cut

use warnings;
use strict;

our $VERSION = '0.04';

our $MAX_NUMBER_OF_LOCK_RETRIES = 10;

use Moose::Role;
use Fcntl qw(:DEFAULT :flock);
use Carp 'confess';

=head1 PROPERTIES

=head2 lock_dir

A folder where to place locks. Default is C<< $self->base_dir / .lock >>.

=cut

has 'lock_dir'       => ( isa => 'Str', is => 'rw', lazy => 1, default => sub { File::Spec->catdir(eval{ $_[0]->base_dir } || confess('no base_dir, do not know how to set lock_dir'), '.lock') } );
has '_lock_dir_data' => ( isa => 'HashRef', is => 'rw', default => sub { {} });

requires('init');

=head1 METHODS

=head2 after 'init'

Will create lock folder if not present.

=cut

after 'init' => sub {
    my $self  = shift;

    mkdir($self->lock_dir)
        if (not -d $self->lock_dir);
    
    return;
};

=head2 lock_sh

Same as L</lock_ex>.

=cut

*lock_sh = *lock_ex;

=head2 lock_ex

Creates a locking file in C<< $self->lock_dir >> in an exclusive way.

=cut

sub lock_ex {
    my $self = shift;
    my $key  = shift;

    my $lock_key = $key;
    $lock_key    =~ s{/}{_}g;
    my $lock_filename = File::Spec->catfile($self->lock_dir, $lock_key);

    $self->_lock_dir_data->{$key}->{'counter'}++;
    # return if already locked
    return
        if ($self->_lock_dir_data->{$key}->{'counter'} != 1);

    my $lock_fh;
    my $num_tries = 0;
    # try to exclusively open the lock the file, if it fails than wait until another process release the LOCK_EX
    while (not sysopen($lock_fh, $lock_filename, O_WRONLY | O_EXCL | O_CREAT, 0644)) {
        # wait until lock on that file is released
        eval {
            my $fh = IO::Any->new([$lock_filename], '+>>', { LOCK_EX => 1 });
            close($fh);
        };

        $num_tries++;
        die 'failed to lock "'.$key.'" using "'.$lock_filename.'" lock file - '.$!
            if ($num_tries > $MAX_NUMBER_OF_LOCK_RETRIES);
    }
    flock($lock_fh, LOCK_EX);
    print $lock_fh $$;
    $lock_fh->flush;
    
    $self->_lock_dir_data->{$key}->{'fh'} = $lock_fh;
    $self->_lock_dir_data->{$key}->{'filename'} = $lock_filename;
}

=head2 unlock

Release a lock.

=cut

sub unlock {
    my $self = shift;
    my $key  = shift;
    
    if (not $self->_lock_dir_data->{$key}) {
        warn 'unlock("'.$key.'") but is is not locked';
        return;
    };

    $self->_lock_dir_data->{$key}->{'counter'}--;

    if ($self->_lock_dir_data->{$key}->{'counter'} <= 0) {
        # release+delete lock file
        unlink delete $self->_lock_dir_data->{$key}->{'filename'};
        close delete $self->_lock_dir_data->{$key}->{'fh'};
        delete $self->_lock_dir_data->{$key};
    }
}

sub DESTROY {
    my $self = shift;
    my %lock_dir_data = %{ $self->_lock_dir_data };
    
    foreach my $key (keys %lock_dir_data) {
        unlink delete $lock_dir_data{$key}->{'filename'};
        close delete $lock_dir_data{$key}->{'fh'};
    }    
}

1;


__END__

=head1 AUTHOR

Jozef Kutej

=cut
