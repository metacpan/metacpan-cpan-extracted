#!/usr/bin/env perl
# t/130-mask-error-values.t -- the storage seam _mask_error_values of every
# storage class of the driver, without a server.
#
# WHY this matters: core sends every text an engine wrote through
# _mask_error_values (ADR 0075). SQL Server quotes values in sentences of its
# own, short ones too, and the driver's override masks those; core's
# next::method masks the bound values wherever they stand. Both have to
# happen in every class a storage can end up in, and the override must not be
# shadowed by a class earlier in the linearisation.

use strict;
use warnings;
use Test::More;
use mro ();
use DBIO::MSSQL::Storage ();
use DBIO::MSSQL::Storage::ODBC ();

my @classes = ('DBIO::MSSQL::Storage', 'DBIO::MSSQL::Storage::ODBC');

if (eval { require DBIO::Sybase::Storage; require DBIO::MSSQL::Storage::Sybase; 1 }) {
  push @classes, 'DBIO::MSSQL::Storage::Sybase';
  push @classes, 'DBIO::MSSQL::Storage::Sybase::NoBindVars'
    if eval { require DBIO::MSSQL::Storage::Sybase::NoBindVars; 1 };
}
else {
  diag 'DBIO::Sybase is not installed: the Sybase classes are not looked at';
}

my $long = 'geheim-und-lang-' . ('x' x 30);

for my $class (@classes) {
  subtest $class => sub {
    my $storage = $class->new(undef);

    my ($first) = grep { defined &{"${_}::_mask_error_values"} } @{ mro::get_linear_isa($class) };
    is $first, 'DBIO::MSSQL::Storage', 'the override is the first definition in the linearisation';

    # the form rule (short value, bound values do not find it)
    is $storage->_mask_error_values(
      "Conversion failed when converting the varchar value 'ab' to data type int.", ['ab'], 'INSERT INTO t (a) VALUES (?)'),
      "Conversion failed when converting the varchar value '***' to data type int.",
      'a short value in a sentence of the server is masked, the type stays';

    is $storage->_mask_error_values(
      "Violation of PRIMARY KEY constraint 'pk_t'. Cannot insert duplicate key in object 'dbo.t'. The duplicate key value is (7, ab).", [7, 'ab'], undef),
      "Violation of PRIMARY KEY constraint 'pk_t'. Cannot insert duplicate key in object 'dbo.t'. The duplicate key value is (***).",
      'the duplicate key value is masked, constraint and table stay';

    # core's next::method (bound values anywhere in the text)
    my $text = $storage->_mask_error_values(
      "Something odd happened with $long and again $long.", [$long], undef);
    unlike $text, qr/geheim/, 'a long bound value is masked everywhere by the core implementation';
    like $text, qr/Something odd happened with \*\*\* and again \*\*\*\./, '... the rest of the text stays';

    # both together
    $text = $storage->_mask_error_values(
      "Conversion failed when converting the varchar value '$long' to data type int. (note $long)", [$long], undef);
    unlike $text, qr/geheim/, 'form rule and bound values together leave no value';
    like $text, qr/data type int/, '... the type stays';

    # never throws, leaves what is not text
    is $storage->_mask_error_values(undef, ['abcd'], undef), undef, 'undef text stays undef';
    my $ref = [];
    is $storage->_mask_error_values($ref, ['abcd'], undef), $ref, 'a reference is returned as it is';
    is $storage->_mask_error_values('plain text', undef, undef), 'plain text', 'no values: the text as it is';
    is $storage->_mask_error_values('plain text', [], undef), 'plain text', 'empty value list: the text as it is';
  };
}

done_testing;
