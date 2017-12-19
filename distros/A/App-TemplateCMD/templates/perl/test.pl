[% IF not module %][% module = 'module' %][% END -%]
[% IF not obj    %][% obj    = 'obj'    %][% END -%]
[% IF not tests  %][% tests  = 10       %][% END -%]
#!/usr/bin/perl

BEGIN { $ENV{TESTING} = 1 }

use strict;
use warnings;
use Test::More;
use Test::Warnings;

my $module = '[% module %]';
use_ok( $module );

[% FOREACH subroutine = class -%]

my $[% obj %] = $module->[% subroutine %]();

ok( defined $[% obj %], "Check that the class method [% subroutine %] returns something" );
ok( $[% obj %]->isa('[% module %]'), " and that it is a [% module %]" );

[% END -%]
[% FOREACH subroutine = object -%]
can_ok( $[% obj %], '[% subroutine %]',  " check object can execute [% subroutine %]()" );
ok( $[%	obj %]->[% subroutine %](),      " check object method [% subroutine %]()" );
is( $[%	obj %]->[% subroutine %](), '?', " check object method [% subroutine %]()" );
[% END -%]

[% FOREACH subroutine = func -%]
ok( $[% module %]::[% subroutine %](),      " check method [% subroutine %]()" );
is( $[% module %]::[% subroutine %](), '?', " check method [% subroutine %]()" );
[% END -%]

done_testing();
