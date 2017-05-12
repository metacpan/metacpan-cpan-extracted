package Test::DataPresenterSpecial;
#$Id: DataPresenterSpecial.pm 1218 2008-02-10 00:11:59Z jimk $
# Contains test subroutines for distribution with Data::Presenter
# As of:  February 10, 2008
require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw( test_two_elements nicedump selection_tests ); 
our %EXPORT_TAGS = (
    seen => [ @EXPORT_OK ],
);
*ok = *Test::More::ok;
*is = *Test::More::is;
*is_deeply = *Test::More::is_deeply;
use Data::Dumper;
use List::Compare::Functional qw( is_LsubsetR get_intersection );

sub test_two_elements {
    my ($sorted_data, $predicted_ref) = @_;
    my (@got0, @got1, @pred0, @pred1);
    foreach my $rec (@$sorted_data) {
        push @got0, $rec->[0];
        push @got1, $rec->[1];
    }
    foreach my $rec (@{$predicted_ref}) {
        push @pred0, $rec->[0];
        push @pred1, $rec->[1];
    }
    is_deeply(\@got0, \@pred0, "elements in index 0 match");
    is_deeply(\@got1, \@pred1, "elements in index 1 match");
}

sub nicedump {
    my @tobedumped = @_;;
    local $Data::Dumper::Indent = 0;
    my $d = Data::Dumper->new(\@tobedumped);
    my $bigstr = $d->Dump;
    $bigstr =~ s/^(.*'index'\s=>\s\d+,)(.*)/$1\n$2/;
    $bigstr =~ s/\],/],\n/g;
    print $bigstr;
    print "\n";
}

sub selection_tests {
    my %args = @_;
    my $dp0;
    ok($dp0 = Data::Presenter::Sample::Census->new(
        $args{source},
        $args{fields},
        $args{params},
        $args{index},
    ), "created object anew");
    $dp0->select_rows(
        $args{column},
        $args{relation},
        $args{choices},
    );
    is( $dp0->get_data_count, $args{count}, 
        'get_data_count() returns predicted number of records for ' . $args{relation});

    # Test that all keys predicted were seen, i.e.
    # @keys_predicted is subset of @{$dp0->get_keys} 
    ok(is_LsubsetR( [ $args{predict}, $dp0->get_keys ] ), 
        "all keys predicted were seen");

    # Then:
    # Test that all keys NOT predicted were NOT seen, i.e.
    # intersection of @keys_not_predicted and @{$dp0->get_keys} is empty
    is( scalar(get_intersection( [ $args{nonpredict}, $dp0->get_keys ] ) ), 0, 
        "no keys not predicted were seen");
}

1;

