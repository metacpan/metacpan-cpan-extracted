use Dwarf::Pragma;
use Dwarf::SQLBuilder;
use Test::More 0.88;

subtest "new_query" => sub {
	my $query = Dwarf::SQLBuilder->new_query;
	is ref $query, 'Dwarf::SQLBuilder::Query';

	$query
		->select(qq{ id, name })
		->from(qq{ users })
		->add_join(qq{ inner join prefectures on users.prefecture_id = prefectures.id })
		->where(qq{ status = 1 })
		->group_by(qq{ prefecture })
		->having(qq{ count(id) > 0 })
		->order_by(qq{ id ASC })
		->limit(100)
		->offset(10);

	is $query->sql, qq{ SELECT  id, name  FROM  users   inner join prefectures on users.prefecture_id = prefectures.id  WHERE  status = 1  GROUP BY  prefecture  HAVING  count(id) > 0  ORDER BY  id ASC  LIMIT 100 OFFSET 10 };
};

done_testing;
