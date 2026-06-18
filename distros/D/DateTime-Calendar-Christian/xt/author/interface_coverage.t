package main;

use 5.008004;

use strict;
use warnings;

use DateTime;
use DateTime::Calendar::Christian;
use List::Util 1.29 qw{ pairs };
use Test::More 0.88;	# Because of done_testing();

BEGIN {
    eval {
	require Class::Inspector;
	1;
    } or plan skip_all => 'Class::Inspector not available';
}

foreach my $pair ( pairs( qw{ DateTime::Calendar::Christian DateTime } ) ) {
    my $got = interface_hash( $pair->[0] );
    my $want = interface_hash( $pair->[1] );
    foreach my $key ( keys %{ $got } ) {
	exists $want->{$key}
	    or delete $got->{$key};
    }
    foreach my $name ( sort keys %{ $want } ) {
	ok $got->{$name}, "$pair->[0] implements $name from $pair->[1]";
    }
}

done_testing;

# The Specio types leak through namespace::clean, at least as of April
# 30 2022:
#   namespace::clean 0.027
#   Specio::Subs 0.47
# The only thing I can think of to do is to add them to the cleanup.
# The list is cut, pasted, and edited lightly from
# Specio::Library::Builtins.

my @specio;

BEGIN {
    foreach my $type ( qw{
      Item
          Bool
          Maybe
          Undef
          Defined
              Value
                  Str
                      Num
                          Int
                      ClassName
              Ref
                  ScalarRef
                  ArrayRef
                  HashRef
                  CodeRef
                  RegexpRef
                  GlobRef
                  FileHandle
                  Object
	
	} )
    {
	foreach my $action ( qw{ assert force is to } ) {
	    push @specio, "${action}_$type";
	}
    }
}

sub interface_hash {
    my ( $module ) = @_;
    # We consider only functions that begin with a lower-case letter to
    # be part of the interface.
    my $rslt = {
	map { $_ => 1 }
	grep { m/ \A [[:lower:]] /smx }
	@{ Class::Inspector->functions( $module ) || [] }
    };
    # Certain functions are not part of the interface.
    delete $rslt->{$_} for qw{ bootstrap }, @specio;
    return $rslt;
}

1;

# ex: set textwidth=72 :
