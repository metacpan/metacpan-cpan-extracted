package MyApp::C::CD;

use strict;
use base 'Catalyst::Base';

sub add : Local { 
    my ( $self, $c ) = @_;

    $self->_do_add($c);
    $c->stash->{output} = "Input Successful" unless scalar @{ $c->error };
}

sub add_error : Local { 
    my ( $self, $c ) = @_;

    $self->_do_add($c, 1);
    $c->stash->{output} = "Input Successful" unless scalar @{ $c->error };
}

sub add_atomic : Local { 
    my ( $self, $c ) = @_;

    $c->atomic( sub { $self->_do_add($c) } );
    $c->stash->{output} = "Input Successful" unless scalar @{ $c->error };
}

sub add_transaction : Local { 
    my ( $self, $c ) = @_;

    $c->transaction( sub { $self->_do_add($c) } );
    $c->stash->{output} = "Input Successful" unless scalar @{ $c->error };
}

sub add_trans : Local { 
    my ( $self, $c ) = @_;

    $c->trans( sub { $self->_do_add($c) } );
    $c->stash->{output} = "Input Successful" unless scalar @{ $c->error };
}

sub add_error_atomic : Local { 
    my ( $self, $c ) = @_;

    $c->atomic( sub { $self->_do_add($c, 1) } );
    $c->stash->{output} = "Input Successful" unless scalar @{ $c->error };
}

sub add_error_transaction : Local { 
    my ( $self, $c ) = @_;

    $c->transaction( sub { $self->_do_add($c, 1) } );
    $c->stash->{output} = "Input Successful" unless scalar @{ $c->error };
}

sub add_error_trans : Local { 
    my ( $self, $c ) = @_;

    $c->trans( sub { $self->_do_add($c, 1) } );
    $c->stash->{output} = "Input Successful" unless scalar @{ $c->error };
}

sub _do_add : Private {
    my ( $self, $c, $error ) = @_;

    my ($artist_name, $title, $year, $notes) = @{ $c->req->arguments };

    my $artist = MyApp::M::CDBI::Artist->find_or_create({
        name => $artist_name,
    });

    my $cd = MyApp::M::CDBI::Cd->create({
        artist => $artist,
        title  => $title,
        year   => $year,
    });

    die("Throwing an error between cd and liner_notes") if $error;

    if ( $notes ) {
        $cd->notes($notes);
        $cd->update;
    }
}

sub default : Private {
    my ( $self, $c ) = @_;

    my $cds = MyApp::M::CDBI::Cd->retrieve_all;

    my $output = join('|', qw/cdid artist title year/) . "\n";
    while ( my $cd = $cds->next ) {
        $output .= join('|', $cd, $cd->artist, $cd->title, $cd->year) . "\n";
    }

    $c->res->output($output);
}

1;
