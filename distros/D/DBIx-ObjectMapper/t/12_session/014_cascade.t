use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;
use lib File::Spec->catfile($FindBin::Bin, 'lib');
use MyTest11;


MyTest11->setup_default_data;
MyTest11->mapping_with_foreign_key;

my $mapper = MyTest11->mapper;

subtest 'cascade_detach' => sub {
    my $session = $mapper->begin_session( autocommit => 0 );
    ok my $artist = $session->get( 'MyTest11::Artist' => 1 );
    for my $cd ( @{$artist->cds} ) {
        ok $cd;
        ok $cd->linernote;
        for my $track ( @{$cd->tracks} ) {
            ok $track;
        }
    }
    $session->detach($artist);
    ok $artist->__mapper__->is_detached, 'is_detached';

    for my $cd ( @{$artist->cds} ) {
        ok $cd->__mapper__->is_detached;
        ok $cd->linernote->__mapper__->is_detached;
        for my $track ( @{$cd->tracks} ) {
            ok $track->__mapper__->is_detached;
        }
    }

    done_testing;
};

subtest 'cascade_delete' => sub {
    my $session = $mapper->begin_session( autocommit => 0 );

    my $cd     = $mapper->metadata->t('cd');
    my $artist = $session->get( 'MyTest11::Artist' => 1 );
    $session->delete($artist);
    $session->flush;

    # check
    ok !$session->get( 'MyTest11::Artist' => 1 );
    is $session->search('MyTest11::Cd')->count, 0;

    is $session->search('MyTest11::Track')->count, 0;
    is $session->search('MyTest11::Linernote')->count, 0;

    done_testing;
};


subtest 'cascade_update' => sub {
    my $session = $mapper->begin_session;

    my $cd2 = $session->get( 'MyTest11::Cd' => 2 );
    my @cd2_tracks = @{$cd2->tracks};
    $cd2->id(100);
    $session->flush;
    is $cd2->__mapper__->status, 'expired';
    is $cd2->id, 100; # not reflesh

    # check
    my $check = $session->get( 'MyTest11::Cd' => 2 );
    ok !$check;
    ok my $cd100 = $session->get( 'MyTest11::Cd' => 100 );
    ok my @cd100_tracks = @{$cd100->tracks};
    ok @cd2_tracks == @cd100_tracks;
    for my $i ( 0 .. $#cd2_tracks ) {
        is $cd2_tracks[$i]->title, $cd100_tracks[$i]->title;
        is $cd2_tracks[$i]->track_no, $cd100_tracks[$i]->track_no;
    }

    done_testing;
};

subtest 'cascade_save' => sub {
    my $session = $mapper->begin_session( autocommit => 0 );
    ok my $jimi = MyTest11::Artist->new( name => 'Jimi Hendrix' );
    is_deeply $jimi->cds, [];
    $session->add($jimi);
    ok my $first_album = MyTest11::Cd->new( title => 'Are You Experienced' );
    push @{$jimi->cds}, $first_album;

    my @bulk_tracks = (
        'Purple Haze',
        'Manic Depression',
        'Hey Joe',
        'Love or Confusion',
        'May This Be Love',
        'I Don\'t Live Today',
        'Wind Cries Mary, The',
        'Fire',
        'Third Stone from the Sun',
        'Foxey Lady',
        'Are You Experienced?',
        'Stone Free',
        '51st Anniversary',
        'Highway Chile',
        'Can You See Me',
        'Remember',
        'Red House'
    );

    my @tracks;
    for ( 0 .. $#bulk_tracks ) {
        push @tracks, MyTest11::Track->new(
            track_no => $_ + 1,
            title    => $bulk_tracks[$_]
        );
    }
    $first_album->tracks(\@tracks);
    $session->commit;

    # check
    ok my $check_artist = $session->get( 'MyTest11::Artist' => $jimi->id );
    ok my $check_cd = $check_artist->cds->[0];
    ok my $check_tracks = $check_cd->tracks;

    for my $i ( 0 .. $#tracks) {
        isnt $tracks[$i], $check_tracks->[$i];
        is $tracks[$i]->title, $check_tracks->[$i]->title;
        is $tracks[$i]->track_no, $check_tracks->[$i]->track_no;
    }

    done_testing;
};

done_testing;

