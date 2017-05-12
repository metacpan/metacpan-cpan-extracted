package Bot::Backbone::Service::OFun::Karma;
$Bot::Backbone::Service::OFun::Karma::VERSION = '0.142230';
use Bot::Backbone::Service;

with qw(
    Bot::Backbone::Service::Role::Service
    Bot::Backbone::Service::Role::Responder
    Bot::Backbone::Service::Role::Storage
);

# ABSTRACT: Keep track of your channel's favorite things


service_dispatcher as {
    command '!score' => given_parameters {
        parameter 'thing' => ( match_original => qr/.+/ );
    } respond_by_method 'score_of_thing';

    command '!best' => respond_by_method 'best_scores';
    command '!score' => respond_by_method 'best_scores';
    command '!worst' => respond_by_method 'worst_scores';

    command '!score_alias' => given_parameters {
        parameter 'this' => ( match => qr/.+/ );
        parameter 'that' => ( match => qr/.+/ );
    } respond_by_method 'alias_this_to_that';
    command '!score_alias' => given_parameters {
        parameter 'this' => ( match => qr/.+/ );
    } respond_by_method 'show_alias_of_this';
    command '!score_unalias' => given_parameters {
        parameter 'this' => ( match => qr/.+/ );
    } respond_by_method 'unalias_this';

    also not_command spoken run_this_method 'update_scores';
};


sub load_schema {
    my ($self, $conn) = @_;

    $conn->run(fixup => sub {
        $_->do(q[
            CREATE TABLE IF NOT EXISTS karma_score(
                name varchar(255),
                score int,
                PRIMARY KEY (name)
            )
        ]);

        $_->do(q[
            CREATE TABLE IF NOT EXISTS karma_alias(
                name varchar(255),
                score_as varchar(255),
                PRIMARY KEY (name)
            );
        ]);
    });
}


sub ok_name {
    my ($self, $name) = @_;

    # No empty string votes
    return unless $name;

    # No file permissions
    return if $name =~ /^[d-][r-][w-][x-][r-][w-][sx-][r-][w-]?[tx-]?/;

    # And there should be at least a couple word chars
    return unless $name =~ /\w.*?\w/;

    # OK!
    return 1;
}


sub update_scores {
    my ($self, $message) = @_;

    my @args = $message->all_args;
    THING: for my $i (0 .. $#args) {
        my $arg  = $args[$i];
        my $name = $arg->text;

        # word by itself, join it to the previous maybe?
        if ($name eq '++' or $name eq '--') {

            # Can't be postfix ++/-- if it's the first thing
            next THING unless $i > 0;

            # Ignore if there's space between ++/-- and the previous thing
            next THING unless $args[$i-1]->original =~ /\S$/;

            # Looks legit, join the last word to this for the vote
            $name = $args[$i-1]->text . $name;
        }

        if ($name =~ s/(\+\+|--)$//) {
            my $direction = $1 eq '++' ? +1 : -1;

            next THING unless $self->ok_name($name);

            $self->db_conn->txn(fixup => sub {
                $_->do(q[
                    INSERT OR IGNORE INTO karma_score(name, score)
                    VALUES (?, ?)
                ], undef, $name, 0);
            
                $_->do(q[
                    UPDATE karma_score
                       SET score = score + ?
                     WHERE name = ?
                ], undef, $direction, $name);
            });
        }
    }
}


sub score_of_thing {
    my ($self, $message) = @_;

    my $thing = $message->parameters->{thing};

    my ($score) = $self->db_conn->txn(fixup => sub {
        my ($score_as) = $_->selectrow_array(q[
            SELECT score_as
              FROM karma_alias
             WHERE name = ?
        ], undef, $thing);

        $thing = $score_as if defined $score_as;
        my $sth = $_->prepare(q[
            SELECT ks.score + COALESCE(SUM(kas.score), 0)
              FROM karma_score ks
         LEFT JOIN karma_alias ka ON ks.name = ka.score_as
         LEFT JOIN karma_score kas ON ka.name = kas.name
             WHERE ks.name = ?
        ]);

        $sth->execute($thing);

        $sth->fetchrow_array;
    });

    $score //= 0;

    return "$thing: $score";
}


sub show_alias_of_this {
    my ($self, $message) = @_;

    my $this = $message->parameters->{this};

    my $aliases = $self->db_conn->run(fixup => sub {
        $_->selectall_arrayref(q[
            SELECT name, score_as
              FROM karma_alias
             WHERE name = ? OR score_as = ?
        ], undef, $this, $this);
    });

    return qq[Nothing aliases to or from "$this".] unless @$aliases;

    my ($scored_as, @included_scores);
    for my $alias (@$aliases) {
        my ($name, $score_as) = @$alias;
        if ($name eq $this) {
            $scored_as = $score_as;
        }
        else {
            push @included_scores, qq["$name"];
        }
    }

    my @messages;
    push @messages, qq[Warning: "$this" has aliases to and from for scoring, which is not supposed to happen.]
        if $scored_as and @included_scores;

    push @messages, qq[Scores for "$this" are counted for "$scored_as" instead.]
        if $scored_as;

    my $comma = '';
    if (@included_scores == 2) {
        $comma = ' and ';
    }
    elsif (@included_scores > 2) {
        $comma = ', ';
        $included_scores[-1] = 'and ' . $included_scores[-1];
    }

    push @messages, qq[Scores for "$this" also include ].join($comma, @included_scores)."."
        if @included_scores;

    return @messages;
}


sub alias_this_to_that {
    my ($self, $message) = @_;

    my $this = $message->parameters->{this};
    my $that = $message->parameters->{that};

    return "Those are both the same thing." if $this eq $that;

    for ($this, $that) {
        return qq[Sorry, but "$_" cannot be scored.] unless $self->ok_name($_);
    }

    $self->db_conn->txn(fixup => sub {
        my $dbh = $_;

        $dbh->do(q[
            DELETE FROM karma_alias
            WHERE name = ? OR score_as = ? OR name = ?
        ], undef, $this, $this, $that);

        # Make sure the name exists for JOINing too
        $dbh->do(q[
            INSERT OR IGNORE INTO karma_score(name, score)
            VALUES (?, ?)
        ], undef, $_, 0) for ($this, $that);

        $dbh->do(q[
            INSERT INTO karma_alias(name, score_as)
            VALUES (?, ?)
        ], undef, $this, $that);
    });

    return qq[Scores for "$this" will count for "$that" instead.];
}


sub unalias_this {
    my ($self, $message) = @_;

    my $this = $message->parameters->{this};

    $self->db_conn->run(fixup => sub {
        $_->do(q[
            DELETE FROM karma_alias
            WHERE name = ?
        ], undef, $this);
    });

    return qq[Scores for "$this" will count for "$this" now.];
}


sub best_scores {
    my ($self, $message) = @_;
    return $self->_n_scores(best => 10);
}


sub worst_scores {
    my ($self, $message) = @_;
    return $self->_n_scores(worst => 10);
}

sub _n_scores {
    my ($self, $which, $n) = @_;

    my $direction = $which eq 'best' ? 'DESC' : 'ASC';
    my ($scores) = $self->db_conn->run(fixup => sub {
        $_->selectall_arrayref(qq[
            SELECT ks.name, ks.score + COALESCE(SUM(kas.score), 0)
              FROM karma_score ks
         LEFT JOIN karma_alias kb ON ks.name = kb.name
         LEFT JOIN karma_alias ka ON ks.name = ka.score_as
         LEFT JOIN karma_score kas ON ka.name = kas.name
             WHERE kb.name IS NULL
          GROUP BY ks.name
            HAVING ks.score + COALESCE(SUM(kas.score), 0) != 0
          ORDER BY SUM(ks.score) $direction
             LIMIT $n
        ]);
    });

    return "No scores." unless @$scores;

    return map { "$_->[0]: $_->[1]" } @$scores;
}


sub initialize { }

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Service::OFun::Karma - Keep track of your channel's favorite things

=head1 VERSION

version 0.142230

=head1 SYNOPSIS

    # in your bot config
    service karma => (
        service => 'OFun::Karma',
        db_dsn  => 'dbi:SQLite:karma.db',
    );

    disapatcher chatroom => as {
        redispatch_to 'karma';
    }

    # in chat
    alice> bob++ that was hilarious
    bob> !best
    bot> alice: 23
         bob: 14
         rob: 7
         bobby: 6
    bob> !score_alias bobby bob
    bot> Scores for "bobby" will count for "bob" instead.
    alice> !score_alias rob bob
    bot> Scores for "rob" will count for "bob" instead.
    bob> !score bob
    bot> bob: 27
    bob> !score bobby
    bot> bob: 27
    bob> !score_alias bob
    bot> Scores for "bob" also include "bobby" and "rob".
    bob> !score_unalias rob
    bot> Scores for "rob" will count for "rob" now.
    alice> "made up stuff"--
    bob> !worst
    bot> made up stuff: -1
         rob: 7
         bob: 20
         alice: 23

=head1 DESCRIPTION

A common idiom in group chat (at least among tech geeks) is to use ++ and -- to show appreciation and derision. Now, you can have a bot that tracks that. It will show you a best ten list, a worst ten list, and the score of any particular word or phrase. 

You can also provide aliases, just in case a particular thing is referred to in more than one way and you want to track those scores together. The scores are still tracked for the original words, but tallied together while aliased. This way, if someone creates a bad or false alias, you can unalias it later without losing how things were scored in the meantime.

=head1 DISPATCHER

=head2 !score

    !score thing
    !score

With an argument, this command reports the score for it. Without an argument, it shows the best ten list, just like C<!best>.

=head2 !best

This command takes no arguments and shows the best ten list.

=head2 !worst

This command takes no argumenst and shows the worst ten list.

=head2 !score_alias

    !score_alias this that
    !score_alias this

With two arguments, this command will establish an alias from one word or phrase to another. You need to make sure to quote your phrases if they contain more than one word. Note that when it creates the alias, it will remove that word from either side of any other alias. Aliases cannot be chained.

If only a single argument is given (again, make sure you quote your phrases), it will report if there are any score aliases to or from that word or phrase.

=head2 !score_unalias

    !score_unalias this

This will delete any alias from this to something else.

=head2 Other Conversation

Finally, any other conversation is monitored to see if it contains ++ or -- notation. Anytime a word or quoted phrase contains a ++ or -- at the end of it, the score for that word or phrase will be incremented or decremented (respectively).

=head1 METHODS

=head2 load_schema

Called when making database connections to create tables needed to store scores and aliases.

=head2 ok_name

Given a name, returns true if it's scorable.

=head2 update_scores

This implements the tracking of ++ and -- to update scores from regular conversation.

=head2 score_of_thing

Reports the score of a thing, including any aliased scores.

=head2 show_alias_of_this

Used to implement C<!score_alias> with a single argument.

=head2 alias_this_to_that

Implements C<!score_alias> with two arguments.

=head2 unalias_this

Implements the C<!score_unalias> command.

=head2 best_scores

Implements the best 10 list.

=head2 worst_scores

Implements the worst 10 list.

=head2 initialize

No op.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
