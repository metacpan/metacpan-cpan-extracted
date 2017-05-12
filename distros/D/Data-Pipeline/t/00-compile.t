use Test::More;

BEGIN {
    my %modules;
    eval { require Text::CSV; $modules{CSV}++ };
    eval { require LWP; $modules{FetchPage}++ };
    eval { require JSON; $modules{JSON}++ };
    eval { require XML::RAI; $modules{RSS}++ };
    eval { require RDF::Query; require URI; $modules{SPARQL}++ };

    plan tests => 23 + scalar(keys %modules);

    use_ok( 'Data::Pipeline' );
    use_ok( 'Data::Pipeline::Types' );
    use_ok( 'Data::Pipeline::Action' );
    use_ok( 'Data::Pipeline::Adapter' );
    use_ok( 'Data::Pipeline::Iterator' );
    use_ok( 'Data::Pipeline::Iterator::Source' );
    use_ok( 'Data::Pipeline::Iterator::Output' );
    use_ok( 'Data::Pipeline::Aggregator::Pipeline' );
    use_ok( 'Data::Pipeline::Aggregator::Union' );
    use_ok( 'Data::Pipeline::Adapter::Array' );
    use_ok( 'Data::Pipeline::Adapter::CSV' ) if $modules{CSV};
    use_ok( 'Data::Pipeline::Adapter::FetchPage' ) if $modules{FetchPage};
    use_ok( 'Data::Pipeline::Adapter::JSON' ) if $modules{JSON};
    use_ok( 'Data::Pipeline::Adapter::RSS' ) if $modules{RSS};
    use_ok( 'Data::Pipeline::Adapter::SPARQL' ) if $modules{SPARQL};
    use_ok( 'Data::Pipeline::Adapter::StringBuilder' );
    use_ok( 'Data::Pipeline::Adapter::UrlBuilder' );
    use_ok( 'Data::Pipeline::Action::Count' );
    use_ok( 'Data::Pipeline::Action::ExcludeFields' );
    use_ok( 'Data::Pipeline::Action::Filter' );
    use_ok( 'Data::Pipeline::Action::ForEach' );
    use_ok( 'Data::Pipeline::Action::Identity' );
    use_ok( 'Data::Pipeline::Action::Regex' );
    use_ok( 'Data::Pipeline::Action::Rename' );
    use_ok( 'Data::Pipeline::Action::StringReplace' );
    use_ok( 'Data::Pipeline::Action::Tail' );
    use_ok( 'Data::Pipeline::Action::Truncate' );
    use_ok( 'Data::Pipeline::Action::Unique' );
}
