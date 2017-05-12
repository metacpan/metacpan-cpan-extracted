#!/usr/bin/perl

use Getopt::Long;

GetOptions ("undef=s", \@undefs,
	    "redef=s", \@redefs);
 

$tag = 'BIO_EMBOSS';


print <<EOB;
/* ***************************************************
   This header file was created 
     by $0 
     on @{[ scalar gmtime() ]} GMT 

   This is a wrapper arround #include "emboss.h"
   ***************************************************
*/

/* undef Perl #define(s) colliding with Emboss */

EOB

&print_undefs (@undefs, @redefs);

print <<EOB;

/* redefine Emboss names, because of collisions with Perl names */

EOB

&print_redefs (@redefs);

print <<EOB;

/* include Emboss headers */

#include "emboss.h"


/* undefine redefinitions */

EOB

&print_redefs_undo(@redefs);

print <<EOB;

/* undo undefs */

EOB

&print_undefs_undo(@redefs, @undefs);

exit(0);

# --- end of main


sub print_undefs {
    foreach (@_) {
	print <<EOB;
#ifdef $_
#define ${_}_BACKUP_${tag} $_
#undef $_
#endif

EOB
    }
}

sub print_undefs_undo {
    foreach (@_) {
	print <<EOB;
#ifdef ${_}_BACKUP_${tag}

#ifdef $_
#undef $_
#endif

#define $_ ${_}_BACKUP_${tag}
/* #undef ${_}_BACKUP_${tag} */
#endif

EOB
   }
}

sub print_redefs {
    foreach (@_) {
	print <<EOB;
#define $_ BIO_EMBOSS_${_}

EOB
    }
}

sub print_redefs_undo {
    foreach (@_) {
	print <<EOB;
#undef $_

EOB
    }
}

