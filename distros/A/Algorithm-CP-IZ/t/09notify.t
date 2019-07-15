use strict;
use warnings;

use Test::More tests => 9;
BEGIN { use_ok('Algorithm::CP::IZ') };

SKIP: {
    my $iz = Algorithm::CP::IZ->new();

    skip "old iZ", 3
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);

    my $s = $iz->create_int(1, 9);
    my $e = $iz->create_int(0, 9);
    my $n = $iz->create_int(0, 9);
    my $d = $iz->create_int(0, 9);
    my $m = $iz->create_int(1, 9);
    my $o = $iz->create_int(0, 9);
    my $r = $iz->create_int(0, 9);
    my $y = $iz->create_int(0, 9);

    $iz->AllNeq([$s, $e, $n, $d, $m, $o, $r, $y]);

    my $v1 = $iz->ScalProd([$s, $e, $n, $d], [1000, 100, 10, 1]);
    my $v2 = $iz->ScalProd([$m, $o, $r, $e], [1000, 100, 10, 1]);
    my $v3 = $iz->ScalProd([$m, $o, $n, $e, $y], [10000, 1000, 100, 10, 1]);
    my $v4 = $iz->Add($v1, $v2);
    $v3->Eq($v4);

    package TestObj;
    sub new {
	my $class = shift;
	bless {}, $class;
    }

    my %called;
    
    sub search_start {
	my $self = shift;
	my $array = shift;
	$called{search_start}++;
    }

    sub search_end {
	my $self = shift;
	my $array = shift;

	$called{search_end}++;

	# 9567 + 1085 = 10652
	# SEND   MORE   MONEY
	# 95671082
	$called{search_end_solution} = join("", ($s, $e, $n, $d, $m, $o, $r, $y));
    }

    sub before_value_selection {
	my $self = shift;
	my ($depth, $index, $vs, $array) = @_;
	# debug
	# print STDERR "value selection: $depth, $index, $array\n";
	# print STDERR "  ", $vs->[0], ", ", $vs->[1], "\n";
	# print STDERR join(", ", map {$_->min} @$array), "\n";
    }

    sub after_value_selection {
	my $self = shift;
	my ($result, $depth, $index, $vs, $array) = @_;
	# debug
	# print STDERR "after value selection: $result, $depth, $index, $array\n";
	# print STDERR "  ", $vs->[0], ", ", $vs->[1], "\n";
	# print STDERR join(", ", map {$_->min} @$array), "\n";
    }

    sub enter {
	my $self = shift;
	my ($depth, $index, $array) = @_;
	# debug
	# print STDERR "enter: $depth, $index, $array\n";
	# print STDERR join(", ", map {"$_"} @$array), "\n";
    }

    sub leave {
	my $self = shift;
	my ($depth, $index, $array) = @_;
	# debug
	# print STDERR "leave: $depth, $index, $array\n";
	# print STDERR join(", ", map {"$_"} @$array), "\n";
    }

    sub found {
	my $self = shift;
	my ($depth, $array) = @_;
	# debug
	# print STDERR "found: $depth, $array\n";
	# print STDERR join(", ", map {"$_"} @$array), "\n";
	return 1;
    }
    
    package main;
    my $obj = TestObj->new;
    my $sn = $iz->create_search_notify($obj);
    # print STDERR "perl obj = $obj, sn = $sn\n";
    my $vs = $iz->get_value_selector(&Algorithm::CP::IZ::CS_VALUE_SELECTOR_MIN_TO_MAX);
    $iz->save_context;
    my $rc1 = $iz->search([$d, $e, $n, $y, $m, $o, $r, $s],
			  {
			      ValueSelectors =>
				  [map { $vs } 1..8],
				  MaxFail => 100,
			      Notify => $sn,
			  });
    is($rc1, 1);

    is($called{search_start}, 1);
    is($called{search_end}, 1);
    is($called{search_end_solution}, "95671082");
    
    $iz->restore_context;


    # notify by hash
    my $search_start2 = 0;
    my $sn2 = $iz->create_search_notify(
	{
	    search_start => sub {
		$search_start2++;
	    }
	});

    $iz->save_context;
    my $rc2 = $iz->search([$d, $e, $n, $y, $m, $o, $r, $s],
			  {
			      ValueSelectors =>
				  [map { $vs } 1..8],
			      Notify => $sn2,
			  });
    
    is($search_start2, 1);
    is($rc2, 1);
	
    $iz->restore_context;


    # fail by found
    my $sn3 = $iz->create_search_notify(
	{
	    found => sub {
		return 0;
	    }
	});

    $iz->save_context;
    my $rc3 = $iz->search([$d, $e, $n, $y, $m, $o, $r, $s],
			  {
			      Notify => $sn3,
			  });
    
    is($rc3, 0);
	
    $iz->restore_context;

    # fail by found (specify hashref directly)
    $iz->save_context;
    my $rc4 = $iz->search([$d, $e, $n, $y, $m, $o, $r, $s],
			  {
			      Notify => {
				  found => sub { return 0; },
			      }
			  });
    
    is($rc4, 0);
	
    $iz->restore_context;
    
}
