#============================================================= -*-perl-*-
#
# Class::Facade
#
# DESCRIPTION
#   Facade class for providing a unified interface to one or more 
#   delegate objects.
#
# AUTHOR
#   Andy Wardley    <abw@kfs.org>
#
# COPYRIGHT
#   Copyright (C) 2001-2002 Andy Wardley.  All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
# REVISION
#   $Id$
#
#========================================================================

package Class::Facade;

use strict;
use Class::Base;
use base qw( Class::Base );

our $VERSION  = '0.01';
our $REVISION = sprintf("%d.%02d", q$Revision$ =~ /(\d+)\.(\d+)/);
our $ERROR;


#------------------------------------------------------------------------
# init()
#------------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;
    my $class = ref $self;

    while (my ($name, $value) = each %$config) {
	no strict 'refs';
	my $type = ref $value;
	
	if ($type eq 'CODE') {
	    my $coderef = $value;
	    *{"$class\::$name"} = sub {
		my $facade = shift;
		&$coderef(@_);
	    };
	}
	elsif ($type eq 'ARRAY') {
	    my ($object, $method, @args) = @$value;
	    *{"$class\::$name"} = sub {
		my $facade = shift;
		$object->$method(@args, @_);
	    };
	}
	elsif ($type eq 'HASH') {
	    my $object = $value->{ class  } 
                      || $value->{ object }
		      || return $self->error("$name: no 'class' or 'object' specified");
	    my $method = $value->{ method } 
		|| return $self->error("$name: no 'method' specified");
	    my $args = $value->{ args } || [ ];

	    *{"$class\::$name"} = sub {
		my $facade = shift;
		$object->$method(@$args, @_);
	    };
	}
	else {
	    return $self->error("$name: invalid delegate specification");
	}
    }

    return $self;
}


1;


=head1 NAME

Class::Facade - interface to one or more delegates

=head1 SYNOPSIS

    use Class::Facade;

    my $facade = Class::Facade->new({
        method1 => sub { ... },
        method2 => [ $class, $method, $arg1, $arg2, ... ],
        method3 => [ $object, $method, $arg1, $arg2, ... ],
        method4 => {
            class  => 'My::Delegate::Class',
            method => 'method_name',
            args   => [ $arg1, $arg2, ... ],
        },
        method5 => {
            object => $object,
            method => 'method_name',
            args   => [ $arg1, $arg2, ... ],
        },
    });

    $facade->method1($more_args1, ...);
    $facade->method2($more_args2, ...);
    # ...etc...

=head1 DESCRIPTION

This module implements a simple facade class, allowing you to create 
objects that delegate their methods to subroutines or other object or 
class methods.

To create a delegate object, simply call the new() constructor passing a
reference to a hash array describing the methods and their delegates.
Each key in the hash specifies a method name for your facade object.
Each value specifies the delegate target and should be a reference to 
a subroutine, list or hash array.  

In the case of a list, the elements in the list should be a class name
or object reference followed by a method name and a list of any
arguments that you want passed to the method when it is called.  Any
additional arguments that the caller of the facade method specifies will
also be passed.

In the case of a hash, the C<class> or C<object> element specifies a
class name or object references, the C<method> element names the
class/object method to be called and C<args> is an optional reference 
to a list of arguments as above.

The Class::Facade constructor creates accessor methods in the module's
symbol table.  One important side effect of this is that all methods
defined will be created for all object of the same class.  For this 
reason it is recommended that you create your own facade modules which
are subclass from Class::Facade.

    package My::Facade::One;
    use base qw( Class::Facade );

    package My::Facade::Two;
    use base qw( Class::Facade );

    package main;
    my $one = My::Facade::One->new({ ... });
    my $two = My::Facade::Two->new({ ... });

=head1 AUTHOR

Andy Wardley E<lt>abw@kfs.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2001-2002 Andy Wardley.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
