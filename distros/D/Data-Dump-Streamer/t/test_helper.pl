use strict;
use warnings;
use Test::More;
use Data::Dumper;
use vars qw/%Has/;
BEGIN {
    $Has{diff}=!!eval "use Algorithm::Diff qw(sdiff diff); 1";
    $Has{sortkeys}=!!eval "Data::Dumper->new([1])->Sortkeys(1)->Dump()";
}

#$Id: test_helper.pl 26 2006-04-16 15:18:52Z demerphq $#

# all of this is acumulated junk used for making the various test easier.
# as a close inspection shows, this all derives from different periods of
# the module and is pretty nasty/hacky to look at. Slowly id like to convert
# everything over to test_dump() and get rid of same().

sub string_diff {
    my ( $str1, $str2, $title1, $title2 ) = @_;
    $title1 ||= "Got";
    $title2 ||= "Expected";

    my $line = ( caller(2) )[2];

    #print $str1,"\n---\n",$str2;
    my $seq1 = ( ref $str1 ) ? $str1 : [ split /\n/, $str1 ];
    my $seq2 = ( ref $str2 ) ? $str2 : [ split /\n/, $str2 ];

    # im sure theres a more elegant way to do all this as well
    my @array;
    my $are_diff;
    Algorithm::Diff::traverse_sequences(
        $seq1, $seq2,
        {
            MATCH => sub {
                my ( $t, $u ) = @_;
                push @array, [ '=', $seq1->[$t], $t, $u ];
            },
            DISCARD_A => sub {
                my ( $t, $u ) = @_;
                push @array, [ '-', $seq1->[$t], $t, $u ];
                $are_diff++;
            },
            DISCARD_B => sub {
                my ( $t, $u ) = @_;
                push @array, [ '+', $seq2->[$u], $t, $u ];
                $are_diff++;
            },
        }
    );
    return "" unless $are_diff;
    my $return = "-$title1\n+$title2\n";

    #especially this bit.
    my ( $last, $skipped ) = ( "=", 1 );
    foreach ( 0 .. $#array ) {
        my $elem = $array[$_];
        my ( $do, $str, $pos, $eq ) = @$elem;

        if (   $do eq $last
            && $do eq '='
            && ( $_ < $#array && $array[ $_ + 1 ][0] eq "=" || $_ == $#array ) )
        {
            $skipped = 1;
            next;
        }

        $str .= "\n" unless $str =~ /\n\z/;
        if ($skipped) {
            $return .= sprintf( "\@%d,%d (%d)\n", $eq + 1, $pos + 1, $line + $eq + 1 );
            $skipped = 0;
        }
        $last = $do;
        $return .= join ( "", $do, " ", $str );
    }
    return $return;
}

sub capture { \@_ }

sub _similar {
    my ( $str1, $str2, $name, $obj ) = @_;

    s/\s+$//gm for $str1,                          $str2;
    s/\r\n/\n/g for $str1,                         $str2;
    s/\(0x[0-9a-xA-X]+\)/(0xdeadbeef)/g for $str1, $str2;
    my @vars = $str2 =~ m/^(?:my\s*)?(\$\w+)\s*=/gm;

    #warn "@vars";
    my $text = "\n" . $str1;
    my $pat  = "\n" . $str2;

    unless ( like( $text, $pat ) ) {
        if ( $] >= 5.012 ) {
            eval qq{
                use re qw( Debug EXECUTE );
                \$text =~ \$pat;
                1;
            }
              or die $@;
        }
        $obj->diag;
    }
}
sub _same {
    my ( $str1, $str2, $name, $obj ) = @_;

    s/\s+$//gm for $str1,                          $str2;
    s/\r\n/\n/g for $str1,                         $str2;
    s/\(0x[0-9a-xA-X]+\)/(0xdeadbeef)/g for $str1, $str2;
    my @vars = $str2 =~ m/^(?:my\s*)?(\$\w+)\s*=/gm;

    for ($str1, $str2) {
        s/^\s+# use warnings;\n//mg;
        s/^\s+# use strict[^;]*;\n//mg;
        s/# ;/#/g;
    }

    #warn "@vars";
    unless ( ok( "\n" . $str1 eq "\n" . $str2, $name ) ) {
        if ( $str2 =~ /\S/ ) {
            eval {
                print string_diff( "\n" . $str2, "\n" . $str1, "Expected", "Result" );
                print "Got:\n" . $str1 . "\n";
                1;
              }
              or do {
                print "Expected:\n$str2\nGot:\n$str1\n";
              }
        } else {
            print $str1, "\n";
        }
        $obj->diag;
    }
}
{
    my $version="";
    my %errors;
    my @errors=('');

sub _dumper {
    my ($todump)=@_;
    my $dump;
    my $error= "";
    foreach my $use_perl (1) {
        my $warned="";
        local $SIG{__WARN__}=sub { my $err=join ('',@_); $warned.=$err unless $err=~/^Subroutine|Encountered/};
        $dump=eval { scalar Data::Dumper->new( $todump )->Purity(1)->Sortkeys(1)->Quotekeys(1)->Useperl($use_perl)->Dump() };
        if ( !$@ ) {
            normalize($dump);
            return ($dump, $error . $warned);
        } else {
            unless ($version) {
                $version="\tSomething is wrong with Data::Dumper v" . Data::Dumper->VERSION . "\n";
                $error= $version;
            }
            my $msg=$@.$warned;
            unless ($errors{$msg}) {
                (my $err=$msg)=~s/^/\t/g;
                push @errors,$msg;
                $errors{$msg}=$#errors;
                $error.=sprintf "\tData::Dumper (Useperl==$use_perl) Error(%#d):\n\t%s",
                        $#errors,$err;
            } else {
                $error.=sprintf "\tData::Dumper (Useperl==$use_perl) Error %#d\n",$errors{$msg};
            }
            next
        }
    }
    #warn $error;
    return ($dump,$error);
}
}

sub vstr {Data::Dump::Streamer::__vstr(@_)}

our $Clean;

sub normalize {
    my @x=@_;
    foreach (@x) {
        #warn "<before>\n$_</before>\n";
        s/^\s*(no|use).*\n//gm;
        s/^\s*BEGIN\s*\{.*\}\n//gm;
        s/\A(?:\s*(?:#\*\.*)?\n)+//g;
        if (/^\s+(#\s*)/) {
            my $ind=$1;
            s/^\s+$ind//gm;
        }
        s/\(0x[0-9a-fA-F]+\)/(0xdeadbeef)/g;
        s/\r\n/\n/g;
        s/\s+$//gm;
        s{\\\\undef}{\\do { my \$v = \\do { my \$v = undef } }}g
            if $] < 5.020;
        $_.="\n";

        #warn "<after>\n$_</after>\n";
    }
    unless (defined wantarray)  {
        $_[$_-1]=$x[$_-1] for 1..@_;
    }
    wantarray ? @x : $x[0]
}

sub similar {
    goto &_similar unless ref( $_[1] );
    my $name   = shift;
    my $obj    = shift;
    my ($expect,$result) = normalize(shift, scalar $obj->Data(@_)->Out());

    my $main_pass = like( "\n$result", "\n$expect" );
    if ( ! $main_pass ) {
        $obj->diag;
    }

    my @declare=grep { /^[\$\@\%]/ } @{$obj->{declare}};

    my @dump   =map  { /^[\@\%\&]/ ? "\\$_" : $_  } @{$obj->{out_names}};
    my $dumpvars=join ( ",", @dump );

    print $result,"\n" if $name=~/Test/;

    my ($dumper,$error) = _dumper(\@_);
    if ($error) {
        diag( "$name\n$error" ) if $ENV{TEST_VERBOSE};
    }
    if ($dumper) {

        my $result2_eval = $result . "\n" . 'scalar( $obj->Data(' . $dumpvars . ")->Out())\n";
        my $dd_result_eval =
          $result . "\nscalar(Data::Dumper->new("
          . 'sub{\@_}->(' . $dumpvars . ")"
          . ")->Purity(1)->Sortkeys(1)->Quotekeys(1)->"
          . "Useperl(1)->Dump())\n";
        unless ( $obj->Declare ) {
            $dd_result_eval = "my(" . join ( ",", @declare ) . ");\n" . $dd_result_eval;
            $result2_eval   = "my(" . join ( ",", @declare ) . ");\n" . $result2_eval;
        }
        foreach my $test ( [ "Data::Dumper", $dd_result_eval, $dumper ],
                           [ "Data::Dump::Streamer", $result2_eval, $result ] ) {
            my ( $test_name, $eval, $orig ) = @$test;

            my ($warned,$res);
            {
                local $SIG{__WARN__}=sub { my $err=join ('',@_); $warned.=$err unless $err=~/^Subroutine|Encountered/};
                $res  = eval $eval;
                if ($warned) { print "Eval $test_name produced warnings:$warned\n$eval" };
            }
            normalize($res);
            my $fail = 0;
            if ($@) {
                print join "\n", "Failed $test_name eval()", $eval, $@, "";
                $fail = 1;
            } elsif ( $res ne $orig ) {
                print "Failed $test_name second time\n";
                eval { print string_diff( $orig, $res, "Orig", "Result" ) };
                print "Orig:\n$orig\nResult:\n$res\nEval:\n$eval\n";
                $fail = 1;
            }
            $obj->diag if $fail;
            return fail($name) if $fail;
        }
        #print join "\n",$result,$result2,$dumper,$dd_result,"";
    }
    ok( $main_pass, $name )
}

sub same {
    goto &_same unless ref( $_[1] );
    my $name   = shift;
    my $obj    = shift;
    my ($expect,$result) = normalize(shift, scalar $obj->Data(@_)->Out());

    my $main_pass;

    {
        my $r=$result;
        my $e=$expect;


        #warn "@vars";
        $main_pass="\n" . $r eq "\n" . $e;

        unless ( $main_pass ) {
            if ( $e =~ /\S/ ) {
                eval {
                    print string_diff( "\n" . $e, "\n" . $r, "Expected", "Result" );
                    print "$name Got:\n" . $r . "\nEXPECT\n";
                  }
                  or do {
                    print "$name Expected:\n$e\nGot:\n$r\n";
                  }
            } else {
                print $r, "\n";
            }
            $obj->diag;
        }
    }


    my @declare=grep { /^[\$\@\%]/ } @{$obj->{declare}};

    my @dump   =map  { /^[\@\%\&]/ ? "\\$_" : $_  } @{$obj->{out_names}};
    my $dumpvars=join ( ",", @dump );

    print $result,"\n" if $name=~/Test/;

    my ($dumper,$error) = _dumper(\@_);
    if ($error) {
        diag( "$name\n$error" ) if $ENV{TEST_VERBOSE};
    }
    if ($dumper) {

        my $result2_eval = $result . "\n" . 'scalar( $obj->Data(' . $dumpvars . ")->Out())\n";
        my $dd_result_eval =
          $result . "\nscalar(Data::Dumper->new("
          . 'sub{\@_}->(' . $dumpvars . ")"
          . ")->Purity(1)->Sortkeys(1)->Quotekeys(1)->"
          . "Useperl(1)->Dump())\n";
        unless ( $obj->Declare ) {
            $dd_result_eval = "my(" . join ( ",", @declare ) . ");\n" . $dd_result_eval;
            $result2_eval   = "my(" . join ( ",", @declare ) . ");\n" . $result2_eval;
        }
        foreach my $test ( [ "Data::Dumper", $dd_result_eval, $dumper ],
                           [ "Data::Dump::Streamer", $result2_eval, $result ] ) {
            my ( $test_name, $eval, $orig ) = @$test;

            my ($warned,$res);
            {
                local $SIG{__WARN__}=sub { my $err=join ('',@_); $warned.=$err unless $err=~/^Subroutine|Encountered/};
                $res  = eval $eval;
                if ($warned) { print "Eval $test_name produced warnings:$warned\n$eval" };
            }
            normalize($res);
            my $fail = 0;
            if ($@) {
                print join "\n", "Failed $test_name eval()", $eval, $@, "";
                $fail = 1;
            } elsif ( $res ne $orig ) {
                print "Failed $test_name second time\n";
                eval { print string_diff( $orig, $res, "Orig", "Result" ) };
                print "Orig:\n$orig\nResult:\n$res\nEval:\n$eval\n";
                $fail = 1;
            }
            $obj->diag if $fail;
            return fail($name) if $fail;
        }
        #print join "\n",$result,$result2,$dumper,$dd_result,"";
    }
    ok( $main_pass, $name )
}



=pod

test_dump(
           "Name", $obj,
           @vars,
           $expect
         )


=cut

my %Methods=(
                'Data::Dumper'=>'->new(sub{\\@_}->(@_))'.
                                '->Purity(1)'.
                                '->Sortkeys(1)'.
                                '->Quotekeys(1)'.
                                '->Useperl(1)'.
                                '->Dump()',
                'Data::Dump::Streamer'=>'->Data(@_)->Out()',
            );

use constant NO_EVAL=>'';

sub _dmp {
    my $obj=shift;
    my $eval=shift;

    my $class=ref($obj) || $obj;
    my $objname=ref($obj) ? '$obj' : $obj;

    my @lines;
    my $method=$Methods{$class};

    if ($eval) {
        return @$eval if @$eval!=1;
        my ($names,$declare,%arg)=@_;

        my @declare= grep { /^[\$\@\%]/ } @$declare;
        my @to_dump= map  { /^[\@\%\&]/ ? "\\$_" : $_  } @$names;
        my $decl=@$declare ? "my(" . join ( ",", @declare ) . ");" : "";

        push @lines,$decl,$arg{pre_eval},$eval->[0],$arg{post_eval};
        $method=~s/\(\@_\)/"(".join (", ",@to_dump).")"/ge;
    }

    push @lines,"normalize ( scalar $objname$method )";

    my $eval_str=join ";\n",map { !$_ ? () : (s/[\s;]+\z//g || 1) && $_ } @lines;
    #print "\n---\n",$eval_str,"\n---\n";
    my $res;
    {
        my @w;
        {
            local $SIG{__WARN__}=sub { push @w,join "",@_; ""};
            $res=eval $eval_str;
        }
        warn "Test $class$method produced warnings. Code:\n$eval_str\nWarnings:\n".join("\n",@w)."\n"
            if @w;
        return ($res,"$class$method failed dump:\n$eval_str\n$@")
            if $@;
    }
    return ($res);
}

my %ldchar=(u=>'=','+'=>'+','-'=>'-','c'=>'!');
my %mdchar=(u=>'|','+'=>'>','-'=>'<','c'=>'*');

sub _my_diff {
    my ($e,$g,$mode)=@_;

    unless ($Has{diff}) {
        if ($e ne $g) {
            return join "\n","Expected:",$e,"Got:",$g,""
        } else {
            return
        }
    }


    my @exp=split /\n/,$e;
    my @got=split /\n/,$g;


    my $line=0;
    my $diff=0;
    my $lw=length('Expected');
    my $u=3;
    my @buff;
    my @lines=map{
                  if ($_->[0]ne'u') {
                    $diff=1;
                    $u=0;
                  } else {
                    $u++;
                  }
                  $lw=length $_->[1] if $lw < length $_->[1];
                  unshift @$_,$line++;
                  if ($u<3) {
                    my @r=$u==0 && @buff ? (@buff,$_) : ($_);
                    @buff=() unless $u;
                    @r
                  } else {
                    shift @buff if @buff>=2;
                    push @buff,$_;
                    ();
                  }
                 } sdiff(\@exp,\@got);
    my $as_str=join("\n",
                sprintf("%7s%*s%3s%s",'',-$lw,'Expected','','Result'),
                map {
                        sprintf "%4d %1s %*s %1s %s",
                            $_->[0],$ldchar{$_->[1]},
                            -$lw,$_->[2]||'',$mdchar{$_->[1]},
                            $_->[3]||''
                    } @lines)."\n";
    return $diff ? $as_str : '';
}

sub _eq {
    my ($exp,$res,$test,$name)=@_;
    my ($exp_err,$res_err);
    # if they are arrays then they from tests involving _dmp
    # but if they are empty then the test isnt performed and
    # we can forget it
    return 1 if ref $exp and !@$exp or ref($res) and !@$res;
    ($exp,$exp_err)=@$exp if ref $exp;
    ($res,$res_err)=@$res if ref $res;
    # the thing we are trying to compare against was a failure
    # so assume we suceed. (or rather the test cant be counted)
    return 1 if $exp_err;
    # result was a failure
    if ($res_err) {
        if ($test->{verbose}) {
            diag "Error:\n$test->{name} subtest $name:\n",$res_err;
        }
        return 0
    }
    # finally both $exp and $res should hold results
    my $diff=_my_diff($exp,$res);
    if ($diff && $test->{verbose}) {
        diag "Error:\n$test->{name} subtest $name failed to return the expected result:\n",
             $diff
    }
    return !$diff;
}

# eventually id like to move everything over to this.

#    test_dump( {name=>"merlyns test 2",
#                verbose=>1}, $o, ( \\@a ),
#               <<'EXPECT',  );
$::Pre_Eval = "";
$::Post_Eval = "";
$::No_Dumper = 0;
$::No_Redump = 0;

sub test_dump {
    my $test = shift;
    my $obj  = shift;
    my $exp  = normalize(pop @_);
    # vars are now left in @_

    $test = {
                name      => $test,
          }
        unless ref $test;

    $test->{pre_eval}= $::Pre_Eval unless exists $test->{pre_eval};
    $test->{post_eval}= $::Post_Eval unless exists $test->{post_eval};
    $test->{no_dumper}= $::No_Dumper unless exists $test->{no_dumper};
    $test->{no_redump}= $::No_Redump unless exists $test->{no_redump};

    $test->{verbose} = 1
        if not exists $test->{verbose} and $ENV{TEST_VERBOSE};

    $test->{no_dumper} = 1 if !$Has{sortkeys};

    my @res=_dmp($obj,NO_EVAL,@_);

    if (@res==2) {
        diag "Error:\n",$res[1];
        fail($test->{name});
        return
    }

    my $to_dump=$obj->{out_names};
    my $to_decl=$obj->Declare ? [] : $obj->{declare}||[];


    my @dmp  =!$test->{no_dumper}
              ? _dmp('Data::Dumper',NO_EVAL,@_)
              : ();

    if (@dmp==2 and $test->{verbose}) {
        diag "Error:\n",$dmp[1];
    }

    my @reres=!$test->{no_redump}
              ? _dmp($obj,\@res,$to_dump,$to_decl,pre_eval=>$test->{pre_eval},post_eval=>$test->{post_eval})
              : ();

    my @redmp=!$test->{no_redump} && !$test->{no_dumper}
              ? _dmp('Data::Dumper',\@res,$to_dump,$to_decl,pre_eval=>$test->{pre_eval},post_eval=>$test->{post_eval})
              : ();

    my $ok= @dmp<2 &&
            _eq($exp, \@res,$test,"Expected")   &&
            _eq($exp, \@reres,$test,"Second time") &&
            _eq(\@dmp,\@redmp,$test,"Both Dumper's same ");

    unless ($ok) {
        warn "Got <<'EXPECT';\n$res[0]\nEXPECT\n";
    }
    ok( $ok, $test->{name} );
}




1;
