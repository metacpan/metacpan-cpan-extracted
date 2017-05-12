use strict;

use Test::More tests => 3;

use File::Spec;

use Bigtop::Parser;

use lib 't';
use Purge;

my $bigtop_string;
my @error_output;
my @correct_error_output;

my $play_dir = File::Spec->catdir( 't', 'gantry' );
my $full_play_dir = File::Spec->catdir( $play_dir, 'Apps-Checkbook' );

Purge::real_purge_dir( $full_play_dir );

#---------------------------------------------------------------------------
# main_listing uses cols arg which is not in the table
#---------------------------------------------------------------------------

$bigtop_string = <<"EO_Bigtop";
config {
    base_dir  `$play_dir`;
    SQL       Postgres {}
    HttpdConf Gantry   {}
    Control   Gantry   {}
}
app Apps::Checkbook {
    table payeepayor {
        field id    { is int, primary_key, auto; }
        field name  {
            is varchar;
            label `Payee or Payor`;
        }
        field category {
            is int;
            label `Expense Category`;
        }
    }
    controller Payee {
        controls_table payeepayor;
        method do_main is main_listing {
            cols nmae;
        }
    }
}
EO_Bigtop

@correct_error_output = split /\n/, <<'EO_error_output';
Error: I couldn't find a field called 'nmae' in payeepayor's field list.
  Perhaps you misspelled 'nmae' in the definition of
  method do_main for controller Payee.
EO_error_output

eval {
    Bigtop::Parser->gen_from_string(
        {
            bigtop_string => $bigtop_string,
            create        => 'create',
            build_list    => [ 'Control', ],
        }
    );
};

@error_output = split /\n/, $@;

is_deeply(
     \@error_output,
     \@correct_error_output,
     'runaway string/missing semicolon'
);

Purge::real_purge_dir( $full_play_dir );

#---------------------------------------------------------------------------
# controller keywords only trigger method calls if they were registered
# by the Control::Gantry package.
#---------------------------------------------------------------------------

$bigtop_string = <<"EO_with_location";
config {
    base_dir  `$play_dir`;
    SQL       Postgres {}
    HttpdConf Gantry   {}
    Control   Gantry   {}
}
app Apps::Checkbook {
    table payeepayor {
        field id    { is int, primary_key, auto; }
        field name  {
            is varchar;
            label `Payee or Payor`;
        }
        field category {
            is int;
            label `Expense Category`;
        }
    }
    controller Payee {
        controls_table payeepayor;
        rel_location   payee;
        method do_main is main_listing {
            cols name;
        }
    }
}
EO_with_location

eval {
    Bigtop::Parser->gen_from_string(
        {
            bigtop_string => $bigtop_string,
            create        => 'create',
            build_list    => [ 'Control', ],
        }
    );
};

is( $@, '', 'non-generating keyword' );

Purge::real_purge_dir( $full_play_dir );

#---------------------------------------------------------------------------
# the type in method name is type is not defined
#---------------------------------------------------------------------------

$bigtop_string = <<"EO_with_location2";
config {
    base_dir  `$play_dir`;
    SQL       Postgres {}
    HttpdConf Gantry   {}
    Control   Gantry   {}
}
app Apps::Checkbook {
    table payeepayor {
        field id    { is int, primary_key, auto; }
        field name  {
            is varchar;
            label `Payee or Payor`;
        }
        field category {
            is int;
            label `Expense Category`;
        }
    }
    controller Payee {
        controls_table payeepayor;
        rel_location   payee;
        method do_main is unknown_type {
            cols name;
        }
    }
}
EO_with_location2

eval {
    Bigtop::Parser->gen_from_string(
        {
            bigtop_string => $bigtop_string,
            create        => 'create',
            build_list    => [ 'Control', ],
        }
    );
};

is(
    $@,
    "Error: bad type 'unknown_type' for method 'do_main'\n"
    . "in controller 'Payee'\n",
    'bad method type'
);

Purge::real_purge_dir( $full_play_dir );
