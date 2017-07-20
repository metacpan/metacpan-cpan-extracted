# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
use strict;
use warnings;
use Test::More tests => 7;

eval {
  require "./bin/clearpress";
};

{
  my $in = {
	    'course' => {
			 'name'     => 'course',
			 'has_a'    => [
					'category'
				       ],
			 'has_many' => [
					'course_user'
				       ]
			},
	   };
  my $received = [map { $_->{name} }
		  sort _sorter
		  values %{$in}];
  my $expected = [qw(course)];
  is_deeply($received,
	    $expected);
}

{
  my $in = {
	    'family' => {
			 'name'     => 'family',
			 'has_many' => [
					'kid'
				       ]
			},
	    'kid'    => {
			 'name'     => 'kid',
			 'has_a'    => [
                                        'family'
                                       ]
			},
	   };
  my $received = [map { $_->{name} }
		  sort _sorter
		  values %{$in}];
  my $expected = [qw(family kid)];

  is_deeply($received,
	    $expected);

  my $received2 = [map { $_->{name} }
		   sort _sorter
		   reverse values %{$in}];
  is_deeply($received2,
	    $expected);
}

{
  my $in = {
	    'house'  => {
			 name => 'house',
			},
	    'family' => {
			 'name'     => 'family',
			 'has_a'    => ['house'],
			 'has_many' => ['kid'],
			},
	    'kid'    => {
			 'name'     => 'kid',
			 'has_a' => [
				     'family'
				    ]
			},
	   };
  my $received = [map { $_->{name} }
		  sort _sorter
		  values %{$in}];
  my $expected = [qw(house family kid)];

  is_deeply($received,
	    $expected);

  my $received2 = [map { $_->{name} }
		   sort _sorter
		   reverse values %{$in}];
  is_deeply($received2,
	    $expected);
}


{
  my $in  = {
	     'course' => {
			  'name'     => 'course',
			  'has_a'    => [
					 'category'
					],
			  'has_many' => [
					 'course_user'
					]
			 },
	     'course_user' => {
			       'name'   => 'course_user',
			       'has_a'  => [
					    'user',
					    'course'
					   ]
			      },
	     'user' => {
			'name'     => 'user',
			'has_many' => [
				       'course_user'
				      ]
		       },
	     'category' => {
			    'name'     => 'category',
			    'has_many' => [
					   'course'
					  ]
			   }
	    };

  my $expected = [qw(category user course course_user)];
  my $received = [map { $_->{name} }
		  sort _sorter
		  values %{$in}];
#  use Data::Dumper; diag Dumper($received, $expected);
  is_deeply($received,
	    $expected);

  my $expected2 = [qw(category user course course_user)];
  my $received2 = [map { $_->{name} }
		   sort _sorter
		   reverse values %{$in}];
#  use Data::Dumper; diag Dumper($received);
  is_deeply($received2,
	    $expected2);
}
