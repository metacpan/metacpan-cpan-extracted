package Data::Peek;

use strict;
use warnings;

use DynaLoader ();

use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK );
$VERSION   = "0.49";
@ISA       = qw( DynaLoader Exporter );
@EXPORT    = qw( DDumper DTidy DDsort DPeek DDisplay DDump DHexDump
		 DDual DGrow );
@EXPORT_OK = qw( triplevar :tidy );
push @EXPORT, "DDump_IO";

bootstrap Data::Peek $VERSION;

our $has_perlio;
our $has_perltidy;

BEGIN {
    use Config;
    $has_perlio   = ($Config{useperlio} || "undef") eq "define";
    $has_perltidy = eval q{use Perl::Tidy; $Perl::Tidy::VERSION};
    }

### ############# DDumper () ##################################################

use Data::Dumper;

my %sk = (
    undef	=> 0,
    ""		=> 0,
    0		=> 0,
    1		=> 1,

    R	=> sub {	# Sort reverse
	    my $r = shift;
	    [ reverse sort                           keys %$r ];
	    },
    N	=> sub {	# Sort by key numerical
	    my $r = shift;
	    [         sort {      $a  <=>      $b  } keys %$r ];
	    },
    NR	=> sub {	# Sort by key numerical reverse
	    my $r = shift;
	    [         sort {      $b  <=>      $a  } keys %$r ];
	    },
    V	=> sub {	# Sort by value
	    my $r = shift;
	    [         sort { $r->{$a} cmp $r->{$b} } keys %$r ];
	    },
    VN	=> sub {	# Sort by value numeric
	    my $r = shift;
	    [         sort { $r->{$a} <=> $r->{$b} } keys %$r ];
	    },
    VNR	=> sub {	# Sort by value numeric reverse
	    my $r = shift;
	    [         sort { $r->{$b} <=> $r->{$a} } keys %$r ];
	    },
    VR	=> sub {	# Sort by value reverse
	    my $r = shift;
	    [         sort { $r->{$b} cmp $r->{$a} } keys %$r ];
	    },
    );
my  $_sortkeys = 1;
our $_perltidy = 0;

my %pmap = map { $_ => $_ } map { split //, $_ }
    q{ !""#$%&'()*+,-./0123456789:;<=>},
    q{@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^},
    q{`abcdefghijklmnopqrstuvwxyz|~}, "{}";
$pmap{$_} = "." for grep { !exists $pmap{$_} } map { chr } 0 .. 255;

sub DDsort {
    @_ or return;

    $_sortkeys = exists $sk{$_[0]} ? $sk{$_[0]} : $_[0];
    } # DDsort

sub import {
    my @exp = @_;
    my @etl;
    foreach my $p (@exp) {
	exists $sk{$p} and DDsort ($p), next;

	if ($p eq ":tidy") {
	    $_perltidy = $has_perltidy;
	    next;
	    }

	push @etl, $p;
	}
    __PACKAGE__->export_to_level (1, @etl);
    } # import

sub DDumper {
    $_perltidy and goto \&DTidy;

    local $Data::Dumper::Sortkeys  = $_sortkeys;
    local $Data::Dumper::Indent    = 1;
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Deparse   = 1;
    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Purity    = 1;
    local $Data::Dumper::Useqq     = 0;	# I want unicode visible

    my $s = Data::Dumper::Dumper @_;
    $s =~ s/^(\s*)(.*?)\s*=>/sprintf "%s%-16s =>", $1, $2/gme;  # Align =>
    $s =~ s/\bbless\s*\(\s*/bless (/gm and $s =~ s/\s+\)([;,])$/)$1/gm;
    $s =~ s/^(?=\s*[]}](?:[;,]|$))/  /gm;
    $s =~ s/^(\s*[{[]) *\n *(?=\S)(?![{[])/$1   /gm;
    $s =~ s/^(\s+)/$1$1/gm;

    defined wantarray or warn $s;
    return $s;
    } # DDumper

sub DTidy {
    $has_perltidy or goto \&DDumper;

    local $Data::Dumper::Sortkeys  = $_sortkeys;
    local $Data::Dumper::Indent    = 1;
    local $Data::Dumper::Quotekeys = 1;
    local $Data::Dumper::Deparse   = 1;
    local $Data::Dumper::Terse     = 1;
    local $Data::Dumper::Purity    = 1;
    local $Data::Dumper::Useqq     = 0;

    my $s = Data::Dumper::Dumper @_;
    my $t;
    my @opts = (
	# Disable stupid options in ~/.perltidyrc
	# people do so, even for root
	"--no-backup-and-modify-in-place",
	"--no-check-syntax",
	"--no-standard-output",
	"--no-warning-output",
	);
    # RT#99514 - Perl::Tidy memoizes .perltidyrc incorrectly
    $has_perltidy > 20120714 and push @opts, "--no-memoize";

    Perl::Tidy::perltidy (source => \$s, destination => \$t, argv => \@opts);
    $s = $t;

    defined wantarray or warn $s;
    return $s;
    } # DTidy

### ############# DDump () ####################################################

sub _DDump_ref {
    my (undef, $down) = (@_, 0);

    my $ref = ref $_[0];
    if ($ref eq "SCALAR" || $ref eq "REF") {
	my %hash = DDump (${$_[0]}, $down);
	return { %hash };
	}
    if ($ref eq "ARRAY") {
	my @list;
	foreach my $list (@{$_[0]}) {
	    my %hash = DDump ($list, $down);
	    push @list, { %hash };
	    }
	return [ @list ];
	}
    if ($ref eq "HASH") {
	my %hash;
	foreach my $key (sort keys %{$_[0]}) {
	    $hash{DPeek ($key)} = { DDump ($_[0]->{$key}, $down) };
	    }
	return { %hash };
	}
    undef;
    } # _DDump_ref

sub _DDump {
    my (undef, $down, $dump, $fh) = (@_, "");

    if ($has_perlio and open $fh, ">", \$dump) {
	#print STDERR "Using DDump_IO\n";
	DDump_IO ($fh, $_[0], $down);
	close $fh;
	}
    else {
	#print STDERR "Using DDump_XS\n";
	$dump = DDump_XS ($_[0]);
	}

    return $dump;
    } # _DDump

sub DDump (;$$) {
    my $down = @_ > 1 ? $_[1] : 0;
    my @dump = split m/[\r\n]+/, _DDump (@_ ? $_[0] : $_, wantarray || $down) or return;

    if (wantarray) {
	my %hash;
	($hash{sv} = $dump[0]) =~ s/^SV\s*=\s*//;
	m/^\s+(\w+)\s*=\s*(.*)/ and $hash{$1} = $2 for @dump;

	if (exists $hash{FLAGS}) {
	    $hash{FLAGS} =~ tr/()//d;
	    $hash{FLAGS} = { map { $_ => 1 } split m/,/ => $hash{FLAGS} };
	    }

	$down && ref $_[0] and
	    $hash{RV} = _DDump_ref ($_[0], $down - 1) || $_[0];
	return %hash;
	}

    my $dump = join "\n", @dump, "";

    defined wantarray and return $dump;

    warn $dump;
    } # DDump

sub DHexDump {
    use bytes;
    my $off = 0;
    my @out;
    my $var = @_ ? $_[0] : $_;
    defined $var or return;
    my $fmt = @_ > 1 && $_[1] < length ($var) ? "A$_[1]" : "A*";
    my $str = pack $fmt, $var;	# force stringification
    for (unpack "(A32)*", unpack "H*", $str) {
	my @b = unpack "(A2)*", $_;
	my $out = sprintf "%04x ", $off;
	$out .= " ".($b[$_]||"  ") for 0 ..  7;
	$out .= " ";
	$out .= " ".($b[$_]||"  ") for 8 .. 15;
	$out .= "  ";
	$out .= $pmap{$_} for map { chr hex $_ } @b;
	push @out, $out."\n";
	$off += 16;
	}

    wantarray and return @out;

    defined wantarray and return join "", @out;

    warn join "", @out;
    } # DHexDump

"Indent";

__END__

=head1 NAME

Data::Peek - A collection of low-level debug facilities

=head1 SYNOPSIS

 use Data::Peek;

 print DDumper \%hash;    # Same syntax as Data::Dumper
 DTidy { ref => $ref };

 print DPeek \$var;
 my ($pv, $iv, $nv, $rv, $magic) = DDual ($var [, 1]);
 print DPeek for DDual ($!, 1);
 print DDisplay ("ab\nc\x{20ac}\rdef\n");
 print DHexDump ("ab\nc\x{20ac}\rdef\n");

 my $dump = DDump $var;
 my %hash = DDump \@list;
 DDump \%hash;

 my %hash = DDump (\%hash, 5);  # dig 5 levels deep

 my $dump;
 open my $fh, ">", \$dump;
 DDump_IO ($fh, \%hash, 6);
 close $fh;
 print $dump;

 # Imports
 use Data::Peek qw( :tidy VNR DGrow triplevar );
 my $x = ""; DGrow ($x, 10000);
 my $tv = triplevar ("\N{GREEK SMALL LETTER PI}", 3, "3.1415");
 DDsort ("R");
 DDumper [ $x ]; # use of :tidy makes DDumper behave like DTidy

=head1 DESCRIPTION

Data::Peek started off as C<DDumper> being a wrapper module over
L<Data::Dumper>, but grew out to be a set of low-level data
introspection utilities that no other module provided yet, using the
lowest level of the perl internals API as possible.

=head2 DDumper ($var, ...)

Not liking the default output of Data::Dumper, and always feeling the need
to set C<$Data::Dumper::Sortkeys = 1;>, and not liking any of the default
layouts, this function is just a wrapper around Data::Dumper::Dumper with
everything set as I like it.

    $Data::Dumper::Sortkeys = 1;
    $Data::Dumper::Indent   = 1;

If C<Data::Peek> is C<use>d with import argument C<:tidy>, the result is
formatted according to L<Perl::Tidy>, see L<DTidy> below, otherwise the
result is further beautified to meet my needs:

  * quotation of hash keys has been removed (with the disadvantage
    that the output might not be parseable again).
  * arrows for hashes are aligned at 16 (longer keys don't align)
  * closing braces and brackets are now correctly aligned

In void context, C<DDumper> C<warn>'s.

Example

  $ perl -MDP \
    -e'DDumper { ape => 1, foo => "egg", bar => [ 2, "baz", undef ]};'

  {   ape              => 1,
      bar              => [
          2,
          'baz',
          undef
          ],
      foo              => 'egg'
      };

=head2 DTidy ($var, ...)

C<DTidy> is an alternative to C<DDumper>, where the output of C<DDumper>
is formatted using C<Perl::Tidy> (if available) according to your
C<.perltidyrc> instead of the default behavior, maybe somewhat like (YMMV):

  $ perl -MDP=:tidy \
    -we'DDumper { ape => 1, foo => "egg", bar => [ 2, "baz", undef ]};'
  {   'ape' => 1,
      'bar' => [2, 'baz', undef],
      'foo' => 'egg'
      }

If C<Data::Peek> is C<use>d with import argument C<:tidy>, this is the
default output method for C<DDumper>.

If L<Perl::Tidy> is not available, C<DTidy> will fallback to C<DDumper>.

This idea was shamelessly copied from John McNamara's L<Data::Dumper::Perltidy>.

=head2 DDsort ( 0 | 1 | R | N | NR | V | VR | VN | VNR )

Set the hash sort algorithm for DDumper. The default is to sort by key value.

  0   - Do not sort
  1   - Sort by key
  R   - Reverse sort by key
  N   - Sort by key numerical
  NR  - Sort by key numerical descending
  V   - Sort by value
  VR  - Reverse sort by value
  VN  - Sort by value numerical
  VNR - Reverse sort by value numerical

These can also be passed to import:

  $ perl -MDP=VNR \
    -we'DDumper { foo => 1, bar => 2, zap => 3, gum => 13 }'
  {   gum              => 13,
      zap              => 3,
      bar              => 2,
      foo              => 1
      };
  $ perl -MDP=V \
    -we'DDumper { foo => 1, bar => 2, zap => 3, gum => 13 }'
  {   foo              => 1,
      gum              => 13,
      bar              => 2,
      zap              => 3
      };

=head2 DPeek

=head2 DPeek ($var)

Playing with C<sv_dump>, I found C<Perl_sv_peek>, and it might be very
useful for simple checks. If C<$var> is omitted, uses $_.

Example

  print DPeek "abc\x{0a}de\x{20ac}fg";

  PV("abc\nde\342\202\254fg"\0) [UTF8 "abc\nde\x{20ac}fg"]

In void context, C<DPeek> prints to C<STDERR> plus a newline.

=head2 DDisplay

=head2 DDisplay ($var)

Show the PV content of a scalar the way perl debugging would have done.
UTF-8 detection is on, so this is effectively the same as returning the
first part the C<DPeek> returns for non-UTF8 PV's or the second part for
UTF-8 PV's. C<DDisplay> returns the empty string for scalars that no
have a valid PV.

Example

  print DDisplay "abc\x{0a}de\x{20ac}fg";

  "abc\nde\x{20ac}fg"

In void context, C<DDisplay> uses C<warn> to display the result.

=head2 DHexDump

=head2 DHexDump ($var)

=head2 DHexDump ($var, $length)

Show the (stringified) content of a scalar as a hex-dump.  If C<$var>
is omitted, C<$_> is dumped. Returns C<undef> or an empty list if
C<$var> (or C<$_>) is undefined. If C<$length> is given and is lower than
the length of the stringified C<$var>, only <$length> bytes are dumped.

In void context, the dump is done to STDERR. In scalar context, the
complete dump is returned as a single string. In list context, the dump
is returned as lines.

Example

  print DHexDump "abc\x{0a}de\x{20ac}fg";

  0000  61 62 63 0a 64 65 e2 82  ac 66 67                 abc.de...fg

=head2 my ($pv, $iv, $nv, $rv, $hm) = DDual ($var [, $getmagic])

DDual will return the basic elements in a variable, guaranteeing that no
conversion takes place. This is very useful for dual-var variables, or
when checking is a variable has defined entries for a certain type of
scalar. For each String (PV), Integer (IV), Double (NV), and Reference (RV),
the current value of C<$var> is returned or undef if it is not set (yet).
The 5th element is an indicator if C<$var> has magic, which is B<not> invoked
in the returned values, unless explicitly asked for with a true optional
second argument.

Example

  print DPeek for DDual ($!, 1);

In void context, DDual does the equivalent of

  { my @d = DDual ($!, 1);
    print STDERR
      DPeek ($!), "\n",
      "  PV: ", DPeek ($d[0]), "\n",
      "  IV: ", DPeek ($d[1]), "\n",
      "  NV: ", DPeek ($d[2]), "\n",
      "  RV: ", DPeek ($d[3]), "\n";
    }
  
=head2 my $len = DGrow ($pv, $size)

Fastest way to preallocate space for a PV scalar. Returns the allocated
length. If $size is smaller than the already allocated space, it will
not shrink.

 cmpthese (-2, {
     pack => q{my $x = ""; $x = pack "x20000"; $x = "";},
     op_x => q{my $x = ""; $x = "x"  x 20000;  $x = "";},
     grow => q{my $x = ""; DGrow ($x,  20000); $x = "";},
     });

           Rate  op_x  pack  grow      5.8.9    5.10.1    5.12.4    5.14.2
 op_x   62127/s    --  -59%  -96%   118606/s  119730/s  352255/s  362605/s
 pack  152046/s  145%    --  -91%   380075/s  355666/s  347247/s  387349/s
 grow 1622943/s 2512%  967%    --  2818380/s 2918783/s 2672340/s 2886787/s

=head2 my $tp = triplevar ($pv, $iv, $nv)

When making C<DDual> I wondered if it were possible to create triple-val
scalar variables. L<Scalar::Util> already gives us C<dualvar>, that creates
you a scalar with different numeric and string values that return different
values in different context. Not that C<triplevar> would be very useful,
compared to C<dualvar>, but at least this shows that it is possible.

C<triplevar> is not exported by default.

Example:

  DDual Data::Peek::triplevar ("\N{GREEK SMALL LETTER PI}", 3, 3.1415);

  PVNV("\317\200"\0) [UTF8 "\x{3c0}"]
    PV: PV("\317\200"\0) [UTF8 "\x{3c0}"]
    IV: IV(3)
    NV: NV(3.1415)
    RV: SV_UNDEF

=head2 DDump ([$var [, $dig_level]])

A very useful module when debugging is C<Devel::Peek>, but is has one big
disadvantage: it only prints to STDERR, which is not very handy when your
code wants to inspect variables at a low level.

Perl itself has C<sv_dump>, which does something similar, but still prints
to STDERR, and only one level deep.

C<DDump> is an attempt to make the innards available to the script level
with a reasonable level of compatibility. C<DDump> is context sensitive.

In void context, it behaves exactly like C<Perl_sv_dump>.

In scalar context, it returns what C<Perl_sv_dump> would have printed.

The default for the first argument is C<$_>.

In list context, it returns a hash of the variable's properties. In this mode
you can pass an optional second argument that determines the depth of digging.

Example

  print scalar DDump "abc\x{0a}de\x{20ac}fg"

  SV = PV(0x723250) at 0x8432b0
    REFCNT = 1
    FLAGS = (PADBUSY,PADMY,POK,pPOK,UTF8)
    PV = 0x731ac0 "abc\nde\342\202\254fg"\0 [UTF8 "abc\nde\x{20ac}fg"]
    CUR = 11
    LEN = 16

  my %h = DDump "abc\x{0a}de\x{20ac}fg";
  print DDumper \%h;

  {   CUR              => '11',
      FLAGS            => {
          PADBUSY          => 1,
          PADMY            => 1,
          POK              => 1,
          UTF8             => 1,
          pPOK             => 1
          },
      LEN              => '16',
      PV               => '0x731ac0 "abc\\nde\\342\\202\\254fg"\\0 [UTF8 "abc\\nde\\x{20ac}fg"]',
      REFCNT           => '1',
      sv               => 'PV(0x723250) at 0x8432c0'
      };

  my %h = DDump {
      ape => 1,
      foo => "egg",
      bar => [ 2, "baz", undef ],
      }, 1;
  print DDumper \%h;

  {   FLAGS            => {
          PADBUSY          => 1,
          PADMY            => 1,
          ROK              => 1
          },
      REFCNT           => '1',
      RV               => {
          PVIV("ape")      => {
              FLAGS            => {
                  IOK              => 1,
                  PADBUSY          => 1,
                  PADMY            => 1,
                  pIOK             => 1
                  },
              IV               => '1',
              REFCNT           => '1',
              sv               => 'IV(0x747020) at 0x843a10'
              },
          PVIV("bar")      => {
              CUR              => '0',
              FLAGS            => {
                  PADBUSY          => 1,
                  PADMY            => 1,
                  ROK              => 1
                  },
              IV               => '1',
              LEN              => '0',
              PV               => '0x720210 ""',
              REFCNT           => '1',
              RV               => '0x720210',
              sv               => 'PVIV(0x7223e0) at 0x843a10'
              },
          PVIV("foo")      => {
              CUR              => '3',
              FLAGS            => {
                  PADBUSY          => 1,
                  PADMY            => 1,
                  POK              => 1,
                  pPOK             => 1
                  },
              IV               => '1',
              LEN              => '8',
              PV               => '0x7496c0 "egg"\\0',
              REFCNT           => '1',
              sv               => 'PVIV(0x7223e0) at 0x843a10'
              }
          },
      sv               => 'RV(0x79d058) at 0x843310'
      };

=head2 DDump_IO ($io, $var [, $dig_level])

A wrapper function around perl's internal C<Perl_do_sv_dump>, which
makes C<Devel::Peek> completely superfluous.

Example

  my $dump;
  open my $eh, ">", \$dump;
  DDump_IO ($eh, { 3 => 4, ape => [5..8]}, 6);
  close $eh;
  print $dump;

  SV = RV(0x79d9e0) at 0x843f00
    REFCNT = 1
    FLAGS = (TEMP,ROK)
    RV = 0x741090
      SV = PVHV(0x79c948) at 0x741090
        REFCNT = 1
        FLAGS = (SHAREKEYS)
        IV = 2
        NV = 0
        ARRAY = 0x748ff0  (0:7, 2:1)
        hash quality = 62.5%
        KEYS = 2
        FILL = 1
        MAX = 7
        RITER = -1
        EITER = 0x0
          Elt "ape" HASH = 0x97623e03
          SV = RV(0x79d9d8) at 0x8440e0
            REFCNT = 1
            FLAGS = (ROK)
            RV = 0x741470
              SV = PVAV(0x7264b0) at 0x741470
                REFCNT = 2
                FLAGS = ()
                IV = 0
                NV = 0
                ARRAY = 0x822f70
                FILL = 3
                MAX = 3
                ARYLEN = 0x0
                FLAGS = (REAL)
                  Elt No. 0
                  SV = IV(0x7467c8) at 0x7c1aa0
                    REFCNT = 1
                    FLAGS = (IOK,pIOK)
                    IV = 5
                  Elt No. 1
                  SV = IV(0x7467b0) at 0x8440f0
                    REFCNT = 1
                    FLAGS = (IOK,pIOK)
                    IV = 6
                  Elt No. 2
                  SV = IV(0x746810) at 0x75be00
                    REFCNT = 1
                    FLAGS = (IOK,pIOK)
                    IV = 7
                  Elt No. 3
                  SV = IV(0x746d38) at 0x7799d0
                    REFCNT = 1
                    FLAGS = (IOK,pIOK)
                    IV = 8
          Elt "3" HASH = 0xa400c7f3
          SV = IV(0x746fd0) at 0x7200e0
            REFCNT = 1
            FLAGS = (IOK,pIOK)
            IV = 4

=head1 INTERNALS

C<DDump> uses an XS wrapper around C<Perl_sv_dump> where the STDERR is
temporarily caught to a pipe. The internal XS helper functions are not
meant for user space

=head2 DDump_XS (SV *sv)

Base interface to internals for C<DDump>.

=head1 BUGS

Windows and AIX might be using a build where not all symbols that were
supposed to be exported in the public API are not. C<Perl_pv_peek> is
one of them.

Not all types of references are supported.

No idea how far back this goes in perl support, but Devel::PPPort has
proven to be a big help.

=head1 SEE ALSO

L<Devel::Peek>, L<Data::Dumper>, L<Data::Dump>, L<Devel::Dumpvar>,
L<Data::Dump::Streamer>, L<Data::Dumper::Perltidy>, L<Perl::Tidy>.

=head1 AUTHOR

H.Merijn Brand <h.m.brand@xs4all.nl>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2020 H.Merijn Brand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
