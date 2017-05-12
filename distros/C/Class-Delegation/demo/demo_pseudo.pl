package Pseudo::Base1;
use fields qw(a b c);
 
sub new {
	my ($class) = @_;
	my Pseudo::Base1 $self = fields::new($class);
	return $self;
}

sub dough { "the stuff I pay for beer\n" }
sub far   { "a long, long way to run -- for beer\n" }
sub so    { "let's have another beer\n" }


package Pseudo::Base2;
use fields qw(a b c);
 
sub new {
	my ($class) = @_;
	my Pseudo::Base2 $self = fields::new($class);
	return $self;
}

sub me  { "the guy who drinks my beer\n" }
sub ray { "the guy who sells me beer\n" }
sub tea { "no substitute for beer\n" }
sub la  { "la...la...la...la...la...beer!\n" }


package Derived;
use Class::Delegation
    send => -ALL,
      to => 'pseudobase1',

    send => -OTHER,
      to => 'pseudobase2',
    ;

sub new {
    my ($class, %named_args) = @_;
    bless { pseudobase1 => Pseudo::Base1->new(%named_args),
	    pseudobase2 => Pseudo::Base2->new(%named_args),
	  }, $class;
}


sub main;

my $der = Derived->new();

print "dough: ", $der->dough();
print "ray:   ", $der->ray();
print "me:    ", $der->me();
print "far:   ", $der->far();
print "so:    ", $der->so();
print "la:    ", $der->la();
print "tea:   ", $der->tea();
