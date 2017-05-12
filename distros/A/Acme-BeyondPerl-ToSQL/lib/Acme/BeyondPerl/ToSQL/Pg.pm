package Acme::BeyondPerl::ToSQL::Pg;

use strict;
use base qw(Acme::BeyondPerl::ToSQL);

our $VERSION = 0.01;

sub xor {
	my ($x, $y) = Acme::BeyondPerl::ToSQL::_get_args_as_bits(@_);
	Acme::BeyondPerl::ToSQL::_calc_by_rdbm("SELECT $x # $y");
}

##############################################################################
#
##############################################################################

package Acme::BeyondPerl::ToSQL::Pg::__Integer;

use base qw(Acme::BeyondPerl::ToSQL::Pg);

sub as_sql { 'CAST(' . ${$_[0]} . ' AS double precision)'; }

#sub as_bit { ${$_[0]}; }

##############################################################################
#
##############################################################################

package Acme::BeyondPerl::ToSQL::Pg::__Float;

use base qw(Acme::BeyondPerl::ToSQL::Pg);

sub as_sql { 'CAST(' . ${$_[0]} . ' AS double precision)'; }

#sub as_bit { ${$_[0]}; }

##############################################################################
1;
__END__

=pod

=head1 NAME

Acme::BeyondPerl::ToSQL::Pg - PostgreSQL support for Acme::BeyondPerl::ToSQL

=head1 SYNOPSIS

 my $dbname;
 my $host;
 my $user;
 my $pass;

 BEGIN{
   $dbname = 'acme_db';
   $host   = '127.0.0.1';
   $user   = 'foo';
   $pass   = 'bar';
 }

 use Acme::BeyondPerl::ToSQL ("dbi:Pg:dbname=$dbname;host=$host", $user, $pass);
 
 # or 
 
 use Acme::BeyondPerl::ToSQL ({
     dbi => ["dbi:Pg:dbname=$dbname;host=$host", $user, $pass],
     debug => 1
 });

=head1 DESCRIPTION

This module implements a PostgreSQL version for Acme::BeyondPerl::ToSQL.
You don't need to use this module directly.

=head1 SEE ALSO

L<Acme::BeyondPerl::ToSQL>, 

PostgreSQL

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
