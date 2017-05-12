package DBIx::Inspector::Driver::mysql;
use strict;
use warnings;
use utf8;
use base qw/DBIx::Inspector::Driver::Base/;

sub foreign_keys {
    my ($self, @args) = @_;

    my $sth = $self->dbh->foreign_key_info(@args);
    Carp::croak($self->dbh->errstr) unless $sth;
    # Note: DBD::mysql returns PRIMARY KEY constraints in the foreing_key_info.
    #       -- 2010-11-28 tokuhirom
    my $iter = DBIx::Inspector::Iterator->new(
        callback => sub {
            DBIx::Inspector::ForeignKey->new( inspector => $self, %{ $_[0] } );
        },
        # XXX DBD::mysql has a bug
        skip_cb => sub { $_[0]->{FK_NAME} eq 'PRIMARY' },
        sth => $sth,
    );
    return wantarray ? $iter->all : $iter;
}

1;

