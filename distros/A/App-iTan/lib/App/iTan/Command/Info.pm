# ================================================================
package App::iTan::Command::Info;
# ================================================================
use utf8;
use Moose;
use 5.0100;

use MooseX::App::Command;
with qw(App::iTan::Utils);

option 'index' => (
    is            => 'ro',
    isa           => 'Int',
    required      => 1,
    documentation => q[iTAN index number that should be fetched],
);

use Text::Table;

sub execute {
    my ( $self, $opts, $args ) = @_;

    my $sth
        = $self->dbh->prepare(
        'SELECT tindex,valid,itan,imported,used,memo FROM itan WHERE tindex = ?'
        ) or die "ERROR: Cannot prepare: " . $self->dbh->errstr();
    $sth->execute( $self->index )
        or die "ERROR: Cannot execute: " . $sth->errstr();

    my $tb = Text::Table->new(
        "Index",    \"|", "Valid", \"|", "Tan", \"|",
        "Imported", \"|", "Used",  \"|", "Memo"
    );

    while ( my $tan_data = $sth->fetchrow_hashref() ) {

        $tb->add(
            $tan_data->{tindex},
            $tan_data->{valid},
            $self->decrypt_string( $tan_data->{itan} ),
            $tan_data->{imported},
            $tan_data->{used},
            $tan_data->{memo} );
    }

    print $tb->title;
    print $tb->rule( '-', '+' );
    print $tb->body;
    
    return;
}

__PACKAGE__->meta->make_immutable;
1;

=pod

=encoding utf8

=head1 NAME

App::iTan::Command::Info - Info about the selected iTAN

=head1 SYNOPSIS

 itan info --index INDEX

=head1 DESCRIPTION

Will print a detailed report about the selected iTAN

=head1 OPTIONS

=head2 index

iTAN index number that should be fetched

=cut