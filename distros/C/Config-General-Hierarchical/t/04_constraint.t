# testscript for Config::General::Hierarchical module
#
# needs to be invoked using the command "make test" from
# the Config::General::Hierarchical source directory.
#
# under normal circumstances every test should succeed.

use Config::General::Hierarchical;
use Test::More tests => 73;
use Test::Differences;

my $cfg = TestConfig->new( file => 't/constraint.conf' );
isa_ok( $cfg, 'Config::General::Hierarchical', 'class inheritance' );

eval { TestConfig->import };
is( $@, '', 'syntax' );

eval { TestConfig3->import };
is( $@, "TestConfig3: syntax method musts return an HASH reference\n",
    'wrong syntax' );

eval { TestConfig4->import };
is(
    $@,
"TestConfig4: wrong use of ARRAY reference as syntax for variable 'WrongR'\n",
    'wrong syntax ref'
);

eval { TestConfig5->import };
is(
    $@,
    "TestConfig5: wrong 'test' syntax for variable 'WrongV'\n",
    'wrong syntax value'
);

eval { TestConfig6->import };
is(
    $@,
"TestConfig6: wrong use of 'm' flag for not string nor array variable 'WrongM->NotMerge'\n",
    'wrong syntax value'
);

eval { $cfg->_Undefined };
like(
    $@,
qr{Config::General::Hierarchical: request for undefined variable 'Undefined'\nin file: .+/t/constraint.conf at t/04_constraint.t line \d+.\n},
    'undefined without constraint'
);

eval { $cfg->_Node->_Undefined };
like(
    $@,
qr{Config::General::Hierarchical: request for undefined variable 'Node->Undefined'\nin file: .+/t/constraint.conf at t/04_constraint.t line \d+.\n},
    'undefined without constraint 2'
);

eval { $cfg->_Array };
like(
    $@,
qr{Config::General::Hierarchical: variable 'Array' is an array: should be a string or a node\nin file: .+/t/constraint.conf at t/04_constraint.t line \d+.\n},
    'array without constraint'
);

eval { $cfg->_Integer };
like(
    $@,
qr{Config::General::Hierarchical: variable 'Integer' is an array but should be a integer value\nin file: .+/t/constraint.conf at t/04_constraint.t line \d+.\n},
    'array but ...'
);

eval { $cfg->_Number };
like(
    $@,
qr{Config::General::Hierarchical: variable 'Number' is a node but should be a number\nin file: .+/t/constraint.conf at t/04_constraint.t line \d+.\n},
    'node but ...'
);

eval { $cfg->_Number };
like(
    $@,
qr{Config::General::Hierarchical: variable 'Number' is a node but should be a number\nin file: .+/t/constraint.conf at t/04_constraint.t line \d+.\n},
    'node but ... cache'
);

is( $cfg->_Boolean, 0,     'undef boolean' );
is( $cfg->_String2, undef, 'undef value' );
is( $cfg->_NodeUnd, undef, 'undef node' );

eval { $cfg->_EMail };
like(
    $@,
qr{Config::General::Hierarchical: request for undefined variable 'EMail'\nin file: .+/t/constraint.conf at t/04_constraint.t line \d+.\n},
    'not undef value'
);

eval { $cfg->_NodeDef };
like(
    $@,
qr{Config::General::Hierarchical: request for undefined variable 'NodeDef'\nin file: .+/t/constraint.conf at t/04_constraint.t line \d+.\n},
    'not undef node'
);

is( $cfg->_String3, 'string3', 'value without constraint' );
isa_ok(
    $cfg->_Node,
    'Config::General::Hierarchical',
    'node without constraint'
);

is( $cfg->_Boolean, 0, 'undefined boolean' );

is( $cfg->_Sub, 'ab', 'inline substitution - undef' );

eval { $cfg->_Array2 };
like(
    $@,
qr{Config::General::Hierarchical: variable 'Array2' should be an array\nin file: .+/t/constraint.conf at t/04_constraint.t line \d+.\n},
    'array but node'
);

is( $cfg->_Merge->_1, 'c',   'undef merge 1' );
is( $cfg->_Merge->_2, 'ef',  'undef merge 2' );
is( $cfg->_Merge->_3, undef, 'undef merge 3' );

my $cfg2 = TestConfig2->new( file => 't/constraint.conf' );
isa_ok( $cfg2, 'Config::General::Hierarchical', 'class inheritance 2' );

eval { $cfg2->_Array };
like(
    $@,
qr{Config::General::Hierarchical: element 'b' of variable 'Array' is not a prooper integer value\nin file: .+/t/constraint.conf at t/04_constraint.t line \d+.\n},
    'array elements syntax'
);

is( $cfg->_Wild->_NotDefined, undef, 'undefined key in wild node' );
isa_ok( $cfg->_Wild->_Test, 'Config::General::Hierarchical', 'wild node' );
is( $cfg->_Wild->_Test->_String,  'test string', 'wild constraints 1' );
is( $cfg->_Wild->_Test->_Integer, 123,           'wild constraints 2' );

eval { $cfg->_Wild->_Test->_Other };
like(
    $@,
qr{Config::General::Hierarchical: value 'string' for variable 'Wild->Test->Other' is not a prooper integer value\nin file: .+/t/constraint2.conf at t/04_constraint.t line \d+.\n},
    'wild constraints 3'
);

$cfg  = $cfg->_Struct;
$cfg2 = $cfg2->_Struct;

eval { $cfg->_SArray };
like(
    $@,
qr{Config::General::Hierarchical: request for undefined variable 'Struct->SArray'\nin file: .+/t/constraint.conf at t/04_constraint.t line \d+.\n},
    'struct 1 1'
);
is( ref $cfg2->_SArray,         'ARRAY', 'struct 1 2' );
is( scalar @{ $cfg2->_SArray }, 0,       'struct 1 3' );

is( $cfg->_SEMail,  'email@test.conf', 'struct 2 1' );
is( $cfg2->_SEMail, 'email@test.conf', 'struct 2 2' );

is( $cfg->_SNode, 0, 'struct 3 1' );
eval { $cfg2->_SNode };
like(
    $@,
qr{Config::General::Hierarchical: variable 'Struct->SNode' should be a node\nin file: .+/t/constraint1.conf at t/04_constraint.t line \d+.\n},
    'struct 3 2'
);

eq_or_diff( $cfg->_SInteger, [ 1, 2, 3, 4 ], 'struct 4 1' );
eq_or_diff( $cfg2->_SInteger, [ 2, 3, 4 ], 'struct 4 2' );

is( $cfg->_VEMail, "test\@test.conf\t, test.test\@test.conf", 'struct 5 1' );
eq_or_diff( $cfg2->_VEMail, [ 'test@test.conf', 'test.test@test.conf' ],
    'struct 5 2' );

is( $cfg->_SString,  'S2S1S3', 'struct 6 1' );
is( $cfg2->_SString, 'S3',     'struct 6 2' );

eq_or_diff( $cfg->_SNumber, [ 1.2, -.2 ], 'struct 7 1' );
eq_or_diff( $cfg2->_SNumber, [ -12, '-.12', 1.2, -.2 ], 'struct 7 2' );

$cfg  = $cfg->_SWild;
$cfg2 = $cfg2->_SWild;

is( $cfg->_WEMail->[0],  'test@test.conf', 'struct 8 1' );
is( $cfg2->_WEMail->[0], 'test@test.conf', 'struct 8 2' );

is( $cfg->_WInteger, 23, 'struct 10 1' );
eq_or_diff( $cfg2->_WInteger, [ ' 321', '23' ], 'struct 10 2' );

$cfg = TestConfig->new( file => 't/constraint_type_error.conf' );

eval { $cfg->_DateTime };
like(
    $@,
qr{Config::General::Hierarchical: value '1976-01-23' for variable 'DateTime' is not a prooper datetime\nin file: .+/t/constraint_type_error.conf at t/04_constraint.t line \d+.\n},
    'A error'
);

eval { $cfg->_Boolean };
like(
    $@,
qr{Config::General::Hierarchical: value 'onn' for variable 'Boolean' is not a prooper boolean value\nin file: .+/t/constraint_type_error.conf at t/04_constraint.t line \d+.\n},
    'B error'
);

eval { $cfg->_Date };
like(
    $@,
qr{Config::General::Hierarchical: value '1976/01/23' for variable 'Date' is not a prooper date\nin file: .+/t/constraint_type_error.conf at t/04_constraint.t line \d+.\n},
    'D error'
);

eval { $cfg->_EMail };
like(
    $@,
qr{Config::General::Hierarchical: value 'email.test.conf' for variable 'EMail' is not a prooper e-mail address\nin file: .+/t/constraint_type_error.conf at t/04_constraint.t line \d+.\n},
    'E error'
);

eval { $cfg->_Integer };
like(
    $@,
qr{Config::General::Hierarchical: value '4.5' for variable 'Integer' is not a prooper integer value\nin file: .+/t/constraint_type_error.conf at t/04_constraint.t line \d+.\n},
    'I error'
);

eval { $cfg->_Number };
like(
    $@,
qr{Config::General::Hierarchical: value '2-3' for variable 'Number' is not a prooper number\nin file: .+/t/constraint_type_error.conf at t/04_constraint.t line \d+.\n},
    'N error'
);

eval { $cfg->_String1 };
like(
    $@,
qr{Config::General::Hierarchical: variable 'String1' is an array but should be a string\nin file: .+/t/constraint_type_error.conf at t/04_constraint.t line \d+.\n},
    'S error'
);

eval { $cfg->_String2 };
like(
    $@,
qr{Config::General::Hierarchical: variable 'String2' is a node but should be a string\nin file: .+/t/constraint_type_error.conf at t/04_constraint.t line \d+.\n},
    '\`\` error'
);

eval { $cfg->_String3 };
like(
    $@,
qr{Config::General::Hierarchical: variable 'String3' is an array: should be a string or a node\nin file: .+/t/constraint_type_error.conf at t/04_constraint.t line \d+.\n},
    'undef error'
);

eval { $cfg->_Time };
like(
    $@,
qr{Config::General::Hierarchical: value '15:0:0' for variable 'Time' is not a prooper time\nin file: .+/t/constraint_type_error.conf at t/04_constraint.t line \d+.\n},
    'T error'
);

eval { $cfg->_Node };
like(
    $@,
qr{Config::General::Hierarchical: variable 'Node' should be a node\nin file: .+/t/constraint_type_error.conf at t/04_constraint.t line \d+.\n},
    'node error'
);

$cfg = TestConfig->new( file => 't/constraint_type.conf' );

is( $cfg->_DateTime, '1976-01-23 15:00:00', 'A ok' );
is( $cfg->_Boolean,  1,                     'B ok' );
is( $cfg->_Date,     '1976-01-23',          'D ok' );
is( $cfg->_EMail,    'email@test.conf',     'E ok' );
is( $cfg->_Integer,  4,                     'I ok' );
is( $cfg->_Number,   2.3,                   'N ok' );
is( $cfg->_String1,  'string1',             'S ok' );
is( $cfg->_String2,  'string2 ',            '\'\' ok' );
is( $cfg->_String3,  ' string3 ',           'undef ok' );
is( $cfg->_Time,     '15:00:00',            'T ok' );
isa_ok( $cfg->_Node, 'Config::General::Hierarchical', 'node ok' );

package TestConfig;

use base 'Config::General::Hierarchical';

sub new {
    my ( $self, @pars ) = @_;

    return $self->SUPER::new( undefined => 'not_defined', @pars );
}

sub syntax {
    my ($self) = @_;
    my %constraint = (
        Array2   => 'a',
        Boolean  => 'Bu',
        Date     => 'D',
        DateTime => 'A',
        EMail    => 'E',
        Integer  => 'I',
        Merge    => { '*' => 'mu' },
        Node     => {},
        NodeDef  => {},
        NodeUnd  => { not_defined => undef },
        NotNode  => '',
        Number   => 'N',
        String1  => 'S',
        String2  => 'u',
        String3  => undef,
        Struct   => {
            SEMail   => 'E',
            SInteger => 'maI',
            SNode    => 'B',
            SNumber  => 'Na',
            SString  => 'm',
            SWild    => {
                WEMail => 'Ea',
                '*'    => 'I',
            },
        },
        Time  => 'T',
        UWild => { '*' => { '*' => 'I' } },
        Wild  => {
            '*' => {
                not_defined => undef,
                String      => undef,
                '*'         => 'I',
            }
        },
    );
    return $self->merge_values( \%constraint, $self->SUPER::syntax );
}

package TestConfig2;

use base 'TestConfig';

sub syntax {
    my ($self) = @_;
    my %constraint = (
        Array  => 'aI',
        Struct => {
            SArray   => 'ua',
            SInteger => 'Ia',
            SNode    => {},
            SNumber  => 'Nam',
            SString  => 'S',
            VEMail   => 'aE',
            SWild    => { '*' => 'am' },
        },
    );
    return $self->merge_values( \%constraint, $self->SUPER::syntax );
}

package TestConfig3;

use base 'TestConfig2';

sub syntax {
    return [];
}

package TestConfig4;

use base 'TestConfig2';

sub syntax {
    my ($self) = @_;
    my %constraint = ( WrongR => [] );
    return $self->merge_values( \%constraint, $self->SUPER::syntax );
}

package TestConfig5;

use base 'TestConfig2';

sub syntax {
    my ($self) = @_;
    my %constraint = ( WrongV => 'test' );
    return $self->merge_values( \%constraint, $self->SUPER::syntax );
}

package TestConfig6;

use base 'TestConfig2';

sub syntax {
    my ($self) = @_;
    my %constraint = ( WrongM => { NotMerge => 'mE' } );
    return $self->merge_values( \%constraint, $self->SUPER::syntax );
}
