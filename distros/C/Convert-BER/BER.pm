# Convert::BER.pm
#
# Copyright (c) 1995-1999 Graham Barr <gbarr@pobox.com>. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Convert::BER;

use vars qw($VERSION @ISA);
use Exporter ();
use strict;
use vars qw($VERSION @ISA @EXPORT_OK);

BEGIN {
    if ($] >= 5.006) {
	require bytes; 'bytes'->import;
    }

    $VERSION = "1.32";

    @ISA = qw(Exporter);
    
    @EXPORT_OK = qw(
	BER_BOOLEAN
	BER_INTEGER
	BER_BIT_STR
	BER_OCTET_STR
	BER_NULL
	BER_OBJECT_ID
	BER_REAL
	BER_SEQUENCE
	BER_SET

	BER_UNIVERSAL
	BER_APPLICATION
	BER_CONTEXT
	BER_PRIVATE

	BER_PRIMITIVE
	BER_CONSTRUCTOR

	BER_LONG_LEN
	BER_EXTENSION_ID
	BER_BIT

	ber_tag
    );

    # 5.003 does not have UNIVERSAL::can
    unless(defined &UNIVERSAL::can) {
        *UNIVERSAL::can = sub {
            my($obj,$meth) = @_;
            my $pkg = ref($obj) || $obj;
            my @pkg = ($pkg);
            my %done;
            while(@pkg) {
                $pkg = shift @pkg;
                next if exists $done{$pkg};
                $done{$pkg} = 1;

                no strict 'refs';

                unshift @pkg,@{$pkg . "::ISA"}
                    if(@{$pkg . "::ISA"});
                return \&{$pkg . "::" . $meth}
                    if defined(&{$pkg . "::" . $meth});
            }
            undef;
        }
    }
}

##
## Constants
##

sub BER_BOOLEAN 	() { 0x01 }
sub BER_INTEGER 	() { 0x02 }
sub BER_BIT_STR 	() { 0x03 }
sub BER_OCTET_STR 	() { 0x04 }
sub BER_NULL 		() { 0x05 }
sub BER_OBJECT_ID 	() { 0x06 }
sub BER_REAL 		() { 0x09 }
sub BER_ENUMERATED	() { 0x0A }
sub BER_SEQUENCE 	() { 0x10 }
sub BER_SET 		() { 0x11 }
sub BER_PRINT_STR	() { 0x13 }
sub BER_IA5_STR		() { 0x16 }
sub BER_UTC_TIME	() { 0x17 }
sub BER_GENERAL_TIME	() { 0x18 }

sub BER_UNIVERSAL 	() { 0x00 }
sub BER_APPLICATION 	() { 0x40 }
sub BER_CONTEXT 	() { 0x80 }
sub BER_PRIVATE		() { 0xC0 }

sub BER_PRIMITIVE	() { 0x00 }
sub BER_CONSTRUCTOR	() { 0x20 }

sub BER_LONG_LEN	() { 0x80 }
sub BER_EXTENSION_ID	() { 0x1F }
sub BER_BIT 		() { 0x80 }

# This module is used a lot so performance matters. For that reason it
# is implemented as an ARRAY instead of a HASH.
# inlined constants for array indices

sub _BUFFER () { 0 }
sub _POS    () { 1 }
sub _INDEX  () { 2 }
sub _ERROR  () { 3 }
sub _PEER   () { 4 }

sub _PACKAGE      () { 0 }
sub _TAG          () { 1 }
sub _PACK         () { 2 }
sub _PACK_ARRAY   () { 3 }
sub _UNPACK       () { 4 }
sub _UNPACK_ARRAY () { 5 }

{
  Convert::BER->define(
    ##
    ## Syntax operator
    ##

    [ BER          => undef, undef ],
    [ ANY          => undef, undef ],
    [ CONSTRUCTED  => undef, undef ],
    [ OPTIONAL     => undef, undef ],
    [ CHOICE       => undef, undef ],

    ##
    ## Primitive operators
    ##

    [ BOOLEAN     => undef, BER_UNIVERSAL | BER_PRIMITIVE   | BER_BOOLEAN    ],
    [ INTEGER     => undef, BER_UNIVERSAL | BER_PRIMITIVE   | BER_INTEGER    ],
    [ STRING      => undef, BER_UNIVERSAL | BER_PRIMITIVE   | BER_OCTET_STR  ],
    [ NULL        => undef, BER_UNIVERSAL | BER_PRIMITIVE   | BER_NULL	     ],
    [ OBJECT_ID   => undef, BER_UNIVERSAL | BER_PRIMITIVE   | BER_OBJECT_ID  ],
    [ BIT_STRING  => undef, BER_UNIVERSAL | BER_PRIMITIVE   | BER_BIT_STR    ],
    [ BIT_STRING8 => undef, BER_UNIVERSAL | BER_PRIMITIVE   | BER_BIT_STR    ],
    [ REAL	  => undef, BER_UNIVERSAL | BER_PRIMITIVE   | BER_REAL       ],

    [ SEQUENCE    => undef, BER_UNIVERSAL | BER_CONSTRUCTOR | BER_SEQUENCE   ],
    [ SEQUENCE_OF => undef, BER_UNIVERSAL | BER_CONSTRUCTOR | BER_SEQUENCE   ],
  );

  ##
  ## These variables will be defined by the above ->define() call
  ##

  use vars qw($INTEGER $SEQUENCE $STRING $SEQUENCE_OF);

  Convert::BER->define(
    ##
    ## Sub-classed primitive operators
    ##

    [ ENUM   => $INTEGER,     BER_UNIVERSAL | BER_PRIMITIVE   | BER_ENUMERATED ],
    [ SET    => $SEQUENCE,    BER_UNIVERSAL | BER_CONSTRUCTOR | BER_SET        ],
    [ SET_OF => $SEQUENCE_OF, BER_UNIVERSAL | BER_CONSTRUCTOR | BER_SET        ],

    [ ObjectDescriptor => $STRING, BER_UNIVERSAL |  7],
    [ UTF8String       => $STRING, BER_UNIVERSAL | 12],
    [ NumericString    => $STRING, BER_UNIVERSAL | 18],
    [ PrintableString  => $STRING, BER_UNIVERSAL | 19],
    [ TeletexString    => $STRING, BER_UNIVERSAL | 20],
    [ T61String        => $STRING, BER_UNIVERSAL | 20],
    [ VideotexString   => $STRING, BER_UNIVERSAL | 21],
    [ IA5String        => $STRING, BER_UNIVERSAL | 22],
    [ GraphicString    => $STRING, BER_UNIVERSAL | 25],
    [ VisibleString    => $STRING, BER_UNIVERSAL | 26],
    [ ISO646String     => $STRING, BER_UNIVERSAL | 26],
    [ GeneralString    => $STRING, BER_UNIVERSAL | 27],
    [ UTCTime          => $STRING, BER_UNIVERSAL | 23],
    [ GeneralizedTime  => $STRING, BER_UNIVERSAL | 24],
  );

  Convert::BER->define(
    [ '_Time_generic' => $STRING, undef ],
    [ TimeUZ  => '_Time_generic', BER_UNIVERSAL | 23],
    [ TimeUL  => '_Time_generic', BER_UNIVERSAL | 23],

    [ TimeGZ  => '_Time_generic', BER_UNIVERSAL | 24],
    [ TimeGL  => '_Time_generic', BER_UNIVERSAL | 24],
  );
}

# only load Carp when needed

sub croak {
    require Carp;
    goto &Carp::croak;
}

##
## define:
##	does all the hard work of dynamically building the BER class
##	and BER-type classes
##

sub define {
    my $pkg = shift;

    no strict 'refs'; # we do some naughty stuff here :-)

    $pkg = ref($pkg) || $pkg;

    while(@_) {
	my($name,$isa,$tag) = @{ $_[0] }; shift;
	my $subpkg = $pkg . "::" . $name;

	croak("Bad tag name '$name'")
		if($name =~ /\A(?:DESTROY|VERSION)\Z/);

	if(defined $isa) {
	    my $isapkg = $pkg->can('_' . $isa) or
		croak "Unknown BER tag type '$isa'";

	    @{$subpkg . "::ISA"} = ( &{$isapkg}()->[ _PACKAGE ] )
		unless @{$subpkg . "::ISA"};

	    $tag = $subpkg->tag
		unless defined $tag;
	}

	if(defined &{$subpkg . "::tag"}) {
	    croak "tags for '$name' do not match "
		unless $subpkg->tag == $tag;
	}
	else {
	    *{$subpkg . "::tag"} = sub { $tag };
	}

	push(@{$pkg . "::EXPORT_OK"}, '$' . $name, $name);

	*{$pkg . "::"  . $name} = \$name;

	my @data = ( $subpkg, $subpkg->tag,
		     map { $subpkg->can($_) }
		         qw(pack pack_array unpack unpack_array)
		   );

	{
	    my $const = $tag;
	    *{$pkg . "::" . $name} = sub () { $const }
		unless defined &{$pkg . "::" . $name};
	}

	*{$pkg . "::_" . $name} = sub { \@data };
    }
}

# Now we have done the naughty stuff, make sure we do no more
use strict;

sub ber_tag {
  my($t,$e) = @_;
  $e ||= 0; # unsigned;

  if($e < 30) {
    return (($t & 0xe0) | $e);
  }

  $t = ($t | 0x1f) & 0xff;
  if ($e & 0xffe00000) {
    die "Too big";
  }
  my @t = ();

  push(@t, ($b >> 14) | 0x80)
    if ($b = ($e & 0x001fc000));

  push(@t, ($b >> 7) | 0x80)
    if ($b = ($e & 0xffffff80));

  unpack("V",pack("C4",$t,@t,$e & 0x7f,0,0));
}

sub new {
    my $package = shift;
    my $class = ref($package) || $package;

    my $self = bless [
	@_ == 1 ? shift : "",
	0,
	ref($package) ? $package->[ Convert::BER::_INDEX() ] : [],
    ], $class;

    @_ ? $self->encode(@_) : $self;
}

##
## Some basic subs for packing/unpacking data
## These methods would be called by the BER-type classes
##

sub num_length {
    return 1 if ( ($_[0] &     0xff) == $_[0]);
    return 2 if ( ($_[0] &   0xffff) == $_[0]);
    return 3 if ( ($_[0] & 0xffffff) == $_[0]);
    return 4;
}

sub pos {
    my $ber = shift;
    @_ ? ($ber->[ Convert::BER::_POS() ] = shift)
       : $ber->[ Convert::BER::_POS() ];
}

sub pack {
    my $ber = shift;
    $ber->[ Convert::BER::_BUFFER() ] .= $_[0];
    1;
}

sub unpack {
    my($ber,$len) = @_;
    my $pos = $ber->[ Convert::BER::_POS() ];
    my $npos = $pos + $len;

    die "Buffer empty"
	if ($npos > CORE::length($ber->[ Convert::BER::_BUFFER() ]));

    $ber->[ Convert::BER::_POS() ] = $npos;

    substr($ber->[ Convert::BER::_BUFFER() ],$pos,$len);
}

sub pack_tag {
    my($ber,$tag) = @_;
    
    # small tag number are more common, so check $tag size in reverse order
    unless(($tag & 0x1f) == 0x1f) {
	$ber->[ Convert::BER::_BUFFER() ] .= chr( $tag );
        return 1;
    }

    unless($tag & ~0x7fff) {
        $ber->[ Convert::BER::_BUFFER() ] .= CORE::pack("v",$tag);
	return 2;
    }

    unless($tag & ~0x7fffff) {
        $ber->[ Convert::BER::_BUFFER() ] .= CORE::pack("vc",$tag, ($tag >> 16));
	return 3;
    }

    $ber->[ Convert::BER::_BUFFER() ] .= CORE::pack("V",$tag);
    return 4;
}

sub unpack_tag {
    my($ber,$expect) = @_;
    my $pos = $ber->[ Convert::BER::_POS() ];
    my $len = CORE::length($ber->[ Convert::BER::_BUFFER() ]);

    die "Buffer empty"
        if($pos >= $len);

    my $tag = CORE::unpack("C",substr($ber->[ Convert::BER::_BUFFER() ],$pos++,1
));

    if(($tag & 0x1f) == 0x1f) {
        my $b;
        my $s = 8;

        do {
            die "Buffer empty"
                if($pos >= $len);
            $b = CORE::unpack("C",substr($ber->[ Convert::BER::_BUFFER() ],$pos++,1));
            $tag |= $b << $s;
            $s += 8;
        } while($b & 0x80);
    }

    die sprintf("Expecting tag 0x%x, found 0x%x",$expect,$tag)
        if(defined($expect) && ($tag != $expect));

    $ber->[ Convert::BER::_POS() ] = $pos;

    $tag
}

sub pack_length {
    my($ber,$len) = @_;

    if($len & ~0x7f) {
	my $lenlen = num_length($len);

	$ber->[ Convert::BER::_BUFFER() ] .= CORE::pack("C", $lenlen | 0x80) . substr(CORE::pack("N",$len), 0 - $lenlen);

	return $lenlen + 1;
    }

    $ber->[ Convert::BER::_BUFFER() ] .= CORE::pack("C", $len);
    return 1;
}



sub unpack_length {
    my $ber = shift;
    my $pos = $ber->[ Convert::BER::_POS() ];

    die "Buffer empty"
	if($pos >= CORE::length($ber->[ Convert::BER::_BUFFER() ]));

    my $len = CORE::unpack("C", substr($ber->[ Convert::BER::_BUFFER() ],$pos++,1));

    if($len & 0x80) {
	my $buf;

	$len &= 0x7f;

	die "Buffer empty"
	    if(($pos+$len) > CORE::length($ber->[ Convert::BER::_BUFFER() ]));

	my $tmp = "\0" x (4 - $len) . substr($ber->[ Convert::BER::_BUFFER() ],$pos,$len);

	$pos += $len;

	$len = $len ? CORE::unpack("N",$tmp) : -1;
    }

    $ber->[ Convert::BER::_POS() ] = $pos;

    $len;
}

##
## User interface (public) method
##

sub error {
    my $ber = shift;
    $ber->[ Convert::BER::_ERROR() ];
}


sub tag {
    my $ber = shift;
    my $pos = $ber->[ Convert::BER::_POS() ];
    my $tag = eval {
	local($SIG{'__DIE__'});
	unpack_tag($ber)
    } or return undef;
    $ber->[ Convert::BER::_POS() ] = $pos;
    $tag;
}

sub length {
    my $ber = shift;

    CORE::length($ber->[ Convert::BER::_BUFFER() ]);
}

sub buffer {
    my $ber = shift;
    if(@_) {
	$ber->[ Convert::BER::_POS() ] = 0;
	$ber->[ Convert::BER::_BUFFER() ] = "" . shift;
    }
    $ber->[ Convert::BER::_BUFFER() ];
}

##
## just for debug :-)
##

sub _hexdump {
  my($fmt,$pos) = @_[1,2]; # Don't copy buffer

  $pos ||= 0;

  my $offset  = 0;
  my $cnt     = 1 << 4;
  my $len     = CORE::length($_[0]);
  my $linefmt = ("%02X " x $cnt) . "%s\n";

  print "\n";

  while ($offset < $len) {
    my $data = substr($_[0],$offset,$cnt);
    my @y = CORE::unpack("C*",$data);

    printf $fmt,$pos if $fmt;

    # On the last time through replace '%02X ' with '__ ' for the
    # missing values
    substr($linefmt, 5*@y,5*($cnt-@y)) = "__ " x ($cnt - @y)
	if @y != $cnt;

    # Change non-printable chars to '.'
    $data =~ s/[\x00-\x1f\x7f-\xff]/./sg;
    printf $linefmt, @y,$data;

    $offset += $cnt;
    $pos += $cnt;
  }
}

my %type = (
  split(/[\t\n]\s*/,
    q(10	SEQUENCE
      01	BOOLEAN
      0A	ENUM
      11	SET
      02	INTEGER
      03	BIT STRING
      C0	PRIVATE [%d]
      04	STRING
      40	APPLICATION [%d]
      05	NULL
      06	OBJECT ID
      80	CONTEXT [%d]
    )
  )
);

sub dump {
  my $ber = shift;
  my $fh = @_ ? shift : \*STDERR;

  my $ofh = select($fh);

  my $pos = 0;
  my $indent = "";
  my @seqend = ();
  my $length = CORE::length($ber->[ Convert::BER::_BUFFER() ]);
  my $fmt = $length > 0xffff ? "%08X" : "%04X";

  local $ber->[ Convert::BER::_POS() ];

  $ber->[ Convert::BER::_POS() ] = 0;

  while(1) {
    while (@seqend && $ber->[ Convert::BER::_POS() ] >= $seqend[0]) {
      $indent = substr($indent,2);
      shift @seqend;
      printf "$fmt        : %s}\n",$ber->[ Convert::BER::_POS() ],$indent;
    }
    last unless $ber->[ Convert::BER::_POS() ] < $length;
    
    my $start = $ber->[ Convert::BER::_POS() ];
    my $tag = unpack_tag($ber);
    my $pos = $ber->[ Convert::BER::_POS() ];
    my $len = Convert::BER::unpack_length($ber);

    if($tag == 0 && $len == 0) {
      $seqend[0] = 0;
      redo;
    }
    printf $fmt. " %02X %4d: %s",$start,$tag,$len,$indent;

    my $label = $type{sprintf("%02X",$tag & ~0x20)}
		|| $type{sprintf("%02X",$tag & 0xC0)}
		|| "UNIVERSAL [%d]";

    if (($tag & 0x1f) == 0x1f) {
      my $k = $tag >> 8;
      my $j = 0;
      while($k) {
        $j = ($j << 7) | ($k & 0x7f);
       $k >>= 8;
      }
      my $l = $label;
      $l =~ s/%d/0x%x/;
      printf $l, $j;
    }
    else {
      printf $label, $tag & ~0xE0;
    }
 
    if ($tag & BER_CONSTRUCTOR) {
      print " {\n";
      if($len < 0) {
          unshift(@seqend, ~(1<<31));
      }
      else {
          unshift(@seqend, $ber->[ Convert::BER::_POS() ] + $len);
      }
      $indent .= "  ";
      next;
    }

    $ber->[ Convert::BER::_POS() ] = $pos;
    my $tmp;

    for ($label) { # switch
      /^INTEGER/ && do {
	Convert::BER::INTEGER->unpack($ber,\$tmp);
	printf " = %d\n",$tmp;
        last;
      };

      /^ENUM/ && do {
	Convert::BER::ENUM->unpack($ber,\$tmp);
	printf " = %d\n",$tmp;
        last;
      };

      /^BOOLEAN/ && do {
	Convert::BER::BOOLEAN->unpack($ber,\$tmp);
	printf " = %s\n",$tmp ? 'TRUE' : 'FALSE';
        last;
      };

      /^OBJECT ID/ && do {
	Convert::BER::OBJECT_ID->unpack($ber,\$tmp);
	printf " = %s\n",$tmp;
        last;
      };

      /^NULL/ && do {
        $ber->[ Convert::BER::_POS() ] = $pos+1;
	print "\n";
        last;
      };

      /^STRING/ && do {
	Convert::BER::STRING->unpack($ber,\$tmp);
	if ($tmp =~ /[\x00-\x1f\x7f-\xff]/s) {
  	  _hexdump($tmp,$fmt . "        :   ".$indent, $pos);
	}
	else {
	  printf " = '%s'\n",$tmp;
	}
        last;
      };

      /^BIT STRING/ && do {
	Convert::BER::BIT_STRING->unpack($ber,\$tmp);
	print " = ",$tmp,"\n";
        last;
      };

      # default -- dump hex data
      Convert::BER::STRING->unpack($ber,\$tmp);
      _hexdump($tmp,$fmt . "        :   ".$indent, $pos);
    }
  }

  select($ofh);
}

sub hexdump {
    my $ber = shift;
    my $fh = @_ ? shift : \*STDERR;
    my $ofh = select($fh);
    _hexdump($ber->[ Convert::BER::_BUFFER() ]);
    print "\n";
    select($ofh);
}

##
## And now the real guts of it, the encoding and decoding routines
##

sub encode {
    my $ber = shift;
    local($SIG{'__DIE__'});

    $ber->[ Convert::BER::_INDEX() ] = [];

    return $ber
	if eval { Convert::BER::_encode($ber,\@_) };

    $ber->[ Convert::BER::_ERROR() ] = $@;

    undef;
}

sub _encode {
    my $ber = shift;
    my $desc = shift;
    my $i = 0;

    while($i < @$desc ) {
	my $type = $desc->[$i++];
	my $arg  = $desc->[$i++];
	my $tag  = undef;

	($type,$tag) = @$type
	    if(ref($type) eq 'ARRAY');

	my $can = $ber->can('_' . $type);

	die "Unknown element '$type'"
	    unless $can;

	my $data = &$can();
        my $pkg = $data->[ Convert::BER::_PACKAGE() ];

	$tag = $data->[ Convert::BER::_TAG() ]
	    unless defined $tag;

	$arg = &{$arg}(@{$ber->[ Convert::BER::_INDEX() ]})
	    if(ref($arg) eq 'CODE');

	if(ref($arg) eq 'ARRAY') {
	    if($can = $data->[Convert::BER::_PACK_ARRAY() ]) {
		pack_tag($ber,$tag)
		    if defined $tag;

		&{$can}($pkg,$ber,$arg);
	    }
	    else {
		my $a;
		foreach $a (@$arg) {
		    pack_tag($ber,$tag)
			if defined $tag;

		    &{$data->[Convert::BER::_PACK() ]}($pkg,$ber,$a);
		}
	    }
	}
	else {
	    pack_tag($ber,$tag)
		if defined $tag;
	    &{$data->[Convert::BER::_PACK() ]}($pkg,$ber,$arg);
	}
    }

    1;
}

sub decode {
    my $ber = shift;
    my $pos = $ber->[ Convert::BER::_POS() ];
    local($SIG{'__DIE__'});

    $ber->[ Convert::BER::_INDEX() ] = [];

    return $ber
	if eval { Convert::BER::_decode($ber,\@_) };

    $ber->[ Convert::BER::_ERROR() ] = $@;
    $ber->[ Convert::BER::_POS() ]   = $pos;

    undef;
}

sub _decode {
    my $ber = shift;
    my $desc = shift;
    my $i = 0;

    my $argc;

TAG:
    for($argc = @$desc ; $argc > 0 ; $argc -= 2) {
	my $type = $desc->[$i++];
	my $arg  = $desc->[$i++];
	my $tag  = undef;

	($type,$tag) = @$type
	    if(ref($type) eq 'ARRAY');

	my $can = $ber->can('_' . $type);

	die "Unknown element '$type'"
	    unless $can;

	my $data = &$can();
	my $pkg  = $data->[ Convert::BER::_PACKAGE() ];

	$tag = $data->[ Convert::BER::_TAG() ]
	    unless defined $tag;

	$arg = &{$arg}(@{$ber->[ Convert::BER::_INDEX() ]})
	    if(ref($arg) eq 'CODE');

	if(ref($arg) eq 'ARRAY') {
	    if($data->[ Convert::BER::_UNPACK_ARRAY() ]) {

		unpack_tag($ber,$tag)
		    if(defined $tag);

		&{$data->[ Convert::BER::_UNPACK_ARRAY() ]}($pkg,$ber,$arg);
	    }
	    else {
		@$arg = ();
		while(CORE::length($ber->[ Convert::BER::_BUFFER() ]) > $ber->[ Convert::BER::_POS() ]) {
		    if(defined $tag) {
			next TAG
			    unless eval { unpack_tag($ber,$tag) };
		    }

		    push @$arg, undef;
		    &{$data->[ Convert::BER::_UNPACK() ]}($pkg,$ber,\$arg->[-1]);
		}
	    }
	}
	else {
	    eval {
		unpack_tag($ber,$tag)
		    if(defined $tag);

		&{$data->[ Convert::BER::_UNPACK() ]}($pkg,$ber,$arg);
		1;
	    } or ($$arg = undef, die);
	}
    }

   1;
}

##
## a couple of routines to interface to a file descriptor.
##

sub read {
    my $ber = shift;
    my $io  = shift;
    my $indef = shift;

    # We need to read one packet, and exactly only one packet.
    # So we have to read the first few bytes one at a time, until
    # we have enough to decode a tage and a length. We then know
    # how many more bytes to read

    $ber = $ber->new unless ref($ber);
    $ber->[ _BUFFER() ] = "" unless $indef;

    my $pos = CORE::length($ber->[ _BUFFER() ]);
    my $start = $pos;

    # The first byte is the tag
    sysread($io,$ber->[ _BUFFER() ],1,$pos++) or
	goto READ_ERR;

#    print STDERR "-"x80,"\n";
#    print STDERR CORE::unpack("H*",$ber->[ _BUFFER() ]),"\n";

    my $ch = ord(substr($ber->[ _BUFFER() ],-1));

    # Tag may be multi-byte
    if(($ch & 0x1f) == 0x1f) {
	do {
	    sysread($io, $ber->[ _BUFFER() ], 1, $pos++) or
		goto READ_ERR;

	    $ch = ord(substr($ber->[ _BUFFER() ],-1));

	} while($ch & 0x80);
    }

#    print STDERR CORE::unpack("H*",$ber->[ _BUFFER() ]),"\n";

    # The next byte will be the first byte of the length
    sysread($io, $ber->[ _BUFFER() ], 1, $pos++) or
	goto READ_ERR;

#    print STDERR CORE::unpack("H*",$ber->[ _BUFFER() ]),"\n";

    $ch = ord(substr($ber->[ _BUFFER() ],-1));
#    print STDERR CORE::unpack("H*",substr($ber->[ _BUFFER() ],-1))," $ch\n";

    # May be a multi-byte length
    if($ch & 0x80) {
	my $len = $ch & 0x7f;
	unless ($len) {
#    print STDERR CORE::unpack("H*",$ber->[ _BUFFER() ]),"\n";
	    # OK we have an indefinate length
	    while(1) {
		Convert::BER::read($ber,$io,1);
		my $p = CORE::length($ber->[ _BUFFER() ]);
		if(($p - $pos) == 2 && substr($ber->[ _BUFFER() ],-2) eq "\0\0") {
#    print STDERR CORE::unpack("H*",$ber->[ _BUFFER() ]),"\n","-"x80,"\n";
		    return $ber;
		}
		$pos = $p;
	    }
	}
	while($len) {
	    my $n = sysread($io, $ber->[ _BUFFER() ], $len, $pos) or
		goto READ_ERR;
	    $len -= $n;
	    $pos += $n;
	}
    }

#    print STDERR CORE::unpack("H*",$ber->[ _BUFFER() ]),"\n";

    # We can now unpack a tage and a length to determine how many more
    # bytes to read

    $ber->[ _POS() ] = $start;
    unpack_tag($ber);
    my $len = unpack_length($ber);

    while($len > 0) {
	my $got;

	goto READ_ERR
	    unless( $got = sysread($io, $ber->[ _BUFFER() ],$len,CORE::length($ber->[ _BUFFER() ])) );

	$len -= $got;
    }

    # Reset pos back to the beginning.
    $ber->[ _POS() ] = 0;

#    print STDERR CORE::unpack("H*",$ber->[ _BUFFER() ]),"\n";
    return $ber;

READ_ERR:
    $@ = "I/O Error $! " . CORE::unpack("H*",$ber->[ _BUFFER() ]);
    return undef;
}

sub write {
    my $ber = shift;
    my $io = shift;
    local($SIG{'__DIE__'});

    my $togo = CORE::length($ber->[ _BUFFER() ]);
    my $pos = 0;

    while($togo) {
	my $len;

	unless ($len = syswrite($io, $ber->[ _BUFFER() ],$togo,$pos)) {
	    $@ = "I/O Error $!";
	    return;
	}

	$togo -= $len;
	$pos += $len;
    }

    1;
}

sub send {
    my $ber = shift;
    my $sock = shift;
    
    local($SIG{'__DIE__'});

    eval {
	# Enable reporting a 'Broken pipe' error rather than dying.
	local ($SIG{PIPE}) = "IGNORE";

	@_ ? send($sock,$ber->[ _BUFFER() ],0,$_[0])
           : send($sock,$ber->[ _BUFFER() ],0);
    } or die "I/O Error: $!";
}

sub recv {
    my $ber = shift;
    my $sock = shift;

    require Socket; # for Socket::MSG_PEEK

    local $SIG{'__DIE__'};

    $ber = $ber->new unless ref($ber);
    $ber->[ _BUFFER() ] = "";

    # We do not know the size of the datagram, so we have to PEEK --GMB
    # is there an easier way to determine the packet size ??

    my $n = 128;
    die "I/O Error: $!" 
	unless ((defined recv($sock,$ber->[ _BUFFER() ],$n,Socket::MSG_PEEK()))
		and not $!);

    # PEEK until we have the complete tag and length of the BER
    # packet. Use the length to determine how much data to read from
    # the socket. This is an attempt to ensure that we read the
    # entire packet and that we don't read into the next packet, if
    # there is one.

    my $len;
    
    # Keep reading until we've read enough of the packet to unpack
    # the BER length field.
    for(;;) {

	# If we can decode a tag and length we can detemine the length
	
	if(defined($len = eval {
	    $ber->[ _POS() ] = 0;
	    unpack_tag($ber);
	    unpack_length($ber)
		+ $ber->[ _POS() ];
  	         })
	   # unpack_length will return -1 for unknown length
	   && $len >= $ber->[ _POS() ]) {
	    
	    $n = $len;
	    last;
	}

	# peek some more
	$n <<= 1;
	die "I/O Error: $!" 
	    unless ((defined recv($sock,$ber->[ _BUFFER() ],$n,Socket::MSG_PEEK()))
		    and not $!);
    }
    
    # now we know the size, get it again but without MSG_PEEK
    # this will cause the kernel to remove the datagram from it's queue

    # If the data on the socket doesn't correspond to a valid BER
    # object, the loop above could have read something it thought was
    # the length and this loop could then block waiting for that many
    # bytes, which will never arrive. What do you do about something
    # like that?
    
    $ber->[ _POS() ] = 0;
    $ber->[ _BUFFER() ] = "";
    my ($read, $tmp);
    $read = 0;
    while ($read < $n) {
	$ber->[ _PEER() ] = recv($sock, $tmp, $n - $read, 0);
	die "I/O Error: $!" 
	    unless ((defined ( $ber->[ _PEER() ] ) and not $!));
	
	$read += CORE::length($tmp);
	$ber->[ _BUFFER() ] .= $tmp;
    }
    $ber;
}

##
## The primitive packages
##

package Convert::BER::BER;

sub pack {
    my($self,$ber,$arg) = @_;

    $ber->[ Convert::BER::_BUFFER() ] .= $arg->[ Convert::BER::_BUFFER() ]
	if ref($arg);

    1;
}

sub unpack {
    my($self,$ber,$arg) = @_;

    my $len = CORE::length($ber->[ Convert::BER::_BUFFER() ]) - $ber->[ Convert::BER::_POS() ];

    $$arg = $ber->new(Convert::BER::unpack($ber,$len));

    1;
}

package Convert::BER::ANY;

sub pack {
    my($self,$ber,$arg) = @_;

    $ber->[ Convert::BER::_BUFFER() ] .= $arg->[ Convert::BER::_BUFFER() ];

    1;
}

sub unpack {
    my($self,$ber,$arg) = @_;

    my $pos = $ber->[ Convert::BER::_POS() ];
    my $tag = Convert::BER::unpack_tag($ber);
    my $len = Convert::BER::unpack_length($ber) + $ber->[ Convert::BER::_POS() ] - $pos;
    $ber->[ Convert::BER::_POS() ] = $pos;

    $$arg = $ber->new(Convert::BER::unpack($ber,$len));

    1;
}

##
##
##

package Convert::BER::BOOLEAN;

sub pack {
    my($self,$ber,$arg) = @_;

    Convert::BER::pack_length($ber,1);
    $ber->[ Convert::BER::_BUFFER() ] .= CORE::pack("c", $arg ? 0xff : 0x00);

    1;
}

sub unpack {
    my($self,$ber,$arg) = @_;

    my $len = Convert::BER::unpack_length($ber);

    $$arg = CORE::unpack("c", Convert::BER::unpack($ber,$len)) ? 1 : 0;

    1;
}

##
##
##

package Convert::BER::INTEGER;

##
## Math::BigInt support
##

sub pack_bigint {
    my($self,$ber,$arg) = @_;

    require Math::BigInt;

    my $neg = ($arg < 0) ? 1 : 0;
    my @octet = ();
    my $num = new Math::BigInt(abs($arg));

    $num -= 1 if $neg;
    while($num > 0) {
	my($i,$y) = $num->bdiv(256);
	$num = new Math::BigInt($i);
	$y = $y ^ 0xff if $neg;
	unshift(@octet,$y);
    }
    @octet = (0) unless @octet;

    my $msb = ($octet[0] & 0x80) ? 1 : 0;

    unshift(@octet,$neg ? 0xff : 0x00)
	if($neg != $msb);

    Convert::BER::pack_length($ber, scalar @octet);

    $ber->[ Convert::BER::_BUFFER() ] .= CORE::pack("C*",@octet);

    1;
}

sub unpack_bigint {
    my($self,$ber,$arg) = @_;

    require Math::BigInt;

    my $len = Convert::BER::unpack_length($ber);
    my @octet = CORE::unpack("C*",Convert::BER::unpack($ber,$len));
    my $neg = ($octet[0] & 0x80) ? 1 : 0;
    my $val = $$arg = 0;

    while(@octet) {
	my $oct = shift @octet;
	$oct = $oct ^ 0xff
	    if $neg;
	$val *= (1<<8);
	$val += $oct;
    }

    $val = -1 - $val
	if $neg;

    1;
}

##
## Math::BigInteger support
##

sub pack_biginteger {
    my($self,$ber,$arg) = @_;

    my($len,$data);
    my $offset = 0;

    require Math::BigInteger;
    # save has no concept of +/-
    my $v = $arg->cmp(new Math::BigInteger(0));

    if($v) {
	if($v < 0) {
	    my $b = $arg->bits + 8;
	    $b -= $b % 8;
	    my $tmp = new Math::BigInteger(1);
	    $tmp->lshift(new Math::BigInteger(1), $b);
	    $arg = $tmp + $arg;
	}

	$data = $arg->save;
	$len = CORE::length($data);

	my $c = ord(substr($data,0,1));

	if($c == 0) {
	    for( ; $len > 1 ; $len--, $offset++) {
		my $ch = ord(substr($data,$offset,1));
		if($ch & 0xff) {
		    if($ch & 0x80) {
			$len++;
			$offset--;
		    }
		    last;
		}
	    }
	}
	elsif($c == 0xff) {
	    for( ; $len > 1 ; $len--, $offset++) {
		my $ch = ord(substr($data,$offset,1));
		unless($ch == 0xff) {
		    unless($ch & 0x80) {
			$len++;
			$offset--;
		    }
		    last;
		}
	    }
	}
    }
    else {
	$len = 1;
	$data = CORE::pack("C",0);
    }

    Convert::BER::pack_length($ber,$len);
    $ber->[ Convert::BER::_BUFFER() ] .= substr($data,$offset);

    return 1;
}

sub unpack_biginteger {
    my($self,$ber,$arg) = @_;

    require Math::BigInteger;

    my $len = Convert::BER::unpack_length($ber);
    my $data = Convert::BER::unpack($ber,$len);
    my $int = restore Math::BigInteger $data;

    # restore has no concept of +/-
    if(ord(substr($data,0,1)) & 0x80) {
	my $tmp = new Math::BigInteger;
	$tmp->lshift(new Math::BigInteger(1), $len * 8);
	$tmp = new Math::BigInteger(0) - $tmp;
	$int = $tmp + $int;
    }
    $$arg = $int;

    return 1;
}

##
##
##

sub pack {
    my($self,$ber,$arg) = @_;

    if(ref $arg) {
	goto &pack_bigint
	    if UNIVERSAL::isa($arg,'Math::BigInt');

	goto &pack_biginteger
	    if UNIVERSAL::isa($arg,'Math::BigInteger');
    }

    my $neg = ($arg < 0) ? 1 : 0;

    my $len = Convert::BER::num_length($neg ? ~ $arg : $arg);

    my $msb = $arg & (0x80 << (($len - 1) * 8));

    $len++
	if(($msb && not($neg)) || ($neg && not($msb)));
    Convert::BER::pack_length($ber,$len);
    $ber->[ Convert::BER::_BUFFER() ] .= substr(CORE::pack("N",$arg), 0 - $len);

    1;
}

sub unpack {
    my($self,$ber,$arg) = @_;

    if( ref($arg) && ref($$arg) ) {
	goto &unpack_bigint
	    if UNIVERSAL::isa($$arg,'Math::BigInt');

	goto &unpack_biginteger
	    if UNIVERSAL::isa($$arg,'Math::BigInteger');
    }

    my $len = Convert::BER::unpack_length($ber);
    my $tmp = "\0" x (4 - $len) . Convert::BER::unpack($ber,$len);
    my $val = CORE::unpack("N",$tmp);

    $val -=  0x1 << ($len * 8)
	if($val & (0x1 << (($len * 8) - 1)));

    $$arg = $val;

    1;
}

##
##
##

package Convert::BER::NULL;

sub pack {
    my($self,$ber,$arg) = @_;

    Convert::BER::pack_length($ber,0);
}

sub unpack {
    my($self,$ber,$arg) = @_;

    Convert::BER::unpack_length($ber);

    $$arg = 1;
}

##
##
##

package Convert::BER::STRING;

sub pack {
    my($self,$ber,$arg) = @_;

    Convert::BER::pack_length($ber,CORE::length($arg));
    $ber->[ Convert::BER::_BUFFER() ] .= $arg;
}

sub unpack {
    my($self,$ber,$arg) = @_;

    my $len = Convert::BER::unpack_length($ber);
    $$arg = Convert::BER::unpack($ber,$len);

    1;
}

##
##
##

package Convert::BER::SEQUENCE;

sub pack {
    my($self,$ber,$arg) = @_;

    Convert::BER::pack_length($ber,CORE::length($arg->[ Convert::BER::_BUFFER() ]));
    $ber->[ Convert::BER::_BUFFER() ] .= $arg->[ Convert::BER::_BUFFER() ];

    1;
}

sub unpack {
    my($self,$ber,$arg) = @_;

    my $len = Convert::BER::unpack_length($ber);
    $$arg = $ber->new(Convert::BER::unpack($ber,$len));

    1;
}

sub pack_array {
    my($self,$ber,$arg) = @_;

    my $ber2 = $ber->new;

    return undef
	unless defined($ber2->_encode($arg));

    Convert::BER::pack_length($ber,CORE::length($ber2->[ Convert::BER::_BUFFER() ]));
    $ber->[ Convert::BER::_BUFFER() ] .= $ber2->[ Convert::BER::_BUFFER() ];

    1;
}

sub unpack_array {
    my($self,$ber,$arg) = @_;

    my $ber2;

    $self->unpack($ber,\$ber2);

    $ber2->_decode($arg);

    die "Sequence buffer not empty"
	if CORE::length($ber2->[ Convert::BER::_BUFFER() ]) != $ber2->[ Convert::BER::_POS() ];

    1;
}

##
##
##

package Convert::BER::OBJECT_ID;

sub pack {
    my($self,$ber,$arg) = @_;
    my @data = ($arg =~ /(\d+)/g);

    if(@data < 2) {
	@data = (0);
    }
    else {
	my $first = $data[1] + ($data[0] * 40);
	splice(@data,0,2,$first);
    }

    @data = map {
	my @d = ($_);
	if($_ >= 0x80) {
	    @d = ();
	    my $v = 0 | $_; # unsigned
	    while($v) {
		unshift(@d, 0x80 | ($v & 0x7f));
		$v >>= 7;
	    }
	    $d[-1] &= 0x7f;
	}
	@d;
    } @data;

    my $data = CORE::pack("C*", @data);

    Convert::BER::pack_length($ber,CORE::length($data));
    $ber->[ Convert::BER::_BUFFER() ] .=  $data;

    1;
}

sub unpack {
    my($self,$ber,$arg) = @_;

    my $len = Convert::BER::unpack_length($ber);
    my @ch = CORE::unpack("C*",Convert::BER::unpack($ber,$len));
    my @data = ();
    my $val = 0;
    while(@ch) {
	my $ch = shift @ch;
	$val = ($val << 7) | ($ch & 0x7f);
	unless($ch & 0x80) {
	    push @data, $val;
	    $val = 0;
	}
    }
    if(@data) {
	my $first = shift @data;
	unshift @data, $first % 40;
	unshift @data, int($first / 40);
#	unshift @data, "";
    }
    $$arg = join(".",@data);
    1;
}

##
##
##

package Convert::BER::CONSTRUCTED;

BEGIN {
    # Cannot call import here as Convert::BER has not been initialized
    *BER_CONSTRUCTOR = *Convert::BER::BER_CONSTRUCTOR
}

sub pack {
    my($self,$ber,$arg) = @_;

    Convert::BER::pack_tag($ber,$arg->tag | BER_CONSTRUCTOR);
    Convert::BER::pack_length($ber,CORE::length($arg->[ Convert::BER::_BUFFER() ]));
    $ber->[ Convert::BER::_BUFFER() ] .= $arg->[ Convert::BER::_BUFFER() ];

    1;
}

sub unpack {
    my($self,$ber,$arg) = @_;
    my $tag = Convert::BER::unpack_tag($ber);

    die "Not constructed"
	unless $tag & BER_CONSTRUCTOR;

    my $len = Convert::BER::unpack_length($ber);
    my $buf = $ber->new( Convert::BER::unpack($ber,$len));

    die &{$ber}(0,"Bad construction")
	unless( ($buf->tag | BER_CONSTRUCTOR) == $tag);

    $$arg = $buf;

    1;
}

sub pack_array {
    my($self,$ber,$arg) = @_;

    $self->_encode($arg);
}

sub unpack_array {
    my($self,$ber,$arg) = @_;

    my $ber2;

    $self->unpack($ber,\$ber2);

    $ber2->_decode($arg);
}

##
##
##

package Convert::BER::OPTIONAL;

# optional elements
# allows skipping in the encode if it comes across structures like
#   OPTIONAL => [ BOOLEAN => undef ]
# or more realistically 
#   my $foo = undef;
#   $foo = 1 if (arg->{'allowed'};
#   $ber->encode(SEQUENCE => [
#                    STRING => $name,
#                    OPTIONAL => [ BOOLEAN => $foo ]
#                 ]);

sub pack_array {
    my($self,$ber,$arg) = @_;
    my $a;
    my @newarg;
    foreach $a (@$arg) {
        return unless defined $a;
        my $c = ref($a) eq "CODE"
                        ? &{$a}(@{$ber->[ Convert::BER::_INDEX() ]})
                        : $a;
        return unless defined $c;
        push @newarg, $c;
    }

    shift @newarg if (@newarg & 1);

    Convert::BER::_encode($ber,\@newarg);
}

sub unpack_array {
    my($self,$ber,$arg) = @_;
    my($yes,$ref);
    my $pos = $ber->[ Convert::BER::_POS() ];

    if(@$arg & 1) {
	$ref = [ @$arg ];
	$yes = shift @$ref;
    }
    else {
        $ref = $arg;
    }

    if (eval { Convert::BER::_decode($ber,$ref) }) {
	$$yes = 1 if ref($yes);
    }
    else {
	$$yes = undef if ref($yes);
	$ber->[ Convert::BER::_POS() ] = $pos;
    }

    1;
}

##
##
##

package Convert::BER::SEQUENCE_OF;

sub pack_array {
    my($self,$ber,$arg) = @_;
    my($n,@desc) = @$arg;
    my $i;

    $n = &{$n}(@{$ber->[ Convert::BER::_INDEX() ]})
	if ref($n) eq 'CODE';

    push(@{$ber->[ Convert::BER::_INDEX() ]},0);

    my $b = $ber->new;

    if(ref($n) eq 'HASH') {
	my $v;
	foreach $v (keys %$n) {
	    $ber->[ Convert::BER::_INDEX() ][-1] = $v;
	    $b->_encode(\@desc);
	}
    }
    elsif(ref($n) eq 'ARRAY') {
	my $v;
	foreach $v (@$n) {
	    $ber->[ Convert::BER::_INDEX() ][-1] = $v;
	    $b->_encode(\@desc);
	}
    }
    else {
	while($n--) {
	    $b->_encode(\@desc);
	    $ber->[ Convert::BER::_INDEX() ][-1] += 1;
	}
    }

    pop @{$ber->[ Convert::BER::_INDEX() ]};

    Convert::BER::pack_length($ber,CORE::length($b->[ Convert::BER::_BUFFER() ]));
    $ber->[ Convert::BER::_BUFFER() ] .= $b->[ Convert::BER::_BUFFER() ];

    1;
}

sub unpack_array {
    my($self,$ber,$arg) = @_;
    my($nref,@desc) = @$arg;

    push(@{$ber->[ Convert::BER::_INDEX() ]},0);

    my $len = Convert::BER::unpack_length($ber);
    my $b   = $ber->new(Convert::BER::unpack($ber,$len));
    my $pos = $ber->[ Convert::BER::_POS() ];
    my $n;

    while(CORE::length($b->[ Convert::BER::_BUFFER() ]) > $b->[ Convert::BER::_POS() ]) {
	$b->_decode(\@desc);
	$ber->[ Convert::BER::_INDEX() ][-1] += 1;
    }

    $$nref = pop @{$ber->[ Convert::BER::_INDEX() ]};
    1;
}

##
##
##

package Convert::BER::BIT_STRING;

sub pack {
    my($self,$ber,$arg) = @_;

    my $less = (8 - (CORE::length($arg) & 7)) & 7;
    $arg .= "0" x $less if $less;
    my $data = CORE::pack("B*",$arg);
    Convert::BER::pack_length($ber,CORE::length($data)+1);
    $ber->[ Convert::BER::_BUFFER() ] .= chr($less) . $data;
}

sub unpack {
    my($self,$ber,$arg) = @_;

    my $len  = Convert::BER::unpack_length($ber);
    my $data = Convert::BER::unpack($ber,$len);
    my $less;
    ($less,$data) = CORE::unpack("C B*",$data,);
    $less = ord($less) & 7;
    substr($data,-$less) = '' if $less;
    $$arg = $data;
    1;
}

##
##
##

package Convert::BER::BIT_STRING8;

sub pack {
    my($self,$ber,$arg) = @_;

    Convert::BER::pack_length($ber,CORE::length($arg)+1);
    $ber->[ Convert::BER::_BUFFER() ] .= chr(0) . $arg;
}

sub unpack {
    my($self,$ber,$arg) = @_;

    my $len  = Convert::BER::unpack_length($ber);
    my $less = Convert::BER::unpack($ber,1);
    my $data = $len > 1 ? Convert::BER::unpack($ber,$len-1) : "";
    $$arg = $data;
    1;
}

##
##
##

package Convert::BER::REAL;

sub pack {
  my($self,$ber,$arg) = @_;
  require POSIX;
  my $data = "";

  if($arg) {
    my $s = 128;
    if($arg < 0) {
      $s |= 64;
      $arg = -$arg;
    }
    my @e = ();
    my @m = ();
    my($v,$e) = POSIX::frexp($arg);
    $e -= 53;
    my $ae = abs($e);

    if($ae < 0x80) {
      @e = ($e & 0xff);
    }
    elsif($ae < 0x8000) {
      @e = map { $_ & 0xff } ($e>>8,$e);
      $s |= 1;
    }
    elsif($ae < 0x800000) {
      @e = map { $_ & 0xff } ($e>>16,$e>>8,$e);
      $s |= 2;
    }
    else {
      @e = (4, map { $_ & 0xff } ($e>>24,$e>>16,$e>>8,$e));
      $s |= 3;
    }

    $v = POSIX::ldexp($v,5);
    my $f = POSIX::floor($v);
    my $i = int($f);
    @m = ($i & 0xff);
    $v -= $f;
    for (1..2) {
      $v = POSIX::ldexp($v,24);
      $f = POSIX::floor($v);
      $i = int($f);
      push @m, ($i >> 16) & 0xff, ($i >> 8) & 0xff, $i & 0xff;
      $v -= $f;
    }
    $data = pack("C*",$s,@e,@m);
  }
  my $len = length($data);
  Convert::BER::pack_length($ber,$len);
  Convert::BER::pack($ber,$data) if $len;
}

my @base = (1,3,4,4);

sub unpack {
  my($self,$ber,$arg) = @_;

  my $len = Convert::BER::unpack_length($ber);
  unless($len) {
    $$arg = undef;
    return 1;
  }
  my $data = Convert::BER::unpack($ber,$len);
  my $byte = unpack("C*",$data);

  if($byte & 0x80) {
    $data = reverse $data;
    chop($data);
    require POSIX; # The sins for using REAL
    my $base = $base[($byte & 0x30) >> 4];
    my $scale = $base & 0xC;
    my $elen = $byte & 0x3;
 
    $elen = ord(chop($data)) - 1 if $elen == 3;

    die "Bad REAL encoding" unless $elen >= 0 && $elen <= 3;

    my $exp = ord chop($data);
    $exp = -256 + $exp if $exp > 127;

    while ($elen--) {
      $exp *= 256;
      $exp += ord chop($data);
    }

    $exp = $exp * $base + $scale;

    my $v = 0;
    while(length($data)) {
      $v = POSIX::ldexp($v,8) + ord chop($data);
    }

    $v = POSIX::ldexp($v,$exp) if $exp;
    $v = -1 * $v if $byte & 0x40; # negative

    $$arg = $v;
  }
  elsif($byte & 0x40) {
    require POSIX;
    $$arg = POSIX::HUGE_VAL() * (($byte & 1) ? -1 : 1);
  }
  elsif(substr($data,1) =~ /^\s*([-+]?)0*(\d+(?:\.\d+(?:[Ee][-+]?\d+)?)?)\s*$/) {
    $$arg = eval "$1$2";
  }
  else {
    $$arg = undef;
  }
  1;
}

##
##
##

package Convert::BER::_Time_generic;

sub pack {
    my($self,$ber,$arg) = @_;

    my $islocal = $self->isa('Convert::BER::TimeUL')
		|| $self->isa('Convert::BER::TimeGL');
    my $isgen = $self->isa('Convert::BER::TimeGL')
		|| $self->isa('Convert::BER::TimeGZ');
    my @time = $islocal ? localtime($arg) : gmtime($arg);
    my $off = 'Z';

    if($islocal) {
      my @g = gmtime($arg);
      my $v = ($time[1] - $g[1]) + ($time[2] - $g[2]) * 60;
      my $d = $time[7] - $g[7];
      if($d == 1 || $d < -1) {
	$v += 1440;
      }
      elsif($d > 1) {
	$v -= 1440;
      }
      $off = sprintf("%+03d%02d",$v / 60, abs($v % 60));
    }
    
    $time[4] += 1;
    $time[5] = $isgen ? $time[5] + 1900 : $time[5] % 100;
    my $str = sprintf("%02d"x6, @time[5,4,3,2,1,0]);
    if($isgen) {
      my $split = $arg - int($arg);
      $str .= sprintf(".%03d", int($split * 1000)) if($split);
    }
    Convert::BER::STRING::pack($self,$ber,$str . $off);
}

sub unpack {
    my($self,$ber,$arg) = @_;
    my $str;
    if(Convert::BER::STRING::unpack($self,$ber,\$str)) {
      my $isgen = $self->isa('Convert::BER::TimeGL')
		|| $self->isa('Convert::BER::TimeGZ');
      my $n = $isgen ? 4 : 2;
      my ($Y,$M,$D,$h,$m,$s,$z) = $str =~ /^
        (\d{$n})
	(\d\d)
	(\d\d)
	(\d\d)
	(\d\d)
	((?:\d\d(?:\.\d+)?)?)
	(Z|[-+]\d{4})
      $/x or die "Bad Time string '$str'";
      my $offset = 0;
      if($z ne 'Z') {
        use integer;
	$offset = ((($z / 100) * 60) + ($z % 100)) * 60;
      }
      if($s > int($s)) { # fraction of a seccond
        $offset -= ($s - int($s));
      }
      $M -= 1;
      if($isgen) {	# GeneralizedTime uses 4-digit years
	$Y -= 1900;
      }
      elsif($Y <= 50) {	# ASN.1 UTCTime
	$Y += 100;	# specifies <=50 = 2000..2050, >50 = 1951..1999
      }
      require Time::Local;
      $$arg = Time::Local::timegm(int($s),$m,$h,$D,$M,$Y) - $offset;
    }
}

package Convert::BER::CHOICE;

sub pack_array {
    my($self,$ber,$arg) = @_;
    my $n = $arg->[0];

    if(defined($n)) {
	my $i = ($n * 2) + 2;
	die "Bad CHOICE index $n" if $n < 0 || $i > @$arg;
	$ber->_encode([$arg->[$i-1], $arg->[$i]]);
    }
    1;
}

sub unpack_array {
    my($self,$ber,$arg) = @_;
    my($i,$m,$err);

    $m = @$arg;
    my $want = Convert::BER::tag($ber);

    for($i = 1 ; $i < $m ; $i += 2) {
      my $tag;
      my $type = $arg->[$i];

      ($type,$tag) = @$type
	  if(ref($type) eq 'ARRAY');

      my $can = UNIVERSAL::can($ber,'_' . $type);

      die "Unknown element '$type'"
	  unless $can;

      my $data = &$can();

      $tag = $data->[ Convert::BER::_TAG() ]
	  unless defined $tag;

      next unless $tag == $want;
      
      if ( eval { Convert::BER::_decode($ber,[@{$arg}[$i,$i+1]]) }) {
	my $choice = $arg->[0];
	$$choice = ($i - 1) >> 1;
	return 1;
      }
      $err = $@ if $@;
    }
    die ($err || sprintf("Cannot decode CHOICE, found tag 0x%X\n",$want));
}

1;
