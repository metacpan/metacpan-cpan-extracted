package Ctype;

use 5.006;
use strict;
use warnings qw(all);
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

our %EXPORT_TAGS = (
'all' => [qw(isalnum isalpha isdigit islower isspace isupper isxdigit toupper tolower useperlfns)],
'classes' => [qw(isalnum isalpha isdigit islower isspace isupper isxdigit)], 
'changes' => [qw(toupper tolower)],
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.02';

sub AUTOLOAD {
    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined Ctype macro $constname";
	}
    }
    {
	no strict 'refs';
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

bootstrap Ctype $VERSION;

local $::useperlfns = 0; # why ::-)
my $Debug = 0;
if (defined $ENV{'DEBUG'}) {
	$Debug = 1;
}

# print debugging
sub Ctype_debug {
	print $_[0] if $Debug;
}

# dump a variable
sub Ctype_dump ($) {
	use Data::Dumper;
	my $d = shift;
	my $str = "Dumping variable (variable contains $d)\n";
	$str .= Data::Dumper::Dumper($d);
	if (UNIVERSAL::isa($d, "Ctype")) {
		# give pretty print of Ctype object
		$str .= "Ctype object, character ";
		$str .= $d->[0];
		$str .= " (code ";
		$str .= ord($d->[0]);
		$str .= "), libperl ctype functions ";
		if ($d->[1]) {
			$str .= "enabled";
		} else {
			$str .= "disabled";
		}
		$str .= "\n";
	}
	$str .= "End of dump\n";
	Ctype_debug($str);
}

sub toupper {
	my $c = shift;
	my $obj = Ctype->new($c);
	$obj->useperlfns if $::useperlfns;
	return $obj->uppercased;
}

sub tolower {
	my $c = shift;
	my $obj = Ctype->new($c);
	$obj->useperlfns if $::useperlfns;
	return $obj->lowercased;
}

sub isalnum {
	my $c = shift;
	my $obj = Ctype->new($c);
	$obj->useperlfns if $::useperlfns;
	return $obj->isalphanumeric;
}

sub isalpha {
	my $c = shift;
	my $obj = Ctype->new($c);
	$obj->useperlfns if $::useperlfns;
	return $obj->isalphabetic;
}

sub isdigit {
	my $c = shift;
	my $obj = Ctype->new($c);
	$obj->useperlfns if $::useperlfns;
	return $obj->isnumeric;
}

sub islower {
	my $c = shift;
	my $obj = Ctype->new($c);
	$obj->useperlfns if $::useperlfns;
	return $obj->islowercase;
}

sub isspace {
	my $c = shift;
	my $obj = Ctype->new($c);
	$obj->useperlfns if $::useperlfns;
	return $obj->iswhitespace;
}

sub isupper {
	my $c = shift;
	my $obj = Ctype->new($c);
	$obj->useperlfns if $::useperlfns;
	return $obj->isuppercase;
}

sub isxdigit {
	my $c = shift;
	my $obj = Ctype->new($c);
	$obj->useperlfns if $::useperlfns;
	return $obj->ishexdigit;
}

sub new {
	my $proto = shift;
	my $class = ref $proto || $proto;
	my $obj = [];
	my $c = shift;
	$obj->[0] = $c;	# character
	$obj->[1] = 0;	# use libperl functions
	bless $obj, $class;
	Ctype_dump $obj;
	return $obj;
}

sub useperlfns {
	my $obj = shift;
	$obj->[1] = !($obj->[1]);
	Ctype_dump $obj;
}

sub setchar {
	my $o = shift;
	$o->[0] = shift;
	Ctype_dump $o;
}

sub lowercased {
	my $obj = shift;
	my $c = $obj->[0];
	my $u = $obj->[1];
	Ctype_dump $obj;
	return $u ? _toLOWER($c) : _tolower($c);
}

sub uppercased {
	my $obj = shift;
	my $c = $obj->[0];
	my $u = $obj->[1];
	return $u ? _toUPPER($c) : _toupper($c);
}

sub isalphanumeric {
	my $obj = shift;
	my $c = $obj->[0];
	my $u = $obj->[1];
	return $u ? _isALNUM($c) : _isalnum($c);
}

sub isalphabetic {
	my $obj = shift;
	my $c = $obj->[0];
	my $u = $obj->[1];
	return $u ? _isALPHA($c) : _isalpha($c);
}

sub isnumerical {
	my $obj = shift;
	my $c = $obj->[0];
	my $u = $obj->[1];
	return $u ? _isDIGIT($c) : _isdigit($c);
}

sub islowercase {
	my $obj = shift;
	my $c = $obj->[0];
	my $u = $obj->[1];
	return $u ? _isLOWER($c) : _islower($c);
}

sub iswhitespace {
	my $obj = shift;
	my $c = $obj->[0];
	my $u = $obj->[1];
	return $u ? _isSPACE($c) : _isspace($c);
}

sub isuppercase {
	my $obj = shift;
	my $c = $obj->[0];
	my $u = $obj->[1];
	return $u ? _isUPPER($c) : _isupper($c);
}

sub _my_isXDIGIT {
	warnings::warnif("deprecated", "isXDIGIT is not offically part of Perl and may be removed");
	return _isXDIGIT(shift);
}

sub ishexdigit {
	my $obj = shift;
	my $c = $obj->[0];
	my $u = $obj->[1];
	return $u ? _my_isXDIGIT($c) : _isxdigit($c);
}

1;
__END__

=head1 NAME

Ctype - Perl extension for character class testing

=head1 SYNOPSIS

  use Ctype qw(toupper);
  # plain style
  $uppercased = toupper("a");
  # OO style
  $obj = Ctype->new("a");
  $uppercased = $obj->uppercased;

=head1 DESCRIPTION

I<Ctype> provides character class testing to Perl programs.  The 
C<ctype.h> functions are part of the C library (in your system!).  
I<Ctype> also supports the Perl library C<ctype> functions.  To use the 
Perl library C<ctype> functions, set the variable $Ctype::useperlfns to 
a non-false value.  For the OO interface, call the method 
$obj->useperlfns to toggle it.  

The OO interface constructor is called (by convention) C<new>.  C<new> 
is called with a character as an argument.  It creates a I<Ctype> object 
that will perform tests on the character when called as an object 
method.  These are the relations to the regular C functions: 

	isalphanumeric		isalnum
	isalphabetic		isalpha
	isnumerical		isdigit
	islowercase		islower
	iswhitespace		isspace
	isuppercase		isupper
	ishexdigit		isxdigit
	
	tolowercase		tolower
	touppercase		toupper

The C<setchar> method sets the character stored in the object.  

=head1 AUTHOR

Samuel Lauber, E<lt>sam124@operamail.comE<gt>

=head1 COPYRIGHT

This module is not copyrighted.  It may be redistributed as much as you want.  

=head1 SEE ALSO

L<perl>, L<ctype.h>, I<DJGPP C Library Refrence>, I<GNU C Library 
Manual>, et al.

=cut
