use strict;
use warnings;
use Test::More;

use DBIO::Core;
use DBIO::Schema;
use DBIO::Firebird::DDL;

# Offline (karr k60, case bind-numeric-exact): a NUMERIC / DECIMAL of more than
# 18 digits is an INT128; DBD::Firebird 1.39 can neither bind nor read one
# (t/97-numeric-int128-dbd-live.t), so install_ddl refuses it on EVERY server,
# naming table and column and the reason. 18 digits (a BIGINT) is written.

my $n = 0;
sub schema_for {
  my ($build) = @_;
  $n++;
  my $sc = "T::K55::S$n";
  { no strict 'refs'; @{"${sc}::ISA"} = ('DBIO::Schema'); }
  my (@later, @classes);
  my $make = sub {
    my ($name, $table, $cols, $pk, $extra) = @_;
    my $rc = "T::K55::S${n}::Result::$name";
    { no strict 'refs'; @{"${rc}::ISA"} = ('DBIO::Core'); $INC{"T/K55/S${n}/Result/$name.pm"} = 1; }
    $rc->table($table);
    $rc->add_columns(@$cols);
    $rc->set_primary_key(@$pk) if $pk;
    push @later, sub { $extra->($rc) } if $extra;
    push @classes, [ $name => $rc ];
  };
  $build->($make);
  $_->() for @later;
  $sc->register_class(@$_) for @classes;
  return $sc;
}
sub ddl_of {
  my ($table, $cols) = @_;
  my $sc = schema_for(sub { $_[0]->(T => $table, [ id => { data_type => 'integer' }, @$cols ], ['id']) });
  return DBIO::Firebird::DDL->install_ddl($sc);
}

my $col = sub { [ v => { data_type => $_[0], size => $_[1], is_nullable => 1 } ] };

for my $type (qw(numeric decimal)) {
  for my $major (3, 4, 5, undef) {
    my $name = defined $major ? "Firebird $major" : 'a server that cannot be asked';
    no warnings 'redefine';
    local *DBIO::Firebird::DDL::server_major_version = sub { $major };
    for my $size ([20, 4], 19, [38, 10]) {
      my $err;
      eval { ddl_of('big', $col->($type, $size)); 1 } or $err = $@;
      my $label = "$type(" . (ref $size ? join(',', @$size) : $size) . ") on $name";
      isa_ok $err, 'DBIO::Exception', "$label: refused";
      like "$err", qr/refus/i, "$label: the text says it is a refusal";
      like "$err", qr/'big'/, "$label: the text names the table";
      like "$err", qr/'v'/, "$label: the text names the column";
      like "$err", qr/cannot bind or read an INT128/, "$label: the text gives the reason";
    }
    like eval { ddl_of('ok', $col->($type, [18, 4])) } // $@, qr/^  "v" DECIMAL\(18,4\),?$/m,
      "$type(18,4) on $name: written, 18 digits is the limit of a BIGINT";
  }
}

done_testing;
