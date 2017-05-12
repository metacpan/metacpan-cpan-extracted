package DBIx::MoCo::Fixture;
use strict;
use warnings;
use Exporter::Lite;

use Carp qw/croak/;
use FindBin;
use Kwalify ();
use Path::Class;
use UNIVERSAL::require;
use YAML::Syck;

our $VERSION = 0.01;

our @EXPORT_OK = qw/fixtures/;
our @EXPORT = @EXPORT_OK;

sub fixtures (@) {
    my $option = pop if ref $_[-1] and ref $_[-1] eq 'HASH';
    $option ||= {};
    croak 'usage: fixtures(@models, { yaml_dir => '...' })' unless @_;

    my $dir = $option->{yaml_dir} || dir($FindBin::Bin)->parent->subdir('fixtures');
    my $res;
    for (@_) {
        my $config = validate_fixture(
            load_fixture( file($dir, sprintf("%s.yml", $_)) )
        );
        $config->{model}->require or die $@;

        delete_all( $config->{model} );
        $res->{$_} = insert( $config->{model}, $config->{records} );
    }
    $res;
}

sub load_fixture {
    my $file = shift;
    my $yaml = $file->slurp or die $!;

    YAML::Syck::Load($yaml);
}

sub validate_fixture {
    my $stuff = shift;

    Kwalify::validate({
        type    => 'map',
        mapping => {
            model   => { type => 'str', required => 1 },
            records => { type => 'any', required => 1 },
        }
    }, $stuff);

    $stuff;
}

sub delete_all {
    my $model = shift;
    if ($model->db->vendor eq 'SQLite') {
        $_->delete for $model->search;
    } else {
        $model->delete_all(where => { 1 => '1' });
    }
}

sub insert {
    my ($model, $records) = @_;

    my $res = {};
    for my $name (keys %$records) {
        my $obj = $model->create( %{ $records->{$name} } );
        $obj->save;

        my %query;
        for (@{ $obj->primary_keys }) {
            $query{$_} = $obj->$_;
        }

        $res->{$name} = $model->retrieve(%query);
    }
    $res;
}

1;

__END__

=head1 NAME

DBIx::MoCo::Fixture - A fixture for testing model components of DBIx::MoCo

=head1 SYNOPSIS

  ## fixtures/entry.yml
  model: My::Bookmark::Entry
  records:
    first:
      id: 1
      title: Hatena Bookmark
      url: http://b.hatena.ne.jp/

    second:
      id: 2
      title: Yahoo
      url: http://www.yahoo.co.jp/

  ## t/entry.t
  use DBIx::MoCo::Fixture;
  use My::Bookmark::Entry;
  use Test::More tests => 2;

  my $f = fixtures(qw/entry/);
  is My::Bookmark::Entry->retrieve(1)->title, $f->{entry}->{first}->{title};
  is My::Bookmark::Entry->retrieve(2)->title, $f->{entry}->{second}->{title};

=head1 DESCRIPTION

A fixture loader for DBIx::MoCo. See L<DBIx::MoCo::Manual::Testing>
for more details.

=head1 METHODS

=head2 fixtures

  my $f = fixtures(qw/entry bookmark/, { yaml_dir => "../fixtures" })

Automatically loads ../fixtures/entry.yml and ../fixtures/bookmark.yml
to the database.

NOTE: All records for the specified model will be once removed when
<fixtures()> called. Do not use fixtures when your model is connected
to the production database.

=head1 More Details on How to Use DBIx::MoCo::Fixture

=head2 Testing with Fixtures

To test your model classes efficiently and strictly, you should use
real data which will be used in your production environment.
DBIx::MoCo has Rails-like feature for testing, that is,
fixtures, and it helps you to automatically set up test data into
database.

=head2 Tables and model classes

Here you're going to perform testing for the tables and model classes
below:

Tables:

  CREATE TABLE user (
    id   INTEGER PRIMARY KEY,
    name varchar(255)
  );

  CREATE TABLE entry (
    id      INTEGER PRIMARY KEY,
    user_id INTEGER,
    title   varchar(255),
    body    text
  )

Model classes:

  package Blog::MoCo::User;
  use strict;
  use warnings;
  use base qw (Blog::MoCo);
  use Blog::MoCo::Entry;

  __PACKAGE__->table('user');
  __PACKAGE__->has_many(
      entries => 'Blog::MoCo::Entry',
      { key => { id => 'user_id' } }
  );

  package Blog::MoCo::Entry;
  use strict;
  use warnings;
  use base qw 'Blog::MoCo';
  use Blog::MoCo::User;

  __PACKAGE__->table('entry');
  __PACKAGE__->has_a(
      user => 'Blog::MoCo::User',
      { key => { user_id => 'id'} }
  );

=head2 Setting up fixtures

Fixtures must be written in YAML and the file must have I<.yml>
extension.

Here's the structure of a fixture.

  model: Your::MoCo::Class
  records:
    record_name1:
      column1: foo
      column2: bar
    record_name2:
      column1: baz
      column2: quux

=over 4

=item model (mandate, unchangeable)

A name of a model which is correspondent to a fixture.

=item records (mandate, unchangeable)

This field contains actual data to be inserted into your database.

=item record_name1, record_name2 ... (changeable along with your
convinience)

Names of each records. You can use this names as keys of a hash
reference to the data in the fixture.

=item column1, column2 ... (this names must be correspondent to the
actual column names)

Names of each actual columns. This field contains the data of the
column.

=back

Well, C<fixtures()> method loads fixtures from I<fixtures> directory
which is located in the same level of I<*.t> scripts directory. You
can make the method to retrieve fixtures from other directory by
passing optional parameters as below:

  my $f = fixtures(qw(user entry), { yaml_dir => "../fixtures" });

Now you can write fixtures for testing like below:

user.yml

  model: Blog::MoCo::User
  records:
    first:
      id: 1
      name: jkondo

    second:
      id: 2
      name: naoya

entry.yml

  model: Blog::MoCo::Entry
  records:
    first:
      id: 1
      user_id: 1
      title: Hello World!
      body: I'm fine!

    second:
      id: 2
      user_id: 1
      title: Cinnamon
      body: The cutest dog ever!!!

=head2 Test Script

Finally, we'll start working on a test script using the fixtures
above.

  use strict;
  use warnings;
  use Test::More;
  use FindBin::libs;

  use Blog::MoCo::User;
  use Blog::MoCo::Entry;

  use DBIx::MoCo::Fixture;

  # fixture() is exported from DBIx::MoCo::Fixture
  my $fixtures = fixtures(qw(user entry));

  plan tests => 8;

  # Verifying if the data from db and from fixture are equal
  is(Blog::MoCo::User->retrieve(1)->name,   $fixtures->{user}{first}{name});
  is(Blog::MoCo::User->retrieve(2)->name,   $fixtures->{user}{second}{name});
  is(Blog::MoCo::Entry->retrieve(1)->title, $fixtures->{entry}{first}{title});
  is(Blog::MoCo::Entry->retrieve(2)->title, $fixtures->{entry}{second}{title});
  is(Blog::MoCo::Entry->retrieve(1)->body,  $fixtures->{entry}{first}{body});
  is(Blog::MoCo::Entry->retrieve(2)->body,  $fixtures->{entry}{second}{body});

  # Verifying if has_a and has_many relationships work well
  is(
      Blog::MoCo::User->retrieve(1)->entries->find(sub { $_->id == 1})->title,
      $fixtures->{entry}{first}{title}
  );
  is(
      Blog::MoCo::Entry->retrieve(1)->user->name,
      $fixtures->{user}{first}{name}
  );

After you pass the names of fixtures into C<fixture()> method and
execute it, this method automatically loads the fixtures and inserts
the data into your database. The return value of the method is a hash
reference whose keys are same as the names of the record names in
fixtures you see above.

In this way, you can easily test your model classes by verifying if
the data from database is equal to one from the fixture.

=head1 AUTHOR

Naoya Ito E<lt>naoya@bloghackers.netE<gt>

=head1 SEE ALSO

L<DBIx::MoCo>, L<Kwalify>

=head1 ACKNOWLEDGEMENT

It borrowed many codes from L<Test::Fixture::DBIC::Schema>.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
