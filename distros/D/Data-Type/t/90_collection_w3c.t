BEGIN
{
        $| = 1;

#        use Test::More qw(no_plan);
        #plan tests => 2 + 1;

	use Test;

	plan tests => 19;
}

use Data::Type qw(:all +W3C);

$Data::Type::debug = 1;

#try{ valid 'http://www.perl.org', W3C::ANYURI; ok(1); } catch Data::Type::Exception with { ok(0); };
#try{ valid '', W3C::BASE64BINARY; ok(1); } catch Data::Type::Exception with { ok(0); };
try{ valid 'true', W3C::BOOLEAN; ok(1); } catch Data::Type::Exception with { ok(0); };
try{ valid '1', W3C::BYTE; ok(1); } catch Data::Type::Exception with { ok(0); };
try{ valid '1', W3C::DECIMAL; ok(1); } catch Data::Type::Exception with { ok(0); };
try{ valid '1', W3C::DOUBLE; ok(1); } catch Data::Type::Exception with { ok(0); };
#try{ valid '', W3C::DURATION; ok(1); } catch Data::Type::Exception with { ok(0); };
#try{ valid '', W3C::ENTITIES; ok(1); } catch Data::Type::Exception with { ok(0); };
#try{ valid '', W3C::ENTITY; ok(1); } catch Data::Type::Exception with { ok(0); };
try{ valid '1', W3C::FLOAT; ok(1); } catch Data::Type::Exception with { ok(0); };
#try{ valid '', W3C::GDAY; ok(1); } catch Data::Type::Exception with { ok(0); };
#try{ valid '', W3C::GMONTH; ok(1); } catch Data::Type::Exception with { ok(0); };
#try{ valid '', W3C::GMONTHDAY; ok(1); } catch Data::Type::Exception with { ok(0); };
#try{ valid '', W3C::GYEAR; ok(1); } catch Data::Type::Exception with { ok(0); };
#try{ valid '', W3C::GYEARMONTH; ok(1); } catch Data::Type::Exception with { ok(0); };
#try{ valid '', W3C::HEXBINARY; ok(1); } catch Data::Type::Exception with { ok(0); };
#try{ valid '', W3C::ID; ok(1); } catch Data::Type::Exception with { ok(0); };
#try{ valid '', W3C::IDREF; ok(1); } catch Data::Type::Exception with { ok(0); };
#try{ valid '', W3C::IDREFS; ok(1); } catch Data::Type::Exception with { ok(0); };
try{ valid '1', W3C::INTEGER; ok(1); } catch Data::Type::Exception with { ok(0); };
try{ valid 'de', W3C::LANGUAGE; ok(1); } catch Data::Type::Exception with { ok(0); };
try{ valid '1', W3C::LONG; ok(1); } catch Data::Type::Exception with { ok(0); };
try{ valid 'ab', W3C::NAME; ok(1); } catch Data::Type::Exception with { ok(0); };
try{ valid 'ab', W3C::NCNAME; ok(1); } catch Data::Type::Exception with { ok(0); };
try{ valid '-1', W3C::NEGATIVEINTEGER; ok(1); } catch Data::Type::Exception with { ok(0); };
#try{ valid '', W3C::NMTOKEN; ok(1); } catch Data::Type::Exception with { ok(0); };
#try{ valid '', W3C::NMTOKENS; ok(1); } catch Data::Type::Exception with { ok(0); };
try{ valid '1', W3C::NONNEGATIVEINTEGER; ok(1); } catch Data::Type::Exception with { ok(0); };
try{ valid '-1', W3C::NONPOSITIVEINTEGER; ok(1); } catch Data::Type::Exception with { ok(0); };
#try{ valid '', W3C::NORMALIZEDSTRING; ok(1); } catch Data::Type::Exception with { ok(0); };
#try{ valid '', W3C::NOTATION; ok(1); } catch Data::Type::Exception with { ok(0); };
try{ valid '1', W3C::POSITIVEINTEGER; ok(1); } catch Data::Type::Exception with { ok(0); };
#try{ valid '', W3C::QNAME; ok(1); } catch Data::Type::Exception with { ok(0); };
#try{ valid '', W3C::SHORT; ok(1); } catch Data::Type::Exception with { ok(0); };
try{ valid 'aabbcc', W3C::STRING; ok(1); } catch Data::Type::Exception with { ok(0); };
#try{ valid '', W3C::TOKEN; ok(1); } catch Data::Type::Exception with { ok(0); };
try{ valid '1', W3C::UNSIGNEDBYTE; ok(1); } catch Data::Type::Exception with { ok(0); };
try{ valid '1', W3C::UNSIGNEDINT; ok(1); } catch Data::Type::Exception with { ok(0); };
try{ valid '1', W3C::UNSIGNEDLONG; ok(1); } catch Data::Type::Exception with { ok(0); };
try{ valid '1', W3C::UNSIGNEDSHORT; ok(1); } catch Data::Type::Exception with { ok(0); };

__END__

try{ valid '', W3C::ANYURI; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::BASE64BINARY; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::BOOLEAN; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::BYTE; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::DECIMAL; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::DOUBLE; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::DURATION; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::ENTITIES; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::ENTITY; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::FLOAT; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::GDAY; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::GMONTH; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::GMONTHDAY; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::GYEAR; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::GYEARMONTH; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::HEXBINARY; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::ID; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::IDREF; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::IDREFS; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::INTEGER; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::LANGUAGE; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::LONG; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::NAME; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::NCNAME; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::NEGATIVEINTEGER; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::NMTOKEN; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::NMTOKENS; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::NONNEGATIVEINTEGER; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::NONPOSITIVEINTEGER; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::NORMALIZEDSTRING; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::NOTATION; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::POSITIVEINTEGER; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::QNAME; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::SHORT; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::STRING; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::TOKEN; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::UNSIGNEDBYTE; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::UNSIGNEDINT; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::UNSIGNEDLONG; ok(0); } catch Data::Type::Exception with { ok(1); };
try{ valid '', W3C::UNSIGNEDSHORT; ok(0); } catch Data::Type::Exception with { ok(1); };

