#!/usr/bin/perl -w

use strict;
use warnings;
no warnings 'once';
use Carp qw(verbose);
use Test::More tests => 113;

my $WARNINGS;
sub catchwarn {
    my ($expected_warning, $how_many) = @_;
    if (not defined $expected_warning) {
        $expected_warning = qr/.*/;
    }
    if (not defined $how_many) {
        $how_many = 1;
    }
    my $n = 0;
    $WARNINGS = 0;
    if ($how_many == 0) {
        $SIG{__WARN__} = 'DEFAULT';
        return
    }
    $SIG{__WARN__} = sub {
        my ($warning) = @_;
        if ($warning =~ $expected_warning) {
            if (++$n >= $how_many) {
                $SIG{__WARN__} = 'DEFAULT';
            }
            $WARNINGS++;
        }
        else {
            print STDERR $warning;
        }
    };
}

{
    package FuncLoad;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'by_option', code => sub { return "feat1inOption(@_)" } },
        { name => 'in_hash' },
        { name => 'in_package' },
    );
    our %features = (
        by_option => sub { return "feat1inHash(@_)" },
        in_hash => sub { return "feat2inHash(@_)" },
    );
    sub in_package {
        return "feat3inPackage(@_)"
    }
    sub by_option {
        return "feat1inPackage(@_)"
    }
}

### Creating the object inheriting from Data::FeatureFactory
my $funcLoad = FuncLoad->new;
is(ref($funcLoad), 'FuncLoad', q{instantiated FuncLoad});
isa_ok($funcLoad, 'Data::FeatureFactory', q{FuncLoad inherited from Data::FeatureFactory});

### retrieving the list of available features
my @names = $funcLoad->names;
is(join(' ', @names), 'by_option in_hash in_package', q{retrieved the list of available features});

### Evaluating features whose code is specified in different manners
my @by_option = $funcLoad->evaluate([qw(by_option)], 'normal', 1 .. 5);
is(scalar(@by_option), 1, q{evaluating feat1 returned one thing});
is('feat1inOption('.join($", 1 .. 5).')', $by_option[0], q{evaluated feat1});

my @in_hash = $funcLoad->evaluate([qw(in_hash)], 'normal', 1 .. 5);
is(scalar(@in_hash), 1, q{evaluating feat2 returned one thing});
is('feat2inHash('.join($", 1 .. 5).')', $in_hash[0], q{evaluated feat2});

my @in_package = $funcLoad->evaluate([qw(in_package)], 'normal', 1 .. 5);
is(scalar(@in_package), 1, q{evaluating feat3 returned one thing});
is('feat3inPackage('.join($", 1 .. 5).')', $in_package[0], q{evaluated feat3});

### Specifying the feature names in different manners
my @by_list = $funcLoad->evaluate([qw(by_option in_hash)], 'normal', 2 .. 6);
my @by_name = $funcLoad->evaluate('in_package',            'normal', 2 .. 6);
my @by_all  = $funcLoad->evaluate('ALL',                   'normal', 2 .. 6);
is(scalar(@by_list), 2, q{evaluating by list returned 2 things});
is(scalar(@by_name), 1, q{evaluating by name returned 1 thing});
is(scalar(@by_all),  3, q{evaluating by all returned 3 things});
is(join(' ', @by_list, @by_name), join(' ', @by_all), q{evaluating by list, name and "ALL" return same things});

undef $funcLoad;

{
    package Labels;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'ball',       code => \&any },
        { name => 'egg',        code => \&any, label => 'living' },
        { name => 'moon',       code => \&any, label => 'Big' },
        { name => 'pig',        code => \&any, label => [qw(big living)] },
        { name => 'cigarette',  code => \&any, label => [qw(Long)] },
        { name => 'finger',     code => \&any, label => [qw(long LIVING)] },
        { name => 'neon',       code => \&any, label => [qw(long BIG)] },
        { name => 'bamboo',     code => \&any, label => [qw(long big living)] },
        { name => 'bullet',     code => \&any, label => 'dark' },
        { name => 'strawberry', code => \&any, label => [qw(dark liVing)] },
        { name => 'earth',      code => \&any, label => [qw(big daRk)] },
        { name => 'elephant',   code => \&any, label => [qw(darK big living)] },
        { name => 'pen',        code => \&any, label => [qw(dark Long)] },
        { name => 'worm',       code => \&any, label => [qw(living loNg dark)] },
        { name => 'rifle',      code => \&any, label => [qw(dark long biG)] },
        { name => 'tree',       code => \&any, label => [qw(big dark livinG long)] },
    );
    sub any {
        return $Data::FeatureFactory::CURRENT_FEATURE."(@_)"
    }
}

my $labels = Labels->new;

my @all = $labels->evaluate('ALL', 'normal', 1);
my $expected = 'ball(1) egg(1) moon(1) pig(1) cigarette(1) finger(1) neon(1) bamboo(1) '
              .'bullet(1) strawberry(1) earth(1) elephant(1) pen(1) worm(1) rifle(1) tree(1)';
is(join(' ', @all), $expected, q{Evaluating all features (some labeled)});

my @big = $labels->evaluate('BIG', 'normal', 2);
$expected = 'moon(2) pig(2) neon(2) bamboo(2) earth(2) elephant(2) rifle(2) tree(2)';
is (join(' ', @big), $expected, q{Evaluating features with a label});

my @long_dark = $labels->evaluate('LONG DARK', 'normal', 3);
$expected = 'cigarette(3) finger(3) neon(3) bamboo(3) bullet(3) strawberry(3) earth(3) elephant(3) pen(3) worm(3) rifle(3) tree(3)';
is (join(' ', @long_dark), $expected, q{Evaluating features with two labels});

my @dark_long = $labels->evaluate('DARK LONG', 'normal', 3);
is (join(' ', @dark_long), join(' ', @long_dark), q{Different order of labels won't affect result});

@dark_long = $labels->evaluate('DARK +LONG', 'normal', 3);
is (join(' ', @dark_long), join(' ', @long_dark), q{Adding + before label name won't affect result});

my @living_big_nodark_nolong = $labels->evaluate('LIVING +BIG -DARK -LONG', 'normal', 4);
$expected = 'egg(4) moon(4) pig(4)';
is (join(' ', @living_big_nodark_nolong), $expected, q{Several + and - labels});

my @nobig_nodark = $labels->evaluate('-BIG -DARK', 'normal', 5);
$expected = 'ball(5) egg(5) cigarette(5) finger(5)';
is (join(' ', @nobig_nodark), $expected, q{Minus labels only});

my @wrong_label = $labels->evaluate('WRONG_LABEL', 'normal', 6);
is (scalar(@wrong_label), 0, q{Wrong label gave an empty result});

undef $@;
my $expected_message = q{Label 'ALL' is special and can't be used with the minus sign, as in BIG -ALL +DARK};
eval { $labels->evaluate('BIG -ALL +DARK', 'normal', 7) };
is(substr($@, 0, length $expected_message), $expected_message, q{croaked with label -ALL});

undef $labels;

{
    package NamelessFeature;
    use base qw(Data::FeatureFactory);
    our @features = (
        { code => \&defunct },
    );
    sub defunct {
        Test::More::diag "This should never be printed!!! (".__PACKAGE__.")\n";
        return
    }
}

undef $@;
$expected_message = q{There was a feature without a name. Each record in the @features array must be a hashref with a 'name' field at least};
eval { NamelessFeature->new };
is(substr($@, 0, length $expected_message), $expected_message, q{croaked with nameless feature});

{
    package IllegalOption;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'defunct', illegal_option => 1 },
    );
    sub defunct {
        Test::More::diag "This should never be printed!!! (".__PACKAGE__.")\n";
        return
    }
}

undef $@;
$expected_message = q{Unrecognized option 'illegal_option' specified for feature 'defunct'};
eval { IllegalOption->new };
is(substr($@, 0, length $expected_message), $expected_message, q{croaked with illegal option});

{
    package UnsupportedOption;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'hack', cat2num => {'a' => 1, 'b' => 2} },
    );
    sub hack {
        return @_%2 ? 'a' : 'b'
    }
}

catchwarn(qr/^Option 'cat2num' you specified for feature 'hack' is not supported. Be sure you know what you are doing/);
UnsupportedOption->new;
is($WARNINGS, 1, q{warned about unsupported option});

{
    package DoubleFeature;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'defunct' },
        { name => 'defunct' },
    );
    sub defunct {
        Test::More::diag "This should never be printed!!! (".__PACKAGE__.")\n";
        return
    }
}

undef $@;
$expected_message = q(Feature defunct specified twice in @DoubleFeature::features);
eval { DoubleFeature->new };
is(substr($@, 0, length $expected_message), $expected_message, q{croaked with name collision});

### Type of the features
{
    package FeatType;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'first_letter' }, # implicit type => cat
        { name => 'first_letter_int', type => 'int', code => \&first_letter },
        { name => 'first_letter_num', type => 'num', code => \&first_letter },
        { name => 'first_letter_bool', type => 'bool', code => \&first_letter },
        { name => 'num_letters_cat', code => \&num_letters },
        { name => 'num_letters', type => 'int' },
        { name => 'num_letters_num', type => 'num', code => \&num_letters },
        { name => 'num_letters_bool', type => 'bool', code => \&num_letters },
        { name => 'half_num_letters_cat', type => 'cat', code => \&half_num_letters },
        { name => 'half_num_letters_int', type => 'int', code => \&half_num_letters },
        { name => 'half_num_letters', type => 'num' },
        { name => 'half_num_letters_bool', type => 'bool', code => \&half_num_letters },
        { name => 'is_digits_cat', type => 'cat', code => \&is_digits },
        { name => 'is_digits_int', type => 'int', code => \&is_digits },
        { name => 'is_digits_num', type => 'num', code => \&is_digits },
        { name => 'is_digits', type => 'bool' },
    );
    sub first_letter {
        die if @_ != 1;
        return substr $_[0], 0, 1
    }
    sub num_letters {
        die if @_ != 1;
        return length $_[0]
    }
    sub half_num_letters {
        die if @_ != 1;
        return length($_[0]) / 2
    }
    sub is_digits {
        die if @_ != 1;
        my @rv = $_[0] =~ /^([0-9]+)$/;
        return pop @rv
    }
}

my $featType = FeatType->new;
is(ref($featType), 'FeatType', q{instantiated FeatType});
catchwarn(qr/^Argument \S+ isn't numeric in addition \(\+\)/, 2);
my ($flc, $fli, $fln, $flb,
    $nlc, $nli, $nln, $nlb,
    $hnc, $hni, $hnn, $hnb,
    $dfc, $dfi, $dfn, $dfb,
) = $featType->evaluate([qw(
    first_letter         first_letter_int     first_letter_num first_letter_bool
    num_letters_cat      num_letters          num_letters_num  num_letters_bool
    half_num_letters_cat half_num_letters_int half_num_letters half_num_letters_bool
    is_digits_cat        is_digits_int        is_digits_num    is_digits
)], 'normal', 'foo');
is($WARNINGS, 2, q{warned about non-numeric values of numeric features});
my ($dtc, $dti, $dtn, $dtb) = $featType->evaluate([qw(
    is_digits_cat is_digits_int is_digits_num is_digits)], 'normal', '00');
is($flc, 'f', q{first letter categorial});
is($fli,  0,  q{first letter integer});
is($fln,  0,  q{first letter numeric});
is($flb,  1,  q{first letter boolean});
is($nlc,  3,  q{number of letters categorial});
is($nli,  3,  q{number of letters integer});
is($nln,  3,  q{number of letters numeric});
is($nlb,  1,  q{number of letters boolean});
cmp_ok($hnc, '==', 1.5, q{half number of letters categorial});
cmp_ok($hni, '==', 1,   q{half number of letters integer});
cmp_ok($hnn, '==', 1.5, q{half number of letters numeric});
cmp_ok($hnb, '==', 1,   q{half number of letters boolean});
ok(not(defined $dfc), q{is digits false categorial});
is($dfi, 0, q{is digits false integer});
is($dfn, 0, q{is digits false numeric});
is($dfb, 0, q{is digits false boolean});
is($dtc, '00', q{is digits true categorial});
is($dti, 0,    q{is digits true integer});
is($dtn, 0,    q{is digits true numeric});
is($dtb, 1,    q{is digits true boolean});

undef $featType;

### Values of the features
{
    package FeatVals;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'first_letter', 'values' => ['a' .. 'z'] },
        { name => 'second_letter', 'values' => { map {; $_ => 1 } 'a' .. 'z' } },
        { name => 'third_letter', 'values' => ['a' .. 'z'], default => '_' },
        { name => 'fourth_letter', values_file => 'lcletters.txt' },
        { name => 'num_letters', range => '2 .. 5', type => 'int' },
        { name => 'half_num_letters', range => '1 .. 2.5', type => 'num', default => '-1' },
        { name => 'no_int_default', range => '1 .. 3', default => 'not_a_number', type => 'int', code => \&num_letters },
        { name => 'succeed', 'values' => ['a' .. 'z', 'A' .. 'Z', 0 .. 9], code => \&first_letter },
    );
    sub first_letter { return substr $_[0], 0, 1 }
    sub second_letter { return substr $_[0], 1, 1 }
    sub third_letter { return substr $_[0], 2, 1 }
    sub fourth_letter { return substr $_[0], 3, 1 }
    sub num_letters { return length $_[0] }
    sub half_num_letters { return length($_[0]) / 2 }
}

catchwarn(qr/^Argument \S+ isn't numeric in int/, 1);
my $featVals = FeatVals->new;
is(ref($featVals), 'FeatVals', q{instantiated FeatVals});
is($WARNINGS, 1, q{warned about non-numeric default for integer feature});

my ($letter) = $featVals->evaluate('first_letter', 'normal', 'word');
is($letter, 'w', q{legal value given by ordered "values"});
catchwarn(qr/Feature '.+?' returned unexpected value '.*?' on arguments '.*?'/);
my @empty = $featVals->evaluate([qw(first_letter succeed)], 'normal', 'WORD');
is(scalar(@empty), 0, q{illegal value given by ordered "values"});
is($WARNINGS, 1, q{warned about unexpected value of a feature (1)});

($letter) = $featVals->evaluate('second_letter', 'normal', 'word');
is($letter, 'o', q{legal value given by hashed "values"});
catchwarn(qr/Feature '.+?' returned unexpected value '.*?' on arguments '.*?'/);
@empty = $featVals->evaluate([qw(second_letter succeed)], 'normal', 'WORD');
is(scalar(@empty), 0, q{illegal value given by hashed "values"});
is($WARNINGS, 1, q{warned about unexpected value of a feature (2)});

($letter) = $featVals->evaluate('third_letter', 'normal', 'word');
is($letter, 'r', q{legal value given by "values" with default});
($letter, @empty) = $featVals->evaluate('third_letter', 'normal', 'WORD');
is(scalar(@empty), 0, q{default returned single value});
is($letter, '_', q{returning default value worked});

($letter) = $featVals->evaluate('fourth_letter', 'normal', 'word');
is($letter, 'd', q{legal value given in file});
catchwarn(qr/Feature '.+?' returned unexpected value '.*?' on arguments '.*?'/);
@empty = $featVals->evaluate([qw(fourth_letter succeed)], 'normal', 'WORD');
is(scalar(@empty), 0, q{illegal value given in file});
is($WARNINGS, 1, q{warned about unexpected value of a feature (3)});

my ($num) = $featVals->evaluate('num_letters', 'normal', 'word');
is($num, 4, q{legal value given by integer range});
catchwarn(qr/Feature '.+?' returned unexpected value '.*?' on arguments '.*?'/);
@empty = $featVals->evaluate([qw(num_letters succeed)], 'normal', 'gibberish');
is(scalar(@empty), 0, q{illegal value given by integer range});
is($WARNINGS, 1, q{warned about unexpected value of a feature (4)});

($num) = $featVals->evaluate('half_num_letters', 'normal', 'world');
cmp_ok($num, '==', 2.5, q{legal value given by numeric range});
($num) = $featVals->evaluate('half_num_letters', 'normal', 'gibberish');
cmp_ok($num, '==', -1, q{default value for exceeding numeric range});

($num) = $featVals->evaluate('no_int_default', 'normal', 'long_word');
is($num, 0, q{numeric feature's default value converted to number});

undef $featVals;

{
    package ValuesFile2g4;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'defunct', 'values' => ['a', 'b'], values_file => '' },
    );
    sub defunct {
        Test::More::diag "This should never be printed!!! (".__PACKAGE__.")\n";
        return
    }
}

undef $@;
$expected_message = "Values specified both explicitly and by file for 'defunct'";
eval { ValuesFile2g4->new };
is(substr($@, 0, length $expected_message), $expected_message, q{values and file together croaked});

{
    package ValuesRange2g4;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'defunct', 'values' => ['a', 'b'], range => '2 .. 5' },
    );
    sub defunct {
        Test::More::diag "This should never be printed!!! (".__PACKAGE__.")\n";
        return
    }
}

undef $@;
$expected_message = "Both range and values specified for feature 'defunct'";
eval { ValuesRange2g4->new };
is(substr($@, 0, length $expected_message), $expected_message, q{values and range together croaked});

{
    package ValuesfileRange2g4;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'defunct', values_file => 'lcletters.txt', range => '2 .. 5' },
    );
    sub defunct {
        Test::More::diag "This should never be printed!!! (".__PACKAGE__.")\n";
        return
    }
}

undef $@;
$expected_message = "Both range and values specified for feature 'defunct'";
eval { ValuesfileRange2g4->new };
is(substr($@, 0, length $expected_message), $expected_message, q{values file and range together croaked});

{
    package MalformedRange;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'defunct', range => 'no dots here' },
    );
    sub defunct {
        Test::More::diag "This should never be printed!!! (".__PACKAGE__.")\n";
        return
    }
}

undef $@;
$expected_message = "Malformed range 'no dots here' of feature 'defunct'. Should be in format '0 .. 5'";
eval { MalformedRange->new };
is(substr($@, 0, length $expected_message), $expected_message, q{malformed range});

{
    package InvalidRange;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'defunct', range => 'one .. five' },
    );
    sub defunct {
        Test::More::diag "This should never be printed!!! (".__PACKAGE__.")\n";
        return
    }
}

undef $@;
$expected_message = "Invalid range 'one .. five' specified for feature 'defunct'";
catchwarn(qr/^Argument \S+ isn't numeric in addition \(\+\)/, 2);
eval { InvalidRange->new };
is(substr($@, 0, length $expected_message), $expected_message, q{invalid range});
is($WARNINGS, 2, q{warned about non-numbers in range});

{
    package ManyBooleanValues;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'defunct', type => 'bool', 'values' => [1 .. 5] },
    );
    sub defunct {
        Test::More::diag "This should never be printed!!! (".__PACKAGE__.")\n";
        return
    }
}

undef $@;
$expected_message = "More than two values (5) specified for feature 'defunct'";
eval { ManyBooleanValues->new };
is(substr($@, 0, length $expected_message), $expected_message, q{many boolean values});

{
    package TrueTwice;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'defunct', type => 'bool', 'values' => [1, 2] },
    );
}

undef $@;
$expected_message = "True value (literal: '1', '2') for feature 'defunct' specified multiple times";
eval { TrueTwice->new };
is(substr($@, 0, length $expected_message), $expected_message, q{true value twice});

{
    package FalseTwice;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'defunct', type => 'bool', 'values' => [0, ''] },
    );
    sub defunct {
        Test::More::diag "This should never be printed!!! (".__PACKAGE__.")\n";
        return
    }
}

undef $@;
$expected_message = "False value (literal: '0', '') for feature 'defunct' specified multiple times";
eval { FalseTwice->new };
is(substr($@, 0, length $expected_message), $expected_message, q{false value twice});

{
    package RedundantDefault;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'defunct', type => 'bool', 'values' => [0,1], default => 0 },
    );
    sub defunct {
        Test::More::diag "This should never be printed!!! (".__PACKAGE__.")\n";
        return
    }
}

undef $@;
$expected_message = "Default value '0' specified for boolean feature 'defunct' which has both values allowed";
eval { RedundantDefault->new };
is(substr($@, 0, length $expected_message), $expected_message, q{redundant default});

{
    package NegatedDefault;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'defunct', type => 'bool', 'values' => [1], default => 2 },
    );
    sub defunct {
        Test::More::diag "This should never be printed!!! (".__PACKAGE__.")\n";
        return
    }
}

undef $@;
$expected_message = "Default and allowed value are both true for feature 'defunct'";
eval { NegatedDefault->new };
is(substr($@, 0, length $expected_message), $expected_message, q{negated default});

### Postprocessing of the features' return values
{
    package Postproc;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'id', postproc => \&my_die, 'values' => [qw(format:numeric format:binary format:normal)]  },
        { name => 'upcase', postproc => sub { return uc $_[0] }, code => \&id },
        { name => 'wvals', postproc => sub { return uc $_[0] }, code => \&id, values => [qw(word)], default => 'illegal' },
        { name => 'pp_name_local', postproc => 'local_uc', code => \&id },
        { name => 'pp_name_remote', postproc => 'OtherPackage::remote_uc', code => \&id },
        { name => 'pp_name_2load_custom', postproc => 'OuterModule::remote_uc', code => \&id },
        { name => 'pp_name_2load_core', postproc => 'Math::Trig::deg2deg', type => 'num', code => \&id },
    );
    sub my_die {
        die "Postproc occurred while evaluating (param: @_)\n"
    }
    sub id {
        return $_[0]
    }
    sub local_uc {
        return uc $_[0]
    }

    package OtherPackage;
    sub remote_uc {
        return uc $_[0]
    }
}

catchwarn(qr/^Use of uninitialized value in/, 2);
my $postproc = Postproc->new;
catchwarn(undef, 0);

undef $@;
eval { $postproc->evaluate('id', 'numeric', 'format:numeric') };
ok(not ($@), q{postproc didn't occur for numeric format});
if ($@) { diag "Eval error: '$@'" }

undef $@;
eval { $postproc->evaluate('id', 'binary', 'format:binary') };
ok(not ($@), q{postproc didn't occur for binary format});
if ($@) { diag "Eval error: '$@'" }

undef $@;
eval { $postproc->evaluate('id', 'normal', 'format:normal') };
is($@, "Postproc occurred while evaluating (param: format:normal)\n", q{postproc occured for normal format});

my $uc = $postproc->evaluate('upcase', 'normal', 'word');
is($uc, 'WORD', q{postprocessing sub given by code works});

$uc = $postproc->evaluate('pp_name_local', 'normal', 'word');
is($uc, 'WORD', q{postprocessing sub given by unqualified name works});

$uc = $postproc->evaluate('pp_name_remote', 'normal', 'word');
is($uc, 'WORD', q{postprocessing sub given by qualified name works});

$uc = $postproc->evaluate('pp_name_2load_custom', 'normal', 'word');
is($uc, 'WORD', q{postprocessing sub given by qualified name in outer custom package works});

$num = $postproc->evaluate('pp_name_2load_core', 'normal', 540);
is($num, 180, q{postprocessing sub given by qualified name in core package works});

$uc = $postproc->evaluate('wvals', 'normal', 'word');
is($uc, 'WORD', q{value checking done before postprocessing});

my $default = $postproc->evaluate('wvals', 'normal', 'unexpected');
is($default, 'ILLEGAL', q{default value postprocessed});

undef $postproc;

### Accessing the name of the feature inside its code
{
    package FeatureName;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'foo', code => \&code },
        { name => 'bar', code => \&code },
    );
    sub code {
        return $Data::FeatureFactory::CURRENT_FEATURE
    }
}

my $featureName = FeatureName->new;
my ($foo, $bar) = $featureName->evaluate([qw(foo bar)], 'normal', 'arg');
is($foo.':'.$bar, 'foo:bar', q{features know their names});

### Evaluating features in numeric format
{
    package NumFormat;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'num_letters', type => 'int' },
        { name => 'half_letters', type => 'num' },
        { name => 'is_alpha', type => 'bool' },
        { name => 'first_letter', 'values' => ['a' .. 'z'], default => '_' },
        { name => 'second_letter', 'values' => { map {;$_=>1} 'a' .. 'd' }, default => '_' },
        { name => 'third_letter' },
    );
    sub num_letters {
        return length $_[0]
    }
    sub half_letters {
        return length($_[0]) / 2
    }
    sub is_alpha {
        return $_[0] =~ /^\w+$/
    }
    sub first_letter {
        return substr $_[0], 0, 1
    }
    sub second_letter {
        return substr $_[0], 1, 1
    }
    sub third_letter {
        return substr $_[0], 2, 1
    }
}

my $numFormat = NumFormat->new;
$expected_message = q{Unknown format: 'INVALID FORMAT'. Please specify one of:};
undef $@;
eval { $numFormat->evaluate('num_letters', 'INVALID FORMAT', 'word') };
is(substr($@, 0, length $expected_message), $expected_message, q{croaked with invalid format});

($num, my $half, my $bin) = $numFormat->evaluate([qw(num_letters half_letters is_alpha)], 'numeric', 'world');
is($num, 5, q{numeric format won't change integer feature});
cmp_ok($half, '==', 2.5, q{numeric format won't change numeric feature});
is($bin, 1, q{numeric format won't change boolean feature});

my @nums = map $numFormat->evaluate('first_letter', 'numeric', $_), qw(a1 j10 t20 j_10 X27);
is(join(' ', @nums), '1 10 20 10 27', q{numifying with ordered values});

@nums = map $numFormat->evaluate('second_letter', 'numeric', $_), qw(_X _a _b _c _d _Y);
is(join(' ', sort @nums), '1 2 3 4 5 5', q{numifying unordered values});

catchwarn(qr/^Categorial feature '.*?' is about to be evaluated numerically but has no set of values specified/);
@nums = map $numFormat->evaluate('third_letter', 'numeric', $_), qw(__a __s __d __f __s __f);
is($WARNINGS, 1, q{warned about converting valueless feature to numeric (1)});
is(join(' ', @nums), '1 2 3 4 2 4', q{numifying dynamically});
undef $numFormat;

$numFormat = NumFormat->new;
catchwarn(qr/^Categorial feature '.*?' is about to be evaluated numerically but has no set of values specified/);
@nums = map $numFormat->evaluate('third_letter', 'numeric', $_), qw(..e ..a ..o ..s ..e ..a);
is($WARNINGS, 1, q{warned about converting valueless feature to numeric (2)});
is (join(' ', @nums), '5 1 6 2 5 1', q{dynamic mapping to numbers persists});

undef $numFormat;

### Evaluating features in binary format
{
    package BinFormat;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'is_alpha', type => 'bool' },
        { name => 'ident' },
        { name => 'num_letters', type => 'int', range => '1 .. 5' },
        { name => 'first_letter', 'values' => { map {;$_=>1} 'a' .. 'd' }, default => '_' },
    );
    sub is_alpha {
        return $_[0] =~ /^\w+$/
    }
    sub ident {
        return $_[0]
    }
    sub num_letters {
        return length $_[0]
    }
    sub first_letter {
        return substr $_[0], 0, 1
    }
}

my $binFormat = BinFormat->new;
my $bin_digit = $binFormat->evaluate('is_alpha', 'binary', 'word');
is($bin_digit, 1, q{binary format won't change boolean feature});

$expected_message = "Attempted to convert feature 'ident' to binary without specifying its values";
undef $@;
eval { $binFormat->evaluate('ident', 'binary', 'word') };
is(substr($@, 0, length $expected_message), $expected_message, q{croaked evaluating a feature without values in binary format});

my @vector = $binFormat->evaluate([qw(num_letters first_letter)], 'binary', 'word');
is(join(' ', @vector), '0 0 0 1 0 0 0 0 0 1', q{evaluating in binary format with ordered values});

my @vectors = map join(',', $binFormat->evaluate('first_letter', 'binary', $_)), qw(al bob c.j. dan eve);
no warnings 'qw';
my @expected_vectors = qw(
    0,0,0,0,1
    0,0,0,1,0
    0,0,1,0,0
    0,1,0,0,0
    1,0,0,0,0
);
use warnings;
is(join(' ', sort @vectors), join(' ', @expected_vectors), q{evaluating in binary format with unordered values});

undef $binFormat;

### Specifying format as an option of the features
{
    package InvalidFormat;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'defunct', format => 'invalid_format' },
    );
    sub defunct {
        Test::More::diag "This should never be printed!!! (".__PACKAGE__.")\n";
        return
    }
}

$expected_message = "Invalid format 'invalid_format' specified for feature 'defunct'. Please specify 'normal', 'numeric' or 'binary'";
undef $@;
eval { InvalidFormat->new };
is(substr($@, 0, length $expected_message), $expected_message, q{croaked specifying an invalid format});

{
    package BinFormatNoValues;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'defunct', format => 'binary' },
    );
    sub defunct {
        Test::More::diag "This should never be printed!!! (".__PACKAGE__.")\n";
        return
    }
}

$expected_message = "Feature 'defunct' has format: 'binary' specified but doesn't have values specified";
undef $@;
eval { BinFormatNoValues->new };
is(substr($@, 0, length $expected_message), $expected_message, q{croaked on binary format without values});

{
    package Formats;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'unspec',    'values' => ['a' .. 'd'], code => \&first_letter },
        { name => 'protected', 'values' => ['a' .. 'd'], code => \&first_letter, format => 'normal'  },
        { name => 'numeric',   'values' => ['a' .. 'd'], code => \&first_letter, format => 'numeric' },
        { name => 'binary',    'values' => ['a' .. 'd'], code => \&first_letter, format => 'binary'  },
    );
    sub first_letter {
        return substr $_[0], 0, 1
    }
}

my $formats = Formats->new;
@vector = $formats->evaluate([qw(unspec protected numeric binary)], 'normal', 'bob');
is(join(' ', @vector), 'b b 2 0 1 0 0', q{format option works with normal evaluation});

@vector = $formats->evaluate([qw(unspec protected numeric binary)], 'numeric', 'c.j.');
is(join(' ', @vector), '3 c 3 0 0 1 0', q{format option works with numeric evaluation});

@vector = $formats->evaluate([qw(unspec protected numeric binary)], 'binary', 'dan');
is(join(' ', @vector), '0 0 0 1 d 4 0 0 0 1', q{format option works with binary evaluation});

undef $formats;

### Using N/A values
{
    package NA;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'second_letter', 'values' => ['a' .. 'd'] },
        { name => 'nothing' },
        { name => 'const', 'values' => ['c'] },
    );
    sub second_letter {
        my @letters = split //, $_[0];
        return $letters[1]
    }
    sub nothing {
        return
    }
    sub const {
        return 'c'
    }
}

my $na = NA->new({'N/A' => 'X'});

@vector = $na->evaluate([qw(second_letter nothing)], 'normal', 'pass');
is(join(' ', @vector), 'a X', q{N/A value in normal evaluation});

my ($x) = $na->evaluate(q(second_letter), 'numeric', 'A');
is($x, 'X', q{N/A value in numeric evaluation});

@vector = $na->evaluate([qw(second_letter const)], 'binary', 'A');
is(join(' ', @vector), 'X X X X 1', q{N/A value in binary evaluation});

$expected_message = q{Attempted to convert feature 'nothing' to binary without specifying its values};
undef $@;
eval { $na->evaluate('nothing', 'binary', 'arg') };
is(substr($@, 0, length $expected_message), $expected_message, q{croaked on binary format without values when N/A specified});

undef $na;
