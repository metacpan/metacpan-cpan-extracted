use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Store::OpenSearch::CQL';
    use_ok($pkg);
}

{
  my $cql = $pkg->new(mapping => +{}, id_key => 'biblio_id');
  is_deeply($cql->parse('cql.allRecords'), +{match_all => {}});
  is_deeply($cql->parse('srw.allRecords'), +{match_all => {}});
}

# default_index
{
  my $cql_mapping = +{};
  my $cql = $pkg->new(mapping => $cql_mapping, id_key => 'biblio_id');
  is_deeply($cql->parse('hello'), {match => {_all => {query => 'hello'}}});
}

{
  my $cql_mapping = +{default_index => 'all'};
  my $cql = $pkg->new(mapping => $cql_mapping, id_key => 'biblio_id');
  is_deeply($cql->parse('hello'), {match => {all => {query => 'hello'}}});
  is_deeply($cql->parse('"hello there"'), {match_phrase => {all => {query => 'hello there'}}});
}

# default_relation
{
  my $cql_mapping = +{
    default_index => 'title',
    indexes => {
      title => {
        op => {
          '=' => 1,
        }
      }
    }
  };
  my $cql = $pkg->new(mapping => $cql_mapping, id_key => 'biblio_id');
  is_deeply($cql->parse('hello'), {match => {title => {query => 'hello'}}});
}

{
  my $cql_mapping = +{
    default_index => 'title',
    indexes => {
      title => {
        op => {
          '=' => 1,
        }
      }
    }
  };
  my $cql = $pkg->new(mapping => $cql_mapping, id_key => 'biblio_id');
  throws_ok(sub {$cql->parse('title exact hello');}, qr/cql error: relation exact not allowed/);
}

{
  my $cql_mapping = +{
    indexes => {}
  };
  my $cql = $pkg->new(mapping => $cql_mapping, id_key => 'biblio_id');
  throws_ok(sub {$cql->parse('title exact hello');}, qr/cql error: unknown index title/);
}

{
  my $cql_mapping = +{
    default_index => 'title',
    default_relation => 'exact',
    indexes => {
      title => {
        op => {
          'exact' => 1,
        }
      }
    }
  };
  my $cql = $pkg->new(mapping => $cql_mapping, id_key => 'biblio_id');
  is_deeply($cql->parse('hello'), {match_phrase => {title => {query => 'hello'}}});
}

{
  my $cql_mapping = +{
    indexes       => {
      _all => {
        op => {
          '='   => 1,
        }
      },
    }
  };
  my $cql = $pkg->new(mapping => $cql_mapping, id_key => 'biblio_id');
  is_deeply($cql->parse('hello'), +{match => {_all => {query => 'hello'}}});
}

{
  my $cql_mapping = +{
    indexes       => {
      title => {
        op => {
          'any'   => 1,
          'all'   => 1,
          '='     => 1,
          '<>'    => 1,
          'exact' => {field => 'title.exact'},
        }
      },
    }
  };
  my $cql = $pkg->new(mapping => $cql_mapping, id_key => 'biblio_id');
  is_deeply($cql->parse('title any hello'), +{
    bool => {
      should => [
        {match => {title => {query => 'hello'}}}
      ]
    }
  });
  is_deeply($cql->parse('title any "hello there"'), +{
    bool => {
      should => [
        {match => {title => {query => 'hello'}}},
        {match => {title => {query => 'there'}}},
      ]
    }
  });
  is_deeply($cql->parse('title = hello or title = there'), +{
    bool => {
      should => [
        {match => {title => {query => 'hello'}}},
        {match => {title => {query => 'there'}}},
      ]
    }
  });
  is_deeply($cql->parse('title all "hello there"'), +{
    bool => {
      must => [
        {match => {title => {query => 'hello'}}},
        {match => {title => {query => 'there'}}},
      ]
    }
  });
  is_deeply($cql->parse('title = hello and title = there'), +{
    bool => {
      must => [
        {match => {title => {query => 'hello'}}},
        {match => {title => {query => 'there'}}},
      ]
    }
  });
  is_deeply($cql->parse('title = hello'), +{
    match => {title => {query => 'hello'}}
  });
  is_deeply($cql->parse('title = "hello there"'), +{
    match_phrase => {title => {query => 'hello there'}}
  });
  is_deeply($cql->parse('title exact "hello there"'), +{
    match_phrase => {'title.exact' => {query => 'hello there'}}
  });
}

# ranges
{
  my $cql_mapping = {
    indexes => {
      year => {
        op => {
          '>' => 1,
          '<' => 1,
          '>='=> 1,
          '<='=> 1,
        }
      }
    }
  };
  my $cql = $pkg->new(mapping => $cql_mapping, id_key => 'biblio_id');
  is_deeply($cql->parse('year > 2024'), {range => {year => {gt => '2024'}}});
  is_deeply($cql->parse('year < 2024'), {range => {year => {lt => '2024'}}});
  is_deeply($cql->parse('year <= 2024'), {range => {year => {lte => '2024'}}});
  is_deeply($cql->parse('year >= 2024'), {range => {year => {gte => '2024'}}});
}

# fuziness
{
  my $cql_mapping = {
    indexes => {
      title => {
        op => {
          '=' => 1, # '=/fuzzy' is allowed by '='
        }
      }
    }
  };
  my $cql = $pkg->new(mapping => $cql_mapping, id_key => 'biblio_id');
  is_deeply($cql->parse('title =/fuzzy helo'), {fuzzy => {title => {value => 'helo', max_expansions => 10}}});
}

# wildcards
{
  my $cql_mapping = {
    default_index => 'title',
    indexes => {
      title => {
        op => {
          '=' => 1,
        }
      }
    }
  };
  my $cql = $pkg->new(mapping => $cql_mapping, id_key => 'biblio_id');
  is_deeply($cql->parse('psych*gy'), {query_string => {query => 'title:psych*gy'}});
  is_deeply($cql->parse('title = psych*gy'), {query_string => {query => 'title:psych*gy'}});
  is_deeply($cql->parse('from prox/distance<3 me'), {
    match_phrase => {
      title => {
        query => 'from me',
        slop  => 2,
      }
    }
  });
}

done_testing;