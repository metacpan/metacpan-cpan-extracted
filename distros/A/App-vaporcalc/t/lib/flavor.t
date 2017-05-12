use Test::Modern;


use App::vaporcalc::Flavor;

my $flav = App::vaporcalc::Flavor->new(
  percentage => 10,
  tag        => 'TFA Raspberry',
);

ok $flav->percentage == 10, 'percentage ok';
ok $flav->tag eq 'TFA Raspberry', 'tag ok';
ok $flav->type eq 'PG', 'default type ok';

$flav = App::vaporcalc::Flavor->new(
  percentage => 10,
  tag        => 'TFA Marshmallow',
  type       => 'VG',
);

ok $flav->type eq 'VG', 'type ok';

ok exception {;
    App::vaporcalc::Flavor->new(percentage => 10)
  },
  'missing required attrib "tag" dies ok';

ok exception {;
    App::vaporcalc::Flavor->new(percentage => 101)
  },
  'invalid attrib "percentage" dies ok';

ok exception {;
  App::vaporcalc::Flavor->new(tag => 'foo')
  },
  'missing required attrib "percentage" dies ok';

done_testing
