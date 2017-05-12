package DBIx::Schema::DSL::Context;
use 5.008_001;
use strict;
use warnings;

use Moo;
use Clone qw/clone/;
use SQL::Translator;

has name => (
    is  => 'rw',
);

has db => (
    is  => 'rw',
    default => sub {'MySQL'},
);

has translator => (
    is  => 'lazy',
    default => sub {
        SQL::Translator->new;
    },
);

has schema => (
    is => 'lazy',
    default => sub {
        my $self = shift;
        $self->translator->schema->name($self->name);
        $self->translator->schema->database($self->db);
        $self->translator->schema;
    },
);

has _creating_table => (
    is => 'rw',
    clearer => '_clear_creating_table',
);

has translate => (
    is => 'lazy',
    default => sub {
        my $self = shift;
        my $output = $self->translator->translate(to => $self->db);
        # ignore initial comments.
        1 while $output =~ s/\A--.*?\r?\n//ms;
        $output;
    },
);

has table_extra => (
    is => 'lazy',
    writer => 'set_table_extra',
    default => sub {
        shift->db eq 'MySQL' ? {
            mysql_table_type => 'InnoDB',
            mysql_charset    => 'utf8',
        } : {};
    },
);

has default_unsigned => (
    is => 'rw',
);

has default_not_null => (
    is => 'rw',
);

has no_fk_translator => (
    is  => 'lazy',
    default => sub {
        my $self = shift;
        my $no_fk_translator = clone $self->translator;

        for my $table ($no_fk_translator->schema->get_tables) {
            $table->drop_constraint($_) for $table->fkey_constraints;
        }

        $no_fk_translator;
    },
);

has no_fk_translate => (
    is => 'lazy',
    default => sub {
        my $self = shift;
        my $output = $self->no_fk_translator->translate(to => $self->db);
        # ignore initial comments.
        1 while $output =~ s/\A--.*?\r?\n//ms;
        $output;
    },
);

has default_varchar_size => (
    is      => 'rw',
    default => sub { 255 },
);

no Moo;

sub _creating_table_name {
    shift->_creating_table->{table_name}
        or die 'Not in create_table block.';
}

1;
