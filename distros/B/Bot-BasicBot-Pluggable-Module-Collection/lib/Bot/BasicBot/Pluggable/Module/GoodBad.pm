
=head1 NAME

Bot::BasicBot::Pluggable::Module::GoodBad - Tracks Good/Bad for people

=head1 SYNOPSIS

Tracks Good/Bad for people

=head1 IRC USAGE

Commands:

=over 4

=item <thing>++ # <comment>

Increases the kerma for <thing>

=item <thing>-- # <comment>

Decreases the karma for <thing>

=back

=cut

package Bot::BasicBot::Pluggable::Module::GoodBad;
use strict;
use warnings;

our $VERSION = '0.04';
use base qw(Bot::BasicBot::Pluggable::Module);

sub said {
    my ( $self, $mess, $pri ) = @_;
    my $body = $mess->{body};
    if ( $pri == 0 ) {
        if (   ( $body =~ /(\w+)\+\+/ )
            or ( $body =~ /\(([^()]+)\)\+\+/ ) )
        {
            $self->good( $1, 1, $mess->{who} );
            return $self->reply_with_goodbad( $mess, $1 );
        }
        elsif (( $body =~ /(\w+)--/ )
            or ( $body =~ /\(([^()]+)\)--/ ) )
        {
            $self->bad( $1, 0, $mess->{who} );
            return $self->reply_with_goodbad( $mess, $1 );
        }
    }
}

sub good {
    my ( $self, $object, $good, $who ) = @_;
    $object = lc($object);
    $object =~ s/-/ /g;
    my $row = { who => $who, timestamp => time, positive => $good };

    my @changes = @{ $self->get("goodbad_$object") || [] };
    push @changes, $row;
    $self->set( "goodbad_$object" => \@changes );
    return;
}

sub bad {
    my ( $self, $object, $bad, $who ) = @_;
    $object = lc($object);
    $object =~ s/-/ /g;
    my $row = { who => $who, timestamp => time, negative => $bad };

    my @changes = @{ $self->get("goodbad_$object") || [] };
    push @changes, $row;
    $self->set( "goodbad_$object" => \@changes );
    return;
}

sub get_goodbad {
    my ( $self, $object ) = @_;
    $object = lc($object);
    $object =~ s/-/ /g;
    my @changes = @{ $self->get("goodbad_$object") || [] };

    my $good = 0;
    my $bad  = 0;

    for my $row (@changes) {
        if ( $row->{positive} ) {
            $good++;
        }
        else {
            $bad++;
        }
    }

    if ( wantarray() ) {
        return ( $good, $bad );
    }
}

sub reply_with_goodbad {
    my ( $self, $message, $target ) = @_;
    my ( $good, $bad ) = $self->get_goodbad($target);
    my $reply .= "\cC14" . $target . " (" . $good . "++, " . $bad . "--" . ")";
    $self->reply( $message, $reply ) if $reply;
}

1;
