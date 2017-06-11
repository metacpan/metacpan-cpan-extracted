# ================================================================
package App::iTan::Command::List;
# ================================================================
use utf8;
use Moose;
use 5.0100;

use MooseX::App::Command;
with qw(App::iTan::Utils);

use Text::Table;
use Moose::Util::TypeConstraints qw(enum);

our @SORTFIELDS = qw(tindex imported used);

option 'sort' => (
    is            => 'ro',
    isa           => enum(\@SORTFIELDS),
    required      => 1,
    default       => $SORTFIELDS[0],
    documentation => q[Set list sorting (].(join ',',@SORTFIELDS).q[)],
);

sub execute {
    my ( $self, $opts, $args ) = @_;

    my $tb = $self->get_table();

    print $tb->title;
    print $tb->rule('-','+');
    print $tb->body;

    return;
}

sub get_table {
    my ($self) = @_;

    my $sort = $self->sort;
    $sort .= ','.$SORTFIELDS[0]
        unless $SORTFIELDS[0] eq $sort;
    my $sth = $self->dbh->prepare("SELECT tindex,imported,used,memo
        FROM itan
        WHERE valid = 1 OR used IS NOT NULL
        ORDER BY $sort")
        or die "ERROR: Cannot prepare: " . $self->dbh->errstr();
    $sth->execute();

    my $tb = Text::Table->new(
        "Index",\"|","Imported",\"|","Used",\"|","Memo"
    );

    while (my @line = $sth->fetchrow_array) {
        $tb->add(@line);
    }

    return $tb;
}

__PACKAGE__->meta->make_immutable;
1;

=pod

=encoding utf8

=head1 NAME

App::iTan::Command::List - List of all iTANs

=head1 SYNOPSIS

 itan list [--sort (tindex imported used)]

=head1 DESCRIPTION

List of all either used or still available iTANs.

=head1 OPTIONS

=head2 sort

Set list sorting. Available options are

=over

=item * tindex

=item * imported

=item * used

=back

=cut
