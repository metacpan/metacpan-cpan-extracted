package BerkeleyDB::Easy::Cursor;
our @ISA = qw(BerkeleyDB::Cursor);

use strict;
use warnings;

use BerkeleyDB::Easy::Common;
use BerkeleyDB::Easy::Error;
use BerkeleyDB qw(
	DB_FIRST
	DB_LAST
	DB_NEXT
	DB_NEXT_DUP
	DB_NEXT_NODUP
	DB_PREV
	DB_PREV_NODUP
	DB_CURRENT
	DB_SET
	DB_SET_RANGE
	DB_GET_BOTH
	DB_GET_RECNO
	DB_SET_RECNO
	DB_AFTER
	DB_BEFORE
	DB_CURRENT
	DB_KEYFIRST
	DB_KEYLAST
);

sub _handle { shift->[1] }

# Each hash elem in %subs defines a wrapper specification. Look at Common.pm
# for how these work. Briefly, the key is our wrapper's name, and the value
# is an array ref with the following fields:
#
#   0  FUNC : the underlying BerkeleyDB.pm function we are wrapping
#   1  RECV : parameters to our wrapper, passed by the end user
#   2  SEND : arguments we call FUNC with, often carried thru from RECV
#   3  SUCC : what to return on success
#   4  FAIL : what to return on failure
#   5  OPTI : integer specifying optimization level
#   6  FLAG : default flag to FUNC
#
# Single-letter aliases expand as:
#
#   K  $key         |   R  $return       |   X  $x
#   V  $value       |   S  $status       |   Y  $y
#   F  $flags       |   T  1  ('True')   |   Z  $z
#   A  @_ ('All')   |   N  '' ('Nope')   |   U  undef

my %subs = (
	c_get      => ['c_get'  ,[     ],[A    ],[S  ],[S],0,             ],
	c_put      => ['c_put'  ,[     ],[A    ],[S  ],[S],0,             ],
	c_del      => ['c_del'  ,[     ],[A    ],[S  ],[S],0,             ],
	c_count    => ['c_count',[     ],[A    ],[S  ],[S],0,             ],
	c_close    => ['c_close',[     ],[A    ],[S  ],[S],0,             ],
	first      => ['c_get'  ,[F    ],[K,V,F],[K,V],[ ],0,DB_FIRST     ],
	last       => ['c_get'  ,[F    ],[K,V,F],[K,V],[ ],0,DB_LAST      ],
	next       => ['c_get'  ,[F    ],[K,V,F],[K,V],[ ],0,DB_NEXT      ],
	next_dup   => ['c_get'  ,[F    ],[K,V,F],[K,V],[ ],0,DB_NEXT_DUP  ],
	next_nodup => ['c_get'  ,[F    ],[K,V,F],[K,V],[ ],0,DB_NEXT_NODUP],
	prev       => ['c_get'  ,[F    ],[K,V,F],[K,V],[ ],0,DB_PREV      ],
	prev_nodup => ['c_get'  ,[F    ],[K,V,F],[K,V],[ ],0,DB_PREV_NODUP],
	current    => ['c_get'  ,[F    ],[K,V,F],[K,V],[ ],0,DB_CURRENT   ],
	set        => ['c_get'  ,[K,F  ],[K,V,F],[K,V],[ ],0,DB_SET       ],
	set_range  => ['c_get'  ,[K,F  ],[K,V,F],[K,V],[ ],0,DB_SET_RANGE ],
	both       => ['c_get'  ,[K,V,F],[K,V,F],[K,V],[ ],0,DB_GET_BOTH  ],
	get_recno  => ['c_get'  ,[F    ],[K,V,F],[K,V],[ ],0,DB_GET_RECNO ],
	set_recno  => ['c_get'  ,[K,F  ],[K,V,F],[K,V],[ ],0,DB_SET_RECNO ],
	after      => ['c_put'  ,[V,F  ],[K,V,F],[T  ],[ ],0,DB_AFTER     ],
	before     => ['c_put'  ,[V,F  ],[K,V,F],[T  ],[ ],0,DB_BEFORE    ],
	replace    => ['c_put'  ,[V,F  ],[K,V,F],[T  ],[ ],0,DB_CURRENT   ],
	keyfirst   => ['c_put'  ,[K,V,F],[K,V,F],[T  ],[ ],0,DB_KEYFIRST  ],
	keylast    => ['c_put'  ,[K,V,F],[K,V,F],[T  ],[ ],0,DB_KEYLAST   ],
	del        => ['c_del'  ,[F    ],[F    ],[T  ],[ ],0,             ],
	count      => ['c_count',[F    ],[X,F  ],[X  ],[ ],0,             ],
	close      => ['c_close',[     ],[     ],[T  ],[ ],0,             ],   
);

# Install the stubs
while (my ($name, $spec) = each %subs) {
	__PACKAGE__->_install($name, $spec);
}

# Method aliases for naming consistency
*get_both    = \&both;
*put_after   = \&after;
*put_before  = \&before;
*put_current = \&replace;
*put_first   = \&keyfirst;
*put_last    = \&keylast;
*delete      = \&del;

INFO and __PACKAGE__->_info(q(Cursor.pm finished loading));

1;

=encoding utf8

=head1 NAME

BerkeleyDB::Easy::Cursor - Cursor to database handle

=head1 METHODS

Most of the functionaly for BerkeleyDB cursors are crammed into a few
underlying functions, with the behavior specified by a flag. For example, to
get the next record, you call C<c_get> and provide the C<DB_NEXT> flag. In
this module, these are split out into individual wrapper methods, and the
required flag is provided for you. You can specify additional flags
and they will be OR'ed together with the default.

=head2 first

Get the first record.

	($key, $val) = $cursor->first();

=head2 last

Get the last record.

	($key, $val) = $cursor->last();

=head2 next

Get the next record.
	
	($key, $val) = $cursor->next();

=head2 prev

Move the previous record.
	
	($key, $val) = $cursor->prev();

=head2 current

Get the record at the current position.
	
	($key, $val) = $cursor->current();

=head2 set

Position the cursor to the specified key.
	
	($key, $val) = $cursor->set($key);

=head2 after

Set the next record to the specified value.
Returns true on success.

	$bool = $cursor->after($val);

=head2 before
	
Set the previous record to the specified value.

	$bool = $cursor->before($val);

=head2 replace

Replace the record at the current position.
	
	$bool = $cursor->replace($val);

=head2 del

Delete the current record.
	
	$bool = $cursor->del();

=head2 close

Close the cursor.
	
	$bool = $cursor->close();

=head1 BUGS

This module is functional but unfinished.

=head1 AUTHOR

Rob Schaber, C<< <robschaber at gmail.com> >>

=head1 LICENSE

Copyright 2013 Rob Schaber.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.
