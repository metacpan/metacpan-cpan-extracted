package DBIx::Inspector::ForeignKey;
use strict;
use warnings;
use utf8;
use Class::Accessor::Lite;
Class::Accessor::Lite->mk_accessors(qw/inspector/);

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{ $_[0] } : @_;
    bless {%args}, $class;
}

{
    no strict 'refs';
    for my $k (
        qw/PKTABLE_NAME FKTABLE_NAME FKCOLUMN_NAME PK_NAME DEFERABILITY FKTABLE_CAT PKTABLE_SCHEM KEY_SEQ PKTABLE_CAT UNIQUE_OR_PRIMARY FKTABLE_SCHEM PKCOLUMN_NAME DELETE_RULE FK_NAME/
      )
    {
        *{ __PACKAGE__ . "::" . lc($k) } = sub { $_[0]->{$k} };
    }
}

1;
__END__

=head1 NAME

DBIx::Inspector::ForeignKey - foreign key

=head1 ACCESSORS

Following attributes are provided.

=over 4

=item $foreign_key->pktable_name()

=item $foreign_key->fktable_name()

=item $foreign_key->fkcolumn_name()

=item $foreign_key->pk_name()

=item $foreign_key->deferability()

=item $foreign_key->fktable_cat()

=item $foreign_key->pktable_schem()

=item $foreign_key->key_seq()

=item $foreign_key->pktable_cat()

=item $foreign_key->unique_or_primary()

=item $foreign_key->fktable_schem()

=item $foreign_key->pkcolumn_name()

=item $foreign_key->delete_rule()

=item $foreign_key->fk_name()

=back

=head1 SEE ALSO

L<DBIx::Inspector>

