package Crop::Object::Extern;
use base qw / Crop::Object /;

=begin nd
Class: Crop::Object::Extern
	Fabrica for various types of links to the extern objects.
	
	There are 3 types of link to the Extern.
	
	1. <Refbook>.
	Means many-to-one or one-to-one.
	
	2. <Bundle>
	One-to-many produces result in a <Crop::Object::Collection> form.
	
	3. <Content>
	Many-to-many. Result is a <Crop::Object::Collection>.
=cut

use v5.14;
use warnings;
no warnings 'experimental';

use Crop::Error;
use Crop::Debug;
use Crop::Util 'load_class';

=begin nd
Variable: our %Attributes
	Class attributes:
	
	type - type of link to extern class; could by either a 'bundle', 'content', or 'refbook'

=cut
our %Attributes = (
	type => undef,
);

=begin nd
Constructor: new ($src)
	Fabrica by the 'type' attribute.

Parameters:
	$src - raw declaration
	
Returns:
	Exemplar of subclass - if all right
	undef                - in case of any error
=cut
sub new {
	my $class = shift;
	
	return $class->SUPER::new(@_) if $class ne __PACKAGE__;
	
	my $src = shift;
	
	exists $src->{type} or return warn 'OBJECT|CRIT: Extern type is not defined';
	
	my $subclass;
	given ($src->{type}) {
		when ('refbook') { $subclass = 'Refbook' }
		when ('content') { $subclass = 'Content' }
		when ('bundle')  { $subclass = 'Bundle'  }
		default { return warn "OBJECT|CRIT: No such class for extern worker '$src->{type}'" }
	}
	
	my $worker = __PACKAGE__ . "::$subclass";
	load_class $worker or return warn "OBJECT|CRIT: Can't load worker for Extern object '$worker'";
	
	$worker->new($src);
}

=begin nd
Method: make_link ($parent)
	Create node and link it to the $parent.
	
	Pure virtual, must be redefined by subclass.
	
Returns:
	an error
=cut
sub make_link { warn "OBJECT|CRIT: method make_link() must be redefined by subclass" }

1;
