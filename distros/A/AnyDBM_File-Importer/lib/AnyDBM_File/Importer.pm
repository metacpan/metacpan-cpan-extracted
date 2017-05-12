#$Id$
package AnyDBM_File::Importer;
use strict;
use warnings;
our $VERSION = '0.012';

=head1 AnyDBM_File::Importer - Import DBM package symbols when using AnyDBM_File

=head1 SYNOPSIS

 BEGIN {
    @AnyDBM_File::ISA = qw( DB_File SDBM_File ) unless @AnyDBM_File::ISA;
 }
 use AnyDBM_File;
 use vars qw( $DB_BTREE &R_DUP); # must declare the globals you expect to use
 use AnyDBM_File::Importer qw(:bdb); # an import tag is REQUIRED

 my %db;
 $DB_BTREE->{'flags'} = R_DUP;
 tie( %db, 'AnyDBM_File', O_CREAT | O_RDWR, 0644, $DB_BTREE);

=head1 DESCRIPTION

This module allows symbols (like $DB_HASH, R_DUP, etc.) to be
imported into the caller's namespace when using the L<AnyDBM_File> DBM
auto-selection package. L<AnyDBM_File> includes its auto-selected module
by using C<require>, which unlike C<use> does not export symbols in
the required packages C<@EXPORT> array.

This is essentially a hack because it relies on L<AnyDBM_File>
internal behavior. Specifically, at the time of DBM module selection,
C<AnyDBM_File> sets its C<@ISA> to a length 1 array containing the
package name of the selected DBM module.

=head1 USAGE NOTES

Use of L<AnyDBM_File::Importer> within module code currently requires
a kludge.  Symbols of imported variables or constants need to be
declared globals, as in the SYNOPSIS above. This is not necessary when
L<AnyDBM_File::Importer> is used in package main. Better solutions are hereby solicited with advance gratitude.

L<AnyDBM_File::Importer> consists entirely of an import function. To
import the symbols, a tag must be given. More than one tag can be
supplied. Symbols cannot be individually specified at the moment.

 :bdb    DB_File (BDB) symbols ($DB_*, R_*, O_*)
 :db     $DB_* type hashrefs
 :R      R_* constants (R_DUP, R_FIRST, etc)
 :O      O_* constants (O_CREAT, O_RDWR, etc)
 :other  Exportable symbols not in any of the above groups
 :all    All exportable symbols

Exportable symbols to be completely ignored can be added to 
C<@AnyDBM_File::Importer::IGNORED_SYMBOLS>. By default, this list
includes the following GNU-undefined symbols:
 
 R_NOKEY, R_SNAPSHOT 
 O_ALIAS, O_ASYNC, O_DEFER, O_DIRECTORY, O_EXLOCK, O_LARGEFILE
 O_RANDOM, O_RAW, O_RSRC, O_SEQUENTIAL, O_SHLOCK, O_TEMPORARY
 
 
=head1 AUTHOR - Mark A. Jensen

 Email: maj -at- fortinbras -dot- us
 http://fortinbras.us
 http://www.bioperl.org/wiki/Mark_Jensen

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

use constant { R_CONST => 1, O_CONST => 2, DB_TYPES => 4, OTHER => 8 };

# ignore "Prototype mismatch:... none vs. ()" 
# and "Amibiguous use of ... resolved to ..." warnings
# for now.../maj

no warnings qw(prototype ambiguous); 

use Carp;

# symbols to ignore; default are gnu-undefined symbols
our @IGNORED_SYMBOLS = qw(R_NOKEY R_SNAPSHOT O_ALIAS O_ASYNC O_DEFER O_DIRECTORY O_EXLOCK O_LARGEFILE O_RANDOM O_RAW O_RSRC O_SEQUENTIAL O_SHLOCK O_TEMPORARY );

sub import {
    my ($class, @args) = @_;
    my ($pkg, $fn, $ln) = caller;
    my $flags = 0;
    for (@args) {
	!defined($_) && do {
	    # simple use
	    return 1;
	};
	/^:all$/ && do {
	    $flags |= (R_CONST | O_CONST |  DB_TYPES | OTHER );
	    next;
	};
	/^:other$/ && do {
	    $flags |= OTHER;
	    next;
	};
	/^:bdb/ && do {
	    $flags |= (R_CONST | O_CONST |  DB_TYPES );
	    next;
	};
	/^:db$/ && do {
	    $flags |= DB_TYPES;
	    next;
	};
	/^:R$/ && do {
	    $flags |= R_CONST;
	    next;
	};
	/^:O$/ && do {
	    $flags |= O_CONST;
	    next;
	};
	do {
	    croak "Tag '$_' not recognized";
	};
    }
    unless ($flags) {
	carp __PACKAGE__.": No symbols exported";
	return;
    }
    
    if (!@AnyDBM_File::ISA) {
	croak "No packages specified for AnyDBM_File (have you forgotten to include AnyDBM_File?)"
    }
    elsif (@AnyDBM_File::ISA > 1) {
	carp "AnyDBM_File has not yet selected a single DBM package; returning..."
    }
    else {
	my @export = eval "(\@$AnyDBM_File::ISA[0]::EXPORT, \@$AnyDBM_File::ISA[0]::EXPORT_OK)";
	my $ref;
	for (@export) {
	    # kludge: ignore gnu perl undefined symbols
	    my $qm = quotemeta;
	    next if grep(/^$qm$/, @IGNORED_SYMBOLS);
	    m/^\$(.*)/ && do {
		$_ = substr $_, 1;
		eval "\$ref = *${pkg}::$_\{SCALAR}";
		croak $@ if $@;
		if ( ($flags & DB_TYPES and ($1 =~ /^DB_/)) ||
		     ($flags & OTHER and ($1 !~ /^DB_/)) ) {
		    $$ref = eval "\$$AnyDBM_File::ISA[0]\::$_";
		}
		next;
	    };
	    m/^\@(.*)/ && do {
		$_ = substr $_, 1;
		eval "\$ref = *${pkg}::$_\{ARRAY}";
		croak $@ if $@;
		if  ($flags & OTHER) {
		    $$ref = eval "\@$AnyDBM_File::ISA[0]\::$1";
		}
		next;
	    };
	    m/^\%(.*)/ && do {
		$_ = substr $_, 1;
		eval "\$ref = *${pkg}::$_\{HASH}";
		croak $@ if $@;
		if  ($flags & OTHER) {
		    $$ref = eval "\%$AnyDBM_File::ISA[0]\::$1";
		}
		next;
	    };
	    m/^[^\$@%]/ && do {
		eval "*{${pkg}::$_} = \\\&$AnyDBM_File::ISA[0]\::$_" if 
		   ( ($flags & R_CONST and /^R_/) ||
		    ($flags & O_CONST and /^O_/) ||
		     ($flags & OTHER and /^[RO]_/) );

		next;
	    };
	}
	return 1;
    }
}

1;
