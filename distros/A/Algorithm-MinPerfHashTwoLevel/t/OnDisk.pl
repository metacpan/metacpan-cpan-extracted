#########################

use strict;
use warnings;

use Test::More;
use File::Temp;
use Data::Dumper; $Data::Dumper::Sortkeys=1; $Data::Dumper::Useqq=1;

use Tie::Hash::MinPerfHashTwoLevel::OnDisk qw(MAX_VARIANT MIN_VARIANT);

sub slurp {
    my ($file_spec)= @_;
    open my $fh, "<", $file_spec
        or die "failed to read '$file_spec': $!";
    local $/;
    my $data= <$fh>;
    return $data;
}

sub files_eq {
    my ($lfile,$rfile)= @_;
    my $left= slurp($lfile);
    my $right= slurp($rfile);
    my $ret= (defined($left) == defined($right) and defined($right) and $left eq $right);
    if (!$ret) {
        diag (sprintf "'%s' is %s bytes '%s' is %s bytes",
            $lfile => length($left)//'undef', $rfile => length($right)//'undef');
        require Data::Dumper;
        diag Data::Dumper::qquote($left),"\n";
        diag Data::Dumper::qquote($right),"\n";

    }
    return $ret;
}

my $class= 'Tie::Hash::MinPerfHashTwoLevel::OnDisk';
plan tests => 2 + 1830 * (defined($ENV{VARIANT}) ? 1 : MAX_VARIANT - MIN_VARIANT + 1);

my $srand= $ENV{SRAND} ? srand(0+$ENV{SRAND}) : srand();
ok(defined($srand),"srand as expected: $srand");
my $eval_ok= eval {
    tie my(%fail), $class => $0;
    1;
};
my $error= !$eval_ok && $@;
ok($error,"it failed: $@");

my $tmpdir= File::Temp->newdir();

my $not_utf8= "not utf8: \x{DF}";
my $utf8_can_be_downgraded= "was utf8: \x{DF}";
utf8::upgrade($utf8_can_be_downgraded);
my $must_be_utf8= "is utf8: \x{100}"; # this can ONLY be represented as utf8
my @source_hashes= (
    simple => {
        foo => "bar",
        baz => "bop",
        fiz => "shmang",
        plop => "shwoosh",
    },
    large => { map { $_ => $_ } 1 .. 50000 },
    mixed_utf8 => {
        $not_utf8 => $not_utf8,
        $utf8_can_be_downgraded => $utf8_can_be_downgraded,
        $must_be_utf8 => $must_be_utf8,
        map { chr($_) => chr($_) } 240 .. 270,
    },
    pow2_08 =>
    { map { $_ => $_ } 1 .. 8 },
    pow2_16 =>
    { map { $_ => $_ } 1 .. 16 },
    pow2_32 =>
    { map { $_ => $_ } 1 .. 32 },
    pow2_64 =>
    { map { $_ => $_ } 1 .. 64 },

    chr_chr_utf8 =>
    { map { chr($_) => chr($_) } 256 .. 270 },
    chr_num_utf8 =>
    { map { chr($_) => $_ } 256 .. 270 },
    num_chr_utf8 =>
    { map { $_ => chr($_) } 256 .. 270 },
    mix_mix_utf8 =>
    { map { ($_ % 2 ? chr($_) : $_) => ($_ % 2 ? $_ : chr($_)) } 256 .. 270 },
    chr_mix_utf8 =>
    { map { chr($_)                 => ($_ % 2 ? $_ : chr($_)) } 256 .. 270 },
    num_mix_utf8 =>
    { map { $_                      => ($_ % 2 ? $_ : chr($_)) } 256 .. 270 },
    mix_num_utf8 =>
    { map { ($_ % 2 ? chr($_) : $_) => $_                      } 256 .. 270 },
    mix_chr_utf8 =>
    { map { ($_ % 2 ? chr($_) : $_) => chr($_)                 } 256 .. 270 },

);

my $rand_seed= join("",map chr(rand 256), 1..16);
foreach my $seed ("1234567812345678", undef, $rand_seed) {
    foreach my $idx (0 .. (@source_hashes/2)-1) {
        my $name= $source_hashes[$idx*2];
        my $source_hash= $source_hashes[$idx*2+1];
        foreach my $variant (defined($ENV{VARIANT}) ? ($ENV{VARIANT}) : (MIN_VARIANT .. MAX_VARIANT)) {
            foreach my $canonical (0 .. 1) {
                my $seed_str= !defined $seed ? "undef" : unpack("H*",$seed);
                my $title= "$name seed:$seed_str variant:$variant";
                my $test_fn= "test.$seed_str.$idx.$variant.$canonical.hash";
                my $test_file= "$tmpdir/$test_fn";
                my $corpus_file= ($canonical && (!$seed or $seed ne $rand_seed)) ? "t/corpus/$test_fn" : "";
                my $seed_arg= $seed;
                ok(1,"starting testset ($title)");
                #diag "building file $test_file";
                my $got_file;
                my $this_comment= "this is a comment: $title";
                my $eval_ok= eval {
                    $got_file= $class->make_file(
                        file        => $test_file,
                        source_hash => $source_hash,
                        comment     => $this_comment,
                        debug       => $ENV{TEST_VERBOSE},
                        seed        => \$seed_arg,
                        variant     => $variant,
                        canonical   => $canonical,
                    );
                    1;
                };
                my $error= !$eval_ok && $@;
                is($error,"","should be no error ($title)");
                ok($eval_ok,"make_file should not die ($title)");
                if ($eval_ok) {
                    if ($corpus_file) {
                        if (!-e $corpus_file and $ENV{CREATE_CORPUS}) {
                            require File::Copy;
                            File::Copy::copy($test_file,$corpus_file);
                        }
                        #use File::Copy qw(copy); copy($test_file, $corpus_file);
                        ok(files_eq($test_file,$corpus_file),"file is as expected ($title)");
                    }
                    ok(defined($seed_arg),"seed_arg is defined after make_file() ($title)");
                    is( $got_file,$test_file, "make_file returned as expected ($title)" );
                    my ($got_variant,$got_message)= $class->validate_file(file=>$test_file);
                    ok( defined $got_variant, "file validates ok ($title)")
                        or diag $got_message;
                    is( $got_variant, $variant, "file variant ok ($title)");
                    my %tied_hash;
                    tie %tied_hash, $class, $test_file;
                    my $scalar= scalar(%tied_hash);
                    ok($scalar,"scalar works");
                    my $obj= tied(%tied_hash);
                    is($obj->get_comment, $this_comment, "comment works as expected");
                    is($obj->get_hdr_variant, $variant, "variant is as expected");
                    is($obj->get_hdr_num_buckets, 0+keys %$source_hash,"num_buckets is as expected");
                    my @ofs=(
                        $obj->get_hdr_state_ofs,
                        $obj->get_hdr_table_ofs,
                        $obj->get_hdr_key_flags_ofs,
                        $obj->get_hdr_val_flags_ofs,
                        $obj->get_hdr_str_buf_ofs,
                    );
                    my @srt_ofs= sort{ $a <=> $b } @ofs;
                    is("@ofs","@srt_ofs","offsets in the right order");

                    my (@got_keys,@got_fetch_values,@want_keys);
                    {
                        my @bad;
                        foreach my $key (sort keys %$source_hash) {
                            push @want_keys, $key;
                            my $got= $tied_hash{$key};
                            my $want= $source_hash->{$key};
                            if (defined($got) != defined($want) or (defined($got) and $got ne $want)) {
                                push @bad, [$key,$got,$want];
                            }
                        }
                        is(0+@bad,0,"no bad values via source_hash ($title)")
                            or diag Dumper($bad[0]);
                    }
                    {
                        my @bad;
                        foreach my $key (sort keys %tied_hash) {
                            push @got_keys, $key;
                            my $got= $tied_hash{$key};
                            my $want= $source_hash->{$key};
                            if (defined($got) != defined($want) or (defined($got) and $got ne $want)) {
                                push @bad, [$key,$got,$want];
                            }
                            push @got_fetch_values, $got;
                        }
                        is(0+@bad,0,"no bad values via tied_hash ($title)")
                            or diag Dumper($bad[0]);
                    }
                    my @got_values= sort values %tied_hash;
                    my @want_values= sort values %$source_hash;

                    my @got_each_keys;
                    my @got_each_values;
                    while (my($k,$v)= each(%tied_hash)) {
                        push @got_each_keys, $k;
                        push @got_each_values, $v;
                    }
                    @got_fetch_values= sort @got_fetch_values;
                    @got_each_keys= sort @got_each_keys;
                    @got_each_values= sort @got_each_values;

                    is_deeply(\@got_keys,\@want_keys,"keys in both are the same ($title)");
                    is_deeply(\@got_each_keys,\@want_keys,"got_keys and got_each_keys agree ($title)");

                    is_deeply(\@got_values,\@want_values,"got_values and got_each_values agree ($title)");
                    is_deeply(\@got_fetch_values,\@want_values,"values in both are same ($title)");
                    is_deeply(\@got_each_values,\@want_values,"values in both are same ($title)");

                    {
                        my @bad;
                        foreach my $idx (0..$#got_keys) {
                            if (utf8::is_utf8($got_keys[$idx]) != utf8::is_utf8($want_keys[$idx])) {
                                push @bad, [ $got_keys[$idx], $want_keys[$idx] ];
                            }
                        }
                        is(0+@bad,0,"no keys with differing utf8 flags ($title)")
                            or diag Dumper($bad[0]);
                    }

                } else {
                    ok(0,"test cannot pass if make_file dies") for 1..17;
                }
            }
        }
    }
}
1;




