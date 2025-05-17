package Crop::Object::Constants;
use base qw / Exporter /;

=begin nd
Class: Crop::Object::Constants
	ORM constants.

	Constants are used in several files such <Crop::Object> and <Crop::Object::Collection> so are located
	in separate file.
=cut

use v5.14;
use warnings;

=begin nd
Variable: our @EXPORT
	All the constants are exported by default.
	
	DONT_SYNC
	
	REMOVED NOSYNC DWHLINK MODIFIED OBJINIT DOSYNC
	
	ANY CACHED STORED KEY
=cut
our @EXPORT = qw/
	DONT_SYNC
	REMOVED NOSYNC DWHLINK MODIFIED OBJINIT DOSYNC
	ANY CACHED STORED KEY
/;

=begin nd
Constant: DONT_SYNC
	Do not synchronyze the Object with database state.

	Constructor has form of:
> My::Class->new(DONT_SYNC, a1=>v1, ...)
=cut
use constant {
	DONT_SYNC => '__DONT_SYNC__',
};

=begin nd
Constants:
	Inner state flags located in $self->{STATE}

Constant: REMOVED
	Object will be removed from database.
	
Constant: NOSYNC
	The object has unsaved changes. See <DONT_SYNC>.
	
Constant: DWHLINK
	Object has been loaded from warehouse.
	
Constant: MODIFIED
	Object is modified after it has been loaded from warehouse. It is significant only if the <DWHLINK> flag is up.
	
Constant: OBJINIT
	The binary mask to setup all the flag at init state.
	
Constant: DOSYNC
	Binary mask for make down the <NO_SYNC> flag.
=cut
use constant {
	REMOVED  => 0b0001,
	NOSYNC   => 0b0010,
	DWHLINK  => 0b0100,
	MODIFIED => 0b1000,

	OBJINIT  => 0b0000,
	DOSYNC   => 0b1101,
};

=begin nd
Constants:
	Attribute could be saved in a warehouse

Constant: ANY
	Any of both types

Constant: CACHED
	Attribute will not be saved in a warehouse

Constant: STORED
	Attribute will be saved in a warehouse
	
Constant: KEY
	Attribute will be saved in database and it is a primary key
=cut
use constant {
	ANY    => 0,
	CACHED => 1,
	STORED => 2,
	KEY    => 3,
};

1;
