use lib qw(t);
use Carp;
use Class::AutoClass;
use Test::More;
use Test::Deep;

################################################################################
# SYNOPSIS
################################################################################

# code that defines class
#
package Person;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES 
	    %SYNONYMS %DEFAULTS);
@AUTO_ATTRIBUTES=qw(first_name last_name sex friends);
@OTHER_ATTRIBUTES=qw(full_name);
@CLASS_ATTRIBUTES=qw(count);
%DEFAULTS=(friends=>[]);
%SYNONYMS=(gender=>'sex',name=>'full_name');
Class::AutoClass::declare;

# method to perform non-standard initialization, if any
sub _init_self {
  my ($self,$class,$args) = @_;
  return unless $class eq __PACKAGE__;
  # any non-standard initialization goes here
  $self->count($self->count + 1); # increment number of objects created
}

# implementation of non-automatic attribute 'full_name' 
# computed from first_name and last_name
sub full_name {
  my $self=shift;
  if (@_) {		 # to set full_name, have to set first & last 
    my $full_name=shift;
    my($first_name,$last_name)=split(/\s+/,$full_name);
    $self->first_name($first_name);
    $self->last_name($last_name);
  }
  return join(' ',$self->first_name,$self->last_name);
}
########################################
# code that uses class
#
package main;			# not in docs. needed for testing
use Test::More;			# not in docs. needed for testing
use Test::Deep;			# not in docs. needed for testing
use Hash::AutoHash::Args;	# not in docs. needed for testing
use autoclassUtil;		# not in docs. needed for testing

####################
# SYNOPSIS
# use Person;
my $john=new Person(name=>'John Smith',sex=>'M');
isa_ok($john,'Person','object is Person');
my $ok=cmp_attrs($john,
		 {full_name=>'John Smith',name=>'John Smith',
		  first_name=>'John',last_name=>'Smith',
		  sex=>'M',gender=>'M',friends=>[]},
		 'new Person');
report($ok,'new Person',__FILE__,__LINE__);

my $first_name=$john->first_name; # 'John'
my $gender=$john->gender;         # 'M'
my $friends=$john->friends;       # []
$john->last_name('Doe');          # set last_name
my $name=$john->name;             # 'John Doe'
my $count=$john->count;           # 1

cmp_deeply([$first_name,$gender,$friends,$name,$count],['John','M',[],'John Doe',1],
	   'get and set attributes');

####################
# DESCRIPTION
my $john=new Person(first_name=>'John',last_name=>'Smith');
my $ok=cmp_attrs($john,
		 {full_name=>'John Smith',name=>'John Smith',
		  first_name=>'John',last_name=>'Smith',
		  friends=>[]},
		 'new Person in DESCRIPTION');
report($ok,'new Person in DESCRIPTION',__FILE__,__LINE__);

####################
# METHODS AND FUNCTIONS
my $john=new Person(first_name=>'John',last_name=>'Smith');
my $ok=cmp_attrs($john,
		 {full_name=>'John Smith',name=>'John Smith',
		  first_name=>'John',last_name=>'Smith',
		  friends=>[]},
		 'new Person in METHODS AND FUNCTIONS');
report($ok,'new Person in METHODS AND FUNCTIONS',__FILE__,__LINE__);

$john->set(last_name=>'Doe',sex=>'M');
my $ok=cmp_attrs($john,
		 {full_name=>'John Doe',name=>'John Doe',
		  first_name=>'John',last_name=>'Doe',
		  sex=>'M',gender=>'M',
		  friends=>[]},
		 'set in METHODS AND FUNCTIONS');
report($ok,'set in METHODS AND FUNCTIONS',__FILE__,__LINE__);

my $args=new Hash::AutoHash::Args first_name=>'Joe',last_name=>'Brown';
$john->set_attributes([qw(first_name last_name)],$args);
my $ok=cmp_attrs($john,
		 {full_name=>'Joe Brown',name=>'Joe Brown',
		  first_name=>'Joe',last_name=>'Brown',
		  sex=>'M',gender=>'M',
		  friends=>[]},
		 'set_attributes in METHODS AND FUNCTIONS');
report($ok,'set_attributes in METHODS AND FUNCTIONS',__FILE__,__LINE__);

my($first,$last)=$john->get(qw(first_name last_name));
cmp_deeply([$first,$last],[qw(Joe Brown)],'get in METHODS AND FUNCTIONS');

done_testing();

