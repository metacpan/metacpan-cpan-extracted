package Bot::BasicBot::Pluggable::Module::Karma;
$Bot::BasicBot::Pluggable::Module::Karma::VERSION = '1.30';
use base qw(Bot::BasicBot::Pluggable::Module);
use warnings;
use strict;

sub init {
    my $self = shift;
    $self->config(
        {
            user_ignore_selfkarma  => 1,
            user_num_comments      => 3,
            user_show_givers       => 1,
            user_randomize_reasons => 1,
	    user_karma_change_response => 1,
        }
    );
}

sub help {
    return
"Gives karma for or against a particular thing. Usage: <thing>++ # comment, <thing>-- # comment, karma <thing>, explain <thing>.";
}

sub told {
    my ( $self, $mess ) = @_;
    my $body = $mess->{body};
    return 0 unless defined $body;

    # If someone is trying to change the bot's karma, we'll have our bot nick in
    # {addressed}, and '++' or '-' in the body ('-' rather than '--' because
    # Bot::BasicBot removes one of the dashes as it considers it part of the
    # address)
    if ( $mess->{address} && ($body eq '++' or $body eq '-') ) {
        $body = '--' if $body eq '-';
        $body = $mess->{address} . $body;
    }

    my $op_re      = qr{ ( \-\- | \+\+ )        }x;
    my $comment_re = qr{ (?: \s* \# \s* (.+) )? }x;
    for my $regex (
        qr{^   (\S+)     $op_re $comment_re  }x, # singleword++
        qr{^ \( (.+)  \) $op_re $comment_re  }x  # (more words)++
    ) {
        if (my($thing, $op, $comment) = $body =~ $regex) {
            my $add = $op eq '++' ? 1 : 0;
            if ( 
                ( $1 eq $mess->{who} ) and $self->get("user_ignore_selfkarma") 
            ){
                return;
            }
            my $reply = $self->add_karma( $thing, $add, $comment, $mess->{who} );
            if (lc $thing eq lc $self->bot->nick) {
                $reply .= ' ' . ($add ? '(thanks!)' : '(pffft)');
            }
            return $reply;
        }
    }

    # OK, handle "karma" / "explain" commands
    my ( $command, $param ) = split( /\s+/, $body, 2 );
    $command = lc($command);

    if ( $command eq "karma" ) {
		$param =~ s/\?+$//; # handle interrogatives - lop off trailing question marks
        if ($param && $param eq 'chameleon') {
            return "Karma karma karma karma karma chameleon, "
                . "you come and go, you come and go...";
        }
        $param ||= $mess->{who};
        return "$param has karma of " . $self->get_karma($param) . ".";
    
    } elsif ( $command eq "explain" and $param ) {
        $param =~ s/^karma\s+//i;
        my ( $karma, $good, $bad ) = $self->get_karma($param);
        my $reply = "positive: " . $self->format_reasons($good) . "; ";
        $reply .= "negative: " . $self->format_reasons($bad) . "; ";
        $reply .= "overall: $karma.";

        return $reply;
    }
}


sub format_reasons {
    my ( $self, $reason ) = @_;
    my $num_comments = $self->get('user_num_comments');

    if ( $num_comments == 0 ) {
        return scalar( $reason->() );
    }

    my @reasons     = $reason->();
    my $num_reasons = @reasons;

    if ( $num_reasons == 0 ) {
        return 'nothing';
    }

    if ( $num_reasons == 1 ) {
        return ( $self->maybe_add_giver(@reasons) )[0];
    }

    $self->trim_list( \@reasons, $num_comments );
    return join( ', ', $self->maybe_add_giver(@reasons) );
}

sub maybe_add_giver {
    my ( $self, @reasons ) = @_;
    if ( $self->get('user_show_givers') ) {

        # adding a (user) string to the all reasons
        return map { $_->{reason} . ' (' . $_->{who} . ')' } @reasons;
    }
    else {

        # just returning the reason string of the reason hash referenes
        return map { $_->{reason} } @reasons;
    }
}

sub get_karma {
    my ( $self, $thing ) = @_;
    $thing = lc($thing);
    $thing =~ s/-/ /g;

    my @changes = grep { ref } @{ $self->get("karma_$thing") || [] };

    my ( @good, @bad );
    my $karma    = 0;
    my $positive = 0;
    my $negative = 0;

    for my $row (@changes) {

        # just push non empty reasons on the array
        my $reason = $row->{reason};
        if ( $row->{positive} ) { $positive++; push( @good, +{ %$row } ) if $reason }
        else                    { $negative++; push( @bad, +{ %$row } ) if $reason }
    }
    $karma = $positive - $negative;

    # The subroutine references return differant values when called.
    # If they are called in scalar context, they return the overall
    # positive or negative karma, but when called in list context you
    # get an array of hash references with all non empty reasons back.

    return wantarray()
      ? (
        $karma,
        sub { return wantarray ? @good : $positive },
        sub { return wantarray ? @bad  : $negative }
      )
      : $karma;
}

sub add_karma {
    my ( $self, $thing, $good, $reason, $who ) = @_;
    $thing = lc($thing);
    $thing =~ s/-/ /g;
    my $row =
      { reason => $reason, who => $who, timestamp => time, positive => $good };
    my @changes = map { +{ %$_ } } grep { ref } @{ $self->get("karma_$thing") || [] };
    push @changes, $row;
    $self->set( "karma_$thing" => \@changes );
    my $respond = $self->get('user_karma_change_response');
    $respond = 1 if !defined $respond;
    return $respond ?
        "Karma for $thing is now " . scalar $self->get_karma($thing) : 1;
}

sub trim_list {
    my ( $self, $list, $count ) = @_;

    # If randomization isn't requested we just return the reasons
    # in reversed chronological order

    if ( $self->get('user_randomize_reasons') ) {
        fisher_yates_shuffle($list);
    }
    else {
        @$list = reverse sort { $b->{timestamp} cmp $a->{timestamp} } @$list;
    }

    if ( scalar(@$list) > $count ) {
        @$list = splice( @$list, 0, $count );
    }
}

sub fisher_yates_shuffle {
    my $array = shift;
    my $i     = @$array;
    while ( $i-- ) {
        my $j = int rand( $i + 1 );
        @$array[ $i, $j ] = @$array[ $j, $i ];
    }
}

1;

__END__

=head1 NAME

Bot::BasicBot::Pluggable::Module::Karma - tracks karma for various concepts

=head1 VERSION

version 1.30

=head1 IRC USAGE

=over 4

=item <thing>++ # <comment>

Increases the karma for <thing>.

Responds with the new karma for <thing> unless C<karma_change_response> is set 
to a false value.

=item <thing>-- # <comment>

Decreases the karma for <thing>.

Responds with the new karma for <thing> unless C<karma_change_response> is set 
to a false value.

=item karma <thing>

Replies with the karma rating for <thing>.

=item explain <thing>

Lists three each good and bad things said about <thing>:

  <user> explain Morbus
  <bot> positive: committing lots of bot documentation; fixing the
        fisher_yates; negative: filling the dev list. overall: 5

=back

=head1 METHODS

=over 4

=item get_karma($username)

Returns either a string representing the total number of karma
points for the passed C<$username> or the total number of karma
points and subroutine reference for good and bad karma comments.
These references return the according karma levels when called in
scalar context or a array of hash reference. Every hash reference
has entries for the timestamp (timestamp), the giver (who) and the
explanation string (reason) for its karma action.

=item add_karma($thing, $good, $reason, $who)

Adds or subtracts from the passed C<$thing>'s karma. C<$good> is either 1 (to
add a karma point to the C<$thing> or 0 (to subtract). C<$reason> is an 
optional string commenting on the reason for the change, and C<$who> is the
person modifying the karma of C<$thing>. Nothing is returned.

=back

=head1 VARS

=over 4

=item ignore_selfkarma

Defaults to 1; determines whether to respect selfkarmaing or not.

=item num_comments

Defaults to 3; number of good and bad comments to display on
explanations. Set this variable to 0 if you do not want to list
reasons at all.

=item show_givers

Defaults to 1; whether to show who gave good or bad comments on
explanations.

=item randomize_reasons

Defaults to 1; whether to randomize the order of reasons. If set
to 0, the reasons are sorted in reversed chronological order.

=item karma_change_response

Defaults to 1; whether to show a response when the karma of a
thing is changed.  If true, the bot will reply with the new karma.
If set to 0, the bot will silently update the karma, without
a response.

=back

=head1 AUTHOR

Mario Domgoergen <mdom@cpan.org>

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.
