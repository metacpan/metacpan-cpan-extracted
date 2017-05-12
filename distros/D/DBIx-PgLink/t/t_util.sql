\i t/init.sql

delete from connections where conn_name = 'FOO';
insert into connections (conn_name, data_source) values ('FOO', 'dbi:Sponge:');

----

select is( 
  (select count(*) from attributes where conn_name='FOO')::int,
  0::int,
  'helper conn_attr'
);
select is( get_attr(null, null, null), null, 'helper conn_attr' );
select is( get_attr('FOO', '', null), null, 'helper conn_attr' );
select is( get_attr('FOO', '', 'foo'), null, 'helper conn_attr' );
select ok( set_attr('FOO', '', 'foo', 'value') is not null, 'helper conn_attr' );
select is( 
  (select count(*) from attributes where conn_name='FOO')::int,
  1::int,
  'helper conn_attr'
);
select is( 
  (select attr_name from attributes where conn_name='FOO' limit 1),
  'foo',
  'helper conn_attr'
);
select is( 
  (select attr_value from attributes where conn_name='FOO' and attr_name='foo'),
  'value',
  'helper conn_attr'
);
select is( get_attr('FOO', '', 'foo'), 'value', 'helper conn_attr' );


select ok( set_attr('FOO', '', 'bar', '12345') is not null, 'helper conn_attr' );
select is( get_attr('FOO', '', 'foo'), 'value', 'helper conn_attr' );
select is( get_attr('FOO', '', 'bar'), '12345', 'helper conn_attr');

select ok( set_attr('FOO', '', 'bar', '42') is not null, 'helper conn_attr' );
select is( get_attr('FOO', '', 'foo'), 'value', 'helper conn_attr' );
select is( get_attr('FOO', '', 'bar'), '42', 'helper conn_attr' );

select ok( not delete_attr('FOO', '', 'dummy'), 'helper conn_attr' );
select ok( delete_attr('FOO', '', 'bar'), 'helper conn_attr' );
select ok( not delete_attr('FOO', '', 'bar'), 'helper conn_attr' );
select is( get_attr('FOO', '', 'foo'), 'value', 'helper conn_attr' );
select is( get_attr('FOO', '', 'bar'), null, 'helper conn_attr' );


-----
select is( 
  (select count(*) from environment where conn_name='FOO')::int,
  0::int,
  'helper conn_env'
);
select is( get_env(null, null, null), null, 'helper conn_env' );
select is( get_env('FOO', '', null), null, 'helper conn_env' );
select is( get_env('FOO', '', 'foo'), null, 'helper conn_env' );
select ok( set_env('FOO', '', 'set', 'foo', 'value') is not null, 'helper conn_env' );
select is( 
  (select count(*) from environment where conn_name='FOO')::int,
  1::int,
  'helper conn_env'
);
select is( 
  (select env_name from environment where conn_name='FOO' limit 1),
  'foo',
  'helper conn_env'
);
select is( 
  (select env_value from environment where conn_name='FOO' and env_name='foo'),
  'value',
  'helper conn_env'
);
select is( get_env('FOO', '', 'foo'), 'value', 'helper conn_env');


select ok( set_env('FOO', '', 'set', 'bar', '12345') is not null, 'helper conn_env' );
select is( get_env('FOO', '', 'foo'), 'value', 'helper conn_env' );
select is( get_env('FOO', '', 'bar'), '12345', 'helper conn_env' );

select ok( set_env('FOO', '', 'set', 'bar', '42') is not null, 'helper conn_env' );
select is( get_env('FOO', '', 'foo'), 'value', 'helper conn_env' );
select is( get_env('FOO', '', 'bar'), '42', 'helper conn_env' );

select ok( not delete_env('FOO', '', 'dummy'), 'helper conn_env' );
select ok( delete_env('FOO', '', 'bar') , 'helper conn_env' );
select ok( not delete_env('FOO', '', 'bar'), 'helper conn_env' );
select is( get_env('FOO', '', 'foo'), 'value', 'helper conn_env' );
select is( get_env('FOO', '', 'bar'), null, 'helper conn_env' );


----

select is( 
  (select count(*) from init_session where conn_name='FOO')::int,
  0::int,
  'helper init_session'
);
select is( get_init_session(null, null, null), null, 'helper init_session');
select is( get_init_session('FOO', '', null), null, 'helper init_session');
select is( get_init_session('FOO', '', 1), null, 'helper init_session');
select ok( 
  set_init_session('FOO', '', 1, 'SET client_min_messages=WARNING', true) is not null,
  'helper init_session'
);
select is( 
  (select count(*) from init_session where conn_name='FOO')::int,
  1::int,
  'helper init_session'
);
select is( 
  (select init_seq from init_session where conn_name='FOO'),
  1,
  'helper init_session'
);
select is( 
  (select init_query from init_session where conn_name='FOO' and init_seq=1),
  'SET client_min_messages=WARNING',
  'helper init_session'
);
select is( 
  get_init_session('FOO', '', 1), 
  'SET client_min_messages=WARNING',
  'helper init_session'
);

--append
select ok( 
  set_init_session('FOO', '', 2, 'SET add_missing_from=true', true) is not null,
  'helper init_session'
);
select ok( 
  set_init_session('FOO', '', 3, 'SET standard_conforming_strings=true', true) is not null,
  'helper init_session'
);
select ok( 
  get_init_session('FOO', '', 1) = 'SET client_min_messages=WARNING',
  'helper init_session'
);
select is( 
  get_init_session('FOO', '', 2), 
  'SET add_missing_from=true',
  'helper init_session'
);
select is( 
  get_init_session('FOO', '', 3),
  'SET standard_conforming_strings=true',
  'helper init_session'
);

--replace
select ok( 
  set_init_session('FOO', '', 2, 'SET add_missing_from=false', true) is not null,
  'helper init_session'
);
select is( 
  get_init_session('FOO', '', 1),
  'SET client_min_messages=WARNING',
  'helper init_session'
);
select is( 
  get_init_session('FOO', '', 2),
  'SET add_missing_from=false',
  'helper init_session'
);
select is( 
  get_init_session('FOO', '', 3),
  'SET standard_conforming_strings=true',
  'helper init_session'
);

--insert
select ok( 
  set_init_session('FOO', '', 2, 'SET plperl.use_strict=true', false) is not null,
  'helper init_session'
);
select is( 
  get_init_session('FOO', '', 1),
  'SET client_min_messages=WARNING',
  'helper init_session'
);
select is( 
  get_init_session('FOO', '', 2),
  'SET plperl.use_strict=true',
  'helper init_session'
);
select is( 
  get_init_session('FOO', '', 3),
  'SET add_missing_from=false',
  'helper init_session'
);
select is( 
  get_init_session('FOO', '', 4),
  'SET standard_conforming_strings=true',
  'helper init_session'
);

--delete
select ok( 
  delete_init_session('FOO', '', 3), 
  'helper init_session'
);
select is( 
  get_init_session('FOO', '', 1),
  'SET client_min_messages=WARNING',
  'helper init_session'
);
select is( 
  get_init_session('FOO', '', 2),
  'SET plperl.use_strict=true',
  'helper init_session'
);
select is( 
  get_init_session('FOO', '', 3),
  null,
  'helper init_session'
);
select is( 
  get_init_session('FOO', '', 4),
  'SET standard_conforming_strings=true',
  'helper init_session'
);
