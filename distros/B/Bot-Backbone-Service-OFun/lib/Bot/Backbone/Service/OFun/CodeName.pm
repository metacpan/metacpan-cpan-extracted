package Bot::Backbone::Service::OFun::CodeName;
$Bot::Backbone::Service::OFun::CodeName::VERSION = '0.142230';
use Bot::Backbone::Service;

with qw(
    Bot::Backbone::Service::Role::Service
    Bot::Backbone::Service::Role::Responder
    Bot::Backbone::Service::Role::Storage
);

use File::Slurp qw( read_file );
use MooseX::Types::Path::Class;
use Digest::SHA qw( sha1 );
use List::Util qw( reduce );

# ABSTRACT: Assign code names to words and phrases for fun and profit


service_dispatcher as {
    command '!codename' => given_parameters {
        parameter 'phrase' => ( match_original => qr/.+/ );
    } respond_by_method 'assign_codename';
};


for my $part (qw( adjective noun )) {
    my $part_file = "${part}s_file";
    has $part_file => (
        is         => 'ro',
        isa        => 'Path::Class::File',
        required   => 1,
        coerce     => 1,

    );

    __PACKAGE__->meta->add_method("_build_${part}s" => sub {
        my $self = shift;
        my @words = map { chomp; s/\s+$//; s/^\s+//; $_ } read_file($self->$part_file);
        return \@words;
    });

    has "${part}s" => (
        is         => 'ro',
        isa        => 'ArrayRef[Str]',
        lazy_build => 1,
        traits     => [ 'Array' ],
        handles    => {
            "get_${part}"    => 'get',
            "${part}s_count" => 'count',
        },
    );
}


sub load_schema {
    my ($self, $conn) = @_;

    $conn->run(fixup => sub {
        $_->do(q[
            CREATE TABLE IF NOT EXISTS codenames(
                name varchar(255),
                alias varchar(255),
                is_code_name integer,
                PRIMARY KEY (name)
            )
        ]);
    });
}


sub assign_codename {
    my ($self, $message) = @_;

    my $phrase = lc $message->parameters->{phrase};
    $phrase =~ s/^\s+//;
    $phrase =~ s/\s+$//;
    $phrase =~ s/\s+/ /g;

    my $alias = $self->find_key($phrase);
    if (defined $alias) {
        return $alias;
    }

    my $code_name = $self->generate_code_name($phrase);
    if ($code_name) {
        $self->store_key($code_name => $phrase, 1);
        $self->store_key($phrase => $code_name, 0);

        return $code_name;
    }
    else {
        return "Too many duplicates. Can't come up with a code name for that. Maybe you need to expand your adjectives or nouns list.";
    }
}


sub generate_code_name {
    my ($self, $phrase) = @_;
    my $try_phrase = $phrase;

    my $max_tries = 5;
    TRY: while ($max_tries >= 0) {
        my $inv_phrase = reverse $try_phrase;

        my $raw_adj_index  = reduce { $a ^ $b } unpack "L*", sha1($try_phrase);
        my $raw_noun_index = reduce { $a ^ $b } unpack "L*", sha1($inv_phrase);

        my $adj_index  = $raw_adj_index  % $self->adjectives_count;
        my $noun_index = $raw_noun_index % $self->nouns_count;

        my $adjective = $self->get_adjective($adj_index);
        my $noun      = $self->get_noun($noun_index);
        my $code_name = join ' ', $adjective, $noun;

        # Duplicate check
        my $pair = $self->find_key($code_name);
        if ($pair) {
            $try_phrase = $try_phrase . '\0' . $phrase;
            $max_tries--;
            next TRY;
        }

        return $code_name;
    } 

    return;
}


sub find_key {
    my ($self, $key) = @_;

    my ($alias) = $self->db_conn->run(fixup => sub {
        my $sth = $_->prepare(q[
            SELECT alias
            FROM codenames
            WHERE name = ?
        ]);
        $sth->execute($key);
        $sth->fetchrow_array;
    });

    return $alias;
}


sub store_key {
    my ($self, $key, $alias, $iscn) = @_;

    $self->db_conn->run(fixup => sub {
        $_->do(q[
            INSERT INTO codenames(name, alias, is_code_name)
            VALUES (?, ?, ?)
        ], undef, $key, $alias, $iscn);
    });
}


sub initialize { }

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Service::OFun::CodeName - Assign code names to words and phrases for fun and profit

=head1 VERSION

version 0.142230

=head1 SYNOPSIS

    # in your bot config
    service code_name => (
        service         => 'OFun::CodeName',
        nouns_file      => 'nouns.txt',
        adjectives_file => adjectives.txt',
        db_dsn          => 'dbi:SQLite:codename.db',
    );

    dispatcher chatroom => as {
        redispatch_to 'code_name';
    };

    # in chat
    alice> !codename bob
    bot> exploding chariot
    alice> !codename exploding chariot
    bot> bob

=head1 DESCRIPTION

Have you ever wanted to assign really horrible code names to your projects? Your
clients? Your coworkers? Well, now is your chance. Just put this little baby
into your bot config and let it assign code names to your heart's content.

To work, you must supply it with your own list of nouns and adjectives (not
included) and a database, which is used to store the code names that have been
assigned. The code names are assigned in a standard-ish way so they will be
reassigned the same way every time, so long as you continue using the same noun
and adjective list. The database is used to remember the code name's reversal
and also to keep the code names the same if you do choose to modify your word
lists for some reason (say to remove some NSFW word or to add an NSFW word you
forgot to add in the first place).

=head1 DISPATCHER

=head2 !codename

    !codename phrase
    !codename code name

This command is used to generate a new codename or to tell you what a code name
refers to. You don't need to quote your words or anything, just give it as short
or as long a phrase as you want named and it will respond.

=head1 ATTRIBUTES

=head2 adjectives_file

=head2 nouns_file

These are files that provide adjectives and nouns to the service. The words
should be listed one-per-line in the file with no blanks. Extra whitespace on
either side of each word will be trimmed.

=head2 adjectives

=head2 nouns

These are arrays of the loaded word lists.

=head1 METHODS

=head2 load_schema

Creates the C<codenames> file. It uses DDL SQL that should be compatible with
SQLite and MySQL databases.

=head2 assign_codename

This implements the C<!codename> command.

=head2 generate_code_name

  my $codename = $self->generate_code_name($phrase);

Given a string, it returns a new code name for that string.

=head2 find_key

  my $alias = $self->find_key($key);

Given a code name or a phrase that has been assigned a code name, it returns the
alias (i.e., the original phrase for code names and the code name assigned for
phrases). If that's not a stored alias, it returns undef.

=head2 store_key

  $self->find_key($key, $alias, $is_code_name);

Stores a key/alias pair. When a code name is generated, it will be stored twice,
once to point the code name to the phrase and once to point the phrase back to
the code name. The C<$is_code_name> flag is used to indicate whether the C<$key>
is a code name or a phrase in this call. This flag is not used for anything
right now, but might be used for something in the future and is used to at least
allow you to discern which is the code name and which is not.

=head2 initialize

No op.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
