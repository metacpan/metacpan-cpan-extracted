#! /usr/bin/env perl -T
use strict;
use warnings;

use Test::More;

use_ok('DataStore::CAS::Virtual') || BAIL_OUT;
use_ok('DataStore::CAS::FS') || BAIL_OUT;

my $tree= {
	f1 => 'File One',
	f2 => 'File Two',
	a => {
		f10 => 'File Ten',
		f11 => 'File Eleven',
		f12 => 'File Twelve',
		b => {
			c => {
				d => {
					L1 => \'/a/f10',
					L2 => \'/a/b',
					f1 => 'Blah Blah',
					f2 => 'Blah Blah Blah',
					e => {
						L3 => \'../../..',
						f1 => 'sldfjlsdkfj',
						L4 => \'f1',
						L5 => \'../f1',
					},
				},
			},
			f => {
				g => {
					j => {
						f1 => 'sdlfshldkjflskdfjslkdjf',
					},
				},
				h => {},
				i => \'g',
			},
		},
	},
};

# Build CAS from tree, with symbolic hashes for easy debugging
my %content;
sub _buildTree {
	my ($node, $id)= @_;
	if (ref $node eq 'HASH') {
		my @entries= map { { name => $_, _buildTree($node->{$_}, "$id.$_") } } keys %$node;
		$content{$id}= DataStore::CAS::FS::DirCodec::Universal->encode(\@entries, {});
		return type => 'dir', ref => $id;
	}
	elsif (ref $node eq 'SCALAR') {
		return type => 'symlink', ref => $$node;
	}
	elsif (!ref $node) {
		$content{$id}= $node;
		return type => 'file', ref => $id;
	}
	else { die "Can't handle $node"; }
}
my $rootEntry= DataStore::CAS::FS::DirEnt->new( name => '', _buildTree($tree, 'root') );

my $sto= new_ok('DataStore::CAS::Virtual', [ entries => \%content ], 'create virtual cas');

subtest resolve_path => sub {
	my $cas= new_ok('DataStore::CAS::FS', [ store => $sto, root => $rootEntry ], 'create file view of cas' );
	is_deeply( $cas->resolve_path('/'), [ $rootEntry ], 'resolve root abs' );
	is_deeply( $cas->resolve_path('.'), [ $rootEntry ], 'resolve current dir at root' );

	is( $cas->resolve_path('/a/b/c')->[-1]->ref, 'root.a.b.c', 'follow subdir abs' );
	is( $cas->resolve_path('a/b/c')->[-1]->ref, 'root.a.b.c', 'follow subdir rel' );

	is( $cas->resolve_path('/f1')->[-1]->ref,   'root.f1',    'resolve file at root abs' );
	is( $cas->resolve_path('f1')->[-1]->ref,    'root.f1',    'resolve file at root rel' );
	is( $cas->resolve_path('a/f10')->[-1]->ref, 'root.a.f10', 'resolve file in dir' );

	is( $cas->resolve_path('a/b/f/g')->[-1]->ref, 'root.a.b.f.g', 'resolve leaf dir' );

	is( $cas->resolve_path('a/b/c/d/e/L4')->[-1]->name, 'L4', 'resolve symlink which points to file' );
	is( $cas->resolve_path('a/b/f/i')->[-1]->name,      'i',  'resolve symlink which points to dir' );
	is( $cas->resolve_path('a/b/f/i/')->[-1]->ref,     'root.a.b.f.g',      'resolve symlink target dir' );
	is( $cas->resolve_path('a/b/f/i/j/f1')->[-1]->ref, 'root.a.b.f.g.j.f1', 'resolve through symlink' );

	is_deeply( $cas->resolve_path('a/../a/../a/..'), [ $rootEntry ], 'follow ".."' );
	is( $cas->resolve_path('a/./b/./././.')->[-1]->ref, 'root.a.b', 'follow "."' );
	is( $cas->resolve_path('a/b/c/d/e/L3/../f10')->[-1]->ref, 'root.a.f10', 'follow symlink through ".."' );
	
	ok( exists $cas->_nodes->{subtree}{a}, 'subtree "a" was visited' );
	ok( !defined $cas->_nodes->{subtree}{a}, 'subtree "a" was garbage collected' );
	my $x= $cas->path('a/b');
	$x->resolve;
	ok( defined $cas->_nodes->{subtree}{a}, 'subtree "a" is not garbage collected' );
	ok( defined $cas->_nodes->{subtree}{a}{subtree}{b}, 'subtree "a/b" is not garbage collected' );
	done_testing;
};

subtest dir_listing => sub {
	my $cas= new_ok('DataStore::CAS::FS', [ store => $sto, root => $rootEntry ], 'create file view of cas' );
	my @expected= qw( L1 L2 e f1 f2 );
	is_deeply( [ $cas->readdir('a/b/c/d') ], \@expected, 'readdir /a/b/c/d' );
	done_testing;
};

subtest alter_path => sub {
	my $cas= new_ok('DataStore::CAS::FS', [ store => $sto, root => $rootEntry ], 'create file view of cas' );
	ok( $cas->update_path('a/b/c', { type => 'dir', ref => 'root.a.b.c.d' }), 'update path' );
	isa_ok( $cas->_nodes, 'HASH', 'overrides initiated' );
	is( $cas->resolve_path('/a/b/c')->[-1]->ref, 'root.a.b.c.d', 'directory is relinked' );
	is( $cas->_nodes->{subtree}{a}{subtree}{b}{subtree}{c}{subtree}, undef, 'a/b/c is a leaf' );
	is( $cas->_nodes->{subtree}{a}{subtree}{b}{subtree}{c}{changed}, 1, 'a/b/c changed' );
	is( $cas->_nodes->{subtree}{a}{subtree}{b}{changed}, 1, 'a/b changed' );
	is( $cas->_nodes->{subtree}{a}{changed}, 1, 'a changed' );
	is( $cas->_nodes->{changed}, 1, 'root changed' );
	is( $cas->resolve_path('/a/b/c/L1')->[-1]->type, 'symlink', 'traverse relinked directory' );
	is( $cas->root_entry->ref, 'root', 'root entry unchanged' );
	ok( $cas->commit, 'commit' );
	isnt( $cas->root_entry->ref, 'root', 'new root entry' );
	isnt( $cas->resolve_path('a')->[-1]->ref, 'root.a', 'new dir "a"' );
	isnt( $cas->resolve_path('a/b')->[-1]->ref, 'root.a.b', 'new dir "a/b"' );
	is( $cas->resolve_path('a/b/c')->[-1]->ref, 'root.a.b.c.d', 'same dir "a/b/c"' );
	is( $cas->resolve_path('a/b/f')->[-1]->ref, 'root.a.b.f', 'same dir "a/b/f"' );
	
	$cas->unlink('a');
	my @expected= ('f1','f2');
	my @actual= $cas->readdir('/');
	is_deeply( \@actual, \@expected, 'unlink dir' );

	$cas->touch('a/b', {mkdir => 1});
	@expected= ('b');
	@actual= $cas->readdir('a');
	is_deeply( \@actual, \@expected, 'recreate dir' );

	is_deeply( $cas->mkdir('a') && [ $cas->readdir('a') ], [ 'b' ], 'mkdir already existing' );
	is_deeply( $cas->mkdir('a/c') && [ $cas->readdir('a') ], [ 'b', 'c' ], 'mkdir immediate' );
	is_deeply( $cas->mkdir('a/c/x/y/z/A') && [ $cas->readdir('a/c/x/y/z') ], ['A'], 'mkdir deep' );
	ok( $cas->commit, 'commit' );
	is_deeply( [ $cas->readdir('a/c/x/y/z') ], ['A'], 'committed' );
	
	done_testing;
};

subtest path_objects => sub {
	my $cas= new_ok('DataStore::CAS::FS', [ store => $sto, root => $rootEntry ], 'create file view of cas' );
	isa_ok( my $path= $cas->path('a','b','c','d','f1'), 'DataStore::CAS::FS::Path' );
	ok( my $handle= $path->open );
	is( do { local $/= undef; scalar <$handle> }, 'Blah Blah' );
	isa_ok( $path= $cas->path('a','b','c','d')->path('..','..','f','i','j','f1'), 'DataStore::CAS::FS::Path' );
	ok( $handle= $path->open );
	is( do { local $/= undef; scalar <$handle> }, 'sdlfshldkjflskdfjslkdjf' );

	is( $cas->path_if_exists("x"), undef, 'path_if_exists returns undef for invalid' );
	isa_ok( $cas->path_if_exists("a"), 'DataStore::CAS::FS::Path', 'path_if_exists return Path for valid' );
	$path= $cas->path("a");
	is( $path->path_if_exists('m'), undef, 'path_if_exists from path object' );
	isa_ok( $path->path_if_exists('b'), 'DataStore::CAS::FS::Path', 'path_if_exists from path object' );

	$path= $cas->path("a/x/y/z")->mkdir();
	is_deeply( [ $path->readdir ], [], 'empty dir' );
	
	done_testing;
};

sub _append_sorted_paths {
	my ($result, $prefix, $node)= @_;
	for (sort keys %$node) {
		push @$result, $prefix.'/'.$_;
		_append_sorted_paths($result, $prefix.'/'.$_, $node->{$_})
			if ref $node->{$_} eq 'HASH';
	}
}

subtest tree_iterator => sub {
	my $cas= new_ok('DataStore::CAS::FS', [ store => $sto, root => $rootEntry ], 'create file view of cas' );
	my $iter= $cas->tree_iterator;
	my @expected= '/';
	_append_sorted_paths(\@expected, '', $tree);
	my @actual;
	while (defined (my $x= $iter->())) {
		push @actual, $x->resolved_canonical_path;
	}
	is_deeply( \@actual, \@expected, 'iterate tree in order' )
		or diag "Expected: ".join(' ', @expected)."\nActual: ".join(' ', @actual);

	@expected= ('/a/b');
	_append_sorted_paths(\@expected, '/a/b', $tree->{a}{b});
	$iter= $cas->tree_iterator(path => '/a/b');
	@actual= ();
	while (defined (my $x= $iter->())) {
		push @actual, $x->resolved_canonical_path;
	}
	is_deeply( \@actual, \@expected, 'iterate subtree in order' )
		or diag "Expected: ".join(' ', @expected)."\nActual: ".join(' ', @actual);

	$iter= $cas->path('a','b')->tree_iterator();
	@actual= ();
	while (defined (my $x= $iter->())) {
		push @actual, $x->resolved_canonical_path;
	}
	is_deeply( \@actual, \@expected, 'iterate subtree from path object' )
		or diag "Expected: ".join(' ', @expected)."\nActual: ".join(' ', @actual);

	# Reset, and should give same result
	@actual= ();
	$iter->reset;
	while (defined (my $x= $iter->())) {
		push @actual, $x->resolved_canonical_path;
	}
	is_deeply( \@actual, \@expected, 'iteration is same after ->reset()' )
		or diag "Expected: ".join(' ', @expected)."\nActual: ".join(' ', @actual);

	# Simulate a --max-depth using the skip_dir method on the iterator
	@actual= ();
	$iter->reset;
	while (defined (my $x= $iter->())) {
		push @actual, $x->resolved_canonical_path;
		$iter->skip_dir
			if @{$x->path_dirents} >= 6 && $x->type eq 'dir';
	}
	@expected= grep { (split m|/|, $_) <= 6 } @expected;
	is_deeply( \@actual, \@expected, 'iteration skipped properly' )
		or diag "Expected: ".join(' ', @expected)."\nActual: ".join(' ', @actual);
	
	done_testing;
};

done_testing;
