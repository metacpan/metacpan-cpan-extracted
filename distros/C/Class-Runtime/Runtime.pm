=pod

=head1 NAME

Class::Runtime - API for dynamic class loading/unloading/status

=head1 DEPENDENCIES

=over 4

=item *

Symbol

=item *

File::Spec

=back

=head1 INSTALLATION

To install this module type the following:

=over 2

=item *

perl Makefile.PL

=item *

make

=item *

make test

=item *

make install

=back

=head1 OVERVIEW

Class for dynamically loading/unloading/stat on modules.  Currently
it is designed for loading a class local to the system at runtime. Future
versions may include loading in a distributed environment.

A specific search path can be associated with the object which will be
'unshifted' onto @INC before attempting to load the class and 'shifted'
off after attempting to load.

Also, a class can be checked whether it is loaded or not in the process.

=head1 SYNOPSIS

 my $class = 'MyClass::MySubClass';
 my $obj = Class::Runtime->new( class=> $class );

 ## LOADING CLASS AT RUNTIME
 unless ( $cl->load ) {
	warn "Error in loading class\n";
	warn "\n\n", $@, "\n\n" if DEBUG;
 }

 ## CHECKING FOR CLASS AVAILABILITY AT RUNTIME
 unless ( $cl->isLoaded ) {
	warn 'Class - ', $class, ' - is loaded', "\n";
 }

 my $newPath;
 ## ADDING SEACH PATH TO OBJECT
 ## Multiple
 $newPath = $cl->addPath( path=> [ qw( /tmp/lib /tmp/lib2 ) ] );
  
 ##OR Single
 $newPath = $cl->addPath( path=> '/tmp/lib' );

 ## REMOVING SEARCH PATH FROM OBJECT
 ## Multiple
 $newPath = $cl->dropPath( path=> [ qw( /tmp/lib /tmp/lib2 ) ] );
  
 ##OR Single
 $newPath = $cl->dropPath( path=> '/tmp/lib' );

 ## GETTING PATH ASSOCIATED WITH OBJECT
 my @path = $cl->getPath;

 ## INVOKING METHOD 
 my $method = 'new';
 if ( $cl->isLoaded and $class->can( 'new' ) ) {
	my $obj = $cl->invoke( 'new', arg1=> 1, arg2=> 2 );
	$obj->method2;
 }

 ## NOT NECESSARY AS ONCE CLASS HAS BEEN LOADED CAN INVOKE DIRECTLY
 if ( $cl->isLoaded and $class->can( 'new' ) ) {
	my $obj = $class->new( arg1=> 1, arg2=> 2 );
	$obj->method2;
 }

 ## UNLOADING CLASS
 if ( $cl->isLoaded ) {
	$cl->unload or warn 'Unable to unload class - ', $class, "\n";
 }
  
=head1 METHODS

=cut
package Class::Runtime;

require 5.005;

use strict;

use Symbol ();
use File::Spec ();

$Class::Runtime::VERSION = '0.2';

=pod

=head2 new B<CONSTRUCTOR>

Creates new object and initializes member variables if
passed in as arguments.  Takes parameterized argument list.

=over 2

=item Input

=over 2

=item *

class => name of class to dynamically load

=back

=item Output

=over 2

=item *

Class::Runtime object

=back

=back

=cut
sub new {
	my $class = shift;
	my $param = { @_ };
	my $loadClass = $param->{'class'} || do {
		warn __PACKAGE__ . " object construction requires parameter 'class'\n";
		return;
	};

	return bless {
		class_=>	$loadClass,
		path_=>		[],	
	}, $class;
}

sub name {
	my $obj = shift;
	return $obj->{'class_'};
}

=pod

=head2 getPath

Method used to retrieve path associated with this object

=over 2

=item Input

=over 2

=item *

None

=back

=item Output

=over 2

=item *

array of paths

=item *

integer 0 if no paths exist

=back

=back

=cut
sub getPath {
	my $obj = shift;

	@{ $obj->{'path_'} } ?
		return @{ $obj->{'path_'} } :
		return 0;
}

=pod

=head2 addPath

Method used to add path to object path list to search from

=over 2

=item Input

=over 2

=item *

path => As a single string or as a reference to an array

=back

=item Output

=over 2

=item *

array of paths

=item *

undef if error

=back

=back

=cut
sub addPath {
	my $obj = shift;
	my $param = { @_ };
	my $path = $param->{'path'} || do {
		warn "Method 'dropPath' requires argument 'path'\n";
		return;
	};

	if ( ref($path) eq 'ARRAY' ) {
		foreach my $incPath ( @INC ) {
			for ( my $i = 0; $i < @$path; ++$i ) {
				if ( $incPath eq $path->[$i] ) {
					splice @$path, $i, 1 
				}
			}
		}
	} else {
		for ( my $i = 0; $i < @INC; ++$i ) {
			if ( $path eq $INC[$i] ) {
				$path = undef;
			}
		}
	}

	if ( defined $path ) {
		push @{ $obj->{'path_'} }, ref($path) eq 'ARRAY' ? @$path : $path;
		return @{ $obj->{'path_'} };
	} else {
		return;
	}
}

=pod

=head2 dropPath

Method used to remove path from object search path

=over 2

=item Input

=over 2

=item *

path=> As a single string or as a reference to an array

=back

=item Output

=over 2

=item *

array of paths

=item *

undef if error

=back

=back

=cut
sub dropPath {
	my $obj = shift;
	my $param = { @_ };
	my $path = $param->{'path'} || do {
		warn "Method 'dropPath' requires argument 'path'\n";
		return;
	};

	return unless defined $obj->getPath;

	my @curPath = @{ $obj->{'path_'} };
	if ( ref($path) eq 'ARRAY' ) {
		foreach my $dropPath ( @$path ) {
			for ( my $i = 0; $i < @curPath; ++$i ) {
				if ( $dropPath eq $curPath[$i] ) {
					splice @curPath, $i, 1 
				}
			}
		}
	} else {
		for ( my $i = 0; $i < @curPath; ++$i ) {
			if ( $path eq $curPath[$i] ) {
				splice @curPath, $i, 1;
			}
		}
	}
	$obj->{'path_'} = \@curPath;
	return @curPath;
}


=pod

=head2 isLoaded

Method used to check whether given class is loaded.

=over 2

=item Input

=over 2

=item *

None

=back

=item Output

=over 2

=item *

1 if loaded

=item *

0 if not loaded

=back

=back

=cut
sub isLoaded {
	my $obj = shift;
	my $param = { @_ };
	my $class = $obj->{'class_'} || do {
		warn __PACKAGE__ . " object is not initialized with class name\n";
		return;
	};

	$class =~ /^(.*::)(\w+)/ if ( $class =~ /::/ );
	my $base = $1 || 'main::';
	my $tail = ( $2 || $class ) . '::';

	{
		no strict 'refs';
		exists ${ $base }{ $tail } ?
			return 1 :
			return 0;
	}

}

=pod

=head2 load

Method used to load library/class.  If a path has been
associated with this object it will be 'unshifted' onto
the global @INC	array.  Immediately after the attempted
load the paths 'unshifted' onto the @INC array will be
'spliced' out.  This is done so as to prevent any wrongful
modification of @INC since the loading library may modify
@INC or perhaps some other code.

=over 2

=item Input

=over 2

=item *

None

=back

=item Output

=over 2

=item *

1 on successful load

=item *

undef if error (setting $@)

=back

=back

=cut
sub load {
	my $obj = shift;
	my $param = { @_ };
	my $class = $obj->{'class_'} || do {
		warn __PACKAGE__ . " object is not initialized with class name\n";
		return;
	};

	my $loadPath = @{ $obj->{'path_'} };
	my $file = File::Spec->catfile( split '::', $class ) . '.pm';

	unshift @INC, @{ $obj->{'path_'} } if $loadPath;
    eval { require $file; };
	$obj->cleanINC_;

	$@ ? return : return 1;
}

=pod

=head2 unload

Method used to unload class/library

=over 2

=item Input

=over 2

=item *

None

=back

=item Output

=over 2

=item *

1 on successful unload

=item *

undef if error

=back

=back

=cut
sub unload {
	my $obj = shift;
	my $param = { @_ };
	my $class = $obj->{'class_'} || do {
		warn __PACKAGE__ . " object is not initialized with class name\n";
		return;
	};
	return if $class eq __PACKAGE__;

	Symbol::delete_package($class);
	my $file = File::Spec->catfile( split '::', $class ) . '.pm';
	delete $INC{$file} if exists $INC{$file};

	return 1;

}

=pod

=head2 invoke

Method used to load class/library and call specific method with that library.

=over 2

=item Input

=over 2

=item *

name of method

=item *

remaining list of arguments to pass off to invoked method

=back

=item Output

=over 2

=item *

value of returned method call

=back

=back

=cut
sub invoke {
	my $obj = shift;
	my $class = $obj->{'class_'} || do {
		warn __PACKAGE__ . " object is not initialized with class name\n";
		return;
	};
	my $method = shift || do {
		warn "First argument to 'invoke' needs to be valid method name\n";
		return;
	};

	return $class->$method( @_ );
}

sub cleanINC_ () {
	my $obj = shift;

	my @curPath = @{ $obj->{'path_'} };
	foreach my $dropPath ( @curPath ) {
		for ( my $i = 0; $i < @INC; ++$i ) {
			if ( $dropPath eq $INC[$i] ) {
				splice @INC, $i, 1 
			}
		}
	}
	return 1;
}

1;

__END__

=pod

=head1 HISTORY

=over 2

=item *

2002/02/14 Created

2003/07/07 Modified to correct issues with method invoke

=back

=head1 SUPPORT AND SUGGESTIONS

Currently you can contact the author at the email address
listed below.

=head1 AUTHOR

=over 2

=item *

Stathy G. Touloumis <stathy-classruntime@stathy.com>

=back

=head1 CREDITS

=over 2

=item *

Per Einar Ellefsen - For providing the code to conver class to file path portably.

=item *

Bhavesh Jardosh - For providing bug info in test.pl and method invoke.

=back

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2002 Stathy G. Touloumis

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

