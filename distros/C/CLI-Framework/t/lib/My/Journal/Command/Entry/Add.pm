package My::Journal::Command::Entry::Add;
use base qw( My::Journal::Command::Entry );

use strict;
use warnings;

sub usage_text {
    q{
    entry add [--tag=<tag-name> [--tag=...]] <entry-text>: add a new journal entry with optional tags
    }
}

sub option_spec {
    (
        [ 'tag=s@' => 'tag text' ],
    )
}

sub validate {
    my ($self, $opts, @args) = @_;
    die 'exactly one argument is required', "\n" unless @args == 1;
}

sub run {
    my ($self, $opts, @args) = @_;

    my $entry_text = shift @args;

    my $db = $self->cache->get( 'db' );
    my $entry_id = $db->insert_entry( $entry_text );

    my $tags = $opts->{tag};
    for my $tag ( @$tags ) {
        $db->add_tag_to_entry( $entry_id, $tag );
    }
    return '';
}

#-------
1;

__END__

=pod

=head1 My::Journal::Command::Entry::Add

=head2 PURPOSE

Command to add a journal entry

=cut
