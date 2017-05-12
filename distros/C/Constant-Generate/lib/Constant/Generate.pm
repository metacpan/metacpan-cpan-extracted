package Constant::Generate;
use strict;
use warnings;
our $VERSION  = '0.17';

use Data::Dumper;
use Carp qw(confess);
use Constant::Generate::Dualvar;
use Scalar::Util qw(looks_like_number);

#these two functions produce reverse mapping, one for simple constants, and
#one for bitfields

use constant {
	CONST_BITFLAG 	=> 1,
	CONST_SIMPLE	=> 2,
	CONST_STRING	=> 3
};

sub _gen_bitfield_fn {
	no strict "refs";
	my ($name,$rhash) = @_;
	*{$name} = sub($) {
		my $flag = $_[0];
		join("|",
			 @{$rhash}{(
				grep($flag & $_, keys %$rhash)
			 )}
		);
	};
}

sub _gen_int_fn {
	no strict 'refs';
	my ($name,$rhash) = @_;
	*{$name} = sub ($) { $rhash->{$_[0] + 0} || "" };
}

sub _gen_str_fn {
	no strict 'refs';
	my ($name,$rhash) = @_;
	*{$name} = sub ($) { $rhash->{ $_[0] } || "" };
}


sub _gen_integer_syms {
	my ($uarr, $symhash, $start) = @_;
	foreach my $sym (@$uarr) {
		$symhash->{$sym} = $start;
		$start++;
	}
}

sub _gen_bitflag_syms {
	my ($uarr,$symhash,$start) = @_;
	foreach my $sym (@$uarr) {
		$symhash->{$sym} = 1 << $start;
		$start++;
	}
}

sub _gen_string_syms {
	my ($uarr,$symhash,$prefix) = @_;
	foreach my $sym (@$uarr) {
		$symhash->{$sym} = $sym;
	}
}

sub _gen_constant {
	my ($pkg,$name,@values) = @_;
	no strict 'refs';
	my $fqname = $pkg . "::$name";
	if(@values == 1) {
        my $value = $values[0];
		*{$fqname} = sub () { $value };
	} else {
		*{$fqname} = sub () { @values };
	}
}

sub _gen_map_rhash {
	my ($symhash, $prefix, $display_prefix) = @_;
	my (%maphash,%rhash);
	if($prefix && $display_prefix) {
		while (my ($sym,$val) = each %$symhash) {
			$maphash{$prefix.$sym} = $val;
		}
	} else {
		%maphash = %$symhash;
	}
	
	#Check for duplicate constants pointing to the same value
	while (my ($sym,$val) = each %maphash) {
		push @{$rhash{$val}}, $sym;
	}
	while (my ($val,$syms) = each %rhash) {
		if(@$syms > 1) {
			$rhash{$val} = sprintf("(%s)", join(",", @$syms));
		} else {
			$rhash{$val} = $syms->[0];
		}
	}
	return \%rhash;
}

sub _mangle_exporter {
	my ($pkg, $symlist, $tag,
		$uspec_export, $uspec_export_ok, $uspec_export_tags) = @_;
	
	my @emap = (
		[$uspec_export, \my $my_export, 'EXPORT', 'ARRAY'],
		[$uspec_export_ok, \my $my_export_ok, 'EXPORT_OK', 'ARRAY'],
		[$uspec_export_tags, \my $my_export_tags, 'EXPORT_TAGS', 'HASH', \$tag]
	);
	
	foreach (@emap) {
		my ($uspec,$myspec,$pvar,$vtype,$depvar) = @$_;
		if(!$uspec) {
			next;
		}
		if (defined $depvar && !$$depvar) {
			next;
		}
		if(ref $uspec) {
			$$myspec = $uspec;
		} else {
			no strict 'refs';
			if(!defined ($$myspec = *{$pkg."::$pvar"}{$vtype})) {
				confess "Requested mangling of $pvar, but $pvar not yet declared!";
			}
		}
	}
	
	if($uspec_export_ok) {
		push @$my_export_ok, @$symlist;
	}
	if($uspec_export) {
		push @$my_export, @$symlist;
	}
	if($uspec_export_tags) {
		$my_export_tags->{$tag} = [ @$symlist ];
	}
	#Verify the required variables 
}

my $FN_CONST_TBL = {
	CONST_BITFLAG, \&_gen_bitflag_syms,
	CONST_SIMPLE, \&_gen_integer_syms,
	CONST_STRING, \&_gen_string_syms
};

my $FN_RMAP_TBL = {
	CONST_BITFLAG, \&_gen_bitfield_fn,
	CONST_SIMPLE, \&_gen_int_fn,
	CONST_STRING, \&_gen_str_fn,
};

sub utype2const {
	my $utype = shift;
	if(!$utype || $utype =~ /int/i) {
		return CONST_SIMPLE;
	} elsif ($utype =~ /bit/i) {
		return CONST_BITFLAG;
	} elsif ($utype =~ /str/i) {
		return CONST_STRING;
	} else {
		die "Unrecognized type '$utype'";
	}
}

sub _getopt(\%$) {
	my ($h,$opt) = @_;
	foreach ($opt,"-$opt") { return delete $h->{$_} if exists $h->{$_} }
}

sub import {
	my ($cls,$symspecs,%opts) = @_;
	return 1 unless $symspecs;
	
	my $reqpkg = caller();
	my $type = utype2const(_getopt(%opts, "type"));
	
	#Determine our tag for %EXPORT_TAGS and reverse mapping
	
	my $mapname 		= _getopt(%opts, "mapname");
	my $export_tag 		= _getopt(%opts, "tag");
	my $prefix			= _getopt(%opts, "prefix") || "";
	my $display_prefix 	= _getopt(%opts, "show_prefix");
	my $start 			= _getopt(%opts, "start_at") || 0;
	my $stringy			= _getopt(%opts, "stringy_vars")
						|| _getopt(%opts, "dualvar");
						
	my $listname		= _getopt(%opts, "allvalues");
	my $symsname		= _getopt(%opts, "allsyms");
	
	if((!$mapname) && $export_tag) {
		$mapname = $export_tag . "_to_str";
	}	
	
	#Generate the values.
	my %symhash;
	#Initial value
	
	ref $symspecs eq 'HASH' ? %symhash = %$symspecs :
		$FN_CONST_TBL->{$type}->($symspecs, \%symhash, $start);
	
	#tie it all together
	
	while (my ($symname,$symval) = each %symhash) {
		if($stringy && looks_like_number($symval)) {
			
			my $dv_name = $display_prefix ? $prefix . $symname : $symname;
			
			$symval = Constant::Generate::Dualvar::CG_dualvar(
				$symval, $dv_name);
		}
		_gen_constant($reqpkg, $prefix.$symname, $symval);
	}
	
	#After we have determined values for all the symbols, we can establish our
	#reverse mappings, if so requested
	if($mapname) {
		my $rhash = _gen_map_rhash(\%symhash, $prefix, $display_prefix);
		$FN_RMAP_TBL->{$type}->($reqpkg."::$mapname", $rhash);
	}
	
	if($prefix) {
		foreach my $usym (keys %symhash) {
			my $v = delete $symhash{$usym};
			$symhash{$prefix.$usym} = $v;
		}
	}
	
	my $auto_export = _getopt(%opts, "export");
	my $auto_export_ok = _getopt(%opts, "export_ok");
	my $h_etags = _getopt(%opts, "export_tags");
		
	my @symlist = keys %symhash;
	
	if($listname) {
		my %tmp = reverse %symhash;
		_gen_constant($reqpkg, $listname, keys %tmp);
		push @symlist, $listname;
	}
	if($symsname) {
		_gen_constant($reqpkg, $symsname, keys %symhash);
		push @symlist, $symsname;
	}
	
	push @symlist, $mapname if $mapname;
	_mangle_exporter($reqpkg, \@symlist,
					 $export_tag,
					 $auto_export, $auto_export_ok, $h_etags || $export_tag);

	if(%opts) {
		die "Unknown keys " . join(",", keys %opts);
	}
}

__END__

=head1 NAME

Constant::Generate - Common tasks for symbolic constants

=head2 SYNOPSIS

Simplest use

  use Constant::Generate [ qw(CONST_FOO CONST_BAR) ];
  printf( "FOO=%d, BAR=%d\n", CONST_FOO, CONST_BAR );
	
Bitflags:

  use Constant::Generate [qw(ANNOYING STRONG LAZY)], type => 'bits';
  my $state = (ANNOYING|LAZY);
  $state & STRONG == 0;

With reverse mapping:

  use Constant::Generate
    [qw(CLIENT_IRSSI CLIENT_XCHAT CLIENT_PURPLE)],
    type => "bits",
    mapname => "client_type_to_str";
  
  my $client_type = CLIENT_IRSSI | CLIENT_PURPLE;
  
  print client_type_to_str($client_type); #prints 'CLIENT_IRSSI|CLIENT_PURPLE';

Generate reverse maps, but do not generate values. also, push to exporter

  #Must define @EXPORT_OK and tags beforehand
  
  our @EXPORT_OK;
  our %EXPORT_TAGS;
  
  use Constant::Generate {
    O_RDONLY => 00,
    O_WRONLY => 01,
    O_RDWR	 => 02,
    O_CREAT  => 0100
  }, tag => "openflags", type => 'bits';
  
  my $oflags = O_RDWR|O_CREAT;
  print openflags_to_str($oflags); #prints 'O_RDWR|O_CREAT';

DWIM Constants

  use Constant::Generate {
    RDONLY  => 00,
    WRONLY  => 01,
    RDWR    => 02,
    CREAT   => 0100
  }, prefix => 'O_', dualvar => 1;
  
  my $oflags = O_RDWR|O_CREAT;
  O_RDWR eq 'RDWR';

Export to other packages

  package My::Constants
  BEGIN { $INC{'My/Constants.pm} = 1; }
  
  use base qw(Exporter);
  our (@EXPORT_OK,@EXPORT,%EXPORT_TAGS);
  
  use Constant::Generate [qw(FOO BAR BAZ)],
        tag => "my_constants",
        export_ok => 1;
  
  package My::User;
  use My::Constants qw(:my_constants);
  FOO == 0 && BAR == 1 && BAZ == 2 &&
        my_constants_to_str(FOO eq 'FOO') && my_constants_to_str(BAR eq 'BAR') &&
        my_constants_to_str(BAZ eq 'BAZ');

=head2 DESCRIPTION

C<Constant::Generate> provides useful utilities for handling, debugging, and
generating opaque, 'magic-cookie' type constants as well as value-significant
constants.

Using its simplest interface,
it will generate a simple enumeration of names passed to it on import.

Read import options to use.

=head2 USAGE

All options and configuration for this module are specified at import time.

The canonical usage of this module is
	
  use Constant::Generate $symspec, %options;

=head3 Symbol Specifications

This is passed as the first argument to C<import> and can exist as a reference
to either a hash or an array. In the case of an array reference, the array will
just contain symbol names whose values will be automatically assigned in order,
with the first symbol being C<0> and each subsequent symbol incrementing on
the value of the previous. The default starting value can be modified using the
C<start_at> option (see L</Options>).

If the symbol specification is a hashref, then keys are symbol names and values
are the symbol values, similar to what L<constant> uses.

By default, symbols are assumed to correlate to a single independent integer value,
and any reverse mapping performed will only ever map a symbol value to a single
symbol name.

For bitflags, it is possible to specify C<type =E<gt> 'bits'> in the L</Options>
which will modify the auto-generation of the constants as well as provide
suitable output for reverse mapping functions.

=head3 Basic Options

The second argument to the import function is a hash of options.

All options may be prefixed by a dash (C<-option>) or in their 'bare' form
(C<option>).

=over

=item C<type>

This specifies the type of constant used in the enumeration for the first
argument as well as the generation of reverse mapping functions.
Valid values are ones matching the regular expression C</bit/i> for
bitfield values, and ones matching C</int/i> for simple integer values.

You can also specify C</str/i> for string constants. When the symbol specification
is an array, the value for the string constants will be the strings themselves.

If C<type> is not specified, it defaults to integer values.

=item C<start_at>

Only valid for auto-generated numeric values.
This specifies the starting value for the first constant of the enumeration.
If the enumeration is a bitfield, then the
value is a factor by which to left-shift 1, thus
	
  use Constant::Generate [qw(OPT_FOO OPT_BAR)], type => "bits";
  
  OPT_FOO == 1 << 0;
  OPT_BAR == 1 << 1;
  #are true

and so on.

For non-bitfield values, this is simply a counter:

  use Constant::Generate [qw(CONST_FOO CONST_BAR)], start_at => 42;
  
  CONST_FOO == 42;
  CONST_BAR == 43;

=item C<tag>

Specify a tag to use for the enumeration.

This tag is used to generate the reverse mapping function, and is also the key
under which symbols will be exported via C<%EXPORT_TAGS>.

=item C<mapname>

Specify the name of the reverse mapping function for the enumeration. If this is
omitted, it will default to the form

  $tag . "_to_str";

where C<$tag> is the L</tag> option passed. If neither are specified, then a
reverse mapping function will not be generated.

=item C<export>, C<export_ok>, C<export_tags>

This group of options specifies the usage and modification of
C<@EXPORT>, C<@EXPORT_OK> and C<%EXPORT_TAGS> respectively,
which are used by L<Exporter>.

Values for these options should either be simple scalar booleans,
or reference objects corresponding to the appropriate variables.

If references are not used as values for these options, C<Constant::Generate>
will expect you to have defined these modules already, and otherwise die.

=item C<prefix>

Set this to a string to be prefixed to all constant names declared in the symbol
specification; thus the following are equivalent:

  use Constant::Generate [qw( MY_FOO MY_BAR MY_BAZ )];

With auto-prefixing:

  use Constant::Generate [qw( FOO BAR BAZ )], prefix => "MY_";

=item C<show_prefix>

When prefixes are specified, the default is that reverse mapping functions will
display only the 'bare', user-specified name. Thus:

  use Constant::Generate [qw( FOO )], prefix => "MY_", mapname => "const_str";
  const_str(MY_FOO) eq 'FOO';

Setting C<show_prefix> to a true value will display the full name.

=back

=head3 Dual-Var Constants

Use of dual variable constants (which return an integer or string value depending
on the context) can be enabled by passing C<stringy_vars> to C<Constant::Generate>,
or using C<Constant::Generate::Dualvar>:

=over

=item C<stringy_vars>

=item C<dualvar>

This will apply some trickery to the values returned by the constant symbols.

Normally, constant symbols will return only their numeric value, and a reverse
mapping function is needed to retrieve the original symbolic name.

When C<dualvar> is set to a true value the values returned by the constant
subroutine will do the right thing in string and numeric contexts; thus:

  use Constant::Generate::Dualvar [qw(FOO BAR)];
  
  FOO eq 'FOO';
  FOO == 0;

The L</show_prefix> option controls whether the prefix is part of the stringified
form.

Do not rely too much on C<dualvar> to magically convert any number into
some meaningful string form. In particular, it will only work on scalars which
are directly descended from the constant symbols. Paritcularly, this means that
unpack()ing or receiving data from a different process will not result in these
special stringy variables.

The C<stringy_vars> option is an alias for C<dualvar>,
which is supported for backwards compatibility.

=back

=head3 Listings

The following options enable constant subroutines which return lists of the
symbols or their values:

  use Constant::Generate [qw(
    FOO BAR BAZ
  )],
  allvalues => "VALS",
  allsyms => "SYMS";
  
  printf "VALUES: %s\n", join(", ", VALUES);
  # => 0, 1, 2 (in no particular order)
  
  printf "SYMBOLS: %s\n", join(", ", SYMS);
  # => FOO, BAR, BAZ (in no particular order)

Or something potentially more useful:

  use Constant::Generate [qw(
    COUGH
    SNEEZE
    HICCUP
    ZOMBIES
    )],
  type => 'bits',
  allvalues => 'symptoms',
  mapname => "symptom_str";
  
  my $remedies = {
    COUGH, "Take some honey",
    SNEEZE, "Buy some tissues",
    HICCUP, "Drink some water"
  };
  
  my $patient = SNEEZE | COUGH | ZOMBIES;
  
  foreach my $symptom (symptoms()) {
    next unless $patient & $symptom;
    my $remedy = $remedies->{$symptom};
    if(!$remedy) {
      printf "Uh-Oh, we don't have a remedy for %s. Go to a hospital!\n",
      symptom_str($symptom);
    } else {
      printf "You should: %s\n", $remedy;
    }
  }

=over

=item C<allvalues>

Sometimes it is convenient to have a list of all the constants defined in the
enumeration. Setting C<allvalues> will make C<Constant::Generate> create a like-named
constant subroutine which will return a list of all the I<values> created.

=item C<allsyms>

Like L</allvalues>, but will return a list of strings for the constants in
the enumeration.

=back

=head3 EXPORTING

This module also allows you to define a 'constants' module of your own,
from which you can export constants to other files in your package.
Figuring out the right exporter parameters is quite hairy,
and the export options can natually be a bit tricky.

In order to succesfully export symbols made by this module, you must specify
either C<export_ok> or C<export> as hash options to C<import>. These correspond
to the like-named variables documented by L<Exporter>.

Additionally, export tags can be specified only if one of the C<export> flags is
set to true (again, following the behavior of C<Exporter>). The auto-export
feature is merely one of syntactical convenience, but these three forms are
effectively equivalent:

Nicest way:

  use base qw(Exporter);
  our (@EXPORT, %EXPORT_TAGS);
  use Constant::Generate
    [qw(FOO BAR BAZ)],
    export => 1,
    tag => "some_constants"
  ;

A bit more explicit:

  use base qw(Exporter);
  use Constant::Generate
    [qw(FOO BAR BAZ)],
      export => \our @EXPORT,
      export_tags => \our %EXPORT_TAGS,
      tag => "some_constants",
      mapname => "some_constants_to_str",
  ;

Or DIY:

  use base qw(Exporter);
  our @EXPORT;
  my @SYMS;
  BEGIN {
    @SYMS = qw(FOO BAR BAZ);
  }
  
  use Constant::Generate \@SYMS, mapname => "some_constants_to_str";
  
  push @EXPORT, @SYMS, "some_constants_to_str";
  $EXPORT_TAGS{'some_constants'} = [@SYMS, "some_constants_to_str"];

Also note that any L</allvalues>, L</allsyms>, or L</mapname>
subroutines will be exported according
to whatever specifications were configured for the constants themselves.

=head2 NOTES

The C<dualvar> or C<stringy_var> option can be short-handed by doing the following:

  use Constant::Generate::Dualvar [qw(
    FOO
    BAR
    BAZ
  )], prefix => 'MY_';
  MY_FOO eq 'FOO';

etc.

=head1 BUGS & TODO

It's somewhat ironic that a module which aims to promote the use of symbolic
constants has all of its configuration options determined by hashes and strings.

=head1 REPOSITORY

L<https://github.com/mnunberg/Constant-Generate>

=head1 AUTHOR & COPYRIGHT

Copyright (c) 2011 by M. Nunberg

You may use and distribute this software under the same terms and conditions as
Perl itself, OR under the terms and conditions of the GNU GPL, version 2 or greater.

