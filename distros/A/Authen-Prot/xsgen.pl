#!/usr/bin/perl
###############################################################################
#
# $Id: xsgen.pl,v 1.8 1998/11/10 05:09:57 paulg Exp $
# Copyright (c) 1998 Paul Gampe. All Rights Reserved.
#
# This script parses the C struct defined in prot.h and generates a
# Prot.xs to match.  
# 
###############################################################################

use strict;
no strict 'refs';

sub int      { return 'var = (int)     SvIV(ST(1));'     }
sub char     { return 'var = (char)*   SvPV(ST(1), na);' }
sub char_ptr { return 'var = (char*)   SvPV(ST(1), na);' }
sub uid_t    { return 'var = (uid_t)   SvNV(ST(1));'     }
sub mask_t   { return 'var = (mask_t)  SvNV(ST(1));'     }
sub aid_t    { return 'var = (aid_t)   SvNV(ST(1));'     }
sub time_t   { return 'var = (time_t)  SvNV(ST(1));'     }
sub long     { return 'var = (long)    SvIV(ST(1));'     }
sub short    { return 'var = (short)   SvIV(ST(1));'     }
sub ushort   { return 'var = (ushort)  SvIV(ST(1));'     }
sub uchar_t  { return 'var = (uchar_t) SvIV(ST(1));'     }

my $proc_struct = 0;

open (PROT, '/usr/include/prot.h') or die "could not open prot.h";

my ($def);
while(<PROT>) {
	## only processing the pr_field struct
	next until /^struct pr_field/ or $proc_struct;

	$proc_struct = 1;	# now inside the struct
	last if /^\}/;		# break if we've hit the end
	chomp;

	# HPUX and SCO include the define above the struct field def.
	if (/^#define\s+(\w+)/) { $def = $1; next; } 

	# Digital have 'es' and 'pr' interfaces.  I'm only supporting the
	# 'pr' interfaces.  Within their pr_field struct, the defines are
	# re-written as comments.  In their struct espw_field they use
	# defines, thanks! So the following regexp has to look for comments.
	if (/^\/\*\s+(\w+)\s+\"[^"]*\"\s+\*\//) { $def = $1; next; } 

	# uid_t	fd_uid;	 	/* uid associated with name above */
	# char	fd_name[9];	/* uses 8 character maximum(and \0) from utmp */

	if (my($type,$field) = /\s+\b(.*)\b\s+([^;]*;)/) {
		chop($field); 								## remove the ;
		my($fd_field,$ext) = split(/\[/, $field);	## check for []
		die "no def for $fd_field\n" unless $def ne "";

		# HPUX: don't do any reserved fd_field
		next if ($type =~ /mask_t/);

		# DIGITAL: have an exts for kernel auth vector and mand attr.
		# which I don't know how to handle as I don't have Digital box.
		# So skip it. If someone can tell me what types these fields are?
		next if ($type =~ /privvec_t/);
		next if ($type =~ /mand_ir_t/);

		# DIGITAL: unsupported field <newcomer@dickinson.edu>
		next if ($fd_field =~ /clearance_filler/);

		# SCO: uses unsigned short map it to ushort for func name
		$type="ushort" if ($type =~ /unsigned short/);

		# SCO: has a void* for future use, skip it for now
		next if ($type =~ /void/);

		my $ufld="ufld_". "$fd_field";
		my $sfld="sfld_". "$fd_field";

		my $fg_field="fg". substr($fd_field,2);
		my $uflg="uflg_". "$fg_field";
		my $sflg="sflg_". "$fg_field";

		my ($perl_conv,$arg_copy);
		if (length($ext) > 1) {
			$type='char *';
			$perl_conv = &char_ptr;
			$arg_copy="strcpy(self->ufld.$fd_field, var);";
		} else {
			$perl_conv = &$type;
			$arg_copy="self->ufld.$fd_field = var;";
		}
		print <<EOT;

#if defined($def)

$type
$ufld(self, ...)
	PASSWD *self
	PREINIT:
		$type var;
	CODE:
		if(items > 1) {
			$perl_conv
			$arg_copy
		}
		RETVAL=self->ufld.$fd_field;
	OUTPUT:
		RETVAL

$type
$sfld(self, ...)
	PASSWD *self
	PREINIT:
		$type var;
	CODE:
		if(items > 1) {
			$perl_conv
			$arg_copy
		}
		RETVAL=self->sfld.$fd_field;
	OUTPUT:
		RETVAL

unsigned short
$uflg(self, ...)
		PASSWD *self
	PREINIT:
		unsigned short us;
    CODE:
		if(items > 1) {
			us = (unsigned short) SvIV(ST(1));
			self->uflg.$fg_field = us;
		}
		RETVAL=self->uflg.$fg_field;
    OUTPUT:
		RETVAL

unsigned short
$sflg(self, ...)
		PASSWD *self
	PREINIT:
		unsigned short us;
    CODE:
		if(items > 1) {
			us = (unsigned short) SvIV(ST(1));
			self->sflg.$fg_field = us;
		}
		RETVAL=self->sflg.$fg_field;
    OUTPUT:
		RETVAL

#endif /* $def */
EOT
	} ## if
} ## while

close(PROT);
