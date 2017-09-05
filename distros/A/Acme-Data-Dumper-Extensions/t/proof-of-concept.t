
use strict;
use warnings;

use Test::More 0.89;

plan tests => 10;

use Data::Dumper;
use Acme::Data::Dumper::Extensions qw/ $_new_with_defaults $_DumpValues /;

{
    local $Data::Dumper::Indent = 10;

    my $bad_instance = Data::Dumper->new( [] );
    my $instance = Data::Dumper->$_new_with_defaults();

    is( $instance->Indent,     2,  "Indent not inherited from localisation" );
    is( $bad_instance->Indent, 10, "Bad Indent inherited from localisation" );

    $instance = Data::Dumper->$_new_with_defaults( { Indent => 4 } );

    is( $instance->Indent, 4, "Indent passed from constructor" );
}
{

    my $bad_instance = Data::Dumper->new( [qw( a b )] );
    my $rval = scalar $bad_instance->$_DumpValues( [qw( xxx yyy )] );

    my $local_plan = 3;

    $local_plan -= unlike $rval, qr/[ab]/,
      "DumpValues replaces constructor values";

    $local_plan -= like $rval, qr/xxx/, "DumpValues gives new values";

    $local_plan -=
      is( scalar $bad_instance->Values, 0, "Instance values wiped" );

    $local_plan == 0 or diag explain [ $rval, $bad_instance ];

}
{

    my $bad_instance = Data::Dumper->new( [qw( a b )], [qw( first second )] );
    {
        my $rval = scalar $bad_instance->$_DumpValues( [qw( xxx yyy )] );

        my $local_plan = 2;

        $local_plan -= unlike $rval, qr/first/,
          "DumpValues ignores preset value names";

        $local_plan -= unlike + ( join q[], $bad_instance->Names ), qr/first/,
          "Instance names wiped";

        $local_plan == 0 or diag explain [ $rval, $bad_instance ];
    }
    {
        my $rval = scalar $bad_instance->$_DumpValues( [qw( xxx yyy )],
            [qw(alpha beta)] );

        my $local_plan = 2;

        $local_plan -= like $rval, qr/alpha/, "DumpValues uses passed names";

        $local_plan -=
          is( scalar $bad_instance->Names, 0, "Instance names wiped" );

        $local_plan == 0 or diag explain [ $rval, $bad_instance ];

    }
}
