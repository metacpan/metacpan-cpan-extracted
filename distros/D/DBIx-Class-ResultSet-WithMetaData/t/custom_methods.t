#!perl

use Test::More;
use lib qw(t/lib);
use DBICTest;
use Data::Dumper;

# set up and populate schema
ok(my $schema = DBICTest->init_schema(), 'got schema');

{
	my $artist_rs = $schema->resultset('Artist')->search({}, { order_by => 'artistid' })->display();
	is_deeply($artist_rs, [
		{
			'artistid' => '1',
			'name' => 'Caterwauler McCrae'
		},
		{
			'artistid' => '2',
			'name' => 'Random Boy Band'
		},
		{
			'artistid' => '3',
			'name' => 'We Are Goth'
		}
	], 'ordered display returned as expected');
}

{
	my $artists = $schema->resultset('Artist')->search({}, { order_by => 'artistid' })->with_substr_multi->display();
	is_deeply($artists, [
		{
			'artistid' => '1',
			'name' => 'Caterwauler McCrae',
			'substr' => 'Cat',
			'substr2' => 'Cate'
		},
		{
			'artistid' => '2',
			'name' => 'Random Boy Band',
			'substr' => 'Ran',
			'substr2' => 'Rand'
		},
		{
			'artistid' => '3',
			'name' => 'We Are Goth',
			'substr' => 'We ',
			'substr2' => 'We A'
		}
	], 'display with substring using _with_meta_hash okay');
}

{
	my $artists = $schema->resultset('Artist')->search({}, { order_by => 'artistid' })->with_substr_multi_object->display();
	is_deeply($artists, [
		{
			'artistid' => '1',
			'name' => 'Caterwauler McCrae',
			'substr' => 'Cat',
			'substr2' => 'Cate'
		},
		{
			'artistid' => '2',
			'name' => 'Random Boy Band',
			'substr' => 'Ran',
			'substr2' => 'Rand'
		},
		{
			'artistid' => '3',
			'name' => 'We Are Goth',
			'substr' => 'We ',
			'substr2' => 'We A'
		}
	], 'display with substring using _with_object_meta_hash okay');
}

{
	my $artists = $schema->resultset('Artist')->search({}, { order_by => 'artistid' })->with_substr_key->display();
	is_deeply($artists, [
		{
			'artistid' => '1',
			'name' => 'Caterwauler McCrae',
			'substr' => 'Cat'
		},
		{
			'artistid' => '2',
			'name' => 'Random Boy Band',
			'substr' => 'Ran'
		},
		{
			'artistid' => '3',
			'name' => 'We Are Goth',
			'substr' => 'We '
		}
	], 'display with substring using _with_meta_key okay');
}

{
	my $artists = $schema->resultset('Artist')->search({}, { order_by => 'artistid' })->with_substr_key_obj->display();
	is_deeply($artists, [
		{
			'artistid' => '1',
			'name' => 'Caterwauler McCrae',
			'substr' => 'Cat'
		},
		{
			'artistid' => '2',
			'name' => 'Random Boy Band',
			'substr' => 'Ran'
		},
		{
			'artistid' => '3',
			'name' => 'We Are Goth',
			'substr' => 'We '
		}
	], 'display with substring using _with_object_meta_key okay');
}

# {
# 	my $artists = $schema->resultset('Artist')->search({}, { order_by => 'artistid' })->with_substr_old->display();
# 	is_deeply($artists, [
# 		{
# 			'artistid' => '1',
# 			'name' => 'Caterwauler McCrae',
# 			'substr' => 'Cat'
# 		},
# 		{
# 			'artistid' => '2',
# 			'name' => 'Random Boy Band',
# 			'substr' => 'Ran'
# 		},
# 		{
# 			'artistid' => '3',
# 			'name' => 'We Are Goth',
# 			'substr' => 'We '
# 		}
# 	], 'display with substring okay');
# }

{
	my $artists = $schema->resultset('Artist')->search({}, { order_by => 'artistid' })->with_substr_key->search({}, { prefetch => 'cds', rows => 1 })->display();
	is_deeply($artists, [
      { 
        'artistid' => 1,
        'cds' => [ 
          { 
            'cdid' => 3,
            'artist' => 1,
            'title' => 'Caterwaulin\' Blues',
            'year' => '1997'
          },
          { 
            'cdid' => 1,
            'artist' => 1,
            'title' => 'Spoonful of bees',
            'year' => '1999'
          },
          { 
            'cdid' => 2,
            'artist' => 1,
            'title' => 'Forkful of bees',
            'year' => '2001'
          }
        ],
        'name' => 'Caterwauler McCrae',
        'substr' => 'Cat'
      }
	], 'substring before prefetch okay');
}

done_testing();
