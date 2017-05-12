package Acme::WalkMethods;

use strict;
use warnings;

=head1 NAME

Acme::WalkMethods - Develope the wrong way

=head1 SYNOPSIS

  package Your::Package;
  use base qw(Acme::WalkMethods);
  1;

  # in a script not far away
  use Your::Package;
  my $object = Your::Package->new();

  $object->foo('5'); 
  $object->bar('5'); 

  print "Foo:" . $object->foo() . "\n" if $object->foo();
  print "Bar:" . $object->bar() . "\n" if $object->bar();

  # From command line:
  >perl <yourscript>.pl
  Can I create bar as a method (y/N)?y
  Can I create foo as a method (y/N)?y
  Foo: 5
  Bar: 5

  Or:

  >perl <yourscript>.pl
  Can I create bar as a method (y/N)?y
  Can I create foo as a method (y/N)?n
  Bar: 5

=head1 DESCRIPTION

Want to start developing the wrong way?

Use this module as your base! 

Write all your end code first and decide
each time you run your code which methods you want
to be able to store data into.

=head1 WHY?

Because acme told me to, this mess has been brought
to you by the letter L and the colour Orange.

=head1 PROBLEMS?

Only if someone finds a 'good' use for this module.

=head1 AUTHOR

Leo Lapworth, LLAP@cuckoo.org

=cut

use vars qw ( $AUTOLOAD $VERSION );
$VERSION = '0.1';

sub new {
    my ($proto,$conf) = @_;
    my $class = ref($proto) || $proto;
    my $self = {};
	bless($self, $class);
	return $self;
}

sub AUTOLOAD {
    my $name = $AUTOLOAD;
    $name =~ s/.*://;

	if(!defined $_[0]->{$name} && defined $_[1]) {
		print "Can I create '$name' as a method (y/N)?";
		my $input = <STDIN>;
		chomp($input);

		unless($input eq 'y') {
			return undef;
		}
	}

	if($_[1]) {
		# set it
        $_[0]->{$name} = $_[1];
    }
    
    # Return it
    return $_[0]->{$name} if defined $_[0]->{$name};
	return undef;
}

sub DESTROY {};

1;
