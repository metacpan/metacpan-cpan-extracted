package My::Journal::Command::Entry::Modify;
use base qw( My::Journal::Command::Entry );

use strict;
use warnings;

sub usage_text {
    q{
    entry modify tag (add|remove|reset) --id=<entry-id> <tag-name1> [<tag-name2> ...]
    }
}

#-------
package My::Journal::Command::Entry::Modify::Tag;
use base qw( My::Journal::Command::Entry::Modify );
use strict;
use warnings;

sub option_spec {
    [ 'id=s' => 'id' ],
}

package My::Journal::Command::Entry::Modify::Tag::Add;
use base qw( My::Journal::Command::Entry::Modify::Tag );
use strict;
use warnings;

sub validate {
    my ($self, $opts, @args) = @_;
    die $self->usage_text(), "\n" unless $opts->{id} && @args;
}

sub run {
    my ($self, $opts, @args) = @_;

    my $db = $self->cache->get( 'db' );

    $db->add_tag_to_entry( $opts->{id}, $_ ) for @args;

    return '';
}

package My::Journal::Command::Entry::Modify::Tag::Remove;
use base qw( My::Journal::Command::Entry::Modify::Tag );
use strict;
use warnings;

sub validate {
    my ($self, $opts, @args) = @_;
    die $self->usage_text(), "\n" unless $opts->{id} && @args;
}

sub run {
    my ($self, $opts, @args) = @_;

    my $db = $self->cache->get( 'db' );

    my @tag_ids;
    for my $tag_text (@args) {
        my $tag_id = $db->get_tag_id_by_name( $tag_text );
        push @tag_ids, $tag_id if defined $tag_id;
    }
    $db->remove_tag_from_entry( $opts->{id}, $_ ) for @tag_ids;

    return '';
}

package My::Journal::Command::Entry::Modify::Tag::Reset;
use base qw( My::Journal::Command::Entry::Modify::Tag );
use strict;
use warnings;

sub validate {
    my ($self, $opts, @args) = @_;
    die $self->usage_text(), "\n" unless $opts->{id} && @args;
}

sub run {
    my ($self, $opts, @args) = @_;

    my $db = $self->cache->get( 'db' );

    $db->clear_tags_from_entry( $opts->{id} );

    $db->add_tag_to_entry( $opts->{id}, $_ ) for @args;

    return '';
}

#-------
1;

__END__

=pod

=head1 NAME

My::Journal::Command::Entry::Modify - Subcommands to modify journal entries

=head2 My::Journal::Command::Entry::Modify::Tag

Subcommands to modify journal entry tags

=head2 My::Journal::Command::Entry::Modify::Tag::Add

=head2 My::Journal::Command::Entry::Modify::Tag::Remove

=head2 My::Journal::Command::Entry::Modify::Tag::Reset

=cut
