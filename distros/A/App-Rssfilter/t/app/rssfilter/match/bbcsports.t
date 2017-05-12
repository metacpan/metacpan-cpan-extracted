use Test::Most;

use App::Rssfilter::Match::BbcSports;
use Mojo::DOM;

throws_ok(
    sub { App::Rssfilter::Match::BbcSports::match },
    qr/missing required argument/,
    'throws error when not given an item to match'
);

throws_ok(
    sub { App::Rssfilter::Match::BbcSports::match( qw( one two ) ) },
    qr/too many arguments/,
    'throws error when given more than one argument'
);

ok(
    App::Rssfilter::Match::BbcSports::match( Mojo::DOM->new( '<guid>www.bbc.co.uk/sport/<\guid>' ) ),
    'match item whose guid contains the BBC sport URL'
);

ok(
    App::Rssfilter::Match::BbcSports::match( Mojo::DOM->new( '<guid>www.bbc.co.uk/sport1/<\guid>' ) ),
    'match item whose guid contains the variant BBC sport URL'
);

ok(
    ! App::Rssfilter::Match::BbcSports::match( Mojo::DOM->new( '<guid>www.bbc.co.uk/science<\guid>' ) ),
    'does not match item whose guid does not contains the BBC sport URL'
);

ok(
    ! App::Rssfilter::Match::BbcSports::match( Mojo::DOM->new( '<guid>espn.com/sport<\guid>' ) ),
    'does not match item whose guid does not contain a BBC URL'
);

done_testing;
