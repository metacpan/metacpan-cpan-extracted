package Bot::Backbone::Service::Fact::Predicate;
{
  $Bot::Backbone::Service::Fact::Predicate::VERSION = '0.142250';
}
use Bot::Backbone::Service;

# ABSTRACT: Keep track of statements of equivalence and the like

with qw(
    Bot::Backbone::Service::Role::Service
    Bot::Backbone::Service::Role::Responder
    Bot::Backbone::Service::Role::Storage
);


service_dispatcher as {
    command '!randomfact' => respond_by_method 'random_fact';
    also not_command spoken respond_by_method 'memorize_and_recall';
};


has accepted_copula => (
    is          => 'ro',
    isa         => 'ArrayRef[Str]',
    required    => 1,
    default     => sub {
        [ qw( is isn't are aren't ) ],
    },
);


has copula_re => (
    is          => 'ro',
    isa         => 'RegexpRef',
    lazy_build  => 1,
);

sub _build_copula_re {
    my $self = shift;
    my $copula_list = join '|', map { quotemeta } @{ $self->accepted_copula };
    return qr/\b($copula_list)\b/;
}


sub load_schema {
    my ($self, $db_conn) = @_;

    $db_conn->run(fixup => sub {
        $_->do(q[
            CREATE TABLE IF NOT EXISTS fact_predicates(
                subject_key TEXT,
                copula_key TEXT,
                predicate_key TEXT,
                subject TEXT,
                copula TEXT,
                predicate TEXT,
                PRIMARY KEY (subject_key, copula_key, predicate_key)
            )
        ]);
    });
}


sub store_fact {
    my ($self, $subject, $copula, $predicate) = @_;

    $self->db_conn->run(fixup => sub {
        $_->do(q[
            INSERT INTO fact_predicates(subject_key, copula_key, predicate_key, subject, copula, predicate)
            VALUES (?, ?, ?, ?, ?, ?)
        ], undef, lc($subject), lc($copula), lc($predicate), $subject, $copula, $predicate);
    });
}


sub recall_fact {
    my ($self, $subject, $copula) = @_;

    my @fact = $self->db_conn->run(fixup => sub {
        $_->selectrow_array(q[
            SELECT subject, copula, predicate
              FROM fact_predicates
             WHERE subject_key = ?
          ORDER BY copula_key = ? DESC, RANDOM()
             LIMIT 1
        ], undef, lc($subject), lc($copula));
    });

    return @fact;
}


sub _trim { local $_ = shift; s/^\s+//; s/\s+$//; $_ }
sub memorize_and_recall {
    my ($self, $message) = @_;

    my $regex = $self->copula_re;
    my $text = $message->text;
    my ($subject, $copula, $predicate) = map { _trim($_) } split /$regex/, $text, 2;

    if ($subject and $copula and $predicate) {
        if (lc($subject) eq 'what' or lc($subject) eq 'who') {
            $predicate =~ s/\?$//;
            $subject = $predicate;
            ($subject, $copula, $predicate) = $self->recall_fact($subject, $copula);
            return "$subject $copula $predicate" if $predicate;
            return;
        }

        else {
            $self->store_fact($subject, $copula, $predicate);
        }
    }

    else {
        my @fact = $self->recall_fact($text, '');
        return join ' ', @fact if @fact;
        return;
    }

    return;
}


sub random_fact {
    my ($self, $message) = @_;

    my @fact = $self->db_conn->run(fixup => sub {
        $_->selectrow_array(q[
            SELECT subject, copula, predicate
              FROM fact_predicates
          ORDER BY RANDOM()
             LIMIT 1
        ]);
    });

    return join ' ', @fact if @fact;
    return 'I do not know any facts.';
}


sub initialize { }

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

Bot::Backbone::Service::Fact::Predicate - Keep track of statements of equivalence and the like

=head1 VERSION

version 0.142250

=head1 SYNOPSIS

    # in the bot configuration
    service predicate => (
        service         => 'Fact::Predicate',
        accepted_copula => [ qw( is says ) ],
    );

    # In chat:
    alice> Zathras says "Can not run out of time, there is infinite time. You
    are finite, Zathras is finite. This is wrong tool. No. No. Not good. No.
    No. Never use this."
    alice> Zathras?
    bot> Zathras says "Can not run out of time, there is infinite time. You
    are finite, Zathras is finite. This is wrong tool. No. No. Not good. No.
    No. Never use this."

=head1 DESCRIPTION

With this service configured, the bot will monitor the chat and whenever
it encounters a statement that appears to be in the correct predicate nominative
form, it will memorize that fact. Later one, if a question is issued for the
memorize fact, the bot will return a memorized response for it. It can
memorize multiple responses for the same fact, in which case, it returns
any one of them at random.

=head1 DISPATCHER

=head2 !randomfact

This command will cause the bot to pick one of it's memorized facts and return
it.

=head2 All Chats

All other chats are memorized to see if they appear to be of the form:

    <subject> <copula> <predicate>

In those cases, the fact is memorized. 

At the same time, it checks to see if any chat message matches a known
subject. If it does, the bot will return the original statement of the fact.

=head1 ATTRIBUTES

=head2 accepted_copula

This is a list of acceptable copula. A "copula" is a connecting word in a sentence connecting a subject and complement. Depending on context, there are a lot of words that can be found in a statement of equivalence, but the default just includes these words:

    is isn't are aren't

You can also put other words that aren't strictly words that define predicate nominative equivalence, such as "says" or "smells like" or whatever. Every time these words appear in a statement within a chat, though, it will be memorized.

=head2 copula_re

This is a regular expression that is usually built from the L</accepted_copula>. It is used to identify and split chats that contain a statement of the form the bot is looking for.

=head1 METHODS

=head2 load_schema

Used by the L<Bot::Backbone::Service::Role::Storage> to setup the C<fact_predicates> table.

=head2 store_fact

This is a helper function that saves a subject/predicate fact.

=head2 recall_fact

This is a helper used to retrieve a subject/predicate fact.

=head2 memorize_and_recall

This is the method used to monitor all chats for facts to memorize or recall.

=head2 random_fact

This implements the C<!randomfact> command.

=head2 initialize

No op.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
