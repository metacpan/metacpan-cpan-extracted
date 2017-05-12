package CGI::Application::Muto::MethodAttributes;

# This module code has been taken almost entirely from the module
# CGI::Application::Plugin::ActionDispatch::Attributes by Jason Yates,
# <lt>jaywhy@gmail.com<gt>

use attributes;
use strict;

our $VERSION = '0.1';

my @attributes;
my %attr_handlers;

my $init = 1;

# MODIFY_CODE_ATTRIBUTES needs to be in the inheritance tree.
push @CGI::Application::Muto::ISA, 'CGI::Application::Muto::MethodAttributes'
	unless grep /^CGI::Application::Muto::MethodAttributes$/, @CGI::Application::Muto::ISA;

	
sub MODIFY_CODE_ATTRIBUTES {
    my($class, $code, @attrs) = @_;
	
    foreach (@attrs) {
	# Parse the attribute string ex: Regex('^/foo/bar/(\d+)/').
	my($method, $params) = /^([a-z_]\w*)(?:[(](.*)[)])?$/is;
	$params =~ s/(^'|'$)//g if defined $params;

	# Attribute definition.
	if($method eq 'ATTR') {
	    $attr_handlers{$code} = $params
	} 
	# Is a custom attribute.
	else {
	    my $handler = $class->can($method);
	    next unless $handler;
	    push(@attributes, [ $class, $method, $code, $params ] );
	}
    }
    
    return ();
}

sub init {
    return unless $init; # Initialize only once
    
    foreach my $attr (@attributes) {
	my $class	= $attr->[0];
	my $method	= $attr->[1];
		
	# calls:  class->method( code, method, params );
	$class->$method( $attr->[2], $attr->[1], $attr->[3]);
    }
    $init = 0;
}


1;

