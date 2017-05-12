package Base;

sub new {
	my ($class, @args) = @_;
	bless { data => \@args }, $class;
}

sub basemethod {
	print "Base::basemethod() --> @{$_[0]{data}}\n";
}

package Derived;
@ISA = 'Base';

sub new {
    my ($class, $new_attr1, $new_attr2, @base_args) = @_;
    my $self = $class->SUPER::new(@base_args);
    $self->{attr1} = $new_attr1;
    $self->{attr1} = $new_attr2;
    return $self;
}

sub method {
	print "Derived::method()\n";
}


package Underived;
use Class::Delegation send => -ALL, to => 'base';

sub new {
    my ($class, $new_attr1, $new_attr2, @base_args) = @_;
    bless { attr1 => $new_attr1,
	    attr2 => $new_attr2,
	    base  => Base->new(@base_args),
	  }, $class;
}

sub method {
	print "Underived::method()\n";
}


package main;

my $der = Derived->new(1,2,3,4,5);
my $und = Underived->new(1,2,3,4,5);

$der->method();
$und->method();

$der->basemethod();
$und->basemethod();
