package Convert::Recode;

# $Id: Recode.pm,v 1.6 2003/12/18 10:24:32 gisle Exp $

use strict;

use vars qw($VERSION $DEBUG);
$VERSION = "1.04";

use Carp qw(croak);
use File::Spec;
my $devnull = File::Spec->devnull;


sub import
{
    my $class = shift;
    my $pkg = caller;

    my $subname;
    for $subname (@_) {
	unless ($subname =~ /^(strict_)?(\w+)_to_(\w+)$/) {
	    croak("recode routine name must be on the form: xxx_to_yyy");
	}
	local(*RECODE, $_);
	my $strict = $1 ? "s" : "";  # strict mode flag
	open(RECODE, "recode -${strict}h $2..$3 2>$devnull|") or die;
	my @codes;
	while (<RECODE>) {
	    push(@codes, /(\d+|\"[^\"]*\"),/g);
	}
	close(RECODE);
	die "Can't recode $subname, 'recode -l' for available charsets\n"
	  unless @codes == 256;

	my $code;
	if ($strict) {
	    my $c = 0;
	    my $from = "";  # all chars (matching $to$del)
	    my $to   = "";  # transformation
	    my $del  = "";  # no tranformation available (to be deleted)
	    for (@codes) {
		my $o = sprintf("\\%03o", $c);
		if ($_ eq "0" || $_ eq '""') {
		    $del .= $o;
		    next;
		}
		$from .= $o;
		s/^\"//; s/\"$//;
		$to   .= $_;
	    } continue {
		$c++;
	    }
	    $to =~ s,/,\\/,;
	    $code = 'sub ($){ my $tmp = shift; $tmp =~ ' .
                    "tr/$from$del/$to/d; \$tmp }";
	} else {
	    $code = 'sub ($) { my $tmp = shift; $tmp =~ tr/\x00-\xFF/' .
	            join("", map sprintf("\\x%02X", $_), @codes) .
	            '/; $tmp }';
	}

	print STDERR $code if $DEBUG;
	my $sub = eval $code;
	die if $@;
	no strict 'refs';
	*{$pkg . "::" . $subname} = $sub;
    }
}

1;

__END__

=head1 NAME

Convert::Recode - make mapping functions between character sets

=head1 SYNOPSIS

  use Convert::Recode qw(ebcdic_to_ascii);

  while (<>) {
     print ebcdic_to_ascii($_);
  }

=head1 DESCRIPTION

The Convert::Recode module can provide mapping functions between
character sets on demand.  It depends on GNU recode to provide the raw
mapping data, i.e. GNU recode must be installed first.  The name of
the mapping function is constructed by taking the names of the two charsets
and joining them with the string "_to_".  For example, if you want to convert
between the "mac" and the "latin1" charsets, just import the
mac_to_latin1() function.

If you prefix the function name with "strict_", any characters that
cannot be mapped are removed during transformation.  For instance, the
strict_mac_to_latin1() function converts a string to latin1 and
removes all mac characters that do not have a corresponding latin1
character.

Running the command C<recode -l> should give you the list of available
character sets.

=head1 COPYRIGHT

© 1997,2003 Gisle Aas.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
