package My::Journal::Command::Entry::Print;
use base qw( My::Journal::Command::Entry );

use strict;
use warnings;
use Carp;

sub usage_text {
    q{
    entry print <id> [<id> ...]: display a journal entry
    }
}

sub validate {
    my ($self, $opts, @args) = @_;
    # Require at least one arg...
    die "at least one argument required\n" unless @args;
    # Accept only digits as args...
    die "only numerical ids allowed\n" if grep /\D/, @args;
}

sub run {
    my ($self, $opts, @args) = @_;

    my $db = $self->cache->get('db');
    my @entries;
    for my $id (@args) {
        my $entry = $db->entry_by_id( $id );
        push @entries, $entry->{id}.': '.$entry->{entry_text} if $entry;
    }
    return join("\n", @entries) . "\n";
}

#-------
1;

__END__

=pod

=head1 PURPOSE

Command to display journal entries given their ids

=cut
