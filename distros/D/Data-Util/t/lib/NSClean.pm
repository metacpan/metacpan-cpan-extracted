package NSClean;

use strict;
use warnings;

use Data::Util;

sub import{
	my $into = caller;

	Data::Util::install_subroutine($into,
		foo => sub{ 'foo' },
		bar => sub{ 'bar' },
		baz => sub{ 'baz' },
	);
	$^H = 0x020000; # HINT_LOCALIZE_HH
	$^H{(__PACKAGE__)} = __PACKAGE__->new(into => $into);
}

sub new{
	my $class = shift;
	bless {@_}, $class;
}

sub DESTROY{
	my($self) = @_;
	Data::Util::uninstall_subroutine($self->{into}, qw(foo bar));

}

1;