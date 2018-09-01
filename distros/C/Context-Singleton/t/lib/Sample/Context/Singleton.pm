
use strict;
use warnings;

package Sample::Context::Singleton;

our $VERSION = v1.0.0;

use parent 'Context::Singleton';

use Ref::Util;

our @EXPORT = @Context::Singleton::EXPORT;

sub import {
	my ($class, @params) = @_;

	my $globals = Ref::Util::is_hashref ($params[0])
		? shift @params
		: {}
		;

	$globals->{into} //= scalar caller;
	$globals->{load_path} //= [];
    push @{ $globals->{load_path} }, 'Sample::Context::Singleton::001';

	$class->SUPER::import ($globals, @params);
}

1;
