package CookBookA::Ex5;

require DynaLoader;
@ISA = 'DynaLoader';

$VERSION = '49.1';

bootstrap CookBookA::Ex5 $VERSION;

sub new {
	my $type = shift;
	bless [], $type;
}

sub dogwood {
	my $self = shift;
	my $val = shift;
	print "# dogwood\n";
	$$val = 42;
}

sub birch {
	my $self = shift;
	print "# birch\n";
	66;
}


1;
