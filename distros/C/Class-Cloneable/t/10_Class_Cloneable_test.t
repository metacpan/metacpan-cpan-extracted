#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 95;

BEGIN { 
    use_ok('Class::Cloneable');
}

{ # basic object, with no cloning
    package ObjectWithoutClone; 
    sub new { bless { no_clone => 1 } }
}

{ # basic object with its own clone method
    package ObjectWithClone;
    sub new   { bless { clone => 1 } }
    sub clone { bless { clone => 1 } }
}

{ # basic cloneable subclass
    package CloneableObject;
    our @ISA = ('Class::Cloneable');
    sub new { bless { cloneable => 1 } }
}

{ # Tied Hash test
    package TiedHashTest;
    # copied straight from Tie::StdHash
    sub TIEHASH  { bless {}, $_[0] }
    sub STORE    { $_[0]->{$_[1]} = $_[2] }
    sub FETCH    { $_[0]->{$_[1]} }
    sub FIRSTKEY { my $a = scalar keys %{$_[0]}; each %{$_[0]} }
    sub NEXTKEY  { each %{$_[0]} }
    sub EXISTS   { exists $_[0]->{$_[1]} }
    sub DELETE   { delete $_[0]->{$_[1]} }
    sub CLEAR    { %{$_[0]} = () }
    sub SCALAR   { scalar %{$_[0]} }   
}

{ # Tied Hash test
    package TiedArrayTest;
    # copied straight from Tie::StdArray
    sub TIEARRAY  { bless [], $_[0] }
    sub FETCHSIZE { scalar @{$_[0]} }
    sub STORESIZE { $#{$_[0]} = $_[1]-1 }
    sub STORE     { $_[0]->[$_[1]] = $_[2] }
    sub FETCH     { $_[0]->[$_[1]] }
    sub CLEAR     { @{$_[0]} = () }
    sub POP       { pop(@{$_[0]}) }
    sub PUSH      { my $o = shift; push(@$o,@_) }
    sub SHIFT     { shift(@{$_[0]}) }
    sub UNSHIFT   { my $o = shift; unshift(@$o,@_) }
    sub EXISTS    { exists $_[0]->[$_[1]] }
    sub DELETE    { delete $_[0]->[$_[1]] }
    sub EXTEND    {}
    sub SPLICE    {}
}

{ # Tied Hash test
    package TiedScalarTest;
    sub TIESCALAR { my $var; bless \$var, $_[0] }    
    sub FETCH   { ${$_[0]} }
    sub STORE   { ${$_[0]} = $_[1] }
    sub DESTROY { undef ${$_[0]} }
}

{ # test cloneable object
    package CloneableTest;
    our @ISA = ('Class::Cloneable');
    
    sub new {
        my ($class) = @_;
        my $scalar = "Test";
        my %hash_to_tie   = ( tied_hash => 1 );
        tie %hash_to_tie, 'TiedHashTest';
        my @array_to_tie  = (1, 2, 3, 4);
        tie @array_to_tie, 'TiedArrayTest';
        my $scalar_to_tie; 
        tie $scalar_to_tie, 'TiedScalarTest';
        $scalar_to_tie = "Tie Me";
        my $cloneable = bless {
            hash             => { one => 1 },
            array            => [ 1, 2, 3 ],
            scalar_ref       => \$scalar,
            weak_scalar_ref  => \$scalar,            
            scalar           => "Test",
            nested_hash      => { level_one => { level_two => { level_three => { level_four => undef }}}},
            nested_array     => [ 1, [ 2, [ 3, [ 4 ]]]],
            tied_hash        => \%hash_to_tie,
            tied_array       => \@array_to_tie,
            tied_scalar      => \$scalar_to_tie,
            code_ref         => sub { "hello" },
            regexp_ref       => qr/(.*?)/,
            glob_ref         => \*new,
            object_wo_clone  => ObjectWithoutClone->new(),
            object_w_clone   => ObjectWithClone->new(),
            cloneable_object => CloneableObject->new()
            }, $class;
        Scalar::Util::weaken($cloneable->{weak_scalar_ref});
        $cloneable->{ref_to_ref} = \$cloneable->{scalar_ref};    
        return $cloneable;
    }
}

{ # test cloneable object w/ overloading
    package OverloadedCloneableTest;
    our @ISA = ('CloneableTest');
    use overload '""' => "toString";
    sub toString { "This is my overloaded stringification method" }
}

# clone testing function
sub test_clone {
    my ($test, $clone) = @_;
    isnt($test->{hash},         $clone->{hash}, '... shallow hash clone was successful');
    is_deeply($test->{hash},    $clone->{hash}, '... shallow hash clone matches original');
    
    isnt($test->{array},        $clone->{array}, '... shallow array clone was successful');
    is_deeply($test->{array},   $clone->{array}, '... shallow array clone matches original');
    
    isnt($test->{scalar_ref},   $clone->{scalar_ref}, '... scalar ref clone was successful');
    is(${$test->{scalar_ref}},  ${$clone->{scalar_ref}}, '... scalar ref clone was successful');
    
    isnt($test->{weak_scalar_ref},   $clone->{weak_scalar_ref}, '... scalar ref clone was successful');
    is(${$test->{weak_scalar_ref}},  ${$clone->{weak_scalar_ref}}, '... scalar ref clone was successful'); 
    
    ok(Scalar::Util::isweak($test->{weak_scalar_ref}), '... properly cloned the weak ref-ness too');   
        
    isnt($test->{ref_to_ref},     $clone->{ref_to_ref}, '... ref of ref clone was successful');    
    is(${${$test->{ref_to_ref}}}, ${${$clone->{ref_to_ref}}}, '... ref of ref clone matches original');    
        
    is($test->{scalar},         $clone->{scalar},     '... scalar clone was successful');
    
    isnt($test->{nested_hash},       $clone->{nested_hash}, '... nested hash clone was successful');
    is_deeply($test->{nested_hash},  $clone->{nested_hash}, '... nested hash clone matches original');
    
    isnt($test->{nested_array},      $clone->{nested_array}, '... nested array clone was successful');
    is_deeply($test->{nested_array}, $clone->{nested_array}, '... nested array clone matches original');
    
    isnt($test->{tied_hash},   $clone->{tied_hash}, '... tied hash clone was successful');
    ok(tied(%{$clone->{tied_hash}}), '... tied hash clone was successful');
    is(ref(tied(%{$clone->{tied_hash}})), 'TiedHashTest', '... tied hash clone was successful');
    
    isnt($test->{tied_array},  $clone->{tied_array}, '... tied array clone was successful');
    ok(tied(@{$clone->{tied_array}}), '... tied array clone was successful');
    is(ref(tied(@{$clone->{tied_array}})), 'TiedArrayTest', '... tied array clone was successful');

    isnt($test->{tied_scalar}, $clone->{tied_scalar}, '... tied scalar clone was successful');
    ok(tied(${$clone->{tied_scalar}}), '... tied scalar clone was successful');
    is(ref(tied(${$clone->{tied_scalar}})), 'TiedScalarTest', '... tied scalar clone was successful');
    
    is($test->{code_ref},        $clone->{code_ref},   '... code ref clone was successful');
    is($test->{regexp_ref},      $clone->{regexp_ref}, '... regexp ref clone was successful');
    is($test->{glob_ref},        $clone->{glob_ref},   '... glob ref clone was successful');
    
    is($test->{object_wo_clone}, $clone->{object_wo_clone}, '... object w/out clone method clone was successful');
    
    isnt($test->{object_w_clone},   $clone->{object_w_clone},   '... object with clone method clone was successful');
    isnt($test->{cloneable_object}, $clone->{cloneable_object}, '... Class::Cloneable clone was successful');
}

## TESTS

# now test the base cloneable
{
    can_ok("CloneableTest", 'new');
    my $test = CloneableTest->new();
    isa_ok($test, 'CloneableTest');
    isa_ok($test, 'Class::Cloneable');
    can_ok($test, 'clone');
    my $clone = $test->clone();
    test_clone($test, $clone);
}

# test it with an overloaded base object
{
    can_ok("OverloadedCloneableTest", 'new');
    my $test = OverloadedCloneableTest->new();
    isa_ok($test, 'OverloadedCloneableTest');
    isa_ok($test, 'CloneableTest');
    isa_ok($test, 'Class::Cloneable');
    can_ok($test, 'clone');
    my $clone = $test->clone();
    test_clone($test, $clone);
}

# test all the exceptions
{
    can_ok("CloneableTest", 'new');
    my $test = CloneableTest->new();
    isa_ok($test, 'CloneableTest');
    isa_ok($test, 'Class::Cloneable');
         
    eval {
        Class::Cloneable::Util::clone();
    };
    like($@, qr/Illegal Operation \: This method can only be called by a subclass of Class\:\:Cloneable/, 
         '... got the error we expected');      
         
    eval {
        Class::Cloneable::Util::cloneObject();
    };
    like($@, qr/Illegal Operation \: This method can only be called by a subclass of Class\:\:Cloneable/, 
         '... got the error we expected');   
         
    eval {
        Class::Cloneable::Util::cloneRef();
    };
    like($@, qr/Illegal Operation \: This method can only be called by a subclass of Class\:\:Cloneable/, 
         '... got the error we expected'); 
         
    {
        package CloneableExceptionTest;
        
        sub clone { Class::Cloneable::Util::clone(@_) }
        sub cloneObject { Class::Cloneable::Util::cloneObject(@_) }
        sub cloneRef { Class::Cloneable::Util::cloneRef(@_) }
    }
    
    eval {
        CloneableExceptionTest::clone();
    };
    like($@, qr/Illegal Operation \: This method can only be called by a subclass of Class\:\:Cloneable/, 
         '... got the error we expected');
         
    eval {
        CloneableExceptionTest::cloneObject();
    };
    like($@, qr/Illegal Operation \: This method can only be called by a subclass of Class\:\:Cloneable/, 
         '... got the error we expected');   
         
    eval {
        CloneableExceptionTest::cloneRef();
    };
    like($@, qr/Illegal Operation \: This method can only be called by a subclass of Class\:\:Cloneable/, 
         '... got the error we expected');  
         
    {
        package CloneableArgumentExceptionTest;
        our @ISA = ('Class::Cloneable');
        
        sub clone { Class::Cloneable::Util::clone(@_) }
        sub cloneObject { Class::Cloneable::Util::cloneObject(@_) }
        sub cloneRef { Class::Cloneable::Util::cloneRef(@_) }
    }
    
    eval {
        CloneableArgumentExceptionTest::clone(undef);
    };
    like($@, qr/Insufficient Arguments \: Must specify the object to clone/, 
         '... got the error we expected');               
         
    eval {
        CloneableArgumentExceptionTest::cloneObject(undef, undef);
    };
    like($@, qr/Insufficient Arguments \: Must specify the object to clone and a valid cache/, 
         '... got the error we expected');  
         
    eval {
        CloneableArgumentExceptionTest::cloneObject("Fail", undef);
    };
    like($@, qr/Insufficient Arguments \: Must specify the object to clone and a valid cache/, 
         '... got the error we expected');   

    eval {
        CloneableArgumentExceptionTest::cloneObject([], undef);
    };
    like($@, qr/Insufficient Arguments \: Must specify the object to clone and a valid cache/, 
         '... got the error we expected');    
         
    eval {
        CloneableArgumentExceptionTest::cloneObject([], "Fail");
    };
    like($@, qr/Insufficient Arguments \: Must specify the object to clone and a valid cache/, 
         '... got the error we expected');                    
         
    eval {
        CloneableArgumentExceptionTest::cloneObject([], []);
    };
    like($@, qr/Insufficient Arguments \: Must specify the object to clone and a valid cache/, 
         '... got the error we expected');                                                             
         
    eval {
        CloneableArgumentExceptionTest::cloneRef(undef, undef);
    };
    like($@, qr/Insufficient Arguments \: Must specify the object to clone and a valid cache/, 
         '... got the error we expected');  
         
    eval {
        CloneableArgumentExceptionTest::cloneRef("Fail", undef);
    };
    like($@, qr/Insufficient Arguments \: Must specify the object to clone and a valid cache/, 
         '... got the error we expected');   

    eval {
        CloneableArgumentExceptionTest::cloneRef([], undef);
    };
    like($@, qr/Insufficient Arguments \: Must specify the object to clone and a valid cache/, 
         '... got the error we expected');    
         
    eval {
        CloneableArgumentExceptionTest::cloneRef([], "Fail");
    };
    like($@, qr/Insufficient Arguments \: Must specify the object to clone and a valid cache/, 
         '... got the error we expected');                    
         
    eval {
        CloneableArgumentExceptionTest::cloneRef([], []);
    };
    like($@, qr/Insufficient Arguments \: Must specify the object to clone and a valid cache/, 
         '... got the error we expected');
         
    # now just test some general weirdness
    # mostly for the sake of code coverage
   
    is_deeply(
        CloneableArgumentExceptionTest::clone("Test"),
        "Test",
        '... cloned as expected');     
      
    is_deeply(
        CloneableArgumentExceptionTest::clone([]),
        [],
        '... cloned as expected');     

    my $misc_obj = bless({}, 'Test');
    is(CloneableArgumentExceptionTest::clone($misc_obj),
        $misc_obj,
        '... cloned as expected');     
                    
}