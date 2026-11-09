use strict;
use warnings;
use Test::More;

use DBIO::MySQL::DDL;

# karr k96 point 4. DDL walks $source->relationships to derive the foreign
# keys. Since core 7e64e7e6b that list is sorted by name, so the DDL of a
# table does not depend on the order in which its belongs_to were declared.
# This pins the property on this side: the same schema declared with its
# relationships in opposite order yields the same script.

sub build {
  my ($tag, $order) = @_;
  my $ns = "RelOrder$tag";

  eval qq{
    package ${ns}::Schema;
    use DBIO 'Schema';
    __PACKAGE__->load_components('MySQL');

    package ${ns}::Schema::Result::$_;
    use DBIO;
    __PACKAGE__->table(lc '$_');
    __PACKAGE__->add_columns(id => { data_type => 'integer', is_auto_increment => 1 });
    __PACKAGE__->set_primary_key('id');
    1;
  } or die $@ for qw(Alpha Beta);

  eval qq{
    package ${ns}::Schema::Result::Child;
    use DBIO;
    __PACKAGE__->table('child');
    __PACKAGE__->add_columns(
      id       => { data_type => 'integer', is_auto_increment => 1 },
      alpha_id => { data_type => 'integer' },
      beta_id  => { data_type => 'integer' },
    );
    __PACKAGE__->set_primary_key('id');
    1;
  } or die $@;

  my %rel = (
    alpha => sub { "${ns}::Schema::Result::Child"->belongs_to(alpha => "${ns}::Schema::Result::Alpha", 'alpha_id') },
    beta  => sub { "${ns}::Schema::Result::Child"->belongs_to(beta  => "${ns}::Schema::Result::Beta",  'beta_id') },
  );
  $rel{$_}->() for @$order;

  "${ns}::Schema"->register_class($_ => "${ns}::Schema::Result::$_") for qw(Alpha Beta Child);
  return DBIO::MySQL::DDL->install_ddl("${ns}::Schema");
}

my $forward = build('Fwd', [qw(alpha beta)]);
my $reverse = build('Rev', [qw(beta alpha)]);

like $forward, qr/FOREIGN KEY/, 'the script carries the foreign keys';
is $reverse, $forward, 'relationships declared in the opposite order give the same script';

done_testing;
