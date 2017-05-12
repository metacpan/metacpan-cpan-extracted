use warnings;
use strict;
use Test::More tests => 32;

use lib qw(blib/lib blib/arch ../blib/lib ../blib/arch);
BEGIN {
    use_ok 'Data::Dumper';
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Useqq = 1;
    $Data::Dumper::Indent = 1;
    use_ok 'Data::StreamDeserializer';
};


sub compare_object($$);
sub compare_object($$)
{
    my ($o1, $o2) = @_;
    return 0 unless ref($o1) eq ref $o2;
    return 1 if !defined($o1) and !defined($o2);
    return $o1 eq $o2 unless ref $o1;                        # SCALAR
    return $o1 eq $o2 if 'Regexp' eq ref $o1;                # Regexp
    return compare_object $$o1, $$o2 if 'SCALAR' eq ref $o1; # SCALARREF
    return compare_object $$o1, $$o2 if 'REF' eq ref $o1;    # REF

    if ('ARRAY' eq ref $o1 or "$o1" =~ /=ARRAY\(/) {
        return 0 unless @$o1 == @$o2;
        for (0 .. $#$o1) {
            return 0 unless compare_object $o1->[$_], $o2->[$_];
        }
        return 1;
    }

    if ('HASH' eq ref $o1 or "$o1" =~ /=HASH\(/) {
        return 0 unless keys(%$o1) == keys %$o2;

        for (keys %$o1) {
            return 0 unless exists $o2->{$_};
            return 0 unless compare_object $o1->{$_}, $o2->{$_};
        }
        return 1;
    }

    die ref $o1;
}


sub one_test($;$) {
    my ($string, $tail) = @_;

    $tail = '' unless @_ > 1;

    my $warn_error = 0;

    local $SIG{__WARN__} = sub {
        diag @_;
        $warn_error = 1;
    };

    my @dres = eval $string;
    my $dwarn = $warn_error;
    my $derr = $@;

    $warn_error = 0;

    my $ds1 = Data::StreamDeserializer->_low_level_new;
    my $ds2 = Data::StreamDeserializer->_low_level_new;
    my $ds3 = Data::StreamDeserializer->_low_level_new;
    $ds3->{block_size} = 10;


    $ds1->{data} = $string;
    1 until $ds1->_ds_look_tail;

    for (0 .. length $string) {
        $ds2->{data} = substr $string, 0, $_;
        1 until $ds2->_ds_look_tail;
    }

    $ds3->{data} = $string;
    1 until $ds3->_ds_look_tail;

    my %h1 = %$ds1;
    my %h2 = %$ds2;
    my %h3 = %$ds3;
    for (qw(block_size counter data tail seen)) {
        delete $h1{$_};
        delete $h2{$_};
        delete $h3{$_};
    }

    ok compare_object(\%h1, \%h2),
        "First and second serializers returned the same";

    note explain  [ \%h1, \%h3]  unless
    ok compare_object(\%h1, \%h3),
        "Second and third serializers returned the same";

    ok !$warn_error, "There was no warning during test";


    diag Dumper([$derr, \@dres, $ds1]) unless
    ok( ($derr && $ds1->{mode}<0) ||
        ($ds1->{mode}>0 && !$derr) ||
        ($derr && length $ds1->{tail}),
        "eval and _ds_look_tail returned the same error status"
    );

    diag Dumper( [$ds1->{tail}, $tail ]) unless
    ok $tail eq $ds1->{tail}, "Unparsed tail is the same as expected";
}


one_test q@ { "1" => +233, -3 => qr{^(abc|bcd)}, "undef" => undef } @;
one_test q{ "123", 234, ++345, 789 }, "++345, 789 ";
one_test q{ \\123 };
one_test q@ [], {}, { 'a' => [ qq( b c d ) ] }  @;
one_test q! [ "bcd\nd", ] ], 123 !, '], 123 ';
one_test q! "aakalakl!, '"aakalakl';
