package Acme::BeyondPerl::ToSQL::SQLite;

use strict;
use base qw(Acme::BeyondPerl::ToSQL);

our $VERSION = 0.01;

my $OPs = {
	'+'    => sub { shift->add(@_) },
	'-'    => sub { shift->sub(@_) },
	'*'    => sub { shift->mul(@_) },
	'/'    => sub { shift->div(@_) },
	'%'    => sub { shift->mod(@_) },
	'abs'  => sub { shift->abs(@_) },
	'<<'   => sub { shift->lshift(@_) },
	'>>'   => sub { shift->rshift(@_) },
	'&'    => sub { shift->and(@_) },
	'|'    => sub { shift->or(@_)  },
};

sub ops { return $OPs; }

##############################################################################
#
##############################################################################

package Acme::BeyondPerl::ToSQL::SQLite::__Integer;

use base qw(Acme::BeyondPerl::ToSQL::SQLite);

sub as_sql { sprintf("%.1f", ${$_[0]}); }

##############################################################################
#
##############################################################################

package Acme::BeyondPerl::ToSQL::SQLite::__Float;

use base qw(Acme::BeyondPerl::ToSQL::SQLite);
use strict;

sub as_sql { sprintf("%.16f", ${$_[0]}); }

##############################################################################
1;
__END__

=pod

=head1 NAME

Acme::BeyondPerl::ToSQL::SQLite - SQLite support for Acme::BeyondPerl::ToSQL

=head1 SYNOPSIS

 use Acme::BeyondPerl::ToSQL ("dbi:SQLite:dbname=acme_db","","");
 
 # or 
 
 use Acme::BeyondPerl::ToSQL ({
      dbi => ["dbi:SQLite:dbname=acme_db","",""], debug => 1,
 });

=head1 DESCRIPTION

This module implements a SQLite version for Acme::BeyondPerl::ToSQL.
You don't need to use this module directly.

=head1 SEE ALSO

L<Acme::BeyondPerl::ToSQL>, 

SQLite

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut


