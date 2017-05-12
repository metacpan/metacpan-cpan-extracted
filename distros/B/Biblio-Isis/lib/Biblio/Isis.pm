package Biblio::Isis;
use strict;

use Carp;
use File::Glob qw(:globally :nocase);

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.24;
	@ISA         = qw (Exporter);
	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();

}

=head1 NAME

Biblio::Isis - Read CDS/ISIS, WinISIS and IsisMarc database

=head1 SYNOPSIS

  use Biblio::Isis;

  my $isis = new Biblio::Isis(
  	isisdb => './cds/cds',
  );

  for(my $mfn = 1; $mfn <= $isis->count; $mfn++) {
	print $isis->to_ascii($mfn),"\n";
  }

=head1 DESCRIPTION

This module will read ISIS databases created by DOS CDS/ISIS, WinIsis or
IsisMarc. It can be used as perl-only alternative to OpenIsis module which
seems to depriciate it's old C<XS> bindings for perl.

It can create hash values from data in ISIS database (using C<to_hash>),
ASCII dump (using C<to_ascii>) or just hash with field names and packed
values (like C<^asomething^belse>).

Unique feature of this module is ability to C<include_deleted> records.
It will also skip zero sized fields (OpenIsis has a bug in XS bindings, so
fields which are zero sized will be filled with random junk from memory).

It also has support for identifiers (only if ISIS database is created by
IsisMarc), see C<to_hash>.

This module will always be slower than OpenIsis module which use C
library. However, since it's written in perl, it's platform independent (so
you don't need C compiler), and can be easily modified. I hope that it
creates data structures which are easier to use than ones created by
OpenIsis, so reduced time in other parts of the code should compensate for
slower performance of this module (speed of reading ISIS database is
rarely an issue).

=head1 METHODS

=cut

#  my $ORDN;		# Nodes Order
#  my $ORDF;		# Leafs Order
#  my $N;		# Number of Memory buffers for nodes
#  my $K;		# Number of buffers for first level index
#  my $LIV;		# Current number of Index Levels
#  my $POSRX;		# Pointer to Root Record in N0x
#  my $NMAXPOS;		# Next Available position in N0x
#  my $FMAXPOS;		# Next available position in L0x
#  my $ABNORMAL;	# Formal BTree normality indicator

#
# some binary reads
#

=head2 new

Open ISIS database

 my $isis = new Biblio::Isis(
 	isisdb => './cds/cds',
	read_fdt => 1,
	include_deleted => 1,
	hash_filter => sub {
		my ($v,$field_number) = @_;
		$v =~ s#foo#bar#g;
	},
	debug => 1,
	join_subfields_with => ' ; ',
 );

Options are described below:

=over 5

=item isisdb

This is full or relative path to ISIS database files which include
common prefix of C<.MST>, and C<.XRF> and optionally C<.FDT> (if using
C<read_fdt> option) files.

In this example it uses C<./cds/cds.MST> and related files.

=item read_fdt

Boolean flag to specify if field definition table should be read. It's off
by default.

=item include_deleted

Don't skip logically deleted records in ISIS.

=item hash_filter

Filter code ref which will be used before data is converted to hash. It will
receive two arguments, whole line from current field (in C<< $_[0] >>) and
field number (in C<< $_[1] >>).

=item debug

Dump a B<lot> of debugging output even at level 1. For even more increase level.

=item join_subfields_with

Define delimiter which will be used to join repeatable subfields. This
option is included to support lagacy application written against version
older than 0.21 of this module. By default, it disabled. See L</to_hash>.

=item ignore_empty_subfields

Remove all empty subfields while reading from ISIS file.

=back

=cut

sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);

	croak "new needs database name (isisdb) as argument!" unless ({@_}->{isisdb});

	foreach my $v (qw{isisdb debug include_deleted hash_filter join_subfields_with ignore_empty_subfields}) {
		$self->{$v} = {@_}->{$v} if defined({@_}->{$v});
	}

	my @isis_files = grep(/\.(FDT|MST|XRF|CNT)$/i,glob($self->{isisdb}."*"));

	foreach my $f (@isis_files) {
		my $ext = $1 if ($f =~ m/\.(\w\w\w)$/);
		$self->{lc($ext)."_file"} = $f;
	}

	my @must_exist = qw(mst xrf);
	push @must_exist, "fdt" if ($self->{read_fdt});

	foreach my $ext (@must_exist) {
		unless ($self->{$ext."_file"}) {
			carp "missing ",uc($ext)," file in ",$self->{isisdb};
			return;
		}
	}

	if ($self->{debug}) {
		print STDERR "## using files: ",join(" ",@isis_files),"\n";
		eval "use Data::Dump";

		if (! $@) {
			*Dumper = *Data::Dump::dump;
		} else {
			use Data::Dumper;
		}
	}

	# if you want to read .FDT file use read_fdt argument when creating class!
	if ($self->{read_fdt} && -e $self->{fdt_file}) {

		# read the $db.FDT file for tags
		my $fieldzone=0;

		open(my $fileFDT, $self->{fdt_file}) || croak "can't read '$self->{fdt_file}': $!";
		binmode($fileFDT);

		while (<$fileFDT>) {
			chomp;
			if ($fieldzone) {
				my $name=substr($_,0,30);
				my $tag=substr($_,50,3);

				$name =~ s/\s+$//;
				$tag =~ s/\s+$//;

				$self->{'TagName'}->{$tag}=$name;  
			}

			if (/^\*\*\*/) {
				$fieldzone=1;
			}
		}
		
		close($fileFDT);
	}

	# Get the Maximum MFN from $db.MST

	open($self->{'fileMST'}, $self->{mst_file}) || croak "can't open '$self->{mst_file}': $!";
	binmode($self->{'fileMST'});

	# MST format:	(* = 32 bit signed)
	# CTLMFN*	always 0
	# NXTMFN*	MFN to be assigned to the next record created
	# NXTMFB*	last block allocated to master file
	# NXTMFP	offset to next available position in last block
	# MFTYPE	always 0 for user db file (1 for system)
	seek($self->{'fileMST'},4,0) || croak "can't seek to offset 0 in MST: $!";

	my $buff;

	read($self->{'fileMST'}, $buff, 4) || croak "can't read NXTMFN from MST: $!";
	$self->{'NXTMFN'}=unpack("V",$buff) || croak "NXTNFN is zero";

	print STDERR "## self ",Dumper($self),"\n" if ($self->{debug});

	# open files for later
	open($self->{'fileXRF'}, $self->{xrf_file}) || croak "can't open '$self->{xrf_file}': $!";
	binmode($self->{'fileXRF'});

	$self ? return $self : return undef;
}

=head2 count

Return number of records in database

  print $isis->count;

=cut

sub count {
	my $self = shift;
	return $self->{'NXTMFN'} - 1;
}

=head2 fetch

Read record with selected MFN

  my $rec = $isis->fetch(55);

Returns hash with keys which are field names and values are unpacked values
for that field like this:

  $rec = {
    '210' => [ '^aNew York^cNew York University press^dcop. 1988' ],
    '990' => [ '2140', '88', 'HAY' ],
  };

=cut

sub fetch {
	my $self = shift;

	my $mfn = shift || croak "fetch needs MFN as argument!";

	# is mfn allready in memory?
	my $old_mfn = $self->{'current_mfn'} || -1;
	return $self->{record} if ($mfn == $old_mfn);

	print STDERR "## fetch: $mfn\n" if ($self->{debug});

	# XXX check this?
	my $mfnpos=($mfn+int(($mfn-1)/127))*4;

	print STDERR "## seeking to $mfnpos in file '$self->{xrf_file}'\n" if ($self->{debug});
	seek($self->{'fileXRF'},$mfnpos,0);

	my $buff;

	# delete old record
	delete $self->{record};

	# read XRFMFB abd XRFMFP
	read($self->{'fileXRF'}, $buff, 4);
	my $pointer=unpack("V",$buff);
	if (! $pointer) {
		if ($self->{include_deleted}) {
			return;
		} else {
			warn "pointer for MFN $mfn is null\n";
			return;
		}
	}

	# check for logically deleted record
	if ($pointer & 0x80000000) {
		print STDERR "## record $mfn is logically deleted\n" if ($self->{debug});
		$self->{deleted} = $mfn;

		return unless $self->{include_deleted};

		# abs
		$pointer = ($pointer ^ 0xffffffff) + 1;
	}

	my $XRFMFB = int($pointer/2048);
	my $XRFMFP = $pointer - ($XRFMFB*2048);

	# (XRFMFB - 1) * 512 + XRFMFP
	# why do i have to do XRFMFP % 1024 ?

	my $blk_off = (($XRFMFB - 1) * 512) + ($XRFMFP % 512);

	print STDERR "## pointer: $pointer XRFMFB: $XRFMFB XRFMFP: $XRFMFP offset: $blk_off\n" if ($self->{'debug'});

	# Get Record Information

	seek($self->{'fileMST'},$blk_off,0) || croak "can't seek to $blk_off: $!";

	read($self->{'fileMST'}, $buff, 4) || croak "can't read 4 bytes at offset $blk_off from MST file: $!";
	my $value=unpack("V",$buff);

	print STDERR "## offset for rowid $value is $blk_off (blk $XRFMFB off $XRFMFP)\n" if ($self->{debug});

	if ($value!=$mfn) {
		if ($value == 0) {
			print STDERR "## record $mfn is physically deleted\n" if ($self->{debug});
			$self->{deleted} = $mfn;
			return;
		}

		carp "Error: MFN ".$mfn." not found in MST file, found $value";    
		return;
	}

	read($self->{'fileMST'}, $buff, 14);

	my ($MFRL,$MFBWB,$MFBWP,$BASE,$NVF,$STATUS) = unpack("vVvvvv", $buff);

	print STDERR "## MFRL: $MFRL MFBWB: $MFBWB MFBWP: $MFBWP BASE: $BASE NVF: $NVF STATUS: $STATUS\n" if ($self->{debug});

	warn "MFRL $MFRL is not even number" unless ($MFRL % 2 == 0);

	warn "BASE is not 18+6*NVF" unless ($BASE == 18 + 6 * $NVF);

	# Get Directory Format

	my @FieldPOS;
	my @FieldLEN;
	my @FieldTAG;

	read($self->{'fileMST'}, $buff, 6 * $NVF);

	my $rec_len = 0;

	for (my $i = 0 ; $i < $NVF ; $i++) {

		my ($TAG,$POS,$LEN) = unpack("vvv", substr($buff,$i * 6, 6));

		print STDERR "## TAG: $TAG POS: $POS LEN: $LEN\n" if ($self->{debug});

		# The TAG does not exists in .FDT so we set it to 0.
		#
		# XXX This is removed from perl version; .FDT file is updated manually, so
		# you will often have fields in .MST file which aren't in .FDT. On the other
		# hand, IsisMarc doesn't use .FDT files at all!

		#if (! $self->{TagName}->{$TAG}) {
		#	$TAG=0;
		#}

		push @FieldTAG,$TAG;
		push @FieldPOS,$POS;
		push @FieldLEN,$LEN;

		$rec_len += $LEN;
	}

	# Get Variable Fields

	read($self->{'fileMST'},$buff,$rec_len);

	print STDERR "## rec_len: $rec_len poc: ",tell($self->{'fileMST'})."\n" if ($self->{debug});

	for (my $i = 0 ; $i < $NVF ; $i++) {
		# skip zero-sized fields
		next if ($FieldLEN[$i] == 0);

		my $v = substr($buff,$FieldPOS[$i],$FieldLEN[$i]);

		if ( $self->{ignore_empty_subfields} ) {
			$v =~ s/(\^\w)+(\^\w)/$2/g;
			$v =~ s/\^\w$//;			# last on line?
			next if ($v eq '');
		}

		push @{$self->{record}->{$FieldTAG[$i]}}, $v;
	}

	$self->{'current_mfn'} = $mfn;

	print STDERR Dumper($self),"\n" if ($self->{debug});

	return $self->{'record'};
}

=head2 mfn

Returns current MFN position

  my $mfn = $isis->mfn;

=cut

# This function should be simple return $self->{current_mfn},
# but if new is called with _hack_mfn it becomes setter.
# It's useful in tests when setting $isis->{record} directly

sub mfn {
	my $self = shift;
	return $self->{current_mfn};
};


=head2 to_ascii

Returns ASCII output of record with specified MFN

  print $isis->to_ascii(42);

This outputs something like this:

  210	^aNew York^cNew York University press^dcop. 1988
  990	2140
  990   88
  990	HAY

If C<read_fdt> is specified when calling C<new> it will display field names
from C<.FDT> file instead of numeric tags.

=cut

sub to_ascii {
	my $self = shift;

	my $mfn = shift || croak "need MFN";

	my $rec = $self->fetch($mfn) || return;

	my $out = "0\t$mfn";

	foreach my $f (sort keys %{$rec}) {
		my $fn = $self->tag_name($f);
		$out .= "\n$fn\t".join("\n$fn\t",@{$self->{record}->{$f}});
	}

	$out .= "\n";

	return $out;
}

=head2 to_hash

Read record with specified MFN and convert it to hash

  my $hash = $isis->to_hash($mfn);

It has ability to convert characters (using C<hash_filter>) from ISIS
database before creating structures enabling character re-mapping or quick
fix-up of data.

This function returns hash which is like this:

  $hash = {
    '210' => [
               {
                 'c' => 'New York University press',
                 'a' => 'New York',
                 'd' => 'cop. 1988'
               }
             ],
    '990' => [
               '2140',
               '88',
               'HAY'
             ],
  };

You can later use that hash to produce any output from ISIS data.

If database is created using IsisMarc, it will also have to special fields
which will be used for identifiers, C<i1> and C<i2> like this:

  '200' => [
             {
               'i1' => '1',
               'i2' => ' '
               'a' => 'Goa',
               'f' => 'Valdo D\'Arienzo',
               'e' => 'tipografie e tipografi nel XVI secolo',
             }
           ],

In case there are repeatable subfields in record, this will create
following structure:

  '900' => [ {
  	'a' => [ 'foo', 'bar', 'baz' ],
  }]

Or in more complex example of

  902	^aa1^aa2^aa3^bb1^aa4^bb2^cc1^aa5

it will create

  902   => [
	{ a => ["a1", "a2", "a3", "a4", "a5"], b => ["b1", "b2"], c => "c1" },
  ],

This behaviour can be changed using C<join_subfields_with> option to L</new>,
in which case C<to_hash> will always create single value for each subfield.
This will change result to:



This method will also create additional field C<000> with MFN.

There is also more elaborative way to call C<to_hash> like this:

  my $hash = $isis->to_hash({
  	mfn => 42,
	include_subfields => 1,
  });

Each option controll creation of hash:

=over 4

=item mfn

Specify MFN number of record

=item include_subfields

This option will create additional key in hash called C<subfields> which will
have original record subfield order and index to that subfield like this:

  902   => [ {
	a => ["a1", "a2", "a3", "a4", "a5"],
	b => ["b1", "b2"],
	c => "c1",
	subfields => ["a", 0, "a", 1, "a", 2, "b", 0, "a", 3, "b", 1, "c", 0, "a", 4],
  } ],

=item join_subfields_with

Define delimiter which will be used to join repeatable subfields. You can
specify option here instead in L</new> if you want to have per-record control.

=item hash_filter

You can override C<hash_filter> defined in L</new> using this option.

=back

=cut

sub to_hash {
	my $self = shift;


	my $mfn = shift || confess "need mfn!";
	my $arg;

	my $hash_filter = $self->{hash_filter};

	if (ref($mfn) eq 'HASH') {
		$arg = $mfn;
		$mfn = $arg->{mfn} || confess "need mfn in arguments";
		$hash_filter = $arg->{hash_filter} if ($arg->{hash_filter});
	}

	# init record to include MFN as field 000
	my $rec = { '000' => [ $mfn ] };

	my $row = $self->fetch($mfn) || return;

	my $j_rs = $arg->{join_subfields_with} || $self->{join_subfields_with};
	$j_rs = $self->{join_subfields_with} unless(defined($j_rs));
	my $i_sf = $arg->{include_subfields};

	foreach my $f_nr (keys %{$row}) {
		foreach my $l (@{$row->{$f_nr}}) {

			# filter output
			$l = $hash_filter->($l, $f_nr) if ($hash_filter);
			next unless defined($l);

			my $val;
			my $r_sf;	# repeatable subfields in this record

			# has identifiers?
			($val->{'i1'},$val->{'i2'}) = ($1,$2) if ($l =~ s/^([01 #])([01 #])\^/\^/);

			# has subfields?
			if ($l =~ m/\^/) {
				foreach my $t (split(/\^/,$l)) {
					next if (! $t);
					my ($sf,$v) = (substr($t,0,1), substr($t,1));
					# XXX this might be option, but why?
					next unless (defined($v) && $v ne '');
#					warn "### $f_nr^$sf:$v",$/ if ($self->{debug} > 1);

					if (ref( $val->{$sf} ) eq 'ARRAY') {

						push @{ $val->{$sf} }, $v;

						# record repeatable subfield it it's offset
						push @{ $val->{subfields} }, ( $sf, $#{ $val->{$sf} } ) if (! $j_rs && $i_sf);
						$r_sf->{$sf}++;

					} elsif (defined( $val->{$sf} )) {

						# convert scalar field to array
						$val->{$sf} = [ $val->{$sf}, $v ];

						push @{ $val->{subfields} }, ( $sf, 1 ) if (! $j_rs && $i_sf);
						$r_sf->{$sf}++;

					} else {
						$val->{$sf} = $v;
						push @{ $val->{subfields} }, ( $sf, 0 ) if ($i_sf);
					}
				}
			} else {
				$val = $l;
			}

			if ($j_rs) {
				map {
					$val->{$_} = join($j_rs, @{ $val->{$_} });
				} keys %$r_sf
			}

			push @{$rec->{$f_nr}}, $val;
		}
	}

	return $rec;
}

=head2 tag_name

Return name of selected tag

 print $isis->tag_name('200');

=cut

sub tag_name {
	my $self = shift;
	my $tag = shift || return;
	return $self->{'TagName'}->{$tag} || $tag;
}


=head2 read_cnt

Read content of C<.CNT> file and return hash containing it.

  print Dumper($isis->read_cnt);

This function is not used by module (C<.CNT> files are not required for this
module to work), but it can be useful to examine your index (while debugging
for example).

=cut

sub read_cnt  {
	my $self = shift;

	croak "missing CNT file in ",$self->{isisdb} unless ($self->{cnt_file});

	# Get the index information from $db.CNT
   
	open(my $fileCNT, $self->{cnt_file}) || croak "can't read '$self->{cnt_file}': $!";
	binmode($fileCNT);

	my $buff;

	read($fileCNT, $buff, 26) || croak "can't read first table from CNT: $!";
	$self->unpack_cnt($buff);

	read($fileCNT, $buff, 26) || croak "can't read second table from CNT: $!";
	$self->unpack_cnt($buff);

	close($fileCNT);

	return $self->{cnt};
}

=head2 unpack_cnt

Unpack one of two 26 bytes fixed length record in C<.CNT> file.

Here is definition of record:

 off key	description				size
  0: IDTYPE	BTree type				s
  2: ORDN	Nodes Order				s
  4: ORDF	Leafs Order				s
  6: N		Number of Memory buffers for nodes	s
  8: K		Number of buffers for first level index	s
 10: LIV	Current number of Index Levels		s
 12: POSRX	Pointer to Root Record in N0x		l
 16: NMAXPOS	Next Available position in N0x		l
 20: FMAXPOS	Next available position in L0x		l
 24: ABNORMAL	Formal BTree normality indicator	s
 length: 26 bytes

This will fill C<$self> object under C<cnt> with hash. It's used by C<read_cnt>.

=cut

sub unpack_cnt {
	my $self = shift;

	my @flds = qw(ORDN ORDF N K LIV POSRX NMAXPOS FMAXPOS ABNORMAL);

	my $buff = shift || return;
	my @arr = unpack("vvvvvvVVVv", $buff);

	print STDERR "unpack_cnt: ",join(" ",@arr),"\n" if ($self->{'debug'});

	my $IDTYPE = shift @arr;
	foreach (@flds) {
		$self->{cnt}->{$IDTYPE}->{$_} = abs(shift @arr);
	}
}

1;

=head1 BUGS

Some parts of CDS/ISIS documentation are not detailed enough to exmplain
some variations in input databases which has been tested with this module.
When I was in doubt, I assumed that OpenIsis's implementation was right
(except for obvious bugs).

However, every effort has been made to test this module with as much
databases (and programs that create them) as possible.

I would be very greatful for success or failure reports about usage of this
module with databases from programs other than WinIsis and IsisMarc. I had
tested this against ouput of one C<isis.dll>-based application, but I don't
know any details about it's version.

=head1 VERSIONS

As this is young module, new features are added in subsequent version. It's
a good idea to specify version when using this module like this:

  use Biblio::Isis 0.23

Below is list of changes in specific version of module (so you can target
older versions if you really have to):

=over 8 

=item 0.24

Added C<ignore_empty_subfields>

=item 0.23

Added C<hash_filter> to L</to_hash>

Fixed bug with documented C<join_subfields_with> in L</new> which wasn't
implemented

=item 0.22

Added field number when calling C<hash_filter>

=item 0.21

Added C<join_subfields_with> to L</new> and L</to_hash>.

Added C<include_subfields> to L</to_hash>.

=item 0.20

Added C<< $isis->mfn >>, support for repeatable subfields and
C<< $isis->to_hash({ mfn => 42, ... }) >> calling convention

=back

=head1 AUTHOR

	Dobrica Pavlinusic
	CPAN ID: DPAVLIN
	dpavlin@rot13.org
	http://www.rot13.org/~dpavlin/

This module is based heavily on code from C<LIBISIS.PHP> library to read ISIS files V0.1.1
written in php and (c) 2000 Franck Martin <franck@sopac.org> and released under LGPL.

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

L<Biblio::Isis::Manual> for CDS/ISIS manual appendix F, G and H which describe file format

OpenIsis web site L<http://www.openisis.org>

perl4lib site L<http://perl4lib.perl.org>

