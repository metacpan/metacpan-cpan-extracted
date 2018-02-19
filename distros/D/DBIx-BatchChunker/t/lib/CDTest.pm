package # hide from PAUSE
    CDTest;

use strict;
use warnings;

use CDTest::Schema;
use Path::Class::File ();

=head1 NAME

CDTest - Small-scale DBIC test module

=head1 SYNOPSIS

    use lib qw(t/lib);
    use CDTest;
    use Test2::Bundle::More;

    my $schema = CDTest->init_schema;

=head1 DESCRIPTION

This module provides a test DBIC schema in a real SQLite DB.  Much of this was stolen and
stripped down from DBICTest in DBIC's test platform.

=head1 METHODS

=head2 init_schema

    my $schema = CDTest->init_schema(
        no_connect  => 1,
        no_deploy   => 1,
        no_populate => 1,
    );

This method creates a new, empty, in-memory SQLite database and then creates a new, empty database.

This method will call L</deploy_schema> by default, unless the C<no_deploy> flag is set.

Also, by default, this method will call L</populate_schema> by default, unless the C<no_deploy> or
C<no_populate> flags are set.

=cut

sub _database {
    my $self = shift;

    return ("dbi:SQLite::memory:", '', '', {
        AutoCommit => 1,
    });
}

sub init_schema {
    my $self = shift;
    my %args = @_;

    my $schema = CDTest::Schema->compose_namespace('CDTest');

    unless ($args{no_connect}) {
        $schema = $schema->connect($self->_database);
    }

    unless ($args{no_deploy}) {
        $self->deploy_schema( $schema );
        $self->populate_schema( $schema ) unless $args{no_populate};
    }

    return $schema;
}

=head2 deploy_schema

    CDTest->deploy_schema( $schema );

Deploys the C<sqlite.sql> schema into the SQLite DB.

=cut

sub deploy_schema {
    my $self = shift;
    my $schema = shift;

    my $file = Path::Class::File->new(__FILE__)->dir->file('sqlite.sql');
    my $sql  = $file->slurp(iomode => '<:encoding(UTF-8)');

    $schema->multi_do($sql);
}

=head2 populate_schema

    CDTest->populate_schema( $schema );

After you deploy your schema, you can use this method to populate the tables with test data.

=cut

sub populate_schema {
    my $self = shift;
    my $schema = shift;

    $schema->populate('Genre', [
        [qw/genreid name/],
        [qw/1       emo /],
        [qw/2       downtempo /],
        [qw/3       soundtrack /],
    ]);

    $schema->populate('Artist', [
        [ qw/artistid name/ ],
        [ 1, 'Caterwauler McCrae' ],
        [ 2, 'Random Boy Band' ],
        [ 3, 'We Are Goth' ],
        # These gaps are intentional
        [ 10, 'Torroni' ],
        [ 11, 'The yy'  ],
        [ 12, 'Kent'    ],
        [ 15, 'A582'    ],
        [ 17, 'Lunar Eclipse' ],
    ]);

    $schema->populate('CD', [
        [ qw/cdid artist title year genreid/ ],
        [ 1, 1, "Spoonful of bees", 1999, 1 ],
        [ 2, 1, "Forkful of bees", 2001 ],
        [ 3, 1, "Caterwaulin' Blues", 1997 ],
        [ 4, 2, "Generic Manufactured Singles", 2001 ],
        [ 5, 3, "Come Be Depressed With Us", 1998 ],

        [ 9,  10, "Me and You", 2007, 2 ],
        [ 10, 11, "Co-Founder", 2011, 2 ],
        [ 11, 12, "Independence Park", 2001 ],
        [ 15, 12, "Flaming Dragon", 2007 ],
        [ 16, 12, "Kent", 2014 ],
        [ 17, 15, "42 Minutes of Silence", 2011 ],
        [ 19, 15, "Two", 2012 ],
        [ 21, 15, "852", 2015 ],
        [ 22, 17, "Glass Window Soundtrack", 2009 ],
        [ 24, 17, "Magenta", 2014 ],
        [ 25, 17, "Yellow", 2014 ],
        [ 30, 17, "Cyan", 2014 ],
    ]);

    $schema->populate('Tag', [
        [ qw/tagid cd tag/ ],
        [ 1, 1, "Blue" ],
        [ 2, 2, "Blue" ],
        [ 3, 3, "Blue" ],
        [ 4, 5, "Blue" ],
        [ 5, 2, "Cheesy" ],
        [ 6, 4, "Cheesy" ],
        [ 7, 5, "Cheesy" ],
        [ 8, 2, "Shiny" ],
        [ 9, 4, "Shiny" ],
    ]);

    $schema->populate('Producer', [
        [ qw/producerid name/ ],
        [ 1, 'Matt S Trout' ],
        [ 2, 'Bob The Builder' ],
        [ 3, 'Fred The Phenotype' ],
        [ 4, 'Various' ],
    ]);

    $schema->populate('CDToProducer', [
        [ qw/cd producer/ ],
        [ 1, 1 ],
        [ 1, 2 ],
        [ 1, 3 ],
    ]);

    $schema->populate('Track', [
        [ qw/trackid cd  position title/ ],
        [ 4, 2, 1, "Stung with Success"],
        [ 5, 2, 2, "Stripy"],
        [ 6, 2, 3, "Sticky Honey"],
        [ 7, 3, 1, "Yowlin"],
        [ 8, 3, 2, "Howlin"],
        [ 9, 3, 3, "Fowlin"],
        [ 10, 4, 1, "Boring Name"],
        [ 11, 4, 2, "Boring Song"],
        [ 12, 4, 3, "No More Ideas"],
        [ 13, 5, 1, "Sad"],
        [ 14, 5, 2, "Under The Weather"],
        [ 15, 5, 3, "Suicidal"],
        [ 16, 1, 1, "The Bees Knees"],
        [ 17, 1, 2, "Apiary"],
        [ 18, 1, 3, "Beehind You"],

        [ 20, 9, 1, "Diamond Circus"],
        [ 21, 9, 2, "We're Crazy"],
        [ 22, 9, 3, "First Heart"],
        [ 23, 10, 1, "World Of Old"],
        [ 24, 10, 2, "Story Of More"],
        [ 26, 10, 3, "Home Secrets"],
        [ 27, 10, 4, "Matter Of Right Now"],
        [ 28, 11, 1, "Dance Tales"],
        [ 29, 11, 2, "She Hopes We Like To Party"],
        [ 30, 11, 3, "Stop Rhythm"],
        [ 32, 15, 1, "Story Of My Party"],
        [ 33, 15, 2, "Finding Her Fire"],
        [ 34, 16, 1, "Crispy Dreams"],
        [ 35, 16, 2, "Kent"],
        [ 36, 16, 3, "Superman"],
        [ 38, 17, 1, "42 Minutes of Silence"],
        [ 40, 19, 1, "Surface Tension"],
        [ 44, 19, 2, "This Could Totally Work"],
        [ 45, 19, 3, "Off-By-One Errors"],
        [ 46, 19, 4, "Two"],
        [ 47, 21, 1, "Enemy"],
        [ 48, 21, 2, "Gamma"],
        [ 50, 21, 3, "258"],
        [ 55, 21, 4, "Genetic Macroeconomics"],
        [ 56, 22, 1, "That One Spot in the Game"],
        [ 57, 22, 2, "Leitmotif"],
        [ 58, 22, 3, "The Part Where He Kills You"],
        [ 59, 24, 1, "Magenta"],
        [ 65, 25, 1, "Yellow"],
        [ 70, 30, 1, "Cyan"],
    ]);
}

1;

