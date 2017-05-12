######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}
use Class::Delegate;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

@Stub::ISA  = 'Class::Delegate';
my $stub    = bless {}, 'Stub';

sub Stub::a                 { return 'Stub::a' }

sub Stub::hello             { return 'hello' }


sub Delegate1::b            { return "Delegate1::b" }

sub Delegate2::b            { return "Delegate2::b" }

sub Delegate1::c            { return "Delegate1::c" }

sub Delegate2::set_owner
{
    my ($self, $owner)  = @_;
    
    $$self{owner}   = $owner;
}

sub Delegate2::talk_to_owner
{
    my ($self)  = @_;

    $$self{owner}->hello;
}

@Delegate3::PUBLIC  = qw(d);

sub Delegate3::c            { return "Delegate3::c" }


$stub->add_delegate(bless({}, 'Delegate1'));
$stub->add_delegate(visible => bless({}, 'Delegate2'));
$stub->add_delegate(bless{}, 'Delegate3');


my $return;

### First, let's see if call-throughs to a(), b(), and c() do the
### right thing.
# The `a' method should call Stub::a():
eval { $return = $stub->a };
if ($@ or $return ne 'Stub::a' )        { print "not ok 2\n" }
else                                    { print "ok 2\n" }

# The `b' method is ambiguous; calling it should fail:
eval { $return = $stub->b };
if ($@)                                 { print "ok 3\n" }
else                                    { print "not ok 3\n" }

# The `c' method should call Delegate1::c():
eval { $return = $stub->c };
if ($@ or $return ne 'Delegate1::c')    { print "not ok 4\n" }
else                                    { print "ok 4\n" }

### Let's do some introspection.
# Can we find the delegate named `visible'?
if (ref $stub->delegate('visible'))     { print "ok 5\n" }
else                                    { print "not ok 5\n" }

### Disambiguate the `b' method, so that it will call Delgate2::b():
$stub->resolve('b', 'visible');
eval { $return = $stub->b };
if ($@ or $return ne 'Delegate2::b')    { print "not ok 6\n" }
else                                    { print "ok 6\n" }

### Test the callback mechanism:
if ($stub->delegate('visible')->talk_to_owner eq 'hello') {
    print "ok 7\n";
} else {
    print "not ok 7\n";
}


### Just some diagnostics, no test here:
my (%delegates) = $stub->_delegates;

print "\nDelegation table:\n";
foreach (sort keys %delegates) {
    if ("$_" eq "$delegates{$_}") {
        printf "%-30s  %s\n", '(anonymous)', $delegates{$_};
    } else {
        printf "%-30s  %s\n", $_, $delegates{$_};
    }
}

