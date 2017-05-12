package DBIx::Class::Journal::EvalWrap;
use base qw(DBIx::Class::Journal);

use strict;
use warnings;

foreach my $method (qw(journal_log_update journal_log_insert journal_log_delete)) {
    local $@;
    eval "sub $method " . ' {
    my ( $self, @args ) = @_;
    local $@;
    eval { $self->next::method(@args) };
    warn $@ if $@;
    }; 1' || warn $@;
}

__PACKAGE__

__END__

=pod

=head1 NAME

DBIx::Class::Journal::EvalWrap - Wrap all journal ops with an eval { }

=head1 SYNOPSIS

    __PACKAGE__->journal_component("Journal::EvalWrap");

=head1 DESCRIPTION

This component is a wrapper for the row methods in L<DBIx:Class::Journal> that
aides in retrofitting a schema for journaling, by wrapping all the journal CRUD
operations with a C<local $@; eval { ... }}.

This is desirable if you'd rather lose journal data than create runtime errors
when retrofitting existing code.

Use with caution.

=cut


