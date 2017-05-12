#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More tests => 37;
use Carp qw(verbose);
use File::Temp;
use File::Basename;
my $PATH;
BEGIN { $PATH = &{ sub { dirname ( (caller)[1] ) } }; }
use lib $PATH;

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

# This is copied from List/MoreUtils.pm
sub zip {
    my $max = -1;
    $max < $#$_  &&  ($max = $#$_)  for @_;

    map { my $ix = $_; map $_->[$ix], @_; } 0..$max;
}

{
    package Basic;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'first_letter', 'values' => ['V' .. 'Z'], postproc => sub { return '_'.$_[0].'_' } },
        { name => 'second_letter', 'values' => ['m' .. 'q'], format => 'normal' },
        { name => 'num_letters', type => 'integer', range => '1 .. 5' },
        { name => 'bin_letters', type => 'integer', range => '1 .. 5', format => 'binary', code => \&num_letters },
        { name => 'upcase', type => 'boolean' },
        { name => 'id', label => 'skipped' },
    );
    sub first_letter {
        return uc substr $_[0], 0, 1
    }
    sub second_letter {
        return lc substr $_[0], 1, 1
    }
    sub num_letters {
        my $l = length $_[0];
        return $l <= 5 ? $l : undef
    }
    sub upcase {
        return $_[0] =~ /^[[:upper:]]+$/ ? 1 : 0
    }
    sub id {
        return $_[0]
    }
}

my $names = '-SKIPPED';

my $basic = Basic->new;
my @normal  = $basic->evaluate($names, 'normal',  'word');
my @numeric = $basic->evaluate($names, 'numeric', 'word');
my @binary  = $basic->evaluate($names, 'binary',  'word');

is(join(' ', @normal), '_W_ o 4 0 0 0 1 0 0', q{normal evaluation});
is(join(' ', @numeric), '2 o 4 0 0 0 1 0 0', q{numeric evaluation});
is(join(' ', @binary), '0 1 0 0 0 o 0 0 0 1 0 0 0 0 1 0 0', q{binary evaluation});

my @norm2norm = $basic->translate_row($names, [@normal], {from_format => 'normal', to_format => 'normal'});
my @norm2num  = $basic->translate_row($names, [@normal], {from_format => 'normal', to_format => 'numeric'});
my @norm2bin  = $basic->translate_row($names, [@normal], {from_format => 'normal', to_format => 'binary'});

is_deeply(\@norm2norm, \@normal, q{translating row normal to normal});
is_deeply(\@norm2num, \@numeric, q{translating row normal to numeric});
is_deeply(\@norm2bin, \@binary,  q{translating row normal to binary});

my @num2norm = $basic->translate_row($names, [@numeric], {from_format => 'numeric', to_format => 'normal'});
my @num2num  = $basic->translate_row($names, [@numeric], {from_format => 'numeric', to_format => 'numeric'});
my @num2bin  = $basic->translate_row($names, [@numeric], {from_format => 'numeric', to_format => 'binary'});

is_deeply(\@num2norm, \@normal, q{translating row numeric to normal});
is_deeply(\@num2num, \@numeric, q{translating row numeric to numeric});
is_deeply(\@num2bin, \@binary,  q{translating row numeric to binary});

my @bin2norm = $basic->translate_row($names, [@binary], {from_format => 'binary', to_format => 'normal'});
my @bin2num  = $basic->translate_row($names, [@binary], {from_format => 'binary', to_format => 'numeric'});
my @bin2bin  = $basic->translate_row($names, [@binary], {from_format => 'binary', to_format => 'binary'});

is_deeply(\@bin2norm, \@normal, q{translating row binary to normal});
is_deeply(\@bin2num, \@numeric, q{translating row binary to numeric});
is_deeply(\@bin2bin, \@binary,  q{translating row binary to binary});

undef $basic;

{
    package NA;
    use base qw(Data::FeatureFactory);
    our @features = (
        { name => 'third_letter', 'values' => ['a' .. 'e'] },
        { name => 'num_digits', type => 'integer', range => '1 .. 5' },
        { name => 'upcase', type => 'boolean' },
    );
    sub third_letter {
        return substr($_[0], 2, 1) || undef
    }
    sub num_digits {
        return undef if length $_[0] == 0;
        return scalar grep /\d/, split //, $_[0]
    }
    sub upcase {
        my $c = substr $_[0], 0, 1;
        if (not defined $c) { return undef }
        if (uc $c eq lc $c) { return undef }
        if ($c eq lc $c)    { return 0 }
        if ($c eq uc $c)    { return 1 }
        return undef
    }
}

my $na = NA->new({'N/A' => 'N/A'});

@normal = $na->evaluate('ALL', 'normal', '21');
is_deeply(\@normal, ['N/A', 2, 'N/A'], q{evaluating with N/A pat.101});
@norm2norm = $na->translate_row('ALL', [@normal], {from_format => 'normal', to_format => 'normal', to_NA => 'XX'});
is_deeply(\@norm2norm, ['XX', 2, 'XX'], q{translating row to norm with to_NA});
@norm2num = $na->translate_row('ALL', [@norm2norm], {from_format => 'normal', to_format => 'numeric', from_NA => 'XX'});
is_deeply(\@norm2num, \@normal, q{translating row to num with from_NA});
@norm2bin = $na->translate_row('ALL', [@norm2norm], {from_format => 'normal', to_format => 'binary', from_NA => 'XX', to_NA => 'YY'});
is_deeply(\@norm2bin, [(('YY') x 5), 0, 1, 0, 0, 0, 'YY'], q{translating row to binary with from_ and to_NA});
@bin2num = $na->translate_row('ALL', [@norm2bin], {from_format => 'binary', to_format => 'numeric', from_NA => 'YY'});
is_deeply(\@bin2num, \@normal, q{translating row from binary with from_NA});

undef $na;

use __Example;

my $norm_fh = File::Temp->new();
my $num_fh  = File::Temp->new();
my $bin_fh  = File::Temp->new();

my $norm_vals_fh = File::Temp->new();
my $num_vals_fh  = File::Temp->new();

my $exfeats = Data::FeatureFactory::Example->new({'N/A' => 'XX'});

no warnings qw(qw);
my @args = qw(I am 1 100 000 years old , wtf ???);
use warnings;

catchwarn(qr/^Categorial feature '.*?' is about to be evaluated numerically but has no set of values specified/);
for my $arg (@args) {
    print {$norm_fh} join(' ', $exfeats->evaluate('ALL', 'normal',  $arg)), "\n";
    print {$num_fh}  join(' ', $exfeats->evaluate('ALL', 'numeric', $arg)), "\n";
    print {$bin_fh}  join(' ', $exfeats->evaluate('-NOVALS', 'binary',  $arg)), "\n";
    print {$norm_vals_fh} join(' ', $exfeats->evaluate('-NOVALS', 'normal',  $arg)), "\n";
    print {$num_vals_fh}  join(' ', $exfeats->evaluate('-NOVALS', 'numeric', $arg)), "\n";
}
is($WARNINGS, 1, q{warned about converting valueless feature to numeric (3)});
seek($norm_fh, 0, 0);
seek($num_fh,  0, 0);
seek($bin_fh,  0, 0);
seek($norm_vals_fh, 0, 0);
seek($num_vals_fh,  0, 0);
my $normal  = do { local $/; <$norm_fh> };
my $numeric = do { local $/; <$num_fh>  };
my $binary  = do { local $/; <$bin_fh>  };
my $normal_vals  = do { local $/; <$norm_vals_fh> };
my $numeric_vals = do { local $/; <$num_vals_fh>  };

my $norm2norm_fh = File::Temp->new;
seek($norm_fh, 0, 0);
$exfeats->translate($norm_fh, $norm2norm_fh, {from_format => 'normal', to_format => 'normal', FS => ' ', names => 'ALL'});
seek($norm2norm_fh, 0, 0);
my $norm2norm = do { local $/; <$norm2norm_fh> };
undef $norm2norm_fh;

is($norm2norm, $normal, q{translating normal to normal});

my $norm2num_fh = File::Temp->new;
seek($norm_fh, 0, 0);
$exfeats->translate($norm_fh, $norm2num_fh, {from_format => 'normal', to_format => 'numeric', FS => ' ', names => 'ALL'});
seek($norm2num_fh, 0, 0);
my $norm2num = do { local $/; <$norm2num_fh> };
undef $norm2num_fh;

is($norm2num, $numeric, q{translating normal to numeric});

my $norm2bin_fh = File::Temp->new;
seek($norm_vals_fh, 0, 0);
$exfeats->translate($norm_vals_fh, $norm2bin_fh, {from_format => 'normal', to_format => 'binary', FS => ' ', names => '-NOVALS'});
seek($norm2bin_fh, 0, 0);
my $norm2bin = do { local $/; <$norm2bin_fh> };
undef $norm2bin_fh;

is($norm2bin, $binary, q{translating normal to binary});

my $num2norm_fh = File::Temp->new;
seek($num_fh, 0, 0);
$exfeats->translate($num_fh, $num2norm_fh, {from_format => 'numeric', to_format => 'normal', FS => ' ', names => 'ALL'});
seek($num2norm_fh, 0, 0);
my $num2norm = do { local $/; <$num2norm_fh> };
undef $num2norm_fh;

is($num2norm, $normal, q{translating numeric to normal});

my $num2num_fh = File::Temp->new;
seek($num_fh, 0, 0);
$exfeats->translate($num_fh, $num2num_fh, {from_format => 'numeric', to_format => 'numeric', FS => ' ', names => 'ALL'});
seek($num2num_fh, 0, 0);
my $num2num = do { local $/; <$num2num_fh> };
undef $num2num_fh;

is($num2num, $numeric, q{translating numeric to numeric});

my $num2bin_fh = File::Temp->new;
seek($num_vals_fh, 0, 0);
$exfeats->translate($num_vals_fh, $num2bin_fh, {from_format => 'numeric', to_format => 'binary', FS => ' ', names => '-NOVALS'});
seek($num2bin_fh, 0, 0);
my $num2bin = do { local $/; <$num2bin_fh> };
undef $num2bin_fh;

is($num2bin, $binary, q{translating numeric to binary});

my $bin2norm_fh = File::Temp->new;
seek($bin_fh, 0, 0);
$exfeats->translate($bin_fh, $bin2norm_fh, {from_format => 'binary', to_format => 'normal', FS => ' ', names => '-NOVALS'});
seek($bin2norm_fh, 0, 0);
my $bin2norm = do { local $/; <$bin2norm_fh> };
undef $bin2norm_fh;

is($bin2norm, $normal_vals, q{translating binary to normal});

my $bin2num_fh = File::Temp->new;
seek($bin_fh, 0, 0);
$exfeats->translate($bin_fh, $bin2num_fh, {from_format => 'binary', to_format => 'numeric', FS => ' ', names => '-NOVALS'});
seek($bin2num_fh, 0, 0);
my $bin2num = do { local $/; <$bin2num_fh> };
undef $bin2num_fh;

is($bin2num, $numeric_vals, q{translating binary to numeric});

my $bin2bin_fh = File::Temp->new;
seek($bin_fh, 0, 0);
$exfeats->translate($bin_fh, $bin2bin_fh, {from_format => 'binary', to_format => 'binary', FS => ' ', names => '-NOVALS'});
seek($bin2bin_fh, 0, 0);
my $bin2bin = do { local $/; <$bin2bin_fh> };
undef $bin2bin_fh;

is($bin2bin, $binary, q{translating binary to binary});

$norm2bin_fh = File::Temp->new;
seek($norm_vals_fh, 0, 0);
$exfeats->translate($norm_vals_fh, $norm2bin_fh, {from_format => 'normal', to_format => 'binary', FS => ' ', names => '-NOVALS', to_NA => 'YY'});
seek($norm2bin_fh, 0, 0);
$norm2bin = do { local $/; <$norm2bin_fh> };
(my $expected = $binary) =~ s/\bXX\b/YY/g;

is($norm2bin, $expected, q{translating with to_NA});

$bin2num_fh = File::Temp->new;
seek($norm2bin_fh, 0, 0);
$exfeats->translate($norm2bin_fh, $bin2num_fh, {
    from_format => 'binary', to_format => 'numeric', FS => ' ', names => '-NOVALS', from_NA => 'YY', to_NA => 'ZZ',
});
undef $norm2bin_fh;
seek($bin2num_fh, 0, 0);
$bin2num = do { local $/; <$bin2num_fh> };
($expected = $numeric_vals) =~ s/\bXX\b/ZZ/g;

is($bin2num, $expected, q{translating with from_NA and to_NA});

$num2norm_fh = File::Temp->new;
seek($bin2num_fh, 0, 0);
$exfeats->translate($bin2num_fh, $num2norm_fh, {from_format => 'numeric', to_format => 'normal', FS => ' ', names => '-NOVALS', from_NA => 'ZZ'});
undef $bin2num_fh;
seek($num2norm_fh, 0, 0);
$num2norm = do { local $/; <$num2norm_fh> };
undef $num2norm_fh;

is($num2norm, $normal_vals, q{translating with from_NA});

$norm2num_fh = File::Temp->new;
seek($norm_fh, 0, 0);
$exfeats->translate($norm_fh, $norm2num_fh, {from_format => 'normal', to_format => 'numeric', FS => ' ', OFS => "\t", names => 'ALL'});
seek($norm2num_fh, 0, 0);
$norm2num = do { local $/; <$norm2num_fh> };
undef $norm2num_fh;
($expected = $numeric) =~ tr/ /\t/;

is($norm2num, $expected, q{translating with OFS});

$bin2norm_fh = File::Temp->new;
seek($bin_fh, 0, 0);
$exfeats->translate($bin_fh, $bin2norm_fh, {from_format => 'binary', to_format => 'normal', FS => ' ', OFS => ';', to_NA => '_', names => '-NOVALS'});
seek($bin2norm_fh, 0, 0);
$bin2norm = do { local $/; <$bin2norm_fh> };
undef $bin2norm_fh;
($expected = $normal_vals) =~ s/\bXX\b/_/g;
$expected =~ tr/ /;/;

is($bin2norm, $expected, q{translating with to_NA and OFS});

my $normhead_fh = File::Temp->new;
my $header = do {
    my @names = $exfeats->names;
    splice @names, 1, 0, ('') x 5;
    join(' ', @names)."\n"
};
print {$normhead_fh} $header;
seek($norm_fh, 0, 0);
print {$normhead_fh} <$norm_fh>;
seek($normhead_fh, 0, 0);
$norm2num_fh = File::Temp->new;
$exfeats->translate($normhead_fh, $norm2num_fh, {from_format => 'normal', to_format => 'numeric', FS => ' ', header => 1});
undef $normhead_fh;
seek($norm2num_fh, 0, 0);
$norm2num = do { local $/; <$norm2num_fh> };
undef $norm2num_fh;

is($norm2num, $header.$numeric, q{translating with header});

my $norm_with_ballast1_fh = File::Temp->new;
my $num_with_ballast1_fh  = File::Temp->new;
my $bin_with_ballast1_fh  = File::Temp->new;
my $norm_with_ballastN_fh = File::Temp->new;
my $num_with_ballastN_fh  = File::Temp->new;
my $bin_with_ballastN_fh  = File::Temp->new;
my @names = qw(first_digit capped letter1 letter2);
my $i = 0;
my @ballast_names = map { 'Ballast'.++$i } @names;
my $header1norm = join(' ', "Ballast", @names) . "\n";
my $header1bin  = 'Ballast first_digit' . ' 'x10 . 'capped letter1' . ' 'x27 . "letter2\n";
my $headerNnorm = join(' ', zip \@names, \@ballast_names) . "\n";
my $headerNbin  = 'first_digit' . ' 'x10 . 'Ballast1 capped Ballast2 letter1' . ' 'x27 . 'Ballast3 letter2' . ' 'x27 . "Ballast4\n";
print {$norm_with_ballast1_fh} $header1norm;
print {$num_with_ballast1_fh } $header1norm;
print {$bin_with_ballast1_fh } $header1bin;
print {$norm_with_ballastN_fh} $headerNnorm;
print {$num_with_ballastN_fh } $headerNnorm;
print {$bin_with_ballastN_fh } $headerNbin;
for my $arg (@args) {
    my @normvals = $exfeats->evaluate([@names], 'normal',  $arg);
    my @numvals  = $exfeats->evaluate([@names], 'numeric', $arg);
    my @binvals  = $exfeats->evaluate([@names], 'binary',  $arg);
    print {$norm_with_ballast1_fh} join(' ', "Ballast", @normvals), "\n";
    print {$num_with_ballast1_fh } join(' ', "Ballast", @numvals ), "\n";
    print {$bin_with_ballast1_fh } join(' ', "Ballast", @binvals ), "\n";
    print {$norm_with_ballastN_fh} join(' ', zip \@normvals, \@ballast_names), "\n";
    print {$num_with_ballastN_fh } join(' ', zip \@numvals,  \@ballast_names), "\n";
    my @binbalN;
    my @ballast_names = @ballast_names;
    for my $name (@names) {
        push (
            @binbalN,
            Data::FeatureFactory::_shift_value($exfeats->{'feat_named'}{ $name }, 'binary', \@binvals),
            shift @ballast_names
        );
    }
    print {$bin_with_ballastN_fh } join(' ', @binbalN), "\n";
}
for (
    $norm_with_ballast1_fh, $num_with_ballast1_fh, $bin_with_ballast1_fh,
    $norm_with_ballastN_fh, $num_with_ballastN_fh, $bin_with_ballastN_fh)
{
    seek($_, 0, 0);
}
my $norm_with_ballast1 = do { local $/; <$norm_with_ballast1_fh> };
my $num_with_ballast1  = do { local $/; <$num_with_ballast1_fh>  };
my $bin_with_ballast1  = do { local $/; <$bin_with_ballast1_fh>  };
my $norm_with_ballastN = do { local $/; <$norm_with_ballastN_fh> };
my $num_with_ballastN  = do { local $/; <$num_with_ballastN_fh>  };
my $bin_with_ballastN  = do { local $/; <$bin_with_ballastN_fh>  };

$norm2num_fh = File::Temp->new;
seek($norm_with_ballast1_fh, 0, 0);
scalar <$norm_with_ballast1_fh>;
$exfeats->translate($norm_with_ballast1_fh, $norm2num_fh, {from_format => 'normal', to_format => 'numeric', FS => ' ', names => [@names], ignore => 0});
undef $norm_with_ballast1_fh;
seek($norm2num_fh, 0, 0);
$norm2num = do { local $/; <$norm2num_fh> };
undef $norm2num_fh;

is($header1norm.$norm2num, $num_with_ballast1, q{one column to ignore, no header});

$num2bin_fh = File::Temp->new;
seek($num_with_ballast1_fh, 0, 0);
$exfeats->translate($num_with_ballast1_fh, $num2bin_fh, {from_format => 'numeric', to_format => 'binary', FS => ' ', header => 1, ignore => 0});
undef $num_with_ballast1_fh;
seek($num2bin_fh, 0, 0);
$num2bin = do { local $/; <$num2bin_fh> };
undef $num2bin_fh;

is($num2bin, $bin_with_ballast1, q{one column to ignore, with header});

$norm2bin_fh = File::Temp->new;
seek($norm_with_ballastN_fh, 0, 0);
scalar <$norm_with_ballastN_fh>;
$exfeats->translate($norm_with_ballastN_fh, $norm2bin_fh, {
    from_format => 'normal', to_format => 'binary', FS => ' ', names => [@names], ignore => [1, 3, 5]});
undef $norm_with_ballastN_fh;
seek($norm2bin_fh, 0, 0);
$norm2bin = do { local $/; <$norm2bin_fh> };
undef $norm2bin_fh;

is($headerNbin.$norm2bin, $bin_with_ballastN, q{many columns to ignore, no header});

$bin2num_fh = File::Temp->new;
seek($bin_with_ballastN_fh, 0, 0);
$exfeats->translate($bin_with_ballastN_fh, $bin2num_fh, {from_format => 'binary', to_format => 'numeric', FS => ' ', header => 1, ignore => [1,3,5,7]});
undef $bin_with_ballastN_fh;
seek($bin2num_fh, 0, 0);
$bin2num = do { local $/; <$bin2num_fh> };
undef $bin2num_fh;

is($bin2num, $num_with_ballastN, q{many columns to ignore, with header});
