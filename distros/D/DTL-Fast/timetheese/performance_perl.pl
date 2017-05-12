use Benchmark qw(:all);

# # speed of shift vs unpacking
# sub myshift{
    # my $var1 = shift;
    # my $var2 = shift;
    # my $var3 = shift;
    # my $var4 = shift;
    # my $var5 = shift;
    # my $var6 = shift;
    # my %kwargs = @_;
    
    # return;
# }

# sub myunpack{
    # my( $var1, $var2, $var3, $var4, $var5, $var6, %kwargs) = @_;
    # return;
# }

# timethese( 3000000, {
    # 'Shift' => sub{ myshift(1,2,3,1,2,3,'a' => 'b', 'c' => 123, 'd' => [1,2,3]); },
    # 'Unpack' => sub{ myunpack(1,2,3,1,2,3,'a' => 'b', 'c' => 123, 'd' => [1,2,3]); },
# });

################### speed of compiled vs inline regexp#########################

# my $reg0 = 'if|this|is|a|test';
# my $reg = qr/($reg0)/s;

# sub precomp_check
# {
    # my $arg = shift;
    # return ${$arg} =~ $reg;
# }

# sub comp_check
# {
    # my $arg = shift;
    # return ${$arg} =~ /($reg0)/s;
# }

# sub precomp_replace
# {
    # my $arg = shift;
    # ${$arg} =~ s/$reg//;
    # return $arg;
# }

# sub comp_replace
# {
    # my $arg = shift;
    # ${$arg} =~ s/($reg0)//s;
    # return $arg;
# }

# my $text = <<'_EOT_' x 1000;
# Hello, this
# is a test message
# for regexp testing
# _EOT_

# #die "Update regexp" if precomp_replace() ne comp_replace();
# #warn precomp_replace($text);

# my $text1 = $text;
# my $text2 = $text;
# my $text3 = $text;
# my $text4 = $text;

# timethese( 1000000, {
    # 'Precomp check  ' => sub{ precomp_check(\$text1); },
    # 'Comp check     ' => sub{ comp_check(\$text2); },
# });

# timethese( 200000, {
    # 'Precomp replace' => sub{ precomp_replace(\$text3); },
    # 'Comp replace   ' => sub{ comp_replace(\$text4); },
# });

############# scalars tossing vas scalars refs #############


sub val_val
{
    my( $arg ) = (@_);
    $arg .= '';
    return $arg;
}

sub ref_val
{
    my( $arg ) = (@_);
    ${$arg}.='';
    return ${$arg};
}

sub ref_ref
{
    my( $arg ) = (@_);
    ${$arg} .= '';
    return $arg;
}

my $text = <<'_EOT_';
Hello, this
is a test message
for regexp testing
_EOT_

my $suffix = 'b' x 100000;
my $test1 = $text.$suffix;
my $test2 = $text.$suffix;
my $test3 = $text.$suffix;
my $test4; 

timethese( 2000000, {
    'Value-Value' => sub{ $test1 = val_val($test1);},
    'Ref-Value  ' => sub{ $test2 = ref_val(\$test2);},
    'Ref-Ref    ' => sub{ $test4 = ref_ref(\$test3);},
});

die "Something is wrong 1 and 2" if $test1 ne $test2;
die "Something is wrong 2 and 3" if $test2 ne $test3;

