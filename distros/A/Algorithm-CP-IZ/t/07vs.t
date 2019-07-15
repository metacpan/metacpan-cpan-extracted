use strict;
use warnings;

use Test::More tests => 41;
BEGIN { use_ok('Algorithm::CP::IZ') };
BEGIN { use_ok('Algorithm::CP::IZ::ValueSelector') };

use Algorithm::CP::IZ qw(:value_selector);


SKIP: {
    my $iz = Algorithm::CP::IZ->new;
    skip "old iZ", 7
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);
		
    my $v = $iz->create_int(0, 2);

    my $vs = $iz->get_value_selector(CS_VALUE_SELECTOR_MIN_TO_MAX);
    my $vsi = $vs->init(0, [$v]);

    my ($meth, $val);

    ($meth, $val) = $vsi->next; # 0
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, 0);

    ($meth, $val) = $vsi->next; # 1
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, 1);

    ($meth, $val) = $vsi->next; # 2
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, 2);

    ok(!defined($vsi->next));
}

SKIP: {
    my $iz = Algorithm::CP::IZ->new;
    skip "old iZ", 14
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);

    my $v = $iz->create_int(0, 2);

    my $vs = $iz->get_value_selector(CS_VALUE_SELECTOR_MAX_TO_MIN);
    my $vsi = $vs->init(0, [$v]);

    my ($meth, $val);

    ($meth, $val) = $vsi->next; # 2
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, 2);

    ($meth, $val) = $vsi->next; # 1
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, 1);

    ($meth, $val) = $vsi->next; # 0
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, 0);

    ok(!defined($vsi->next));

    # twice
    $vsi = $vs->init(0, [$v]);

    ($meth, $val) = $vsi->next; # 2
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, 2);

    ($meth, $val) = $vsi->next; # 1
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, 1);

    ($meth, $val) = $vsi->next; # 0
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, 0);

    ok(!defined($vsi->next));
}

SKIP: {
    my $iz = Algorithm::CP::IZ->new;

    skip "old iZ", 0
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);

    package TestVS1;
    sub new {
	my $class = shift;
	my ($v, $index) = @_;

	my $self = {
	    _pos => 0,
	};
	bless $self, $class;
    }

    sub next {
	my $self = shift;
	my ($v, $index) = @_;

	my $pos = $self->{_pos};
	my $domain = $v->domain;
	return if ($pos >= @$domain);

	my @ret = (Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ, $domain->[$pos]);
	$self->{_pos} = ++$pos;

	return @ret;
    }

    sub DESTROY {
    }

    package main;
}

SKIP: {
    my $iz = Algorithm::CP::IZ->new;

    skip "old iZ", 0
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);

    my $obj = $iz->create_value_selector_simple("TestVS1");
    
    my $v = $iz->create_int(0, 2);
    # my $vsi = $obj->init(0, [$v]);
    # print $vsi->next;
    $iz = undef;
}

SKIP: {
    my $iz = Algorithm::CP::IZ->new();

    skip "old iZ", 13
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);

    my $vs = $iz->create_value_selector_simple("TestVS1");
    my $v1 = $iz->create_int(-2, 1);
    my $v2 = $iz->create_int(3);

    my $vs1 = $vs->init(0, [$v1, $v2]);
    my ($meth, $val);
    ($meth, $val) = $vs1->next;
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, -2);
    ($meth, $val) = $vs1->next;
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, -1);
    ($meth, $val) = $vs1->next;
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, 0);
    ($meth, $val) = $vs1->next;
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, 1);
    ($meth, $val) = $vs1->next;
    ok(!defined($vs1->next));

    my $vs2 = $vs->init(1, [$v1, $v2]);
    ($meth, $val) = $vs2->next;
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    is($val, 3);
    is($meth, Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ);
    ok(!defined($vs2->next));
}


SKIP: {
    my $iz = Algorithm::CP::IZ->new();

    skip "old iZ", 3
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);

    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 5);
    $iz->AllNeq([$v1, $v2]);

    my $vs = $iz->create_value_selector_simple("TestVS1");
    my $label = $iz->save_context();
    my $rc = $iz->search([$v1, $v2],
			 { ValueSelectors
			       => [$vs, $vs], }
	);

    is($rc, 1);
    is($v1->value, 0);
    is($v2->value, 1);
}

# bad value 1
SKIP: {
    my $iz = Algorithm::CP::IZ->new;

    skip "old iZ", 0
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);

    package TestVS2;
    sub new {
	my $class = shift;
	my ($v, $index) = @_;

	my $self = {
	    _pos => 0,
	};
	bless $self, $class;
    }

    sub next {
	my $self = shift;
	my ($v, $index) = @_;

	my $pos = $self->{_pos};
	my $domain = $v->domain;
	return if ($pos >= @$domain);

	my @ret = (Algorithm::CP::IZ::CS_VALUE_SELECTION_EQ, undef);
	$self->{_pos} = ++$pos;

	return @ret;
    }

    sub DESTROY {
    }

    package main;

    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 5);
    my $vs = $iz->create_value_selector_simple("TestVS");

    eval {
	my $rc = $iz->search([$v1, $v2],
			     { ValueSelectors
				   => [$vs, $vs], }
	    );
    };

    # error
    ok($@);
}

# bad value 2
SKIP: {
    my $iz = Algorithm::CP::IZ->new;

    skip "old iZ", 0
	unless (defined($iz->get_version)
		&& $iz->IZ_VERSION_MAJOR >= 3
		&& $iz->IZ_VERSION_MINOR >= 6);

    package TestVS3;
    sub new {
	my $class = shift;
	my ($v, $index) = @_;

	my $self = {
	    _pos => 0,
	};
	bless $self, $class;
    }

    sub next {
	my $self = shift;
	my ($v, $index) = @_;

	my $pos = $self->{_pos};
	my $domain = $v->domain;
	return if ($pos >= @$domain);

	my @ret = ("*", 3);
	$self->{_pos} = ++$pos;

	return @ret;
    }

    sub DESTROY {
    }

    package main;

    my $v1 = $iz->create_int(0, 10);
    my $v2 = $iz->create_int(0, 5);
    my $vs = $iz->create_value_selector_simple("TestVS");

    eval {
	my $rc = $iz->search([$v1, $v2],
			     { ValueSelectors
				   => [$vs, $vs], }
	    );
    };

    # error
    ok($@);
}
