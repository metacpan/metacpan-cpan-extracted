use strict;
use warnings;

use Test::More tests => 41;
    
{
    package Class;
    use Abstract::Meta::Class ':all'; storage_type 'Array';
    has '$.to_one'  => (associated_class => 'AssociatedClass');
    has '@.ordered' => (associated_class => 'AssociatedClass');
    has '%.to_many' => (associated_class => 'AssociatedClass', index_by => 'a', item_accessor => 'association');
}

{
    package AssociatedClass;
    use Abstract::Meta::Class ':all'; storage_type 'Array';
    has '$.a';
}

{
    eval {Class->new(to_one => bless({},'main') )};
    like($@, qr{to_one must be of the AssociatedClass type},  'should catch invalid assocated_class - to one type');
    my $obj = Class->new(to_one => AssociatedClass->new);
    isa_ok($obj, 'Class');
    ok($obj->has_to_one, 'should have value');
    $obj->reset_to_one;
    ok(! $obj->has_to_one, 'should have reset value');
}

{
    eval {Class->new(ordered => [bless({},'main')])};
    like($@, qr{ordered must be of the AssociatedClass type},  'should catch invalid assocated_class - ordered type' );
    my $obj = Class->new(ordered => [AssociatedClass->new]);
    isa_ok($obj, 'Class');
    ok($obj->has_ordered, 'should have value');
    $obj->reset_ordered;
    ok(! $obj->has_ordered, 'should have reset value');
}

{
    eval {Class->new(to_many => [bless({},'main')])};
    like($@, qr{to_many must be of the AssociatedClass type},  'should catch invalid assocated_class - to many type');
    my @associations = (AssociatedClass->new(a => '002'), AssociatedClass->new(a => '302'));
    my $obj = Class->new(to_many => \@associations);
    isa_ok($obj, 'Class');
    my @exp_association = values %{$obj->to_many};
    is_deeply([sort @associations], [sort @exp_association], 'should have associations');

    is($obj->association('002'), $associations[0], 'should have indexed association');
    is($obj->association('302'), $associations[1], 'should have indexed association');

    ok($obj->has_to_many, 'should have value');
    $obj->reset_to_many;
    ok(! $obj->has_to_many, 'should have reset value');

}


{
    package ClassA;
    use Abstract::Meta::Class ':all'; storage_type 'Array';
    has '$.to_oneA'  => (associated_class => 'AssociatedClassA', the_other_end => 'classAA' );
    has '$.to_one'  => (associated_class => 'AssociatedClassA', the_other_end => 'classA' );
    has '@.ordered' => (associated_class => 'AssociatedClassA');
    has '%.to_many' => (associated_class => 'AssociatedClassA', index_by => 'a', item_accessor => 'association');
}


{
    package AssociatedClassA;
    use Abstract::Meta::Class ':all'; storage_type 'Array';
    has '$.a';
    has '$.ordered_ClassA' => (associated_class => 'ClassA', the_other_end => 'ordered');
    has '$.to_many_ClassA' => (associated_class => 'ClassA', the_other_end => 'to_many');
    
    has '$.classAA';
    my $a1 = AssociatedClassA->new(a => 1);
    my $a2 = AssociatedClassA->new(a => 2);
    ;
    eval { ClassA->new(to_oneA => $a1) };
    ::like($@, qr{invalid definition for ClassA::to_oneA - associatied class not defined on AssociatedClassA::classAA.+},
           'should catch invalid definition on the other end attribute');

    
    eval { ClassA->new(to_one => $a1) };
    ::like($@, qr{missing other end attribute on AssociatedClassA::classA.+}, 'shuould catch the invalid other end definition');
    has '$.classA' => (associated_class => 'ClassA', the_other_end => 'to_one');
    
    {
        my $clazz = ClassA->new(to_one => $a1);
        ::is($a1, $clazz->to_one, 'should associate');
        $clazz->to_one($a2);
        ::is($a2, $clazz->to_one, 'should deassociate the other end (scalar)');
        ::is($a2->classA, $clazz, 'should associate the other end (scalar)');
    }
    
    {
        my $clazz = ClassA->new(ordered => [$a1, $a2]);
        ::ok((grep {$_ eq $a1} $clazz->ordered), 'should associate the other end (array)');
    }

    {
        my $clazz = ClassA->new(to_many => [$a1, $a2]);
        ::ok((grep {$_ eq $a1} values %{$clazz->to_many}), 'should associate the other end (hash)');
    }


        #THE OTHER END BIDIRECTIONAL ASSOCIATION, DEASSOCIATION
    {
        package Master;
        use Abstract::Meta::Class ':all'; storage_type 'Array';
        has '$.name' => (required => 1);
        has '%.details' => (
            associated_class => 'Detail',
            index_by         => 'id',
            item_accessor    => 'detail',
            the_other_end    => 'master',
        );
    }

    {
        package Detail;
        use Abstract::Meta::Class ':all'; storage_type 'Array';
        has '$.id'     => (required => 1);
        has '$.master' => (
            associated_class => 'Master',
            the_other_end    => 'details'
        );
    }
    
    {
        my @details = (Detail->new(id => 1), Detail->new(id => 2,), Detail->new(id => 3));
        my $master = Master->new(name => 'master', details => [@details]);
        $master->remove_details($details[1]);
        ::ok(! $details[1]->master, 'should deassociate relationship');
        my $detauls = $master->details;
        ::is_deeply($detauls, {1=> $details[0], 3 => $details[-1]}, 'should remove details');
        $master->remove_details(3);
        ::ok(! $details[2]->master, 'should deassociate relationship');
    }
    
    
    
    

    {    
        my @details  = (
            Detail->new(id => 1),
            Detail->new(id => 2),
            Detail->new(id => 3),
        );
        
        my $master = Master->new(name    => 'foo', details => [@details]);
        ::is($details[$_]->master, $master, "should associate by biderectional def") for (0 .. 2);
        
        my $master2 = Master->new(name    => 'foo2');
        $details[-1]->set_master($master2);
        my @detail1 = values %{$master->details};
        my @details_ids1 = keys %{$master->details};
        
        ::is_deeply([sort @detail1], [sort @details[0 .. 1]], 'should have 2 details elements');
        ::is_deeply([sort @details_ids1], [1,2], 'should have 2 details index');
        ::is($master2->detail(3), $details[-1], "should have details");
    }



        #THE OTHER END BIDIRECTIONAL ASSOCIATION, DEASSOCIATION
    {
        package MasterA;
        use Abstract::Meta::Class ':all'; storage_type 'Array';
        has '$.name' => (required => 1);
        has '@.details' => (
            associated_class => 'DetailA',
            index_by         => 'id',
            item_accessor    => 'detail',
            the_other_end    => 'master',
        );
    }

    {
        package DetailA;
        use Abstract::Meta::Class ':all'; storage_type 'Array';
        has '$.id'     => (required => 1);
        has '$.master' => (
            associated_class => 'MasterA',
            the_other_end    => 'details'
        );
    }

    {    
        my @details  = (
            DetailA->new(id => 1),
            DetailA->new(id => 2),
            DetailA->new(id => 3),
        );
        
        my $master = MasterA->new(name    => 'foo', details => [@details]);
        ::is($details[$_]->master, $master, "should associate by biderectional def") for (0 .. 2);
        
        my $master2 = MasterA->new(name    => 'foo2');
        $details[-1]->set_master($master2);
        my @detail1 = $master->details;
        
        ::is_deeply(\@detail1, [@details[0 .. 1]], 'should have 2 details elements');
        ::is($master2->detail(0), $details[-1], "should have details");
        
        
        
        $master->cleanup;
        ::is($_->master, undef, 'should be deassociiated') for @details[0 .. 1];
        
        my $details = $master->details;
        ::is_deeply($details, [], 'should not have details association');
    }


    {    
        my @details  = (
            DetailA->new(id => 1),
            DetailA->new(id => 2),
            DetailA->new(id => 3),
        );
        
        my $master = MasterA->new(name    => 'foo', details => [@details]);
        $master->remove_details($details[1]);
        ::ok($details[1]->master, 'should deassociate the other end');
        my $details = $master->details;
        ::is_deeply($details, [$details[0], $details[-1]], 'should remove object');
    }

}
