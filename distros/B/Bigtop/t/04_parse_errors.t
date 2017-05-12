use strict;

use Test::More tests => 10;

use Bigtop::Parser;

my $bigtop_string;
my @error_output;
my @correct_error_output;

#---------------------------------------------------------------------------
# runaway string causing missed semi-colon
#---------------------------------------------------------------------------

$bigtop_string = <<"EO_Bigtop";
config {
    base_dir  `.`;
    SQL       Postgres {}
    HttpdConf Gantry   {}
}
app Apps::Checkbook {
    table payeepayor {
        field id    { is int, primary_key, auto; }
        field name  {
            is varchar;
            label `Payee or Payor;
        }
        field category {
            is int;
            label `Expense Category`;
        }
    }
}
EO_Bigtop

@correct_error_output = split /\n/, <<'EO_error_output';
Error: missing semi-colon (possible run-away string beginning on line 11.)
    on line 15 near:
Expense Category`;
        }
    }
}
EO_error_output

Bigtop::Parser->add_valid_keywords(
    'field',
    { keyword => 'is' },
    { keyword => 'update_with' },
    { keyword => 'label' },
);
eval {
    my $conf         = Bigtop::Parser->parse_string($bigtop_string);
};

@error_output = split /\n/, $@;

is_deeply(
     \@error_output,
     \@correct_error_output,
     'runaway string/missing semicolon'
);

#---------------------------------------------------------------------------
# invalid field keyword
#---------------------------------------------------------------------------

$bigtop_string = <<"EO_Bigtop_label_error";
config {
    base_dir  `.`;
    SQL       Postgres {}
    HttpdConf Gantry   {}
}
app Apps::Checkbook {
    table payeepayor {
        field id    { is int, primary_key, auto; }
        field name  {
            is varchar;
            lable `Payee or Payor`;
        }
    }
}
EO_Bigtop_label_error

@correct_error_output = split /\n/, <<'EO_keyword_error';
Error: invalid keyword 'lable' (line 11) near:
 `Payee or Payor`;
I was expecting one of these: is, label, not_for, on_delete, on_update, refers_to, update_with.
EO_keyword_error

Bigtop::Parser->add_valid_keywords(
    'field',
    { keyword => 'is' },
    { keyword => 'update_with' },
    { keyword => 'label' },
);
eval {
    my $conf         = Bigtop::Parser->parse_string($bigtop_string);
};

@error_output = split /\n/, $@;

is_deeply(
     \@error_output,
     \@correct_error_output,
     'invalid keyword'
);

#---------------------------------------------------------------------------
# => instead of space
#---------------------------------------------------------------------------

$bigtop_string = <<"EO_Bigtop";
config {
    base_dir  `.`;
    SQL       Postgres {}
    HttpdConf Gantry   {}
}
app Apps::Checkbook {
    table payeepayor {
        field id    { is int, primary_key, auto; }
        field name  {
            is varchar;
            label => `Payee or Payor`;
        }
        field category {
            is int;
            label `Expense Category`;
        }
    }
}
EO_Bigtop

my $filler = ' ' x 8;
@correct_error_output = split /\n/, <<"EO_fat_comma";
Error: I was expecting an argument or argument list
    on line 11 near:
 => `Payee or Payor`;
        }
        field category {
$filler
EO_fat_comma

#Bigtop::Parser->add_valid_keywords( 'field', qw( is update_with label ) );
eval {
    my $conf         = Bigtop::Parser->parse_string($bigtop_string);
};

@error_output = split /\n/, $@;

is_deeply(
     \@error_output,
     \@correct_error_output,
     'punctuation where space expected'
);

#---------------------------------------------------------------------------
# Backend given as statement
#---------------------------------------------------------------------------

$bigtop_string = <<"EO_Bigtop";
config {
    base_dir  `.`;
    SQL       Postgres;
    HttpdConf Gantry   {}
}
app Apps::Checkbook {
    table payeepayor {
        field id    { is int, primary_key, auto; }
        field name  {
            is varchar;
            label => `Payee or Payor`;
        }
        field category {
            is int;
            label `Expense Category`;
        }
    }
}
EO_Bigtop

@correct_error_output = split /\n/, <<"EO_bad_backed";
Error: invalid keyword 'SQL' (line 3) near:
       Postgres;
I was expecting one of these: app_dir, base_dir, engine, plugins, template_engine, or a valid backend block.
EO_bad_backed

eval {
    my $conf         = Bigtop::Parser->parse_string($bigtop_string);
};

@error_output = split /\n/, $@;

is_deeply(
     \@error_output,
     \@correct_error_output,
     'backend block omitted'
);

#---------------------------------------------------------------------------
# Bad literal at app level
#---------------------------------------------------------------------------

$bigtop_string = <<"EO_Bigtop_bad_lit";
config {
    base_dir  `.`;
    SQL       Postgres {}
    HttpdConf Gantry   {}
}
app Apps::Checkbook {
    lateral NotSupported ``;
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
}
EO_Bigtop_bad_lit

@correct_error_output = split /\n/, <<"EO_bad_lit";
Error: invalid keyword 'lateral' (line 7) near:
 NotSupported ``;
I was expecting one of these: literal, location, no_gen, or a valid block (controller, sequence, config, table, or join_table).
EO_bad_lit

eval {
    my $conf         = Bigtop::Parser->parse_string($bigtop_string);
};

@error_output = split /\n/, $@;

is_deeply(
     \@error_output,
     \@correct_error_output,
     'literal misspelled'
);

#---------------------------------------------------------------------------
# Misspelled block keyword at app level
#---------------------------------------------------------------------------

$bigtop_string = <<"EO_Bigtop_misspelled_block";
config {
    base_dir  `.`;
    SQL       Postgres {}
    HttpdConf Gantry   {}
}
app Apps::Checkbook {
    tbale payeepayor {
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
}
EO_Bigtop_misspelled_block

Bigtop::Parser->add_valid_keywords(
    'app', { keyword => 'authors' }, { keyword => 'label' }
);

@correct_error_output = split /\n/, <<"EO_mispelt_block";
Error: invalid keyword 'tbale' (line 7) near:
 payeepayor {
I was expecting one of these: authors, label, literal, location, no_gen, or a valid block (controller, sequence, config, table, or join_table).
EO_mispelt_block

eval {
    my $conf         = Bigtop::Parser->parse_string($bigtop_string);
};

@error_output = split /\n/, $@;

is_deeply(
     \@error_output,
     \@correct_error_output,
     'block type misspelled'
);

#---------------------------------------------------------------------------
# Misspelled literal keyword
#---------------------------------------------------------------------------

$bigtop_string = <<"EO_Bigtop_misspelled_literal";
config {
    base_dir  `.`;
    SQL       Postgres {}
    HttpdConf Gantry   {}
}
app Apps::Checkbook {
    literal Lcoaction `Include file`;
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
}
EO_Bigtop_misspelled_literal

Bigtop::Parser->add_valid_keywords(
    'app_literal', { keyword => 'Location' }
);

@correct_error_output = split /\n/, <<"EO_mispelt_literal";
Error: invalid keyword 'Lcoaction' (line 7) near:
 `Include file`;
I was expecting one of these: HttpdConf, Location, PerlBlock, PerlTop, SQL.
EO_mispelt_literal

eval {
    my $conf         = Bigtop::Parser->parse_string($bigtop_string);
};

@error_output = split /\n/, $@;

is_deeply(
     \@error_output,
     \@correct_error_output,
     'literal keyword misspelled'
);

#---------------------------------------------------------------------------
# Extra Semicolon in app config block
#---------------------------------------------------------------------------

$bigtop_string = <<"EO_Extra_Config_Semicolon";
config {
    base_dir  `.`;
    SQL       Postgres {}
    HttpdConf Gantry   {}
}
app Apps::Checkbook {
    config {
        var value;
        bad_var `value`;
                => no_accessor;
        var2 value;
    }
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
}
EO_Extra_Config_Semicolon

@correct_error_output = split /\n/, <<"EO_extra_semi";
Error: bad config statement, possible extra semicolon
    on line 10 near:
=> no_accessor;
        var2 value;
    }
    table payeepayor {
EO_extra_semi

eval {
    my $conf         = Bigtop::Parser->parse_string($bigtop_string);
};

@error_output = split /\n/, $@;

is_deeply(
     \@error_output,
     \@correct_error_output,
     'extra semicolon in app config'
);

#---------------------------------------------------------------------------
# Extra Semicolon in controller config block
#---------------------------------------------------------------------------

$bigtop_string = <<"EO_Extra_Controller_Config_Semicolon";
config {
    base_dir  `.`;
    SQL       Postgres {}
    HttpdConf Gantry   {}
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
    controller Name {
        config {
            var value;
            bad_var `value`;
                    => no_accessor;
            var2 value;
        }
    }
}
EO_Extra_Controller_Config_Semicolon

@correct_error_output = split /\n/, <<"EO_extra_semi";
Error: bad config statement, possible extra semicolon
    on line 22 near:
=> no_accessor;
            var2 value;
        }
    }
}
EO_extra_semi

eval {
    my $conf         = Bigtop::Parser->parse_string($bigtop_string);
};

@error_output = split /\n/, $@;

is_deeply(
     \@error_output,
     \@correct_error_output,
     'extra semicolon in controller config'
);

#---------------------------------------------------------------------------
# Missing block name
#---------------------------------------------------------------------------

$bigtop_string = <<"EO_Missing_Block_Name";
config {
    base_dir  `.`;
    SQL       Postgres {}
    HttpdConf Gantry   {}
}
app Apps::Checkbook {
    table {
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
    controller Name {
        config {
            var value;
            bad_var `value`;
                    => no_accessor;
            var2 value;
        }
    }
}
EO_Missing_Block_Name

@correct_error_output = split /\n/, <<"EO_extra_semi";
Error: missing name for table block (line 7) near:
 {
EO_extra_semi

eval {
    my $conf         = Bigtop::Parser->parse_string($bigtop_string);
};

@error_output = split /\n/, $@;

is_deeply(
     \@error_output,
     \@correct_error_output,
     'missing app block name',
);

