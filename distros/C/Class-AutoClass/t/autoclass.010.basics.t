use strict;
use lib qw(t);
use Test::More;
use Test::Deep;
use Storable qw(dclone);
use Hash::AutoHash::Args;
use autoclassUtil;
use autoclass_010::Parent;

# test basics: create objects, get and set attributes, try each method

# cmp_object tests state of object: defined attrs and their values
# $actual is object. $correct is HASH of atttr=>value pairs wih Test::Deep decorations
sub cmp_object {
  my($actual,$correct,$label,$quiet)=@_;
  my($package,$file,$line)=caller; # for fails
  my $ok=1;
  $ok&&=cmp_can($actual,$correct,$label,$file,$line);
  $ok&&=cmp_attrs($actual,$correct,$label,$file,$line);
  report_pass($ok,$label) unless $quiet;
  $ok;
}
# cmp_values tests values extracted ('gotten') from object
# $actual, $correct are HASHes of atttr=>value pairs
sub cmp_values {
  my($actual,$correct,$label)=@_;
  my($package,$file,$line)=caller; # for fails
  my $ok=1;
  $ok&&=cmp_hashes($actual,$correct,$label,$file,$line);
  report_pass($ok,$label);
}
my @attrs=qw(auto real auto_dflt real_dflt 
	     other other_dflt 
	     class class_dflt 
	     syn syn_dflt);
my %defaults=(auto_dflt=>'auto attribute default',
	      other_dflt=>['other attribute default'],
	      class_dflt=>'class attribute default',
	      syn_dflt=>'synonym default',
	      real_dflt=>'real default',);
my @class_attrs=qw(class class_dflt);
my %class_defaults=(class_dflt => 'class attribute default');

sub correct (\@\%%) {
  my($attrs,$defaults)=splice(@_,0,2);
  my %defined_attrs=@_;
  # copy $defaults so values not clobbered...
  $defaults=dclone($defaults);
  my $correct={(map {$_=>undef} @$attrs),%$defaults};
  # 'other' attributes are special: setter pushes new value onto old
  while(my($attr,$value)=each %defined_attrs) {
    if ($attr=~/^other/ && 'ARRAY' ne ref $value) {
      push (@{$correct->{$attr}},$value);
    } else {
      $correct->{$attr}=$value;
    }
  }
  while(my($attr,$value)=each %$correct) {
    # 'syn' and 'real' attributes are special
    # if both set, either value ok. if one set, other must match
    if ($attr=~/^real/) {
      my($suffix)=$attr=~/^real(.*)$/;
      my $syn_value=$correct->{"syn$suffix"};
      if (defined $value && defined $syn_value) { # both can have either value
	$correct->{$attr}=$correct->{"syn$suffix"}=any($value,$syn_value);
      } elsif (defined $value || defined $syn_value) { # both must match
	($value)=grep {defined $_} ($value,$syn_value);
	$correct->{$attr}=$correct->{"syn$suffix"}=$value;
      }}}
  $correct;
}

my $object=new autoclass_010::Parent;
isa_ok($object,'autoclass_010::Parent','new');

# defaults
cmp_object($object,correct(@attrs,%defaults),'defaults');

# get & set each attribute one-by-one
# first get initial values
my(@ok,@bad);
my $correct=correct(@attrs,%defaults);
for my $attr (@attrs) {
  my $before=$object->$attr;
  eq_deeply($before,$correct->{$attr})? push(@ok,$attr): push(@bad,$attr);
}
report(!@bad,'get initial values one-by-one',__FILE__,__LINE__,"attributes '@bad' wrong");
# now set each attribute
my(@ok,@bad);
my $correct;
for my $attr (@attrs) {
  my $value="$attr set value";
  my $after=$object->$attr($value);
  if ($attr=~/^other/) {
    $value=[$value];
    my $default=$defaults{$attr};
    unshift(@$value,@$default) if defined $default;
  }
  $correct->{$attr}=$value;
  eq_deeply($after,$correct->{$attr})? push(@ok,$attr): push(@bad,$attr);
}
report(!@bad,'set values one-by-one',__FILE__,__LINE__,"attributes '@bad' wrong");
# finally get new values
my(@ok,@bad);
my $correct=correct(@attrs,%defaults,map {$_=>"$_ set value"} @attrs);
for my $attr (@attrs) {
  my $after=$object->$attr;
  eq_deeply($after,$correct->{$attr})? push(@ok,$attr): push(@bad,$attr);
}
report(!@bad,'get new values one-by-one',__FILE__,__LINE__,"attributes '@bad' wrong");

# get class attributes by class
my(@ok,@bad);
my $correct=correct(@class_attrs,%defaults,map {$_=>"$_ set value"} @class_attrs);
for my $attr (@class_attrs) {
  my $after=autoclass_010::Parent->$attr;
  eq_deeply($after,$correct->{$attr})? push(@ok,$attr): push(@bad,$attr);
}
report(!@bad,'get class attributes via class one-by-one',__FILE__,__LINE__,"attributes '@bad' wrong");

# set attributes in 'new' - one at a time
my(@ok,@bad);
for my $attr (@attrs) {
  my $value="$attr new value";
  my $object=new autoclass_010::Parent $attr=>$value;
  # note: this sets class attributes to previous value unless being set here
  # makes sure 'other' attribute set to new value even if default
  $value=[$value] if $attr=~/^other/;
  my $correct=correct(@attrs,%defaults,
		      (map {$_=>autoclass_010::Parent->$_} @class_attrs),
		      $attr=>$value);
  cmp_object($object,$correct,"set attribute $attr via new",'quiet')? 
    push(@ok,$attr): push(@bad,$attr);
}
report(!@bad,'set attributes via new one-by-one',__FILE__,__LINE__,"attributes '@bad' wrong");

# set attributes in 'new' - all at once
my %args=map {$_=>"$_ new value"} @attrs;
my $object=new autoclass_010::Parent %args;
my $correct=correct(@attrs,%defaults,
		    (map {$_=>/^other/? ["$_ new value"]: "$_ new value"}
		     @attrs));
cmp_object($object,$correct,"set attributes via new all at once");

# set attributes via 'set' method - one at a time
my(@ok,@bad);
for my $attr (@attrs) {
  my $value="$attr set value";
  my $object=new autoclass_010::Parent;
  $object->set($attr=>$value);
  # note: this sets class attributes to previous value unless being set here
  my $correct=correct(@attrs,%defaults,
		      (map {$_=>autoclass_010::Parent->$_} @class_attrs),
		      $attr=>$value);
  cmp_object($object,$correct,"set attribute $attr via set",'quiet')? 
    push(@ok,$attr): push(@bad,$attr);
}
report(!@bad,'set attributes via set one-by-one',__FILE__,__LINE__,"attributes '@bad' wrong");

# set attributes via 'set' - all at once
my %args=map {$_=>"$_ set value"} @attrs;
my $object=new autoclass_010::Parent;
$object->set(%args);
my $correct=correct(@attrs,%defaults, (map {$_=>"$_ set value"} @attrs));
cmp_object($object,$correct,"set attributes via set all at once");

# set attributes via 'set_attribuutes' method - one at a time
my(@ok,@bad);
my %args=map {$_=>"$_ set value"} @attrs;
my $args=new Hash::AutoHash::Args %args;
for my $attr (@attrs) {
  my $value="$attr set value";
  my $object=new autoclass_010::Parent;
  $object->set_attributes([$attr],$args);
  # note: this sets class attributes to previous value unless being set here
  my $correct=correct(@attrs,%defaults,
		      (map {$_=>autoclass_010::Parent->$_} @class_attrs),
		      $attr=>$value);
  cmp_object($object,$correct,"set attribute $attr via set_attributes",'quiet')? 
    push(@ok,$attr): push(@bad,$attr);
}
report(!@bad,'set attributes via set_attributes one-by-one',
       __FILE__,__LINE__,"attributes '@bad' wrong");

# set attributes via 'set_attributes' - all at once
my %args=map {$_=>"$_ set value"} @attrs;
my $args=new Hash::AutoHash::Args %args;
my $correct=correct(@attrs,%defaults, (map {$_=>"$_ set value"} @attrs));
my $object=new autoclass_010::Parent;
$object->set_attributes(\@attrs,$args);
cmp_object($object,$correct,"set attributes via set_attributes all at once");

# do it again with some superfluous attributes.
my $object=new autoclass_010::Parent;
$object->set_attributes([@attrs,qw(fee fie foe fum)],$args);
cmp_object($object,$correct,"set attributes via set_attributes with superfluous attributes");

# get attributes via 'get' method - one at a time
# first set 'em all
my $object=new autoclass_010::Parent;
$object->set(map {$_=>"$_ set value"} @attrs);
# now get 'em one-by-one
my(@ok,@bad);
my $correct=correct(@attrs,%defaults,map {$_=>"$_ set value"} @attrs);
for my $attr (@attrs) {
  my $actual=$object->get($attr);
  eq_deeply($actual,$correct->{$attr})? push(@ok,$attr): push(@bad,$attr);
}
report(!@bad,'get new values via get one-by-one',__FILE__,__LINE__,"attributes '@bad' wrong");

# get attributes via 'get' - all at once
# first set 'em all
my $object=new autoclass_010::Parent;
$object->set(map {$_=>"$_ set value"} @attrs);
# now get 'em all at once
my $actual;
@$actual{@attrs}=$object->get(@attrs);
cmp_values($actual,$correct,'get new values via get all at once');

done_testing();
