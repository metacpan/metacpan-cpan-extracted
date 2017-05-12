package Convert::Cyr;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Convert::Cyr ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );
#@_funcs = qw(chcp)

our @EXPORT_OK = ( 'chcp' );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

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
	    croak "Your vendor has not defined Convert::Cyr macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

bootstrap Convert::Cyr $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Convert::Cyr, chcp - Perl module for change cyrillic code page 
of a text.

=head1 SYNOPSIS

use Convert::Cyr qw(chcp);
$converted_string=chcp($string, $maxlen, $from, $to);

=head1 ABSTRACT

Convert::Cyr, chcp - change cyrillic code page of a text.

=head1 DESCRIPTION

chcp takes as the first argument a string that is to be converted.
It returns the converted string. Second argument is the lenght of
the string. Third is source codepage. Forth is target codepage.

Original description from PHP function:

convert_cyr_string (string str, string from, string to)
"This function returns the given string converted from one Cyrillic 
character set to another. The from and to arguments are single 
characters that represent the source and target Cyrillic character sets." 

The supported types are: 
k - koi8-r 
w - windows-1251 
i - iso8859-5 
a - x-cp866 
d - x-cp866 
m - x-mac-cyrillic 

=head2 EXPORT

chcp($string, $maxlen, $from, $to);

=head1 AUTHOR

Konstantin Doulepov <kdoulepov@eur.ko.com>. With code integrated
that was in built-in PHP function of ...


=head1 SEE ALSO

L<perl>.

=cut
