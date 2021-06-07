package # hide from PAUSE
    CDTest;

use strict;
use warnings;

use CDTest::Schema;
use Class::Load       qw< is_class_loaded >;
use Env               qw< CDTEST_DSN CDTEST_MASS_POPULATE >;
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
        # Defaults
        no_connect  => 0,
        no_deploy   => 0,
        no_preclean => 0,
        no_populate => 0,
    );

    my $schema = CDTest->init_schema(
        mass_populate => 100,
    );

This method creates a new, empty, in-memory SQLite database and then creates a new, empty database.
If C<CDTEST_DSN>, C<CDTEST_DBUSER>, and C<CDTEST_DBPASS> are specified, it will use that database
instead.  Make sure the database doesn't have any useful data in it.

This method will call L</deploy_schema> by default, unless the C<no_deploy> flag is set.

It will also call L</clean_schema> by default, unless the C<no_preclean> flag is set, or the SQLite
in-memory DB is used (which is the default).

Also, by default, this method will call L</populate_schema>, unless the C<no_deploy> or
C<no_populate> flags are set.

If C<mass_populate> or C<CDTEST_MASS_POPULATE> is set, L</mass_populate_schema> will be called
instead, with the number of batches specified.

=cut

sub _database {
    my $self = shift;
    my %args = @_;

    # Delete CDTest options
    delete $args{$_} for qw< no_connect no_deploy no_preclean no_populate mass_populate >;

    if ($CDTEST_DSN) {
        return (
            (map { $ENV{"CDTEST_${_}"} || '' } qw/DSN DBUSER DBPASS/),
            { AutoCommit => 1, %args },
        );
    }

    return ("dbi:SQLite::memory:", '', '', {
        AutoCommit => 1,

        # SQLite needs FKs turned on after connect
        on_connect_do => sub {
            my $storage = shift;
            my $dbh = $storage->_get_dbh;

            $dbh->do('PRAGMA foreign_keys = ON');
        },
    });
}

sub init_schema {
    my $self = shift;
    my %args = @_;

    my @dbi_args = $self->_database(%args);

    $args{mass_populate} ||= $CDTEST_MASS_POPULATE if $CDTEST_MASS_POPULATE;

    my $schema = CDTest::Schema->compose_namespace('CDTest');

    unless ($args{no_connect}) {
        $schema = $schema->connect(@dbi_args);

        # Advertise the DBMS version
        if (is_class_loaded('Test2::Tools::Basic')) {
            my $dbh = $schema->storage->dbh;
            Test2::Tools::Basic::note($dbh->get_info(17)." version ".$dbh->get_info(18));  # SQL_DBMS_NAME+VER
        }
    }
    else {
        return $schema
    }

    unless ($args{no_preclean} || $dbi_args[0] =~ /^dbi:SQLite::memory:/) {  # :memory: needs no pre-cleanup
        $self->clean_schema( $schema );
    }
    unless ($args{no_deploy}) {
        $self->deploy_schema( $schema );
        unless ($args{no_populate}) {
            if ($args{mass_populate}) { $self->mass_populate_schema( $schema, $args{mass_populate} ) }
            else                      { $self->populate_schema( $schema ); }
        }
    }

    return $schema;
}

=head2 dbms_name

    my $dbms_name = CDTest->dbms_name;

Acquires the driver name without connecting to anything.

=cut

sub dbms_name {
    my $self = shift;

    if ($CDTEST_DSN && $CDTEST_DSN =~ /^dbi:(\w+)/) {
        my $driver = $1;
        my $drh = DBI->install_driver($driver);
        my $bare_dbh = DBI::_new_dbh($drh, {});

        return $bare_dbh->get_info(17);  # SQL_DBMS_NAME
    }
    else {
        return 'SQLite';
    }
}

=head2 deploy_schema

    CDTest->deploy_schema( $schema );

Deploys the C<sqlite.sql> schema into the SQLite DB.

=cut

sub deploy_schema {
    my $self   = shift;
    my $schema = shift;
    my $dbh    = $schema->storage->dbh;

    my $file = Path::Class::File->new(__FILE__)->dir->file('sqlite.sql');
    my $sql  = $file->slurp(iomode => '<:encoding(UTF-8)');

    # Clean the SQL to work with whatever RDBMS we're using
    my $dbms_name = $self->dbms_name;
    unless ($dbms_name eq 'SQLite') {
        $sql =~ s/\"(\w+)\"/$dbh->quote_identifier($1)/ge;
    }
    if ($dbms_name eq 'MySQL') {
        $sql =~ s/(PRIMARY KEY NOT NULL)/AUTO_INCREMENT $1/g;
    }

    $schema->multi_do($sql);
}

=head2 clean_schema

    CDTest->clean_schema( $schema );

Drops all of the tables in the schema.

=cut

sub clean_schema {
    my $self   = shift;
    my $schema = shift;
    my $dbh    = $schema->storage->dbh;

    my $dbms_name = $self->dbms_name;

    # Turn off FK constraints
    if    ($dbms_name eq 'SQLite') {
        $dbh->do('PRAGMA foreign_keys = OFF');
    }
    elsif ($dbms_name eq 'MySQL') {
        $dbh->do('SET SESSION foreign_key_checks=0');
    }

    foreach my $source_name (sort $schema->sources) {
        my $rsrc  = $schema->source($source_name);
        my $table = $rsrc->from;

        my $type = $rsrc->isa('DBIx::Class::ResultSource::View') ? 'VIEW' : 'TABLE';

        $dbh->do("DROP $type IF EXISTS ".$dbh->quote_identifier($table));
    }
}

=head2 populate_schema

    CDTest->populate_schema( $schema );

After you deploy your schema, you can use this method to populate the tables with test data.

=cut

sub populate_schema {
    my $self   = shift;
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
        [ qw/cdid artist title year prev_cdid genreid/ ],
        [ 1, 1, "Spoonful of bees", 1999, undef, 1 ],
        [ 2, 1, "Forkful of bees", 2001, 1 ],
        [ 3, 1, "Caterwaulin' Blues", 1997, 2 ],
        [ 4, 2, "Generic Manufactured Singles", 2001 ],
        [ 5, 3, "Come Be Depressed With Us", 1998 ],

        [ 9,  10, "Me and You", 2007, undef, 2 ],
        [ 10, 11, "Co-Founder", 2011, undef, 2 ],
        [ 11, 12, "Independence Park", 2001 ],
        [ 15, 12, "Flaming Dragon", 2007, 11 ],
        [ 16, 12, "Kent", 2014, 15 ],
        [ 17, 15, "42 Minutes of Silence", 2011 ],
        [ 19, 15, "Two", 2012, 17 ],
        [ 21, 15, "852", 2015, 19 ],
        [ 22, 17, "Glass Window Soundtrack", 2009 ],
        [ 24, 17, "Magenta", 2014, 22 ],
        [ 25, 17, "Yellow", 2014, 24 ],
        [ 30, 17, "Cyan", 2014, 25 ],
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
        [ 2, 2 ],
        [ 3, 2 ],
        [ 3, 3 ],
        [ 4, 1 ],
        map { [ $_, 4 ] } qw< 9 10 11 15 16 17 19 21 22 24 25 30 >,
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

=head2 mass_populate_schema

    CDTest->mass_populate_schema( $schema, $batches );

Populate the schema with massive amounts of data, mostly as duplicates of different rows.

The C<$batches> are measured in thousands of artists.  In other words, one batch is:

    1000   artists
    ~2500  CDs
    ~20000 tracks

Just 10 batches takes up quite a bit of space (around 100MB of memory in the SQLite in-memory DB),
and takes around 30 seconds to populate.

=cut

sub mass_populate_schema {
    my ($self, $schema, $batches) = @_;
    $batches ||= 10;

    for (1 .. $batches) {
        if (is_class_loaded('Test2::Tools::Basic')) {
            Test2::Tools::Basic::note("Mass populating data: $_,000 records");
        }

        # Create 1000 fake artists
        my $artist_rows = [ [ qw/name/ ] ];
        my $track_rows  = [ [ qw/cd position title/ ] ];

        for (1 .. 1000) {
            push @$artist_rows, [ $self->_random_words ];
        }
        my @artists = $schema->populate('Artist', $artist_rows);

        # Create a bunch of fake albums
        while (my $artist = shift @artists) {
            my $cd_rows = [ [ qw/artist title year/ ] ];
            for (1 .. int(rand 5)+1) {
                push @$cd_rows, [
                    $artist->artistid,
                    $self->_random_words,
                    1950 + int(rand(68)),
                ];
            }
            my @cds = $schema->populate('CD', $cd_rows);

            # Create a bunch of fake tracks
            while (my $cd = shift @cds) {
                for (1 .. int(rand 15)+1) {
                    push @$track_rows, [
                        $cd->cdid,
                        $_,
                        $self->_random_words,
                    ];
                }
            }
        }

        # Push these in one big batch (since we don't need the rows)
        $schema->populate('Track', $track_rows);
    }
}

my @letters        = map { chr } (97..122);
my @vowel_patterns = qw<
    e i a o u y io ia ou ie ea oo ee ai oi au eu ua ui ei oa eo ue iou oe ae iu ay eou yo ya
    yi ey ye uo oy uou eye aye ao aeo eau ii oya aya aa ayi ioi uie yu oye eei
>;
my @conson_patterns = qw<
    n r t s l c d m p v b g ng st nt ss f ll h nd pr z bl ph tr ns rs k nc w ch th ct sh x
    rm gr sc cr rt sm sp rr tt pl br rd ck q mp cl nn str pt dr rn rc mm j ps sl mb fl rg
    ngl rb lt rl pp nf ntr gl ff sn ls gn nr ts nv fr cc rp dl nch rv nl gg ld nm nk rch np
    nh sk rk rh dn wh rf ngs bb ntl ds dd tch nts nth ght ms lm ln chr scr sts
>;

sub _random_word {
    # Random word generator
    my $word = $letters[int rand @letters];
    return uc $word if rand() <= .01;

    while (rand >= .33 || length $word < 2) {
        $word .= $vowel_patterns [int rand @vowel_patterns ];
        $word .= $conson_patterns[int rand @conson_patterns];
        last if length $word > 20;
    }

    return ucfirst $word;
}

sub _random_words {
    my $self = shift;
    my @words = map { $self->_random_word } (1 .. int(rand 4)+1);
    my $words = join ' ', @words;
    $words .= ' '.$self->_random_word unless length $words > 20;
    return $words;
}

1;

