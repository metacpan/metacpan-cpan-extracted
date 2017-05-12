use strict;
use warnings;
use Test::More;
use lib qw(t/lib);
use make_dbictest_db_multi_m2m;

use DBIx::Class::Schema::Loader;

my $schema_counter = 0;

{
    my $hashmap = schema_with(
        rel_name_map => {
            foos_2s => "other_foos",
            bars_2s => "other_bars",
        },
    );

    foreach ([qw(Foo bars)], [qw(Bar foos)]) {
        my ($source, $rel) = @{$_};
        my $row = $hashmap->resultset($source)->find(1);
        foreach my $link ("", "other_") {
            can_ok $row, "${link}${rel}";
        }
    }
}
{
    my $submap = schema_with(
        rel_name_map => sub {
            my ($args) = @_;
            if ($args->{type} eq "many_to_many") {
                like $args->{link_class},
                    qr/\ADBICTest::Schema::${schema_counter}::Result::FooBar(?:One|Two)\z/,
                    "link_class";
                like $args->{link_moniker}, qr/\AFooBar(?:One|Two)\z/,
                    "link_moniker";
                like $args->{link_rel_name}, qr/\Afoo_bar_(?:ones|twos)\z/,
                    "link_rel_name";

                return $args->{name}."_".(split /_/, $args->{link_rel_name})[-1];
            }
        },
    );
    foreach ([qw(Foo bars)], [qw(Bar foos)]) {
        my ($source, $rel) = @{$_};
        my $row = $submap->resultset($source)->find(1);
        foreach ([ones => 1], [twos => 2]) {
            my ($link, $count) = @{$_};
            my $m2m = "${rel}_${link}";
            can_ok $row, $m2m;
            is $row->$m2m->count, $count, "$m2m count";
        }
    }
}

done_testing;

#### generates a new schema with the given opts every time it's called
sub schema_with {
    $schema_counter++;
    DBIx::Class::Schema::Loader::make_schema_at(
            'DBICTest::Schema::'.$schema_counter,
            { naming => 'current', @_ },
            [ $make_dbictest_db_multi_m2m::dsn ],
    );
    "DBICTest::Schema::$schema_counter"->clone;
}
