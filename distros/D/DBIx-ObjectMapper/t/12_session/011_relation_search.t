use strict;
use warnings;
use Test::More;
use Test::Exception;
use Capture::Tiny;
use File::Spec;
use FindBin;
use lib File::Spec->catfile($FindBin::Bin, 'lib');
use MyTest11;

MyTest11->setup_default_data;
MyTest11->mapping_with_foreign_key;

my $mapper = MyTest11->mapper;

{ # has_many/has_one
    my $session = $mapper->begin_session;
    my $artist = $mapper->attribute('MyTest11::Artist');
    my $it = $session->search('MyTest11::Artist')
        ->filter(
            $artist->p('cds.title')->like('Led Zeppelin%')
        )->order_by($artist->p('cds.id'))->execute;

    ok $it;
    my $loop_cnt = 0;
    while( my $a = $it->next ) {
        $loop_cnt++;
        is $a->id, 1;
        is $a->name, 'Led Zeppelin';
        is ref($a->cds), 'ARRAY';
        for my $cd ( @{$a->cds} ) {
            ok $cd->id;
            ok $cd->linernote;
            ok $cd->linernote->id;
        }
    }
    is $loop_cnt, 1;
};


{ # belongs_to
    my $session = $mapper->begin_session;
    my $cd = $mapper->attribute('MyTest11::Cd');
    my $it = $session->search('MyTest11::Cd')
        ->filter(
            $cd->property('artist.name') == 'Led Zeppelin',
            $cd->prop('title')->like('Led Zeppelin%')
        )->execute;
    ok $it;
    my $loop_cnt = 0;
    while( my $a = $it->next ) {
        $loop_cnt++;
    }
    is $loop_cnt, 4;
};

{ # belongs_to eagerload
    my $session = $mapper->begin_session;
    my $cd = $mapper->attribute('MyTest11::Cd');
    my $it = $session->search( 'MyTest11::Cd')
     ->eager( $cd->p('artist') )
     ->filter( $cd->p('title') == 'Led Zeppelin' )->execute;
    ok $it;
    while( my $a = $it->next ) {

    }
};

{ # eargerload
    my $session = $mapper->begin_session;
    my $artist = $mapper->attribute('MyTest11::Artist');
    my $it = $session->search('MyTest11::Artist')
     ->eager($artist->p('cds'))
     ->filter( $artist->p('cds.title')->like('Led Zeppelin%') )
     ->order_by( $artist->p('cds.id')->desc )
     ->execute;
    ok $it;
    my $loop_cnt = 0;
    my $cd_id = 4;
    while( my $a = $it->next ) {
        $loop_cnt++;
        is $a->id, 1;
        is $a->name, 'Led Zeppelin';
        for my $cd ( @{$a->cds} ) {
            is $cd->id, $cd_id--;
        }
    }
    is $loop_cnt, 1;
    is $it->size, 1;
};

{ # eagerload2
    my $session = $mapper->begin_session;
    my $artist = $mapper->attribute('MyTest11::Artist');

    my $it = $session->search('MyTest11::Artist')
     ->eager(
         $artist->p('cds'),
         $artist->p('cds.linernote'),
         $artist->p('cds.tracks'),
     )
     ->filter( $artist->p('cds.title')->like('Led Zeppelin%') )
     ->order_by( $artist->p('cds.id')->desc )
     ->execute;
    ok $it;
    my $loop_cnt = 0;
    my $cd_id = 4;
    while( my $a = $it->next ) {
        $loop_cnt++;
        is $a->id, 1;
        is $a->name, 'Led Zeppelin';
        for my $cd ( @{$a->cds} ) {
            is $cd->id, $cd_id--;
        }
    }
    is $loop_cnt, 1;
    is $it->size, 1;
};

{ # eager_join and first,count
    my $session = $mapper->begin_session;
    my $artist = $mapper->attribute('MyTest11::Artist');

    my $query = $session->search('MyTest11::Artist')
     ->eager( $artist->p('cds') )
     ->filter( $artist->p('cds.title')->like('Led Zeppelin%') )
     ->order_by( $artist->p('cds.id')->desc );

    ok my $a = $query->first;

    is $a->name, 'Led Zeppelin';
    is @{$a->cds}, 4;
};

{ # using the eager_join method with the limit method warning.
    my $session = $mapper->begin_session;
    my $artist = $mapper->attribute('MyTest11::Artist');

    my $query = $session->search('MyTest11::Artist')
     ->eager( $artist->p('cds') )
     ->filter( $artist->p('cds.title')->like('Led Zeppelin%') )
     ->order_by( $artist->p('cds.id')->desc )->limit(2);

    my $it;
    my ( $stdout, $stderr ) = Capture::Tiny::capture {
        $it = $query->execute;
    };
    ok $stderr =~ /the limit method is used with the eager_join method/;

    ok my $a = $it->next;
    is $a->name, 'Led Zeppelin';
    is @{$a->cds}, 2;
};

{ # has_many is one record
    my $session = $mapper->begin_session;
    my $artist = $mapper->attribute('MyTest11::Artist');

    my $it = $session->search(
        'MyTest11::Artist',
     )
     ->eager($artist->p('cds'))
     ->filter( $artist->p('cds.id') == 1 )
     ->execute;

    my $loop_cnt = 0;
    while( my $artist = $it->next ) {
        is ref($artist->cds), 'ARRAY';
        is scalar(@{$artist->cds}), 1;
        $loop_cnt++;
    }
    is $loop_cnt, 1;
};

{ # nest join
    my $session = $mapper->begin_session;
    my $attr = $mapper->attribute('MyTest11::Artist');

    my $it = $session->search('MyTest11::Artist')
    ->filter(
        $attr->p('cds.title')->like('Led Zeppelin%'),
        $attr->p('cds.tracks.track_no') > 8,
    )->execute;

    my $loop_cnt = 0;
    while( my $a = $it->next ) {
        $loop_cnt++;
        is $a->id, 1;
        is $a->name, 'Led Zeppelin';
    }

    is $loop_cnt, 1;
};

{ # nest join 2
    my $session = $mapper->begin_session;
    my $attr = $mapper->attribute('MyTest11::Artist');

    my $it = $session->search('MyTest11::Artist')
    ->filter(
        {
            OR => [
                $attr->p('cds.title')->like('Led Zeppelin%'),
                $attr->p('id') == 1,
            ]
        },
        $attr->p('cds.tracks.track_no') > 8,
    )->execute;

    my $loop_cnt = 0;
    while( my $a = $it->next ) {
        $loop_cnt++;
        is $a->id, 1;
        is $a->name, 'Led Zeppelin';
    }

    is $loop_cnt, 1;
};

{ # nest join eagerload
    my $session = $mapper->begin_session;
    my $attr = $mapper->attribute('MyTest11::Artist');

    my $it
        = $session->search( 'MyTest11::Artist' )
        ->eager( $attr->p('cds'), $attr->p('cds.tracks') )
        ->filter(
            $attr->p('cds.title')->like('Led Zeppelin%'),
            $attr->p('cds.tracks.track_no') > 8,
        )->execute;
    my $loop_cnt = 0;
    while( my $a = $it->next ) {
        $loop_cnt++;
        is $a->id, 1;
        is $a->name, 'Led Zeppelin';
        ok $a->cds;
        ok $a->cds->[0]->tracks;
        ok $a->cds->[0]->tracks->[0]->track_no > 8;
    }

    is $loop_cnt, 1;
    is $session->uow->query_cnt, 1;
};

{ # nested get
    my $session = $mapper->begin_session;
    my $a = $session->get( 'MyTest11::Artist' => 1 );
    is $a->name, 'Led Zeppelin';
    is $a->id, 1;

    is ref($a->cds), 'ARRAY';
    my $cd_id = 1;
    for my $cd ( @{$a->cds} ) {
        is $cd->id, $cd_id++;
    }
    is $cd_id, 11;

    my $cd2 = $a->cds->[1];
    is $cd2->id, 2;
    is $cd2->title, 'Led Zeppelin II';
    is ref($cd2->tracks), 'ARRAY';
    my $track_no = 1;
    for my $track ( @{$cd2->tracks} ) {
        is $track->track_no, $track_no++;
    }
    is $track_no, 10;
};

{ # get with eargerload
    my $session = $mapper->begin_session;
    my $cd = $session->get( 'MyTest11::Cd' => 1, { eagerload => 'artist' } );
    is $cd->artist->name, 'Led Zeppelin';
    is $cd->artist->id, 1;
    is $session->uow->query_cnt, 1;
};

{ # get with eargerload2
    my $session = $mapper->begin_session;
    my $cd = $session->get(
        'MyTest11::Cd' => 1,
        { eagerload => ['artist', 'linernote'] }
    );
    is $cd->artist->name, 'Led Zeppelin';
    is $cd->artist->id, 1;
    ok $cd->linernote;
    ok $cd->linernote->id;
    is $session->uow->query_cnt, 1;
};

{ # egear and join
    my $session = $mapper->begin_session;
    my $attr = $mapper->attribute('MyTest11::Cd');

    my $it = $session->search('MyTest11::Cd')->eager($attr->p('linernote'))
        ->filter( $attr->p('tracks.track_no') > 9 )->execute;
    my $loop_cnt = 0;
    while( my $cd = $it->next ) {
        ok $cd->id;
        ok $cd->linernote;
        ok $cd->linernote->id;
        ok $cd->tracks;
        is ref($cd->tracks), 'ARRAY';
        $loop_cnt++;
    }
    is $session->uow->query_cnt, 1 + $loop_cnt; # tracks is lazyload
};

{ # egear and join2
    my $session = $mapper->begin_session;
    my $attr = $mapper->attribute('MyTest11::Cd');

    my $it = $session->search('MyTest11::Cd')->eager($attr->p('tracks'))
        #->filter( $attr->p('linernote.note')->func('length') > 0 )
        ->execute;
    my $loop_cnt = 0;
    while( my $cd = $it->next ) {
        ok $cd->id;
        ok $cd->linernote;
        ok $cd->linernote->id;
        ok $cd->tracks;
        is ref($cd->tracks), 'ARRAY';
        $loop_cnt++;
    }
    ok $loop_cnt;
    is $session->uow->query_cnt, $loop_cnt + 1;
};


{ # errors
    my $session = $mapper->begin_session;

    my $attr = $mapper->attribute('MyTest11::Artist');

    eval {
        $session->search('MyTest11::Artist')
           ->eager($attr->p('linernote'))
            ->execute;
    };
    ok $@ =~ /linernote does not exists/;

    eval {
        $attr->p('cds.hogefuga');
    };

    ok $@ =~ /hogefuga does not exists/;


    eval {
        $session->search('MyTest11::Artist')->eager($attr->p('cds'))->page(1);
    };
    ok $@ =~ /the page method is not suppurted/;
};

{ # has_many modify
    my $session = $mapper->begin_session;
    my $artist = $session->get( 'MyTest11::Artist' => 1 );
    ok $artist->cds;
    is scalar(@{$artist->cds}), 10;
    my $cd1 = shift(@{$artist->cds});
    is scalar(@{$artist->cds}), 9;
    is $cd1->__mapper__->status, 'persistent';
    # deleted $cd1
};

{ # check
    my $session = $mapper->begin_session;
    my $artist = $session->get( 'MyTest11::Artist' => 1 );
    is scalar(@{$artist->cds}), 9;
};

{ # add
    my $session = $mapper->begin_session;
    my $artist = $session->get( 'MyTest11::Artist' => 1 );
    my $new_cd = MyTest11::Cd->new(
        id => 11,
        artist_id => $artist->id,
        title => 'Led Zeppelin',
    );
    unshift(@{$artist->cds}, $new_cd);
};

{ # check
    my $session = $mapper->begin_session;
    my $artist = $session->get( 'MyTest11::Artist' => 1 );
    is scalar(@{$artist->cds}), 10;
};

done_testing;
__END__
