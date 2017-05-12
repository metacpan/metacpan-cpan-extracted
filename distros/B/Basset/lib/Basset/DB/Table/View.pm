package Basset::DB::Table::View;

#Basset::DB::Table::View, copyright and (c) 2004 James A Thomason III
#Basset::DB::Table is distributed under the terms of the Perl Artistic License.

$VERSION = '1.00';

use Basset::DB::Table;
@ISA = qw(Basset::DB::Table);

use strict;
use warnings;

=pod

=head1 NAME

Basset::DB::Table::View - used to define virtual views to your objects.

=head1 AUTHOR

Jim Thomason, jim@jimandkoka.com

=head1 SYNOPSIS

For example,

 my $table = Basset::DB::Table::View->new(
	'name'				=> 'user',
	'primary_column'	=> 'id',
	'select_query' => <<'	eSQL',
		select
			user.id,
			name,
			count(*) as movies
		from
			user, movies
		where
			user.id = movies.user
			and user.id = ?
		group by
			user.id, name
	eSQL
	'definition'		=> {
		'id'		=> 'SQL_INTEGER',
		'name'		=> 'SQL_VARCHAR',
		'movies'	=> 'SQL_INTEGER',
	}
 );
 
 Some::Class->add_primarytable($table);
 
 my $object = Some::Class->load(1);	#load by user 1
 print $object->id, "\n"; #id (user id)
 print $object->name, "\n"; #"Jack Sprat"
 print $object->movies, "\n"; #145 (he owns 145 movies)


=head1 DESCRIPTION

Basset::DB::Table::View provides an abstract and consistent location for defining database views. Normally,
your objects are mapped to tables (most frequently in a 1-1 manner), but sometimes it's convenient to hide
a view of data behind an object. This way you can access a complex data query as if it were an object.

Basset::DB::Table::View as your primary table allows you to do that.

Naturally, by virtue of the fact that these are potentially complex queries, objects that use view tables
are read-only.

=cut

=pod

=head1 ATTRIBUTES

=over

=cut

=pod

=item select_query

In view tables, the select_query is an attribute, not a method. You should explicitly define the select query that is
used by this table view.

 $table->select_query('select * from somewhere');

=cut

__PACKAGE__->add_attr('select_query');

=pod

=begin btest select_query

my $o = __PACKAGE__->new();
$test->ok($o, "Got object");
$test->is(scalar(__PACKAGE__->select_query), undef, "could not call object method as class method");
$test->is(__PACKAGE__->errcode, "BO-08", "proper error code");
$test->is(scalar($o->select_query), undef, 'select_query is undefined');
$test->is($o->select_query('abc'), 'abc', 'set select_query to abc');
$test->is($o->select_query(), 'abc', 'read value of select_query - abc');
my $h = {};
$test->ok($h, 'got hashref');
$test->is($o->select_query($h), $h, 'set select_query to hashref');
$test->is($o->select_query(), $h, 'read value of select_query  - hashref');
my $a = [];
$test->ok($a, 'got arrayref');
$test->is($o->select_query($a), $a, 'set select_query to arrayref');
$test->is($o->select_query(), $a, 'read value of select_query  - arrayref');

=end btest

=back

=cut

sub insert_query {
	return shift->error("Views cannot insert", "BDTV-01");
}

=pod

=begin btest insert_query

my $o = __PACKAGE__->new();
$test->ok($o, "got object");
$test->ok(! $o->insert_query, "Cannot call insert_query");
$test->is($o->errcode, "BDTV-01", "proper error code");

=end btest

=cut

sub replace_query {
	return shift->error("Views cannot replace", "BDTV-02");
}

=pod

=begin btest replace_query

my $o = __PACKAGE__->new();
$test->ok($o, "got object");
$test->ok(! $o->replace_query, "Cannot call replace_query");
$test->is($o->errcode, "BDTV-02", "proper error code");

=end btest

=cut


sub update_query {
	return shift->error("Views cannot update", "BDTV-03");
}

=pod

=begin btest update_query

my $o = __PACKAGE__->new();
$test->ok($o, "got object");
$test->ok(! $o->update_query, "Cannot call update_query");
$test->is($o->errcode, "BDTV-03", "proper error code");

=end btest

=cut

sub delete_query {
	return shift->error("Views cannot delete", "BDTV-04");
}

=pod

=begin btest delete_query

my $o = __PACKAGE__->new();
$test->ok($o, "got object");
$test->ok(! $o->delete_query, "Cannot call delete_query");
$test->is($o->errcode, "BDTV-04", "proper error code");

=end btest

=cut

sub multiselect_query {
	return shift->error("Views cannot multiselect", "BDTV-05");
}

=pod

=begin btest multiselect_query

my $o = __PACKAGE__->new();
$test->ok($o, "got object");
$test->ok(! $o->multiselect_query, "Cannot call multiselect_query");
$test->is($o->errcode, "BDTV-05", "proper error code");

=end btest

=cut

sub attach_to_query {
	my $self	= shift;
	my $query	= shift;
	
	return $self->SUPER::attach_to_query($query);
}

=pod

=begin btest attach_to_query

my $o = __PACKAGE__->new();
$test->ok($o, "got object");
$test->ok(! $o->attach_to_query, "cannot attach to query w/o query");
$test->is($o->errcode, "BDT-02", "proper error code");
$test->is($o->attach_to_query('foo'), 'foo', 'query returns query');
$test->is($o->attach_to_query('foo', {}), 'foo', 'query returns query');
$test->is($o->attach_to_query('foo', {'where' => '2 > 1'}), 'foo', 'query returns query');

=end btest

=cut


1;
