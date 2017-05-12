#!/usr/bin/perl -w

use strict;

use Aw;
use Aw::Admin;


my $event_type_name = "Test::Event";

my $t = new Aw::Admin::TypeDef ( $event_type_name, FIELD_TYPE_EVENT );

#
#  the same in two steps:
#
#  my $t = new Aw::Admin::TypeDef ( FIELD_TYPE_EVENT );
#  $t->setTypeName ( $event_type_name );
#

$t->setFieldType ( "strAlpha", FIELD_TYPE_STRING       );
$t->setFieldType ( "bBeta",    FIELD_TYPE_BOOLEAN      );
$t->setFieldType ( "iGamma",   FIELD_TYPE_INT          );
$t->setFieldType ( "dDelta",   FIELD_TYPE_DATE         );
$t->setFieldType ( "uEpsilon", FIELD_TYPE_UNICODE_CHAR );

print $t->toString, "\n";


my $tt = new Aw::Admin::TypeDef;

#  the same:
#
#  my $t = new Aw::Admin::TypeDef ( FIELD_TYPE_STRUCT );
#
#  create struct with a name, but can't insert it into another
#  type def later:
#
#  my $t = new Aw::Admin::TypeDef ( "theStruct", FIELD_TYPE_STRUCT );
#

$tt->setFieldType ( "strAlpha", FIELD_TYPE_STRING  );
$tt->setFieldType ( "bBeta",    FIELD_TYPE_BOOLEAN );
$tt->setFieldType ( "iGamma",   FIELD_TYPE_INT     );
$tt->setFieldType ( "dDelta",   FIELD_TYPE_DATE    );

print $tt->toString, "\n";


#
#  insert into our event type def and associate with field "xMyStruct":
#
$t->setFieldDef ( "wMyStruct", $tt );

print $t->toString, "\n";


#
#  the same but using a hash instead of type def object
#
my %hash 		=(
	 strAlpha	=> FIELD_TYPE_STRING,
	 bBeta		=> FIELD_TYPE_BOOLEAN,
	 iGamma		=> FIELD_TYPE_INT,
	 dDelta		=> FIELD_TYPE_DATE
);

$t->setFieldDef ( "xMyStruct", \%hash );

print $t->toString, "\n";


#
#  repeat the "xMyStruct" setup but w/o using ->setFieldDef
#
$t->setFieldType ( "yMyStruct",          FIELD_TYPE_STRUCT  );
$t->setFieldType ( "yMyStruct.strAlpha", FIELD_TYPE_STRING  );
$t->setFieldType ( "yMyStruct.bBeta",    FIELD_TYPE_BOOLEAN );
$t->setFieldType ( "yMyStruct.iGamma",   FIELD_TYPE_INT     );
$t->setFieldType ( "yMyStruct.dDelta",   FIELD_TYPE_DATE    );

print $t->toString, "\n";


#
#  define an array field:
#
$t->setFieldType ( "yArray[]", FIELD_TYPE_FLOAT  );
#
#  reset
#
$t->setFieldType ( "yArray[]", FIELD_TYPE_STRUCT );
$t->setFieldDef  ( "yArray[]", \%hash            );


#
#  finally, an array of structures:
#
$t->setFieldType ( "zMyStruct[]",           FIELD_TYPE_STRUCT       );
$t->setFieldType ( "zMyStruct[].strAlpha",  FIELD_TYPE_STRING       );
$t->setFieldType ( "zMyStruct[].bBeta",     FIELD_TYPE_BOOLEAN      );
$t->setFieldType ( "zMyStruct[].iGamma",    FIELD_TYPE_INT          );
$t->setFieldType ( "zMyStruct[].dDelta",    FIELD_TYPE_DATE         );
$t->setFieldDef  ( "zMyStruct[].xMyStruct", $tt                     );
$t->setFieldType ( "zMyStruct[].ucArray[]", FIELD_TYPE_UNICODE_CHAR );

print $t->toString, "\n";


#
#  if you want to write this mess to a broker:
#
#  my $c = new Aw::Admin::Client ( $broker_host, $broker_name, "", "admin",
#          "The Creator", "" ) || die "Broker Connection Failed: $@\n";
#
#  $c->setEventAdminTypeDef ( $t );
#
#  GUIs?  We don't need no stink'n GUIs!!

__END__

=head1 NAME

typedef-test1.pl - An Aw::Admin::TypeDef Demonstrator.

=head1 SYNOPSIS

./typedef-test1.pl

=head1 DESCRIPTION

A simple demonstration of creating an Aw::Admin::TypeDef and defining
it one field at a time.

=head1 AUTHOR

Daniel Yacob Mekonnen,  L<Yacob@wMUsers.Com|mailto:Yacob@wMUsers.Com>

=head1 SEE ALSO

S<perl(1). ActiveWorks Supplied Documentation>

=cut
