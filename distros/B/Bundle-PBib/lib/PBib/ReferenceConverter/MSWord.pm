# --*-Perl-*--
# $Id: MSWord.pm 11 2004-11-22 23:56:20Z tandler $
#
#
# the package RefConverterMSWord is actually empty, it instead 
# defines an extension for package PBib::Doc::MSWord
#
# Currently not working, i.e. unused
#

package PBib::ReferenceConverter::MSWord;
use 5.006;
use strict;
use warnings;
#use English;

# for debug:
use Data::Dumper;

BEGIN {
    use vars qw($Revision $VERSION);
	my $major = 1; q$Revision: 11 $ =~ /: (\d+)/; my ($minor) = ($1); $VERSION = "$major." . ($minor<10 ? '0' : '') . $minor;
}

# superclass
use PBib::ReferenceConverter;
our @ISA = qw(PBib::ReferenceConverter);

# used standard modules
#use FileHandle;

# used own modules
# use RefConverterMSWord::SubModule;

# module variables
#use vars qw($mmmm);
# or
#our($mmm);




#
#
# converting methods
#
#


### not working yet .... (2004-11-17 PT)

#
#
# extension of package PBib::Doc::MSWord;
#
#

package PBib::Document::MSWord;

sub referenceConverterClass {
#
# return which class of reference converter to use (undef for default)
#
	my ($self, $rcClass) = @_;
#print 'PBib::ReferenceConverter::MSWord';
	# hm, currently use the normal one + convert to RTF ...
	return 'PBib::ReferenceConverter';
}


1;

#
# $Log: MSWord.pm,v $
# Revision 1.3  2003/06/12 22:11:53  tandler
# don't use Word's special converter for now ...
#
# Revision 1.2  2002/08/22 10:42:34  peter
# - a lot of stuff moved to Document::MSWord
#

