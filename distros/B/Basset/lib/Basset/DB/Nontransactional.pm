package Basset::DB::Nontransactional;

#Basset::DB::Nontransactional 2004, 2006 James A Thomason III
#Basset::DB::Nontransactional is distributed under the terms of the Perl Artistic License.

$VERSION = '1.02';

=pod

=head1 NAME

Basset::DB::Nontransactional - A non transactional database driver.

=head1 AUTHOR

Jim Thomason, jim@jimandkoka.com

=head1 SYNOPSIS

If you really really really want to use non-transactional database drivers, just swap in 
this driver in your conf file.

 types %= driver=Basset::DB::Nontransactional

Voila! No transactions.

=cut

use Basset::DB;
@ISA = qw(Basset::DB);

use strict;
use warnings;

sub create_handle {
	return shift->SUPER::create_handle(
		@_,
		'AutoCommit' => 1
	);
}

#dummy out the Basset::DB methods that deal with transactions.

sub stack	{ return 0 };
sub begin	{ return 1 };
sub end		{ return '0 but true' };
sub finish	{ return 1 };
sub fail	{ return 1 };
sub wipe	{ return 1 };
sub failed	{ return 0 };

1;
