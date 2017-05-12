package My::Journal::Command::Entry;
use base qw( CLI::Framework::Command );

use strict;
use warnings;

#-------

sub usage_text {
    q{
    entry [--date=yyyy-mm-dd] [subcommands...]

    OPTIONS
       --date=yyyy-mm-dd:       set date that entry appiles to
   
    ARGUMENTS (subcommands)
        add:                    add an entry
        remove:                 remove an entry
        modify:                 modify an entry
        search:                 search for entries by regex; show summary
        print:                  display full text of entries
    }
}

sub option_spec {
    return unless ref $_[0] eq __PACKAGE__; # non-inheritable behavior
    (
        [ 'date=s' => 'date that entry applies to' ],
    )
}

sub subcommand_alias {
    return unless ref $_[0] eq __PACKAGE__; # non-inheritable behavior
    (
        a   => 'add',
        s   => 'search',
        p   => 'print',

        rm  => 'remove',
        del => 'remove',
        rem => 'remove',

        m   => 'modify',
        mod => 'modify',
    )
}

sub validate {
    my ($self, $opts, @args) = @_;
    return unless ref $_[0] eq __PACKAGE__; # non-inheritable behavior

    # ...
}

sub notify_master {
    my ($self, $subcommand, $opts, @args ) = @_;
    return unless ref $_[0] eq __PACKAGE__; # non-inheritable behavior

    # ...
}

#-------

#
# Inline subcommand example...
#
# NOTE that the 'search' subcommand is defined inline in the same package
# file as its master commnd, 'entry.'
#
# This is supported as an alternative to defining the subcommand in its
# own separate package file.
#

package My::Journal::Command::Entry::Search;
use base qw( My::Journal::Command::Entry );

use strict;
use warnings;

sub usage_text {
    q{
    entry search --regex=<regex> [--tag=<tag>]: search for journal entries
    }
}

sub option_spec {
    [ 'regex=s' => 'regex' ],
    [ 'tag=s@'   => 'tag' ],
}

sub validate {
    my ($self, $opts, @args) = @_;
    die "missing required option 'regex'\n" unless $opts->{regex};
}

sub run {
    my ($self, $opts, @args) = @_;

    my $regex   = $opts->{regex};
    my $tags    = $opts->{tag};

    my $r = eval { qr/$regex/ };
    $r ||= qr/.*/;
    warn "searching...\n" if $self->cache->get('verbose');

    my $db = $self->cache->get('db');  # model class object

    # Show a brief summary of truncated entries with their ids...
    my @entries;
    if( defined $tags ) {
        for my $tag ( @$tags ) {
            push @entries, $db->entries_by_tag($tag);
        }
    }
    else {
        @entries = $db->all_entries();
    }
    my $matching;
    for my $entry (@entries) {
        if( $entry->{entry_text} =~ /$r/m ) {
            my $id = $entry->{id};
            my $entry_summary = sprintf "%10d: %s",
                $id, substr( $entry->{entry_text}, 0, 80 );
            $matching->{$id} = $entry_summary;
        }
    }
    return join "\n", values %$matching;
}

#-------
1;

__END__

=pod

=head1 NAME 

My::Journal::Command::Entry - Command to work with journal entries

=head2 My::Journal::Command::Entry::Search

Subcommand to search for journal entries

=cut
