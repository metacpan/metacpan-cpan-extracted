package Acme::BeyondPerl::ToSQL;

use strict;
use DBI;
use Carp;

our $VERSION = 0.01;
our $DEBUG   = 0;

my $Dbh;   # database handle
my $Type;  # rdbm type

END {
	$Dbh->disconnect()
}

##############################################################################

sub import {
	my $class = shift;
	my %hash  = %{ $_[0] } if(@_ == 1);
	my ($dsn, $user, $pass, $opt) = (@_ > 1) ? @_ : @{$hash{dbi}};

	_connect($dsn, $user, $pass, $opt) unless($Dbh);

	_overload();

	overload::constant (
		integer => \&_integer_handler,
		float   => \&_float_handler,
	);

	if(defined $hash{debug}){ $DEBUG = $hash{debug}; }

}


my $OPs = {
	'+'    => sub { shift->add(@_) },
	'-'    => sub { shift->sub(@_) },
	'*'    => sub { shift->mul(@_) },
	'/'    => sub { shift->div(@_) },
	'%'    => sub { shift->mod(@_) },
	'**'   => sub { shift->pow(@_) },
	'log'  => sub { shift->log(@_) },
	'sqrt' => sub { shift->sqrt(@_)},
	'abs'  => sub { shift->abs(@_) },
	'cos'  => sub { shift->cos(@_) },
	'sin'  => sub { shift->sin(@_) },
	'exp'  => sub { shift->exp(@_) },
	'atan2'=> sub { shift->atan2(@_) },
	'<<'   => sub { shift->lshift(@_) },
	'>>'   => sub { shift->rshift(@_) },
	'&'    => sub { shift->and(@_) },
	'|'    => sub { shift->or(@_)  },
	'^'    => sub { shift->xor(@_) },
};


sub ops { return $OPs; }

sub Type { $Type; }

##############################################################################

sub _connect {
	my ($dsn, $user, $pass, $opts) = @_;

	$Dbh = DBI->connect($dsn, $user, $pass, $opts) or die $!;

	$Type = ($dsn =~ /dbi:(\w+)/)[0];
}


sub _overload {
	my $mod = __PACKAGE__ . '::' . $Type;

	eval qq| require $mod |;
	if($@){ croak "Can't load $mod."; }

	my $ops = $mod->ops;
	my %operators = (
		nomethod => \&_nomethod,
		'""'   => sub { ${$_[0]} },
		'<=>'  => sub { ${$_[0]} <=> ${$_[1]} },
		'0+'   => sub { ${$_[0]} },
		'bool' => sub { ${$_[0]} },
		'cmp'  => sub { ${$_[0]} cmp ${$_[1]} },
		%{ $ops }
	);

	eval q| use overload %operators |;
	if($@){ die $@; }

}


sub _integer_handler {
	my ($ori, $interp, $contect) = @_;
	return bless \$interp, __PACKAGE__ . "::$Type\::__Integer";
}

sub _float_handler {
	my ($ori, $interp, $contect) = @_;
	return bless \$interp, __PACKAGE__ . "::$Type\::__Float";
}


##############################################################################
# Use From Objects
##############################################################################

sub _calc_by_rdbm {
	if($DEBUG){ print "$_[0]\n"; }
	_float_handler( undef, $Dbh->selectrow_array($_[0]) );
}


sub _nomethod {
	my ($x, $y, $swap, $op) = @_;
	croak "This operator '$op' is not implemented in $Type";
}


sub _get_args {
	my ($x, $y, $swap) = @_;
	if($swap){ ($x, $y) = ($y, $x) }
	$x = $x->as_sql if(UNIVERSAL::can($x,'as_sql'));
	$y = $y->as_sql if(UNIVERSAL::can($y,'as_sql'));
	return ($x,$y);
}

sub _get_args_as_bits {
	my ($x, $y, $swap) = @_;
	if($swap){ ($x, $y) = ($y, $x) }
	$x = $x->as_bit if(UNIVERSAL::can($x,'as_sql'));
	$y = $y->as_bit if(UNIVERSAL::can($y,'as_sql'));
	return ($x,$y);
}

sub as_sql { ${$_[0]} }

sub as_bit { ${$_[0]} }

##############################################################################
# OPERATORS
##############################################################################

sub add {
	my ($x, $y) = _get_args(@_);
	_calc_by_rdbm("SELECT $x + $y");
}


sub sub {
	my ($x, $y) = _get_args(@_);
	_calc_by_rdbm("SELECT $x - $y");
}


sub mul {
	my ($x, $y) = _get_args(@_);
	_calc_by_rdbm("SELECT $x * $y");
}


sub div {
	my ($x, $y) = _get_args(@_);
	_calc_by_rdbm("SELECT $x / $y");
}


sub mod {
	my ($x, $y) = _get_args(@_);
	_calc_by_rdbm("SELECT $x % $y");
}


sub pow {
	my ($x, $y) = _get_args(@_);
	_calc_by_rdbm("SELECT pow($x, $y)");
}

sub abs {
	my ($x) = _get_args(@_);
	_calc_by_rdbm("SELECT abs($x)");
}

sub log {
	my ($x) = _get_args(@_);
	_calc_by_rdbm("SELECT ln($x)");
}

sub exp {
	my ($x) = _get_args(@_);
	_calc_by_rdbm("SELECT exp($x)");
}

sub sqrt {
	my ($x) = _get_args(@_);
	_calc_by_rdbm("SELECT sqrt($x)");
}

sub sin {
	my ($x) = _get_args(@_);
	_calc_by_rdbm("SELECT sin($x)");
}

sub cos {
	my ($x) = _get_args(@_);
	_calc_by_rdbm("SELECT cos($x)");
}

sub atan2 {
	my ($x, $y) = _get_args(@_);
	_calc_by_rdbm("SELECT atan2($x, $y)");
}

sub lshift {
	my ($x, $y) = _get_args_as_bits(@_);
	_calc_by_rdbm("SELECT $x << $y");
}

sub rshift {
	my ($x, $y) = _get_args_as_bits(@_);
	_calc_by_rdbm("SELECT $x >> $y");
}

sub and {
	my ($x, $y) = _get_args_as_bits(@_);
	_calc_by_rdbm("SELECT $x & $y");
}

sub or {
	my ($x, $y) = _get_args_as_bits(@_);
	_calc_by_rdbm("SELECT $x | $y");
}

sub xor {
	my ($x, $y) = _get_args_as_bits(@_);
	_calc_by_rdbm("SELECT $x ^ $y");
}

##############################################################################
1;
__END__

=pod

=head1 NAME

Acme::BeyondPerl::ToSQL - RDBMS calculates instead of Perl

=head1 SYNOPSIS

 use Acme::BeyondPerl::ToSQL ("dbi:SQLite:dbname=acme_db","","");
 
 my $value = 5;
 
 print 2 + $value , "\n"; # 7
 print 1.2 - 0.2  , "\n"; # 1
 print 9 / 2      , "\n"; # 4.5
 
 
 # DEBUG MODE
 # use Acme::BeyondPerl::ToSQL ({
 #     dbi => ["dbi:SQLite:dbname=acme_db","",""], debug => 1,
 # });
 #
 # SELECT 1.2000000000000000 - 0.2000000000000000
 # SELECT 9.0 / 2.0
 # SELECT 2.0 + 5.0

 # use Acme::BeyondPerl::ToSQL ({
 #     dbi => ["dbi:Pg:dbname=$dbname;host=$host", $user, $pass], debug => 1,
 # });
 #
 # SELECT CAST(1.2 AS double precision) - CAST(0.2 AS double precision)
 # SELECT CAST(9 AS double precision) / CAST(2 AS double precision)
 # SELECT CAST(2 AS double precision) + CAST(5 AS double precision)

=head1 DESCRIPTION

When you use C<Acme::BeyondPerl::ToSQL>, your RDBMS will calculate
instead of Perl!

Currently supported RDBMS are SQLite, PostgreSQL and MySQL.

=head1 HOW TO USE

=over 4

=item Acme::BeyondPerl::ToSQL ($dsn, $user, $pass, $opts)

To use DBI, you must pass some arguments.

 use Acme::BeyondPerl::ToSQL ("dbi:SQLite:dbname=acme_db","","");

 use Acme::BeyondPerl::ToSQL
           ("dbi:Pg:dbname=$dbname;host=$host", $user, $pass, \%opts);

=item Acme::BeyondPerl::ToSQL ({dbi => $arrayref, debug => $true_or_false})

 use Acme::BeyondPerl::ToSQL ({
     dbi   => ["dbi:SQLite:dbname=acme_db","",""],
     debug => 1,
 });


=back

=head1 EXPORT

None.

=head1 BUGS

All the effects of this module are constrained to C<overload> and
C<overload::constant>.

There might be an operator not supported.

When this module is used at the same time with two or more files
on Windows 2000 + ActivePerl, I find a warning
"Attempt to free unreferenced scalar".

=head1 SEE ALSO

L<overload>,

L<overload::constant>,

L<DBI>

=head1 AUTHOR

Makamaka Hannyaharamitu, E<lt>makamaka[at]cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Makamaka Hannyaharamitu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut


