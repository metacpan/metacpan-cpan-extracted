use Class::DBI::Frozen::301;
use strict;
use Test::More;

BEGIN {
	eval "use DBD::SQLite";
	plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 15);
}

INIT {
	use lib 't/testlib';
	use Film;
	use Actor;
	Film->CONSTRUCT;
	Actor->CONSTRUCT;
}

my $f1 = Film->create({ title => 'A', director => 'AA', rating => 'PG' });
my $f2 = Film->create({ title => 'B', director => 'BA', rating => 'PG' });
my $f3 = Film->create({ title => 'C', director => 'AA', rating => '15' });
my $f4 = Film->create({ title => 'D', director => 'BA', rating => '18' });
my $f5 = Film->create({ title => 'E', director => 'AA', rating => '18' });

Film->set_sql(
	pgs => qq{
	SELECT __ESSENTIAL__
	FROM   __TABLE__
	WHERE  __TABLE__.rating = 'PG'
	ORDER BY title DESC 
}
);

{
	(my $sth = Film->sql_pgs())->execute;
	my @pgs = Film->sth_to_objects($sth);
	is @pgs, 2, "Execute our own SQL";
	is $pgs[0]->id, $f2->id, "get F2";
	is $pgs[1]->id, $f1->id, "and F1";
}

{
	my @pgs = Film->search_pgs;
	is @pgs, 2, "SQL creates search() method";
	is $pgs[0]->id, $f2->id, "get F2";
	is $pgs[1]->id, $f1->id, "and F1";
};

Film->set_sql(
	rating => qq{
	SELECT __ESSENTIAL__
	FROM   __TABLE__
	WHERE  rating = ?
	ORDER BY title DESC 
}
);

{
	my @pgs = Film->search_rating('18');
	is @pgs, 2, "Can pass parameters to created search()";
	is $pgs[0]->id, $f5->id, "F5";
	is $pgs[1]->id, $f4->id, "and F4";
};

{
	Actor->has_a(film => "Film");
	Film->set_sql(
		namerate => qq{
		SELECT __ESSENTIAL(f)__
		FROM   __TABLE(=f)__, __TABLE(Actor=a)__ 
		WHERE  __JOIN(a f)__    
		AND    a.name LIKE ?
		AND    f.rating = ?
		ORDER BY title 
	}
	);

	my $a1 = Actor->create({ name => "A1", film => $f1 });
	my $a2 = Actor->create({ name => "A2", film => $f2 });
	my $a3 = Actor->create({ name => "B1", film => $f1 });

	my @apg = Film->search_namerate("A_", "PG");
	is @apg, 2, "2 Films with A* that are PG";
	is $apg[0]->title, "A", "A";
	is $apg[1]->title, "B", "and B";
}

{    # join in reverse
	Actor->has_a(film => "Film");
	Film->set_sql(
		ratename => qq{
		SELECT __ESSENTIAL(f)__
		FROM   __TABLE(=f)__, __TABLE(Actor=a)__ 
		WHERE  __JOIN(f a)__    
		AND    f.rating = ?
		AND    a.name LIKE ?
		ORDER BY title 
	}
	);

	my @apg = Film->search_ratename(PG => "A_");
	is @apg, 2, "2 Films with A* that are PG";
	is $apg[0]->title, "A", "A";
	is $apg[1]->title, "B", "and B";
}

