# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2009,2010 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Acme::Study::OS::DateLocales;

use 5.008;

use strict;
our $VERSION = '0.03';

use base qw(Exporter);
our @EXPORT = qw(weekday_and_month_names_dump);

use Data::Dumper qw(Dumper);
use File::Spec::Functions qw(file_name_is_absolute);
use POSIX qw(strftime);

sub all_locales {
    my @res;
    if (_is_in_path("locale")) {
	open my $fh, "-|", "locale", "-a"
	    or die $!;
	while(<$fh>) {
	    chomp;
	    push @res, $_;
	    last if @res > 300; # Sanity check: limit to at most 300 locales. FreeBSD 7.x has 163.
	}
	close $fh
	    or die $!;
    }
    @res;
}

sub weekday_and_month_names {
    my @res;
    my @locales = all_locales();
    if (!@locales) {
	push @locales, ""; # means: use default locale
    }

    my %register;
    my $fingerprint_data = sub {
	my($ref) = @_;
	local $Data::Dumper::Indent = 0;
	local $Data::Dumper::Useqq = 0;
	local $Data::Dumper::Sortkeys = 1;
	Dumper($ref);
    };
    my $register_and_use_data = sub {
	my($ref, $name) = @_;
	my $fingerprint = $fingerprint_data->($ref);
	if (exists $register{$fingerprint}) {
	    +{ '==' => $register{$fingerprint} };
	} else {
	    $register{$fingerprint} = $name;
	    $ref;
	}
    };

    for my $locale (@locales) {

	my $locname;
	if ($locale eq '') {
	    $locname = '<default>';
	} else {
	    $locname = $locale;
	    POSIX::setlocale(&POSIX::LC_ALL, $locale);
	    POSIX::setlocale(&POSIX::LC_TIME, $locale);
	}

	my %locale_res;
	{
	    my @l = (0,0,0,1,undef,2000-1900);
	    for my $mon (1..12) {
		$l[4] = $mon-1;
		push @{$locale_res{'%B'}},  strftime("%B", @l);
		push @{$locale_res{'%b'}},  strftime("%b", @l);
		push @{$locale_res{'%OB'}}, strftime("%OB", @l);
	    }
	}

	{
	    my @l = (0,0,0,1,1,1,undef);
	    foreach my $wkday (0..6) {
		$l[6] = $wkday;
		push @{$locale_res{'%A'}},  strftime("%A", @l);
		push @{$locale_res{'%a'}},  strftime("%a", @l);
	    }
	}

	# Order of the register_and_use_data calls is crucial here:
	# first do it for the whole dataset, and then for every
	# embedded array.
	my $locale_res = $register_and_use_data->(\%locale_res, $locname);
	unless ($locale_res->{'=='}) {
	    for my $key (keys %$locale_res) {
		$locale_res->{$key} = $register_and_use_data->($locale_res->{$key}, $key);
	    }
	}

	push @res, {
		    # 'n' (name) has a leading space, to have it first
		    # in the Sortkeys-sorted dump
		    " n" => $locname,
		    "d" => $locale_res,
		   };
    }
    @res;
}

sub weekday_and_month_names_dump {
    my @res = weekday_and_month_names();
    join "\n", map {
	Data::Dumper->new([$_],['r'])->Useqq(1)->Indent(0)->Sortkeys(1)->Dump
    } @res;
}

# REPO BEGIN
sub _is_in_path {
    my($prog) = @_;
    if (file_name_is_absolute($prog)) {
	if ($^O eq 'MSWin32') {
	    return $prog       if (-f $prog && -x $prog);
	    return "$prog.bat" if (-f "$prog.bat" && -x "$prog.bat");
	    return "$prog.com" if (-f "$prog.com" && -x "$prog.com");
	    return "$prog.exe" if (-f "$prog.exe" && -x "$prog.exe");
	    return "$prog.cmd" if (-f "$prog.cmd" && -x "$prog.cmd");
	} else {
	    return $prog if -f $prog and -x $prog;
	}
    }
    require Config;
    %Config::Config = %Config::Config if 0; # cease -w
    my $sep = $Config::Config{'path_sep'} || ':';
    foreach (split(/$sep/o, $ENV{PATH})) {
	if ($^O eq 'MSWin32') {
	    # maybe use $ENV{PATHEXT} like maybe_command in ExtUtils/MM_Win32.pm?
	    return "$_\\$prog"     if (-f "$_\\$prog" && -x "$_\\$prog");
	    return "$_\\$prog.bat" if (-f "$_\\$prog.bat" && -x "$_\\$prog.bat");
	    return "$_\\$prog.com" if (-f "$_\\$prog.com" && -x "$_\\$prog.com");
	    return "$_\\$prog.exe" if (-f "$_\\$prog.exe" && -x "$_\\$prog.exe");
	    return "$_\\$prog.cmd" if (-f "$_\\$prog.cmd" && -x "$_\\$prog.cmd");
	} else {
	    return "$_/$prog" if (-x "$_/$prog" && !-d "$_/$prog");
	}
    }
    undef;
}
# REPO END


1;

__END__

=head1 NAME

Acme::Study::OS::DateLocales - study date-specific locales

=head1 SYNOPSIS

None. Just run the Pod.

=head1 DESCRIPTION

This module misuses the CPAN testers system to study the result of
date-specific locale operations. Some of the questions to answer:

=over

=item Can we rely on the fact that the locale implementation will
return "bytes" in the given charset (encoding)?

=item Is the %OB extension of L<POSIX/strftime> supported?

=back

The results make me believe that one should not use POSIX-based
locales for dates, but rather use L<DateTime::Locale>.

=head2 RESULTS

 * Solaris 10:
   * does not understand %OB
   * %B seems to return the genitive form
   * the "short" locale names seem to link to the non-utf8 forms (iso-8859-1 or so)
   * encoding seems to match the locale charset
   * all Serbian variants are cyrillic
 * FreeBSD 6.2, 7.0, 7.2:
   * understands %OB, which is usually the nominative form of month names
   * %B has the genitive form (modulo bugs, see the Croatian locale)
   * encoding matches the locale charset
   * the ISO8859-2 variant of Serbian is latin, all others are cyrillic
   * it seems that all of locales are installed by default
 * Linux (debian lenny):
   * does not understand %OB
   * encoding seems to match the locale charset
 * Linux (debian etch):
   * does not understand %OB
   * %B returns the nominative form (at least for Croatian)
   * encoding seems to match the locale charset
   * the "short" locale names seem to link to the non-utf8 forms (iso-8859-1 or so)
 * Linux (s390x-linux):
   * does not understand %OB
   * %B returns the nominative form (at least for Bosnian and Czech)
   * the @euro form seems to be the same like the "short" locale (that is, iso-8859-15 or so)
 * OpenBSD 4.5:
   * does not seem to have the "locales -a" command, so only the default locale was tested
   * understands %OB, contents (genitive vs. nominative) unclear
 * Darwin 8:
   * understands %OB, and seems to have the same bugs as the FreeBSD version
     (Croatian locale)
   * encoding matches the locale charset
   * the ISO8859-2 variant of Serbian is latin, all others are cyrillic
   * it seems that all of locales are installed by default
 * MSWin32:
   * does not understand %OB
 * cygwin:
   * does not seem to have the "locales -a" command, so only the default locale was tested
   * understands %OB, contents (genitive vs. nominative) unclear
 * irix 6.5:
   * does not understand %OB
   * does not have utf-8 locales, but iso-8859-15 locales
   * the non-latin-1 locales (latin2, russian) don't have an encoding spec in its
     locale name, so detecting the encoding must be done through an heuristic

=head1 AUTHOR

Slaven Rezic.

=head1 SEE ALSO

L<Acme::Study::Perl>.

=cut
