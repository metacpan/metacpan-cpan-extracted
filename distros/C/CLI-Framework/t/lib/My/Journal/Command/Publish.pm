package My::Journal::Command::Publish;
use base qw( CLI::Framework::Command );

use strict;
use warnings;
use Carp;

#-------

sub usage_text {
    q{
    publish [--out=<output-file> --format=<format>]: publish a journal
    }
}

sub option_spec {
    (
        [ 'format=s'      => 'publish in specific format' ],
        [ 'template=s'    => '' ],
        [ 'out=s'         => 'output file' ],
    )
}

sub run {
    my ($self, $opts, @args) = @_;

    my $db = $self->cache->get('db');
    croak "DB not initialized in cache" unless $db;

    my @entries = $db->all_entries();
    my @entries_output;
    for my $entry (@entries) {
        my $entry_output = $entry->{id}.':'.$entry->{entry_text};

        my @tags = $db->tags_by_entry_id( $entry->{id} );
        $entry_output .= ' [tags: ' . join(',', @tags) . ']' if @tags;

        push @entries_output, $entry_output;
    }
print 'Pretend that this data gets published in the ',
'requested format, using a specified template, and sent to a named ',
"output file\n\n";
    return join("\n", @entries_output) . "\n";
}

#-------
1;

__END__

=pod

=head1 PURPOSE

Command to publish a journal

=cut
