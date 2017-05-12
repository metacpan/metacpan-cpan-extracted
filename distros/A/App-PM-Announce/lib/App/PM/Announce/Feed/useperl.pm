package App::PM::Announce::Feed::useperl;

use warnings;
use strict;

use Moose;
extends 'App::PM::Announce::Feed';

has +uri => qw/required 0/;
has promote => qw/is ro default publish/;

use WWW::UsePerl::Journal::Post;
use WWW::UsePerl::Journal;

sub announce {
    my $self = shift;
    my %event = @_;

    my $username = $self->username;
    my $password = $self->password;
    my $promote = $self->promote || 'publish';

    $self->logger->debug( "Login as $username / $password" );

    my $journal = WWW::UsePerl::Journal->new( $username );
    $journal->login( $password );

    my $post = WWW::UsePerl::Journal::Post->new(
        j => $journal, # Duh, why is this required?
        username => $username,
        password => $password,
    );

    $self->logger->debug( "Promote as $promote" );

    $post->postentry(
        title => $self->format( \%event => 'title' ),
        text => $self->format( \%event => 'description' ),
        promote => $promote,
    );
}

1;
