# vi:sw=2
package # Hide from PAUSE
  common;

use strictures 2;

use base 'Exporter';
our @EXPORT_OK = qw(
  sims_test Schema
);

use DDP;
use Test2::V0 qw(
  E item object array bag hash subtest skip_all number is match call field
  end
);
use Test::Warn;
use Test::Trap;

use Test::DBIx::Class;

sub sims_test ($$) {
  my ($name, $opts) = @_;

  subtest $name => sub {
    skip_all($opts->{skip}) if $opts->{skip};

    Schema->storage->dbh_do(sub {
      my ($st, $dbh) = @_; $dbh->do('PRAGMA foreign_keys = OFF');
    });
    Schema->deploy({ add_drop_table => 1 }) if $opts->{deploy} // 1;
    Schema->storage->dbh_do(sub {
      my ($st, $dbh) = @_; $dbh->do('PRAGMA foreign_keys = ON');
    }) unless $opts->{skip_foreign_keys};

    foreach my $name (Schema->sources) {
      my $c = ResultSet($name)->count;
      my $l = $opts->{loaded}{$name} // 0;
      #cmp_ok $c, '==', $l, "$name has $l rows loaded at first";
      is($c, number($l), "$name has $l rows loaded at first");
    }

    $ENV{TEST_VERBOSE} = 1 if $ENV{SIMS_DEBUG};

    my ($rv, $addl);
    eval {
      local $SIG{ALRM} = sub { die "test timeout\n" };
      alarm 1;
      if ($opts->{dies}) {
        if ($opts->{load_sims}) {
          trap {
            ($rv, $addl) = $opts->{load_sims}->(Schema)
          };
          is($trap->leaveby, 'die', 'load_sims fails');
          if ($opts->{warning}) {
            is($trap->stderr, match($opts->{warning}), "Warning as expected");
          }
          my $continue = is(($trap->die // '') . "", match($opts->{dies}), 'Error message as expected');
          unless ($continue) {
            warn $trap->stderr;
            warn $trap->die;
            return; # Don't continue the test if we die unexpectedly.
          }
        }
        else {
          my @args = ref($opts->{spec}//'') eq 'ARRAY'
            ? @{$opts->{spec}} : ($opts->{spec}//{});
          trap {
            ($rv, $addl) = $opts->{as_class_method}
              ? DBIx::Class::Sims->load_sims(Schema, @args)
              : Schema->load_sims(@args);
          };
          is($trap->leaveby, 'die', 'load_sims fails');
          if ($opts->{warning}) {
            is($trap->stderr, match($opts->{warning}), "Warning as expected");
          }
          my $continue = is(($trap->die // '') . "", match($opts->{dies}), 'Error message as expected');
          unless ($continue) {
            warn $trap->stderr;
            warn $trap->die;
            return; # Don't continue the test if we die unexpectedly.
          }
        }
      }
      else {
        if ($opts->{load_sims}) {
          trap {
            ($rv, $addl) = $opts->{load_sims}->(Schema)
          };
          my $continue = is $trap->leaveby, 'return', "load_sims runs to completion";
          unless ($continue) {
            warn $trap->stderr;
            warn $trap->die;
            return; # Don't continue the test if we die unexpectedly.
          }
          warn $trap->stderr if $ENV{TEST_VERBOSE} && $trap->stderr;
        }
        else {
          my @args = ref($opts->{spec}//'') eq 'ARRAY'
            ? @{$opts->{spec}} : ($opts->{spec}//{});
          if ($opts->{warning}) {
            warning_like {
              ($rv, $addl) = $opts->{as_class_method}
                ? DBIx::Class::Sims->load_sims(Schema, @args)
                : Schema->load_sims(@args);
            } $opts->{warning}, "Warning as expected";
          }
          else {
            trap {
              ($rv, $addl) = $opts->{as_class_method}
                ? DBIx::Class::Sims->load_sims(Schema, @args)
                : Schema->load_sims(@args);
            };
            my $continue = is $trap->leaveby, 'return', "load_sims runs to completion";
            unless ($continue) {
              warn $trap->stderr;
              warn $trap->die;
              return; # Don't continue the test if we die unexpectedly.
            }
            warn $trap->stderr if $ENV{TEST_VERBOSE} && $trap->stderr;
          }
        }

        if (ref($opts->{expect}//'') eq 'CODE') {
          $opts->{expect} = $opts->{expect}->($opts);
        }

        while (my ($name, $expect) = each %{$opts->{expect} // {}}) {
          $expect = [ $expect ] unless ref($expect) eq 'ARRAY';
          my $check = bag {
            foreach my $exp ( @$expect ) {
              item object {
                while ( my ($k,$v) = each(%$exp) ) {
                  call $k => $v;
                }
              };
            }
            end();
          };
          my @x = ResultSet($name)->all;
          warn("EXPECT-CHECK $name: " . np(@x)) if $ENV{SIMS_DEBUG};
          is(
            \@x, $check,
            "Rows in database for $name are expected",
          );
        }

        if (ref($opts->{rv}//'') eq 'CODE') {
          $opts->{rv} = $opts->{rv}->($opts);
        }

        my $check = hash {
          while (my ($n,$e) = each %{$opts->{rv} // $opts->{expect} // {}}) {
            $e = [ $e ] unless ref($e) eq 'ARRAY';
            field $n => bag {
              foreach my $exp ( @$e ) {
                item object {
                  while ( my ($k,$v) = each %$exp ) {
                    call $k => $v;
                  }
                };
              }
              end;
            };
          }
          end;
        };
        warn("RV-CHECK: " . np($rv)) if $ENV{SIMS_DEBUG};
        is( $rv, $check, "Return value is as expected" );

        if ($opts->{addl}) {
          # Don't force me to set these things, unless I want to.
          $opts->{addl}{duplicates} //= {};
          $opts->{addl}{seed} //= match(qr/^[\d.]+$/);
          $opts->{addl}{created} //= E();
          is($addl, $opts->{addl}, "Additional value is as expected");
        }
      }
      alarm 0;
    };
    alarm 0;
    if ($@) {
      die unless $@ eq "test timeout\n";
      ok(0, "Test timed out");
    }

    foreach my $export (@{$opts->{export} // []}) {
      my ($target, $rule) = @$export;
      $$target = $rule->($rv, $addl);
    }
  };
}

1;
