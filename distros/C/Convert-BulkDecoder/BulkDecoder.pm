package Convert::BulkDecoder;

# Convert::BulkDecoder - Extract binary data from mail and news messages
# RCS Info        : $Id: BulkDecoder.pm,v 1.12 2005-06-19 17:35:38+02 jv Exp $
# Author          : Johan Vromans
# Created On      : Wed Jan 29 16:59:58 2003
# Last Modified By: Johan Vromans
# Last Modified On: Sun Jun 19 17:34:31 2005
# Update Count    : 88
# Status          : Unknown, Use with caution!

$VERSION = "1.03";

use strict;
use integer;

sub new {
    my ($pkg, %atts) = @_;
    $pkg = ref $pkg if ref $pkg;

    my $self = bless {
        # Set explicit defaults.
	tmpdir   => "/var/tmp",
	destdir  => "",
        force    => 0,
	verbose  => 1,
	crc      => 1,
	md5      => 1,
	debug    => 0,
	neat     => \&_neat,
    }, $pkg;

    # Copy constructor attributes.
    foreach ( keys(%$self) ) {
	if ( defined($atts{$_}) ) {
	    $self->{$_} = delete($atts{$_});
	}
    }

    # Bail of if any remain.
    my $err = "";
    foreach my $k ( sort keys %atts ) {
	$err .= $pkg . ": invalid constructor attribute: $k\n";
    }
    die($err) if $err;

    # Polish.
    foreach ( $self->{destdir}, $self->{tmpdir} ) {
	next unless $_;
	$_ .= "/";
	s;/+$;/;;
    }

    if ( $self->{md5} ) {
	require Digest::MD5;
	$self->{_md5} = Digest::MD5->new;
    }

    $self;
}

sub decode {

    my ($self, $a) = @_;

    # Try uudecode, or find out better.
    my $ret = $self->uudecode($a);

    # MIME.
    $ret = $self->mimedecode($a) if $ret eq 'M';

    # yEnc.
    $ret = $self->ydecode($a) if $ret =~ /^Y/;

    # UNSUPPORTED -- FOR TESTING ONLY!
    # $ret = $self->ydecode_ydecode($a, $1) if $ret =~ /^Y(.*)/;

    $ret;
}

sub uudecode {
    my ($self, $a) = @_;

    my $doing = 0;
    my $size = 0;
    my $name;
    $self->{result} = "EMPTY";

    # Process the message lines.
    foreach ( @$a ) {
	if ( $doing ) {		# uudecoding...
	    if ( /^end/ ) {
		close(OUT);
		$self->{md5} = $self->{_md5}->b64digest if $self->{md5};
		$self->{size} = $size;
		$doing = 2;	# done
		$self->{result} = "OK";
		last;
	    }
	    # Select lines to process.
	    next if /[a-z]/;
	    next unless int((((ord() - 32) & 077) + 2) / 3)
	      == int(length() / 4);
	    # Decode.
	    my $t = unpack("u",$_);
	    print OUT $t or die("print(".$self->{file}."): $!\n");
	    $size += length($t);
	    $self->{_md5}->add($t) if $self->{md5};
	    next;
	}

	# Check for MIME.
	if ( m;^content-type:.*(image/|multipart);i ) {
	    return 'M';		# MIME
	}

	if ( m/^=ybegin\s+.*\s+name=(.+)/i ) {
	    return "Y$1";	# yEnc
	}

	# Otherwise, search for the uudecode 'begin' line.
	if ( /^begin\s+\d+\s+(.+)$/ ) {
	    $name = $self->{neat}->($1);
	    $self->{type} = "U";
	    $self->{name} = $name;
	    $self->{file} = $self->{destdir} . $name;
	    $doing = 2;		# Done
	    warn("Decoding(UU) to ", $self->{file}, "\n")
	      if $self->{verbose};
	    # Skip duplicates.
	    # Note that testing for -s fails if it is a
	    # notexisting symlink.
	    if ( (-l $self->{file} || -s _ ) && !$self->{force} ) {
		$self->{size} = -s _;
		$self->{result} = "DUP";
		last;
	    }

	    open (OUT, ">".$self->{file})
	      or die("create(".$self->{file}."): $!\n");
	    binmode(OUT);
	    $doing = 1;		# Doing
	    $self->{result} = "FAIL";
	    next;
	}
    }
    push(@{$self->{parts}},
	 { type   => $self->{type},
	   size   => $self->{size},
	   md5    => $self->{md5},
	   result => $self->{result},
	   name   => $self->{name},
	   file   => $self->{file} });
    return $self->{result};
}

my @crctab;

sub ydecode {
    my ($self, $a) = @_;
    $self->{type} = "Y";
    $self->{result} = "EMPTY";

    _fill_crctab() unless @crctab || !$self->{crc};

    my @lines = @$a;

    my ($ydec_part, $ydec_line, $ydec_size, $ydec_name, $ydec_pcrc,
	$ydec_begin, $ydec_end);
    my $pcrc;

    while ( $_ = shift(@lines) ) {
	# Newlines a fakes and should not be decoded.
	chomp;
	s/\r//g;
	# If we've started decoding $ydec_name will be set.
	if ( !$ydec_name  ) {
	    # Skip until beginning of yDecoded part.
	    next unless /^=ybegin/;
	    if ( / part=(\d+)/ ) {
		$ydec_part = $1;
	    }

	    if ( / size=(\d+)/ ) {
		$self->{size} = $ydec_size = $1;
	    }
	    else {
		die("Mandatory field 'size' missing\n");
	    }
	    if ( / line=(\d+)/ ) {
		$ydec_line = $1;
	    }
	    if( / name=(.*)$/ ) {
		$ydec_name = $self->{neat}->($1);
		$self->{file} = $self->{destdir} . $ydec_name;
		$self->{name} = $ydec_name;
		if ( !defined($ydec_part) || $ydec_part == 1 ) {
		    warn("Decoding(yEnc) to ", $self->{file}, "\n")
		      if $self->{verbose};
		    if ( -s $self->{file} ) {
			if ( $self->{force} ) {
			    unlink($self->{file});
			}
			else {
			    $self->{size} = -s _;
			    $self->{result} = "DUP";
			    last;
			}
		    }
		}
	    }
	    else {
		die("Unknown attach name\n");
	    }

	    # Multipart messages contain more information on.
	    # the second line.
	    if ( $ydec_part ) {
		$_ = shift(@lines);
		chomp;
		s/\r//g;
		if ( /^=ypart/ ) {
		    if ( / begin=(\d+)/ ) {
			# We need this to check if the size of this message
			# is correct.
			$ydec_begin = $1;
			$pcrc = 0xffffffff;
			undef $ydec_pcrc;
		    }
		    else {
			warn("No begin field found in part, ignoring\n");
			undef $ydec_part;
		    }
		    if ( / end=(\d+)/ ) {
			# We need this to calculate the size of this message.
			$ydec_end = $1;
		    }
		    else {
			warn("No end field found in part, ignoring");
			undef $ydec_part;
		    }
		}
		else {
		    warn("Article described as multipart message, however ".
			 "it doesn't seem that way\n");
		    undef $ydec_part;
		}
	    }
	    else {
		$pcrc = 0xffffffff;
	    }

	    # If the $ydec_part is different from 1
	    # we need to open the file for appending.
	    if ( -e $self->{file} ) {
		if ( defined($ydec_part) && $ydec_part != 1 ) {
		    # If we have a multipart message, the file exists
		    # and we are not at the first part, we should just
		    # open the file as an append. We assume that this is
		    # the multipart we were already processing.
		    #print "Opening $ydec_name for appending\n";
		    if ( !open(OUT, ">>".$self->{file}) ) {
			die("Couldn't open ".$self->{file}.
			    " for appending: $!\n");
		    }
		}
		elsif ( !open(OUT, ">".$self->{file}) ) {
		    die("Couldn't create ".$self->{file}.": $!\n");
		}
	    }
	    else {
		# File doesn't exist. We open it for writing O' so plain.
		if ( defined($ydec_part) && $ydec_part != 1 ) {
		    die("Missing  ".$self->{file}. " for appending: $!\n");
		}
		if ( !open(OUT, ">".$self->{file}) ) {
		    die("Couldn't create ".$self->{file}.": $!\n");
		}
		$self->{result} = "FAIL";
	    }
	    # Cancel any file translations.
	    binmode(OUT);
	    # Excellent.. We have determed all the info for this file we
	    # need.. Skip till next line, this should contain the real
	    # data.
	    next;
	}

	# Looking for the end tag.
	if ( /^=yend/ ) {
	    # We are done.. Check the sanity of article.
	    # and unset $ydec_name in case that there are more
	    # ydecoded files in the same article.
	    $self->{result} = "OK";
	    if ( / part=(\d+)/ ) {
		if ( $ydec_part != $1 ) {
		    die("Part number '$1' different from beginning part '$ydec_part'\n");
		}
	    }
	    if ( / size=(\d+)/ ) {
		# Check size, but first calculate it.
		my $size;
		if ( defined($ydec_part) ) {
		    $size = ($ydec_end - $ydec_begin + 1);
		}
		else {
		    $size = $ydec_size;
		}
		if ( $1 != $size ) {
		    die("Size '$1' different from beginning size '$size'\n");
		}
	    }
	    if ( / pcrc32=([0-9a-f]+)/i && @crctab ) {
		if ( defined($ydec_pcrc) && ($ydec_pcrc != $1) ) {
		    die("CRC '$1' different from beginning CRC '$ydec_pcrc'\n");
		}
		$ydec_pcrc = hex($1);
		$pcrc = $pcrc ^ 0xffffffff;
		if ( $pcrc == $ydec_pcrc ) {
		    warn("Part $ydec_part, checksum OK\n")
		      if $self->{verbose};
		}
		else {
		    warn(sprintf("Part $ydec_part, checksum mismatch, ".
				 "got 0x%08x, expected 0x%08x\n",
				 $pcrc, $ydec_pcrc));
		}

	    }
	    if ( !defined($ydec_part) && / crc32=([0-9a-f]+)/i && @crctab ) {
		$ydec_pcrc = hex($1);
		$pcrc = $pcrc ^ 0xffffffff;
		if ( $pcrc == $ydec_pcrc ) {
		    warn("Checksum OK\n")
		      if $self->{verbose};
		}
		else {
		    warn(sprintf("Checksum mismatch, ".
				 "got 0x%08x, expected 0x%08x\n",
				 $pcrc, $ydec_pcrc));
		}

	    }
	    undef $ydec_name;
	    # Dont encode the endline, we skip to the next line
	    # in search for any more parts.
	    next;
	}

	# If we got here, we are within an encoded article, an
	# we will take meassures to decode it.
	# We decode line by line.

	# Decoder by jvromans@squirrel.nl.
	s/=(.)/chr(ord($1)+(256-64) & 255)/ge;
	tr{\000-\377}{\326-\377\000-\325};

	my $data = $_;
	# CRC check code by jvromans@squirrel.nl.
	if ( @crctab ) {
	    foreach ( split(//, $data) ) {
		$pcrc = $crctab[($pcrc^ord($_))&0xff] ^ (($pcrc >> 8) & 0x00ffffff);
	    }
	}

	print OUT $data;
	$self->{_md5}->add($data) if $self->{md5};
    }

    close(OUT);
    $self->{md5} = $self->{_md5}->b64digest if $self->{md5};
    push(@{$self->{parts}},
	 { type   => $self->{type},
	   size   => $self->{size},
	   md5    => $self->{md5},
	   result => $self->{result},
	   name   => $self->{name},
	   file   => $self->{file} });
    return $self->{result};
}

sub _fill_crctab {
    @crctab = 
      ( 0x00000000, 0x77073096, 0xee0e612c, 0x990951ba, 0x076dc419, 0x706af48f,
	0xe963a535, 0x9e6495a3, 0x0edb8832, 0x79dcb8a4, 0xe0d5e91e, 0x97d2d988,
	0x09b64c2b, 0x7eb17cbd, 0xe7b82d07, 0x90bf1d91, 0x1db71064, 0x6ab020f2,
	0xf3b97148, 0x84be41de, 0x1adad47d, 0x6ddde4eb, 0xf4d4b551, 0x83d385c7,
	0x136c9856, 0x646ba8c0, 0xfd62f97a, 0x8a65c9ec, 0x14015c4f, 0x63066cd9,
	0xfa0f3d63, 0x8d080df5, 0x3b6e20c8, 0x4c69105e, 0xd56041e4, 0xa2677172,
	0x3c03e4d1, 0x4b04d447, 0xd20d85fd, 0xa50ab56b, 0x35b5a8fa, 0x42b2986c,
	0xdbbbc9d6, 0xacbcf940, 0x32d86ce3, 0x45df5c75, 0xdcd60dcf, 0xabd13d59,
	0x26d930ac, 0x51de003a, 0xc8d75180, 0xbfd06116, 0x21b4f4b5, 0x56b3c423,
	0xcfba9599, 0xb8bda50f, 0x2802b89e, 0x5f058808, 0xc60cd9b2, 0xb10be924,
	0x2f6f7c87, 0x58684c11, 0xc1611dab, 0xb6662d3d, 0x76dc4190, 0x01db7106,
	0x98d220bc, 0xefd5102a, 0x71b18589, 0x06b6b51f, 0x9fbfe4a5, 0xe8b8d433,
	0x7807c9a2, 0x0f00f934, 0x9609a88e, 0xe10e9818, 0x7f6a0dbb, 0x086d3d2d,
	0x91646c97, 0xe6635c01, 0x6b6b51f4, 0x1c6c6162, 0x856530d8, 0xf262004e,
	0x6c0695ed, 0x1b01a57b, 0x8208f4c1, 0xf50fc457, 0x65b0d9c6, 0x12b7e950,
	0x8bbeb8ea, 0xfcb9887c, 0x62dd1ddf, 0x15da2d49, 0x8cd37cf3, 0xfbd44c65,
	0x4db26158, 0x3ab551ce, 0xa3bc0074, 0xd4bb30e2, 0x4adfa541, 0x3dd895d7,
	0xa4d1c46d, 0xd3d6f4fb, 0x4369e96a, 0x346ed9fc, 0xad678846, 0xda60b8d0,
	0x44042d73, 0x33031de5, 0xaa0a4c5f, 0xdd0d7cc9, 0x5005713c, 0x270241aa,
	0xbe0b1010, 0xc90c2086, 0x5768b525, 0x206f85b3, 0xb966d409, 0xce61e49f,
	0x5edef90e, 0x29d9c998, 0xb0d09822, 0xc7d7a8b4, 0x59b33d17, 0x2eb40d81,
	0xb7bd5c3b, 0xc0ba6cad, 0xedb88320, 0x9abfb3b6, 0x03b6e20c, 0x74b1d29a,
	0xead54739, 0x9dd277af, 0x04db2615, 0x73dc1683, 0xe3630b12, 0x94643b84,
	0x0d6d6a3e, 0x7a6a5aa8, 0xe40ecf0b, 0x9309ff9d, 0x0a00ae27, 0x7d079eb1,
	0xf00f9344, 0x8708a3d2, 0x1e01f268, 0x6906c2fe, 0xf762575d, 0x806567cb,
	0x196c3671, 0x6e6b06e7, 0xfed41b76, 0x89d32be0, 0x10da7a5a, 0x67dd4acc,
	0xf9b9df6f, 0x8ebeeff9, 0x17b7be43, 0x60b08ed5, 0xd6d6a3e8, 0xa1d1937e,
	0x38d8c2c4, 0x4fdff252, 0xd1bb67f1, 0xa6bc5767, 0x3fb506dd, 0x48b2364b,
	0xd80d2bda, 0xaf0a1b4c, 0x36034af6, 0x41047a60, 0xdf60efc3, 0xa867df55,
	0x316e8eef, 0x4669be79, 0xcb61b38c, 0xbc66831a, 0x256fd2a0, 0x5268e236,
	0xcc0c7795, 0xbb0b4703, 0x220216b9, 0x5505262f, 0xc5ba3bbe, 0xb2bd0b28,
	0x2bb45a92, 0x5cb36a04, 0xc2d7ffa7, 0xb5d0cf31, 0x2cd99e8b, 0x5bdeae1d,
	0x9b64c2b0, 0xec63f226, 0x756aa39c, 0x026d930a, 0x9c0906a9, 0xeb0e363f,
	0x72076785, 0x05005713, 0x95bf4a82, 0xe2b87a14, 0x7bb12bae, 0x0cb61b38,
	0x92d28e9b, 0xe5d5be0d, 0x7cdcefb7, 0x0bdbdf21, 0x86d3d2d4, 0xf1d4e242,
	0x68ddb3f8, 0x1fda836e, 0x81be16cd, 0xf6b9265b, 0x6fb077e1, 0x18b74777,
	0x88085ae6, 0xff0f6a70, 0x66063bca, 0x11010b5c, 0x8f659eff, 0xf862ae69,
	0x616bffd3, 0x166ccf45, 0xa00ae278, 0xd70dd2ee, 0x4e048354, 0x3903b3c2,
	0xa7672661, 0xd06016f7, 0x4969474d, 0x3e6e77db, 0xaed16a4a, 0xd9d65adc,
	0x40df0b66, 0x37d83bf0, 0xa9bcae53, 0xdebb9ec5, 0x47b2cf7f, 0x30b5ffe9,
	0xbdbdf21c, 0xcabac28a, 0x53b39330, 0x24b4a3a6, 0xbad03605, 0xcdd70693,
	0x54de5729, 0x23d967bf, 0xb3667a2e, 0xc4614ab8, 0x5d681b02, 0x2a6f2b94,
	0xb40bbe37, 0xc30c8ea1, 0x5a05df1b, 0x2d02ef8d,
      );
}

sub ydecode_ydecode {
    my ($self, $a, $name) = @_;
    my $tmp = $self->{tmpdir} . "mfetch.$$.";

    $self->{type} = "Y";
    if ( $name ) {
	$self->{file} = $self->{destdir} . $name;
	warn("Decoding(ydecode) to ", $self->{file}, "\n")
	  if $self->{verbose};
	if ( -s $self->{file} ) {
	    if ( $self->{force} ) {
		unlink($self->{file});
	    }
	    else {
		$self->{size} = -s _;
		$self->{result} = "DUP";
		goto QXIT;
	    }
	}
    }

    my @files;
    my $copy = 0;
    my $part;
    foreach ( @$a ) {
	if ( $copy && /^=yend/ ) {
	    print TMP $_;
	    close(TMP);
	    $copy = 0;
	    next;
	}
	if ( !$copy && /^=ybegin.*\s+part=(\d+)/ ) {
	    my $file = sprintf("$tmp%03d", $part = $1);
	    $files[$1-1] = $file;
	    $copy = $1 if /\s+line=(\d+)/;
	    $self->{size} = $1 if /\s+size=(\d+)/;
	    $self->{name} = $1 if /\s+name=(.+)/;
	    $self->{file} = $self->{destdir} . $self->{name};
	    if ( -s $self->{file} ) {
		if ( $self->{force} ) {
		    unlink($self->{file});
		}
		else {
		    $self->{size} = -s _;
		    $self->{result} = "DUP";
		    goto QXIT;
		}
	    }
	    open(TMP, ">$file") || die("$file: $!\n");
	    binmode(TMP);
	    $copy++;
	}
	if ( $copy > 1 ) {	# check length
	    # If it starts with an unescaped period, the line will be
	    # one too short. Add the period since ydecode requires it.
	    if ( /^\./ && length($_) == $copy ) {
		$_ = ".$_";
	    }
	}
	print TMP $_ if $copy;
    }

    system("ydecode", "-k",
	   $self->{destdir} ? "--output=".$self->{destdir} : (),
	   @files);

    $self->{result} = "FAIL";
    if ( -s $self->{file} == $self->{size} ) {
	unlink(@files);
	if ( $self->{md5} ) {
	    open(F, $self->{file})
	      or die($self->{file} . " (reopen) $!\n");
	    binmode(F);
	    local($/) = undef;
	    $self->{_md5}->add(<F>);
	    close(F);
	    $self->{md5} = $self->{_md5}->b64digest;
	}
	$self->{result} = "OK";
    }
QXIT:
    push(@{$self->{parts}},
	 { type   => $self->{type},
	   size   => $self->{size},
	   md5    => $self->{md5},
	   result => $self->{result},
	   name   => $self->{name},
	   file   => $self->{file} });
    return $self->{result};
}

sub mimedecode {
    my ($self, $a) = @_;

    require MIME::Parser;

    $self->{type} = "M";
    my $parser = new MIME::Parser;
    # Store everything in memory.
    $parser->output_to_core(1);
    my $e = $parser->parse_data($a);

    unless ( defined $e->{ME_Parts} &&  @{$e->{ME_Parts}} ) {
	$e->{ME_Parts} = [ $e ];
    }

    foreach my $part ( @{$e->{ME_Parts}} ) {
	my $name;
	foreach ( 'Content-Type', 'Content-Disposition' ) {

	    my $ct = $part->{mail_inet_head}->{mail_hdr_hash}->{$_};
	    next unless defined $ct && defined ($ct = ${$ct->[0]});
	    if ( $ct =~ m{((file)?name)="([^"]+)"}i ) {
		$name = $self->{name} = $self->{neat}->($3);
		$self->{file} = $self->{destdir} . $name;
		warn("Decoding(MIME) to ", $self->{file}, "\n")
		  if $self->{verbose};
		if ( -s $self->{file} && !$self->{force} ) {
		    $self->{size} = -s _;
		    $self->{result} = "DUP";
		    push(@{$self->{parts}},
			 { type   => $self->{type},
			   size   => $self->{size},
			   result => $self->{result},
			   name   => $self->{name},
			   file   => $self->{file} });
		    next;
		}
	    }
	}

	# Skip body.
	next unless $name;
	next if $name eq $self->{destdir}."body";

	# Skip duplicates.
	if ( -s $name && !$self->{force} ) {
	    $self->{size} = -s _;
	    $self->{result} = "DUP";
	    push(@{$self->{parts}},
		 { type   => $self->{type},
		   size   => $self->{size},
		   result => $self->{result},
		   name   => $self->{name},
		   file   => $self->{file} });
	    next;
	}

	# Store it.
	my $bh = $part->{ME_Bodyhandle};
	if ( $bh && defined $bh->{MBC_Data} && open (OUT, ">".$self->{file}) ) {
	    binmode(OUT);
	    my $size = 0;
	    foreach ( @{$bh->{MBC_Data}} ) {
		print OUT $_;
		$self->{_md5}->add($_) if $self->{md5};
		$size += length($_);
	    }
	    close (OUT);
	    $self->{md5} = $self->{_md5}->b64digest if $self->{md5};
	    $self->{size} = $size;
	    $self->{result} = "OK";
	    push(@{$self->{parts}},
		 { type   => $self->{type},
		   size   => $self->{size},
		   md5    => $self->{md5},
		   result => $self->{result},
		   name   => $self->{name},
		   file   => $self->{file} });
	}
	else {
	    $self->{result} = "FAIL";
	    push(@{$self->{parts}},
		 { type   => $self->{type},
		   result => $self->{result},
		   name   => $self->{name},
		   file   => $self->{file} });
	}
    }

    # Return values for the first file.
    while ( my($k,$v) = each(%{$self->{parts}->[0]}) ) {
	$self->{$k} = $v;
    }
    return $self->{result};

}

sub _neat {
    local ($_) = @_;
    s/^\[a-z]://i;
    s/^.*?([^\\]+$)/$1/;
    # Spaces and unprintables to _.
    s/\s+/_/g;
    s/\.\.+/./g;
    s/[\0-\040'`"\177-\240\/]/_/g;
    # Remove leading dots.
    s/^\.+//;
    $_;
}

1;

__END__

=head1 NAME

Convert::BulkDecoder - Extract (binary) data from mail and news messages

=head1 SYNOPSIS

  use Convert::BulkDecoder;
  my $cvt = new Convert::BulkDecoder::;
  # Collect the articles into an array ref.
  my $art = [<>];
  # Decode.
  my $res =  $cvt->decode($art);
  die("Failed!") unless $res eq "OK";
  print "Extracted ", $cvt->{size}, " bytes to file ", $cvt->{file}, "\n";

=head1 DESCRIPTION

Convert::BulkDecoder can be used to decode binary contents as included
in email and news articles. It supports UUdecoding, ydecoding and MIME
attachments. The contents may be split over multiple articles (files),
but must be supplied to the decode() function in one bulk.

For yencoded contents, it is possible to verify file consistency using
length and checksum tests.

=head1 CONSTRUCTOR ARGUMENTS

=over

=item crc

When non-zero (default), the CRC of the data is verified, if possible.

=item md5

Return a base64 encoded MD5 checksum of the data.

=item force

When non-zero, disables duplicate detection.

=item verbose

Produce some information during the operation.

=item debug

Produce some debugging information during the operation.

=item destdir

The name of the directory where resultant files must be placed.
Default is the current directory.

=item tmpdir

A place where temporary files can be stored, if needed.

=item neat

A function that gets called with the name of the file as deduced from
the data. It must return the desired name of the file to be created.

Default is a function that strips out illegal (and problematic)
characters, and turns all blanks into underscores.

=back

=head1 RETURN VALUES

Return values are constant strings.

Severe errors are signalled using die(), so you should use C<try { }> to
catch them.

=over

=item OK

The decode operation completed successfully.

=item EMPTY

No contents was found.

=item FAIL

The operation failed.

=item DUP

The requested file already exists with a non-zero size.

=back

Additionally, this information will be returned in the decoder object:

=over

=item result

The return value.

=item type

The type of decoding: "M" (MIME), "U" (uudecode) or "Y" (ydecode).

=item name

The name of the file created, relative to the destination directory.

=item file

The full name (destination directory + name) of the file created.

=item size

The length of the data.

=item md5

A base64 encoded MD5 checksum of the data.

=item parts

An array reference. Each element is a hash reference that contains the
fields C<result>, C<name>, C<file>, C<size>, and C<md5> for each file
that was extracted.

=back

If decoding originated in more than one file, the fields C<result>, C<name>,
C<file>, C<size>, and C<md5> will apply to the first file that was
extracted.

=head1 LIMITATIONS

Only yencoded data can be CRC checked. CRC checking is slow, so only
the partial checksums are verified.

Multi-message MIME attachments are not handled yet.

=head1 AUTHOR

Johan Vromans, Squirrel Consultancy <jvromans@squirrel.nl>

Parts of the ydecoding have been stolen from other tools, in particular
newsgrab by Jesper L. Nielsen <lyager@phunkbros.dk>.

=head1 SEE ALSO

L<Convert::yEnc>, L<Mail::Box>.

=head1 COPYRIGHT AND LICENCE

Copyright 2003 Squirrel Consultancy.

License: Artistic.

=cut
