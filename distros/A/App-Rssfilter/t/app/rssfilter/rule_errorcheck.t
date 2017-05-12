use strict;
use warnings;

use Test::Most;
use App::Rssfilter::Rule;
use List::MoreUtils;
use Mojo::DOM;

{
    package Test::NoMatch;
    sub finder {
        my( $item ) = @_;
        return 1;
    }
}

{
    package Test::NoFilter;
    sub exclude {
        my( $item, $finder_name ) = @_;
        $item->description->replace_content( "Found by $finder_name" );
    }
}

throws_ok {
    App::Rssfilter::Rule->new(
        condition => 'Test::NoMatch',
        action    => sub {},
    );
} qr/Test::NoMatch::match does not exist/,
'condition attr must specify a namespace with a match sub';

throws_ok {
    App::Rssfilter::Rule->new(
        condition => sub {},
        action    => 'Test::NoFilter'
    );
} qr/Test::NoFilter::filter does not exist/,
'action attr must specify a namespace with a filter sub';

{
    package Test::NoMatch::OO;

    sub new {
        return bless \do { my $anon }, $_[0] ;
    }

    sub finder {
        my( $self, $item ) = @_;
        return 1;
    }
}

{
    package Test::NoFilter::OO;
    sub new {
        return bless \do { my $anon }, $_[0] ;
    }

    sub exclude {
        my( $self, $item, $finder_name ) = @_;
        $item->description->replace_content( "Found by $finder_name" );
    }
}

throws_ok {
    App::Rssfilter::Rule->new(
        condition => 'Test::NoMatch::OO',
        action    => sub {},
    );
} qr/Test::NoMatch::OO::match does not exist/,
'condition attr must specify an OO namespace with a match method';

throws_ok {
    App::Rssfilter::Rule->new(
        condition => Test::NoMatch::OO->new(),
        action    => sub {},
    );
} qr/Test::NoMatch::OO::match does not exist/,
'condition attr must specify an OO instance with a match method';

throws_ok {
    App::Rssfilter::Rule->new(
        condition => sub {},
        action    => 'Test::NoFilter::OO',
    );
} qr/Test::NoFilter::OO::filter does not exist/,
'action attr must specify an OO namespace with a filter method';

throws_ok {
    App::Rssfilter::Rule->new(
        condition => sub {},
        action    => Test::NoFilter::OO->new(),
    );
} qr/Test::NoFilter::OO::filter does not exist/,
'action attr must specify an OO instance with a filter method';


done_testing;
