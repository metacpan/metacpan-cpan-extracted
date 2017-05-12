package Acme::Perl::Consensual;

use 5;
use strict;
use POSIX qw(mktime floor);

BEGIN {
	$Acme::Perl::Consensual::AUTHORITY = 'cpan:TOBYINK';
	$Acme::Perl::Consensual::VERSION   = '0.002';
};

# Mostly sourced from
# http://upload.wikimedia.org/wikipedia/commons/4/4e/Age_of_Consent_-_Global.svg
my %requirements = (
	bo => { puberty => 1 },
	ao => { age => 12 },
	(map { $_ => { age => 13 } } qw(
		ar bf es jp km kr ne
	)),
	(map { $_ => { age => 14 } } qw(
		al at ba bd bg br cl cn co de 
		ec ee hr hu it li me mg mk mm 
		mo mw pt py rs sl sm td va
	)),
	(map { $_ => { age => 15 } } qw(
		aw cr cw cz dk fo fr gf gl gn 
		gp gr hn is kh ki kp la mc mf 
		mq pf pl re ro sb se si sk sx 
		sy tf th tv uy vc wf
	)),
	(map { $_ => { age => 16 } } qw(
		ad ag am as ax az bb be bh bm 
		bn bq bs bw by bz ca cc ch ck 
		cm cu dm dz fi fj gb ge gh gi 
		gu gw gy hk il im in je jm jo 
		ke kg kn ky kz lc lk ls lt lu 
		lv md mh mn mr ms mu my mz na 
		nf nl no np nz pg pn pr pw ru 
		sg sj sn sr sz tj tm to tt tw 
		ua um uz ve vu ws za zm zw
	)),
	(map { $_ => { age => 17 } } qw(
		cy ie nr
	)),
	(map { $_ => { age => 18 } } qw(
		bi bj bt cd dj do eg er et ga 
		gm gq gt ht lb lr ma ml mt ng 
		ni pa pe ph ss rw sc sd so sv 
		tr tz ug vi vn
	)),
	id => { age => 19 },
	tn => { age => 20 },
	(map { $_ => { married => 1 } } qw(
		ae af ir kw mv om pk qa sa ye
	)),
	(map { $_ => undef } qw(
		ai bl bv cf cg ci cv cx eh fk 
		fm gd gg hm io iq ly mp nc nu 
		pm ps sh st tc tg tl vg
	)),
	# There are US federal laws, but they're fairly complicated for a little
	# module like this to assess, and the state laws (below) are generally
	# more relevant.
	us => undef,
	(map { ;"us-$_" => { age => 16 } } qw(
		al ak ar ct dc ga hi id ia ks
		ky me md ma mi mn ms mt nv nh
		nj nc oh ok ri sc sd vt wa wv
	)),
	(map { ;"us-$_" => { age => 17 } } qw(
		co il la mo ne nm ny tx wy
	)),
	(map { ;"us-$_" => { age => 18 } } qw(
		az ca de fl id nd or tn ut va
		wi pa
	)),
	# Australian federal laws apply to Australian citizens while outside
	# Australia; while inside Australia only state laws are relevant.
	au => undef,
	(map { ;"au-$_" => { age => 16 } } qw(
		act nsw nt qld vic wa
	)),
	(map { ;"au-$_" => { age => 17 } } qw(
		sa tas
	)),
	mx => { age => 12 },
	(map { ;"mx-$_" => { age => 12 } } qw(
		agu bcs cam chp coa dif gua gro
		hid jal mic mor oax pue que roo
		slp sin son tab 
	)),
	(map { ;"mx-$_" => { age => 13 } } qw(
		yuc zac
	)),
	(map { ;"mx-$_" => { age => 14 } } qw(
		bcn chh col dur nle tla ver
	)),
	"mx-mex" => { age => 15 },
	"mx-nay" => { puberty => 1 },
);

my %perlhist;

sub new
{
	my ($class, %args) = @_;
	$args{locale} = $ENV{LC_ALL} || $ENV{LC_LEGAL} || 'en_XX.UTF-8'
		unless exists $args{locale};
	$args{locale} = $1
		if $args{locale} =~ /^.._(.+?)(\.|$)/;
	bless \%args => $class;
}

sub locale
{
	lc shift->{locale};
}

sub can
{
	if (@_ == 2 and not ref $_[1])
	{
		shift->SUPER::can(@_);
	}
	else
	{
		shift->_can_consent(@_);
	}
}

sub _can_consent
{
	my $self     = ref $_[0] ? shift : shift->new;
	
	my $provides = ref $_[0] ? shift : +{@_};
	my $requires = $requirements{ $self->locale };
	
	# If locale includes a region, fallback to country.
	if ($self->locale =~ /^([a-z]{2})-/)
	{
		$requires ||= $requirements{ $1 };
	}
	
	return undef unless defined $requires;
	
	for (keys %$requires)
	{
		return undef unless defined $provides->{$_};
		return !1 unless $provides->{$_} >= $requires->{$_};
	}
	
	!0;
}

sub age_of_perl
{
	my $class = shift;
	return $class->age_of_perl_in_seconds(shift)
		/ 31_556_736 # 365.24 * 24 * 60 * 60
}

sub age_of_perl_in_seconds
{
	my ($class, $v) = @_;
	$v ||= $];
		
	my $pl_date = do
	{
		$class->_perlhist;
	
		my $date = $perlhist{$v};
		unless ($date)
		{
			for (sort keys %perlhist)
			{
				next if $_ lt $v;  # XXX: need smarter version matching!
				$date = $perlhist{$_} and last;
			}
		}
		return unless $date;
		$class->_parse_date($date);
	};
	
	return time() - $pl_date;
}

sub _parse_date
{
	my ($class, $date) = @_;
	my ($y, $m, $d) = split '-', $date;
	
	$m = {
		Jan => 0x00,
		Feb => 0x01,
		Mar => 0x02,
		Apr => 0x03,
		May => 0x04,
		Jun => 0x05,
		Jul => 0x06,
		Aug => 0x07,
		Sep => 0x08,
		Oct => 0x09,
		Nov => 0x0A,
		Dec => 0x0B,
	}->{$m};
	
	return mktime(0, 0, 0, $d, $m, $y - 1900);
}

sub _perlhist
{
	unless (%perlhist)
	{
		my $prev_date;
		while ( <DATA> )
		{
			if (/([1-5]\.[A-Za-z0-9\._]+)\s+(\d{4}-[\?\w]{3}-[\?\d]{2})/)
			{
				my $vers = $1;
				my $date = $2;
				my @vers = ($vers);
				
				if ($vers =~ /^(\d)\.(\d{3})\.\.(\d*)/)
				{
					@vers = ();
					for (my $i = $2; $i >= $3; $i++)
					{
						push @vers, sprintf "%d.%03d", $1, $i;
					}
				}
				
				if ($date =~ /\?/)
				{
					$date = $prev_date;
				}
				else
				{
					$prev_date = $date;
				}
				
				$perlhist{$_} = $date for @vers;
			}
		}
	}
}

sub perl_can
{
	my $self = shift;
	$self->can(
		age     => floor($self->age_of_perl(shift)),
		puberty => 1,
	);
}

sub import
{
	my $class = shift;
	
	if (grep { $_ eq '-check' } @_)
	{
		require Carp;
		Carp::croak("Perl $] failed age of consent check, died")
			unless $class->new->perl_can;
	}
}

1;

=head1 NAME

Acme::Perl::Consensual - check that your version of Perl is old enough to consent

=head1 DESCRIPTION

This module checks that your version of Perl is old enough to consent to
sexual activity. It could be considered a counterpart for L<Modern::Perl>.

=head2 Constructor

=over

=item C<< new(locale => $locale) >>

Creates a new Acme::Perl::Consensual object which can act as an age of consent
checker for a particular locale.

The locale string should be an ISO 3166 alpha2 country code such as "US" for
the United States, "GB" for the United Kingdom or "DE" for Germany. It may
optionally include a hyphen followed by a subdivision designator, such as
"US-TX" for Texas, United States, "AU-NSW" for New South Wales, Australia or
"GB-WLS" for Wales, United Kingdom.

If the locale is omitted, the module will attempt to extract the locale
from the LC_LEGAL or LC_ALL environment variable.

=back

=head2 Methods

=over

=item C<< locale >>

Returns the locale provided to the constructor, or detected from environment
variables, lower-cased.

=item C<< can(%details) >>

Given a person's details (or a piece of software's details), returns true if
they are legally able to consent. For example:

	my $can_consent = $acme->can(age => 26, married => 1);

Currently recognised details are 'age' (in years), 'married' (0 for no, 1 for
yes) and 'puberty' (0 for no, 1 for yes).

If called with a single scalar argument, acts like UNIVERSAL::can (see
L<UNIVERSAL>).

=item C<< age_of_perl_in_seconds($version) >>

The age of a particular release of Perl, in seconds. (Actually we don't know
exactly what time of day Perl was released, so we assume midnight on the
release date.)

If C<< $version >> is omitted, then the current version.

=item C<< age_of_perl($version) >>

As per C<age_of_perl_in_seconds>, but measured in years. Returns a floating
point. Use POSIX::floor to round down to the nearest whole number. This
method assumes that all years are 365.24 days long, and all days are 86400
(i.e. 24*60*60) seconds long. 

=item C<< perl_can($version) >>

Shorthand for:

	$acme->can(
		age     => POSIX::floor($acme->age_of_perl($version)),
		puberty => 1, # Perl is regarded as a mature programming language
	);

=back

=head2 Import

Passing a "-check" parameter on import:

	use Acme::Perl::Consensual -check;

is a shorthand for:

	BEGIN {
		require Acme::Perl::Consensual;
		Acme::Perl::Consensual->new()->perl_can()
			or die "Perl $] failed age of consent check, died";
	}

That is, it's the opposite of C<< use Modern::Perl >>. It requires your
version of Perl to be past the age of consent in your locale.

=head1 CAVEATS

Most jurisdictions have legal subtleties that this module cannot take into
account. Use of this module does not constitute a legal defence.

Even if you obtain consent from Perl, there are practical limits to what you
could actually do with it, sexually.

=head1 INSTALL

While this distribution is believed to work in any version of Perl 5, it has
only been tested so far in Perl 5.8+. In older versions of Perl, Makefile.PL
may not run, but the library can be manually installed by copying
C<< lib/Acme/Perl/Consensual.pm >> to an appropriate location.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Acme-Perl-Consensual>.

=head1 SEE ALSO

L<Sex>, L<XXX>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>, but MSCHWERN deserves at least a
little of the blame.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

# Data below reproduced from `perldoc -T -t perlhist`

__DATA__
 Larry   0              Classified.     Don't ask.
 
 Larry   1.000          1987-Dec-18
 
          1.001..10     1988-Jan-30
          1.011..14     1988-Feb-02
 Schwern  1.0.15        2002-Dec-18     Modernization
 Richard  1.0_16        2003-Dec-18
 
 Larry   2.000          1988-Jun-05
 
          2.001         1988-Jun-28
 
 Larry   3.000          1989-Oct-18
 
          3.001         1989-Oct-26
          3.002..4      1989-Nov-11
          3.005         1989-Nov-18
          3.006..8      1989-Dec-22
          3.009..13     1990-Mar-02
          3.014         1990-Mar-13
          3.015         1990-Mar-14
          3.016..18     1990-Mar-28
          3.019..27     1990-Aug-10     User subs.
          3.028         1990-Aug-14
          3.029..36     1990-Oct-17
          3.037         1990-Oct-20
          3.040         1990-Nov-10
          3.041         1990-Nov-13
          3.042..43     1991-Jan-??
          3.044         1991-Jan-12
 
 Larry   4.000          1991-Mar-21
 
          4.001..3      1991-Apr-12
          4.004..9      1991-Jun-07
          4.010         1991-Jun-10
          4.011..18     1991-Nov-05
          4.019         1991-Nov-11     Stable.
          4.020..33     1992-Jun-08
          4.034         1992-Jun-11
          4.035         1992-Jun-23
 Larry    4.036         1993-Feb-05     Very stable.
 
          5.000alpha1   1993-Jul-31
          5.000alpha2   1993-Aug-16
          5.000alpha3   1993-Oct-10
          5.000alpha4   1993-???-??
          5.000alpha5   1993-???-??
          5.000alpha6   1994-Mar-18
          5.000alpha7   1994-Mar-25
 Andy     5.000alpha8   1994-Apr-04
 Larry    5.000alpha9   1994-May-05     ext appears.
          5.000alpha10  1994-Jun-11
          5.000alpha11  1994-Jul-01
 Andy     5.000a11a     1994-Jul-07     To fit 14.
          5.000a11b     1994-Jul-14
          5.000a11c     1994-Jul-19
          5.000a11d     1994-Jul-22
 Larry    5.000alpha12  1994-Aug-04
 Andy     5.000a12a     1994-Aug-08
          5.000a12b     1994-Aug-15
          5.000a12c     1994-Aug-22
          5.000a12d     1994-Aug-22
          5.000a12e     1994-Aug-22
          5.000a12f     1994-Aug-24
          5.000a12g     1994-Aug-24
          5.000a12h     1994-Aug-24
 Larry    5.000beta1    1994-Aug-30
 Andy     5.000b1a      1994-Sep-06
 Larry    5.000beta2    1994-Sep-14     Core slushified.
 Andy     5.000b2a      1994-Sep-14
          5.000b2b      1994-Sep-17
          5.000b2c      1994-Sep-17
 Larry    5.000beta3    1994-Sep-??
 Andy     5.000b3a      1994-Sep-18
          5.000b3b      1994-Sep-22
          5.000b3c      1994-Sep-23
          5.000b3d      1994-Sep-27
          5.000b3e      1994-Sep-28
          5.000b3f      1994-Sep-30
          5.000b3g      1994-Oct-04
 Andy     5.000b3h      1994-Oct-07
 Larry?   5.000gamma    1994-Oct-13?
 
 Larry   5.000          1994-Oct-17
 
 Andy     5.000a        1994-Dec-19
          5.000b        1995-Jan-18
          5.000c        1995-Jan-18
          5.000d        1995-Jan-18
          5.000e        1995-Jan-18
          5.000f        1995-Jan-18
          5.000g        1995-Jan-18
          5.000h        1995-Jan-18
          5.000i        1995-Jan-26
          5.000j        1995-Feb-07
          5.000k        1995-Feb-11
          5.000l        1995-Feb-21
          5.000m        1995-Feb-28
          5.000n        1995-Mar-07
          5.000o        1995-Mar-13?
 
 Larry   5.001          1995-Mar-13
 
 Andy     5.001a        1995-Mar-15
          5.001b        1995-Mar-31
          5.001c        1995-Apr-07
          5.001d        1995-Apr-14
          5.001e        1995-Apr-18     Stable.
          5.001f        1995-May-31
          5.001g        1995-May-25
          5.001h        1995-May-25
          5.001i        1995-May-30
          5.001j        1995-Jun-05
          5.001k        1995-Jun-06
          5.001l        1995-Jun-06     Stable.
          5.001m        1995-Jul-02     Very stable.
          5.001n        1995-Oct-31     Very unstable.
          5.002beta1    1995-Nov-21
          5.002b1a      1995-Dec-04
          5.002b1b      1995-Dec-04
          5.002b1c      1995-Dec-04
          5.002b1d      1995-Dec-04
          5.002b1e      1995-Dec-08
          5.002b1f      1995-Dec-08
 Tom      5.002b1g      1995-Dec-21     Doc release.
 Andy     5.002b1h      1996-Jan-05
          5.002b2       1996-Jan-14
 Larry    5.002b3       1996-Feb-02
 Andy     5.002gamma    1996-Feb-11
 Larry    5.002delta    1996-Feb-27
 
 Larry   5.002          1996-Feb-29     Prototypes.
 
 Charles  5.002_01      1996-Mar-25
 
         5.003          1996-Jun-25     Security release.
 
          5.003_01      1996-Jul-31
 Nick     5.003_02      1996-Aug-10
 Andy     5.003_03      1996-Aug-28
          5.003_04      1996-Sep-02
          5.003_05      1996-Sep-12
          5.003_06      1996-Oct-07
          5.003_07      1996-Oct-10
 Chip     5.003_08      1996-Nov-19
          5.003_09      1996-Nov-26
          5.003_10      1996-Nov-29
          5.003_11      1996-Dec-06
          5.003_12      1996-Dec-19
          5.003_13      1996-Dec-20
          5.003_14      1996-Dec-23
          5.003_15      1996-Dec-23
          5.003_16      1996-Dec-24
          5.003_17      1996-Dec-27
          5.003_18      1996-Dec-31
          5.003_19      1997-Jan-04
          5.003_20      1997-Jan-07
          5.003_21      1997-Jan-15
          5.003_22      1997-Jan-16
          5.003_23      1997-Jan-25
          5.003_24      1997-Jan-29
          5.003_25      1997-Feb-04
          5.003_26      1997-Feb-10
          5.003_27      1997-Feb-18
          5.003_28      1997-Feb-21
          5.003_90      1997-Feb-25     Ramping up to the 5.004 release.
          5.003_91      1997-Mar-01
          5.003_92      1997-Mar-06
          5.003_93      1997-Mar-10
          5.003_94      1997-Mar-22
          5.003_95      1997-Mar-25
          5.003_96      1997-Apr-01
          5.003_97      1997-Apr-03     Fairly widely used.
          5.003_97a     1997-Apr-05
          5.003_97b     1997-Apr-08
          5.003_97c     1997-Apr-10
          5.003_97d     1997-Apr-13
          5.003_97e     1997-Apr-15
          5.003_97f     1997-Apr-17
          5.003_97g     1997-Apr-18
          5.003_97h     1997-Apr-24
          5.003_97i     1997-Apr-25
          5.003_97j     1997-Apr-28
          5.003_98      1997-Apr-30
          5.003_99      1997-May-01
          5.003_99a     1997-May-09
          p54rc1        1997-May-12     Release Candidates.
          p54rc2        1997-May-14
 
 Chip    5.004          1997-May-15     A major maintenance release.
 
 Tim      5.004_01-t1   1997-???-??     The 5.004 maintenance track.
          5.004_01-t2   1997-Jun-11     aka perl5.004m1t2
          5.004_01      1997-Jun-13
          5.004_01_01   1997-Jul-29     aka perl5.004m2t1
          5.004_01_02   1997-Aug-01     aka perl5.004m2t2
          5.004_01_03   1997-Aug-05     aka perl5.004m2t3
          5.004_02      1997-Aug-07
          5.004_02_01   1997-Aug-12     aka perl5.004m3t1
          5.004_03-t2   1997-Aug-13     aka perl5.004m3t2
          5.004_03      1997-Sep-05
          5.004_04-t1   1997-Sep-19     aka perl5.004m4t1
          5.004_04-t2   1997-Sep-23     aka perl5.004m4t2
          5.004_04-t3   1997-Oct-10     aka perl5.004m4t3
          5.004_04-t4   1997-Oct-14     aka perl5.004m4t4
          5.004_04      1997-Oct-15
          5.004_04-m1   1998-Mar-04     (5.004m5t1) Maint. trials for 5.004_05.
          5.004_04-m2   1998-May-01
          5.004_04-m3   1998-May-15
          5.004_04-m4   1998-May-19
          5.004_05-MT5  1998-Jul-21
          5.004_05-MT6  1998-Oct-09
          5.004_05-MT7  1998-Nov-22
          5.004_05-MT8  1998-Dec-03
 Chip     5.004_05-MT9  1999-Apr-26
          5.004_05      1999-Apr-29
 
 Malcolm  5.004_50      1997-Sep-09     The 5.005 development track.
          5.004_51      1997-Oct-02
          5.004_52      1997-Oct-15
          5.004_53      1997-Oct-16
          5.004_54      1997-Nov-14
          5.004_55      1997-Nov-25
          5.004_56      1997-Dec-18
          5.004_57      1998-Feb-03
          5.004_58      1998-Feb-06
          5.004_59      1998-Feb-13
          5.004_60      1998-Feb-20
          5.004_61      1998-Feb-27
          5.004_62      1998-Mar-06
          5.004_63      1998-Mar-17
          5.004_64      1998-Apr-03
          5.004_65      1998-May-15
          5.004_66      1998-May-29
 Sarathy  5.004_67      1998-Jun-15
          5.004_68      1998-Jun-23
          5.004_69      1998-Jun-29
          5.004_70      1998-Jul-06
          5.004_71      1998-Jul-09
          5.004_72      1998-Jul-12
          5.004_73      1998-Jul-13
          5.004_74      1998-Jul-14     5.005 beta candidate.
          5.004_75      1998-Jul-15     5.005 beta1.
          5.004_76      1998-Jul-21     5.005 beta2.
 
 Sarathy  5.005         1998-Jul-22     Oneperl.
 
 Sarathy  5.005_01      1998-Jul-27     The 5.005 maintenance track.
          5.005_02-T1   1998-Aug-02
          5.005_02-T2   1998-Aug-05
          5.005_02      1998-Aug-08
 Graham   5.005_03-MT1  1998-Nov-30
          5.005_03-MT2  1999-Jan-04
          5.005_03-MT3  1999-Jan-17
          5.005_03-MT4  1999-Jan-26
          5.005_03-MT5  1999-Jan-28
          5.005_03-MT6  1999-Mar-05
          5.005_03      1999-Mar-28
 Leon     5.005_04-RC1  2004-Feb-05
          5.005_04-RC2  2004-Feb-18
          5.005_04      2004-Feb-23
          5.005_05-RC1  2009-Feb-16
 
 Sarathy  5.005_50      1998-Jul-26     The 5.6 development track.
          5.005_51      1998-Aug-10
          5.005_52      1998-Sep-25
          5.005_53      1998-Oct-31
          5.005_54      1998-Nov-30
          5.005_55      1999-Feb-16
          5.005_56      1999-Mar-01
          5.005_57      1999-May-25
          5.005_58      1999-Jul-27
          5.005_59      1999-Aug-02
          5.005_60      1999-Aug-02
          5.005_61      1999-Aug-20
          5.005_62      1999-Oct-15
          5.005_63      1999-Dec-09
          5.5.640       2000-Feb-02
          5.5.650       2000-Feb-08     beta1
          5.5.660       2000-Feb-22     beta2
          5.5.670       2000-Feb-29     beta3
          5.6.0-RC1     2000-Mar-09     Release candidate 1.
          5.6.0-RC2     2000-Mar-14     Release candidate 2.
          5.6.0-RC3     2000-Mar-21     Release candidate 3.
 
 Sarathy  5.6.0         2000-Mar-22
 
 Sarathy  5.6.1-TRIAL1  2000-Dec-18     The 5.6 maintenance track.
          5.6.1-TRIAL2  2001-Jan-31
          5.6.1-TRIAL3  2001-Mar-19
          5.6.1-foolish 2001-Apr-01     The "fools-gold" release.
          5.6.1         2001-Apr-08
 Rafael   5.6.2-RC1     2003-Nov-08
          5.6.2         2003-Nov-15     Fix new build issues
 
 Jarkko   5.7.0         2000-Sep-02     The 5.7 track: Development.
          5.7.1         2001-Apr-09
          5.7.2         2001-Jul-13     Virtual release candidate 0.
          5.7.3         2002-Mar-05
          5.8.0-RC1     2002-Jun-01
          5.8.0-RC2     2002-Jun-21
          5.8.0-RC3     2002-Jul-13
 
 Jarkko   5.8.0         2002-Jul-18
 
 Jarkko   5.8.1-RC1     2003-Jul-10     The 5.8 maintenance track
          5.8.1-RC2     2003-Jul-11
          5.8.1-RC3     2003-Jul-30
          5.8.1-RC4     2003-Aug-01
          5.8.1-RC5     2003-Sep-22
          5.8.1         2003-Sep-25
 Nicholas 5.8.2-RC1     2003-Oct-27
          5.8.2-RC2     2003-Nov-03
          5.8.2         2003-Nov-05
          5.8.3-RC1     2004-Jan-07
          5.8.3         2004-Jan-14
          5.8.4-RC1     2004-Apr-05
          5.8.4-RC2     2004-Apr-15
          5.8.4         2004-Apr-21
          5.8.5-RC1     2004-Jul-06
          5.8.5-RC2     2004-Jul-08
          5.8.5         2004-Jul-19
          5.8.6-RC1     2004-Nov-11
          5.8.6         2004-Nov-27
          5.8.7-RC1     2005-May-18
          5.8.7         2005-May-30
          5.8.8-RC1     2006-Jan-20
          5.8.8         2006-Jan-31
          5.8.9-RC1     2008-Nov-10
          5.8.9-RC2     2008-Dec-06
          5.8.9         2008-Dec-14
 
 Hugo     5.9.0         2003-Oct-27     The 5.9 development track
 Rafael   5.9.1         2004-Mar-16
          5.9.2         2005-Apr-01
          5.9.3         2006-Jan-28
          5.9.4         2006-Aug-15
          5.9.5         2007-Jul-07
          5.10.0-RC1    2007-Nov-17
          5.10.0-RC2    2007-Nov-25
 
 Rafael   5.10.0        2007-Dec-18
 
 David M  5.10.1-RC1    2009-Aug-06     The 5.10 maintenance track
          5.10.1-RC2    2009-Aug-18
          5.10.1        2009-Aug-22
 
 Jesse    5.11.0        2009-Oct-02     The 5.11 development track
          5.11.1        2009-Oct-20
 Leon     5.11.2        2009-Nov-20
 Jesse    5.11.3        2009-Dec-20
 Ricardo  5.11.4        2010-Jan-20
 Steve    5.11.5        2010-Feb-20
 Jesse    5.12.0-RC0    2010-Mar-21
          5.12.0-RC1    2010-Mar-29
          5.12.0-RC2    2010-Apr-01
          5.12.0-RC3    2010-Apr-02
          5.12.0-RC4    2010-Apr-06
          5.12.0-RC5    2010-Apr-09
 
 Jesse    5.12.0        2010-Apr-12
 
 Jesse    5.12.1-RC2    2010-May-13     The 5.12 maintenance track
          5.12.1-RC1    2010-May-09
          5.12.1        2010-May-16
          5.12.2-RC2    2010-Aug-31
          5.12.2        2010-Sep-06
 Ricardo  5.12.3-RC1    2011-Jan-09
 Ricardo  5.12.3-RC2    2011-Jan-14
 Ricardo  5.12.3-RC3    2011-Jan-17
 Ricardo  5.12.3        2011-Jan-21
 Leon     5.12.4-RC1    2011-Jun-08
 Leon     5.12.4        2011-Jun-20
 Dominic  5.12.5        2012-Nov-10
 
 Leon     5.13.0        2010-Apr-20     The 5.13 development track
 Ricardo  5.13.1        2010-May-20
 Matt     5.13.2        2010-Jun-22
 David G  5.13.3        2010-Jul-20
 Florian  5.13.4        2010-Aug-20
 Steve    5.13.5        2010-Sep-19
 Miyagawa 5.13.6        2010-Oct-20
 BinGOs   5.13.7        2010-Nov-20
 Zefram   5.13.8        2010-Dec-20
 Jesse    5.13.9        2011-Jan-20
 Ævar     5.13.10       2011-Feb-20
 Florian  5.13.11       2011-Mar-20
 Jesse    5.14.0RC1     2011-Apr-20
 Jesse    5.14.0RC2     2011-May-04
 Jesse    5.14.0RC3     2011-May-11
 
 Jesse    5.14.0        2011-May-14     The 5.14 maintenance track
 Jesse    5.14.1        2011-Jun-16
 Florian  5.14.2-RC1    2011-Sep-19
          5.14.2        2011-Sep-26
 Dominic  5.14.3        2012-Oct-12
 David M  5.14.4-RC1    2013-Mar-05
 David M  5.14.4-RC2    2013-Mar-07
 David M  5.14.4        2013-Mar-10
 
 David G  5.15.0        2011-Jun-20     The 5.15 development track
 Zefram   5.15.1        2011-Jul-20
 Ricardo  5.15.2        2011-Aug-20
 Stevan   5.15.3        2011-Sep-20
 Florian  5.15.4        2011-Oct-20
 Steve    5.15.5        2011-Nov-20
 Dave R   5.15.6        2011-Dec-20
 BinGOs   5.15.7        2012-Jan-20
 Max M    5.15.8        2012-Feb-20
 Abigail  5.15.9        2012-Mar-20
 Ricardo  5.16.0-RC0    2012-May-10
 Ricardo  5.16.0-RC1    2012-May-14
 Ricardo  5.16.0-RC2    2012-May-15
 
 Ricardo  5.16.0        2012-May-20     The 5.16 maintenance track
 Ricardo  5.16.1        2012-Aug-08
 Ricardo  5.16.2        2012-Nov-01
 Ricardo  5.16.3-RC1    2013-Mar-06
 Ricardo  5.16.3        2013-Mar-11
 
 Zefram   5.17.0        2012-May-26     The 5.17 development track
 Jesse L  5.17.1        2012-Jun-20
 TonyC    5.17.2        2012-Jul-20
 Steve    5.17.3        2012-Aug-20
 Florian  5.17.4        2012-Sep-20
 Florian  5.17.5        2012-Oct-20
 Ricardo  5.17.6        2012-Nov-20
 Dave R   5.17.7        2012-Dec-18
 Aaron    5.17.8        2013-Jan-20
 BinGOs   5.17.9        2013-Feb-20
 Max M    5.17.10       2013-Mar-21
 
 Ricardo  5.18.0-RC1    2013-May-11
 Ricardo  5.18.0-RC2    2013-May-12
 Ricardo  5.18.0-RC3    2013-May-13
 Ricardo  5.18.0-RC4    2013-May-15
 
 Ricardo  5.18.0        2012-May-18     The 5.18 maintenance track
