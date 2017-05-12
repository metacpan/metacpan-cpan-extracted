package My::Journal::Command::Entry::Remove;
use base qw( My::Journal::Command::Entry );

use strict;
use warnings;
use Carp;

#-------

sub usage_text {
    q{
    entry remove: remove journal entries
    }
}

sub validate {
    my ($self, $opts, @args) = @_;

    # Require at least one arg...
    die $self->usage_text(), "\n" unless @args;

    # Accept only digits as args...
    die 'arguments must be digits', "\n" if grep /\D/, @args;
}

sub run {
    my ($self, $opts, @args) = @_;

    my $db = $self->cache->get('db');
    $db->delete_entry( $_ ) for (@args);

    return;
}

#-------
1;

__END__

=pod

=head1 PURPOSE

Command to remove journal entries

=cut
