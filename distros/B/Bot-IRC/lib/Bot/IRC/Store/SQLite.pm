package Bot::IRC::Store::SQLite;
# ABSTRACT: Bot::IRC persistent data storage with SQLite

use 5.012;
use strict;
use warnings;

use DBI;
use DBD::SQLite;
use JSON::XS;
use Try::Tiny;

our $VERSION = '1.24'; # VERSION

sub init {
    my ($bot) = @_;
    my $obj = __PACKAGE__->new($bot);

    $bot->subs( 'store' => sub { return $obj } );
    $bot->register('Bot::IRC::Store');
}

sub new {
    my ( $class, $bot ) = @_;
    my $self = bless( {}, $class );

    $self->{file} = $bot->vars('store') || 'store.sqlite';
    my $pre_exists = ( -f $self->{file} ) ? 1 : 0;

    $self->{dbh} = DBI->connect( 'dbi:SQLite:dbname=' . $self->{file} ) or die "$@\n";

    $self->{dbh}->do(q{
        CREATE TABLE IF NOT EXISTS bot_store (
            id INTEGER PRIMARY KEY ASC,
            namespace TEXT,
            key TEXT,
            value TEXT
        )
    }) unless ($pre_exists);

    $self->{json} = JSON::XS->new->ascii;

    return $self;
}

sub get {
    my ( $self, $key ) = @_;
    my $namespace = ( caller() )[0];
    my $value;

    try {
        my $sth = $self->{dbh}->prepare_cached(q{
            SELECT value FROM bot_store WHERE namespace = ? AND key = ?
        });
        $sth->execute( $namespace, $key ) or die $self->{dbh}->errstr;
        $value = $sth->fetchrow_array;
        $sth->finish;
    }
    catch {
        warn "Store get error with $namespace (likely an IRC::Store::SQLite issue); key = $key; error = $_\n";
    };

    if ($value) {
        $value = $self->{json}->decode($value) || undef;
        $value = $value->{value} if ( ref $value eq 'HASH' and exists $value->{value} );
    }

    return $value;
}

sub set {
    my ( $self, $key, $value ) = @_;
    my $namespace = ( caller() )[0];

    try {
        $self->{dbh}->prepare_cached(q{
            DELETE FROM bot_store WHERE namespace = ? AND key = ?
        })->execute( $namespace, $key ) or die $self->{dbh}->errstr;

        $self->{dbh}->prepare_cached(q{
            INSERT INTO bot_store ( namespace, key, value ) VALUES ( ?, ?, ? )
        })->execute(
            $namespace,
            $key,
            $self->{json}->encode( { value => $value } ),
        ) or die $self->{dbh}->errstr;
    }
    catch {
        warn "Store set error with $namespace (likely an IRC::Store::SQLite issue); key = $key; error = $_\n";
    };

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::IRC::Store::SQLite - Bot::IRC persistent data storage with SQLite

=head1 VERSION

version 1.24

=head1 SYNOPSIS

    use Bot::IRC;

    Bot::IRC->new(
        connect => { server => 'irc.perl.org' },
        plugins => ['Store::SQLite'],
        vars    => { store => 'bot.sqlite' },
    )->run;

=head1 DESCRIPTION

This L<Bot::IRC> plugin provides a persistent storage mechanism with a SQLite
database file. By default, it's the "store.sqlite" file, but this can be changed
with the C<vars>, C<store> value.

=head1 EXAMPLE USE

This plugin adds a single sub to the bot object called C<store()>. Calling it
will return a storage object which itself provides C<get()> and C<set()>
methods. These operate just like you would expect.

=head2 set

    $bot->store->set( user => { nick => 'gryphon', score => 42 } );

=head2 get

    my $score = $bot->store->set('user')->{score};

=head2 SEE ALSO

L<Bot::IRC>

=for Pod::Coverage init new

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
