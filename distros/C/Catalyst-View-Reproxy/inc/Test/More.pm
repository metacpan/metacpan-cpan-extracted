#line 1
package Test::More;

use 5.004;

use strict;
use Test::Builder;


# Can't use Carp because it might cause use_ok() to accidentally succeed
# even though the module being used forgot to use Carp.  Yes, this
# actually happened.
sub _carp {
    my($file, $line) = (caller(1))[1,2];
    warn @_, " at $file line $line\n";
}



require Exporter;
use vars qw($VERSION @ISA @EXPORT %EXPORT_TAGS $TODO);
$VERSION = '0.54';
$VERSION = eval $VERSION;    # make the alpha version come out as a number

@ISA    = qw(Exporter);
@EXPORT = qw(ok use_ok require_ok
             is isnt like unlike is_deeply
             cmp_ok
             skip todo todo_skip
             pass fail
             eq_array eq_hash eq_set
             $TODO
             plan
             can_ok  isa_ok
             diag
            );

my $Test = Test::Builder->new;
my $Show_Diag = 1;


# 5.004's Exporter doesn't have export_to_level.
sub _export_to_level
{
      my $pkg = shift;
      my $level = shift;
      (undef) = shift;                  # redundant arg
      my $callpkg = caller($level);
      $pkg->export($callpkg, @_);
}


#line 177

sub plan {
    my(@plan) = @_;

    my $idx = 0;
    my @cleaned_plan;
    while( $idx <= $#plan ) {
        my $item = $plan[$idx];

        if( $item eq 'no_diag' ) {
            $Show_Diag = 0;
        }
        else {
            push @cleaned_plan, $item;
        }

        $idx++;
    }

    $Test->plan(@cleaned_plan);
}

sub import {
    my($class) = shift;

    my $caller = caller;

    $Test->exported_to($caller);

    my $idx = 0;
    my @plan;
    my @imports;
    while( $idx <= $#_ ) {
        my $item = $_[$idx];

        if( $item eq 'import' ) {
            push @imports, @{$_[$idx+1]};
            $idx++;
        }
        else {
            push @plan, $item;
        }

        $idx++;
    }

    plan(@plan);

    __PACKAGE__->_export_to_level(1, __PACKAGE__, @imports);
}


#line 295

sub ok ($;$) {
    my($test, $name) = @_;
    $Test->ok($test, $name);
}

#line 359

sub is ($$;$) {
    $Test->is_eq(@_);
}

sub isnt ($$;$) {
    $Test->isnt_eq(@_);
}

*isn't = \&isnt;


#line 400

sub like ($$;$) {
    $Test->like(@_);
}


#line 414

sub unlike ($$;$) {
    $Test->unlike(@_);
}


#line 452

sub cmp_ok($$$;$) {
    $Test->cmp_ok(@_);
}


#line 486

sub can_ok ($@) {
    my($proto, @methods) = @_;
    my $class = ref $proto || $proto;

    unless( @methods ) {
        my $ok = $Test->ok( 0, "$class->can(...)" );
        $Test->diag('    can_ok() called with no methods');
        return $ok;
    }

    my @nok = ();
    foreach my $method (@methods) {
        local($!, $@);  # don't interfere with caller's $@
                        # eval sometimes resets $!
        eval { $proto->can($method) } || push @nok, $method;
    }

    my $name;
    $name = @methods == 1 ? "$class->can('$methods[0]')" 
                          : "$class->can(...)";
    
    my $ok = $Test->ok( !@nok, $name );

    $Test->diag(map "    $class->can('$_') failed\n", @nok);

    return $ok;
}

#line 543

sub isa_ok ($$;$) {
    my($object, $class, $obj_name) = @_;

    my $diag;
    $obj_name = 'The object' unless defined $obj_name;
    my $name = "$obj_name isa $class";
    if( !defined $object ) {
        $diag = "$obj_name isn't defined";
    }
    elsif( !ref $object ) {
        $diag = "$obj_name isn't a reference";
    }
    else {
        # We can't use UNIVERSAL::isa because we want to honor isa() overrides
        local($@, $!);  # eval sometimes resets $!
        my $rslt = eval { $object->isa($class) };
        if( $@ ) {
            if( $@ =~ /^Can't call method "isa" on unblessed reference/ ) {
                if( !UNIVERSAL::isa($object, $class) ) {
                    my $ref = ref $object;
                    $diag = "$obj_name isn't a '$class' it's a '$ref'";
                }
            } else {
                die <<WHOA;
WHOA! I tried to call ->isa on your object and got some weird error.
This should never happen.  Please contact the author immediately.
Here's the error.
$@
WHOA
            }
        }
        elsif( !$rslt ) {
            my $ref = ref $object;
            $diag = "$obj_name isn't a '$class' it's a '$ref'";
        }
    }
            
      

    my $ok;
    if( $diag ) {
        $ok = $Test->ok( 0, $name );
        $Test->diag("    $diag\n");
    }
    else {
        $ok = $Test->ok( 1, $name );
    }

    return $ok;
}


#line 612

sub pass (;$) {
    $Test->ok(1, @_);
}

sub fail (;$) {
    $Test->ok(0, @_);
}

#line 665

sub diag {
    return unless $Show_Diag;
    $Test->diag(@_);
}


#line 721

sub use_ok ($;@) {
    my($module, @imports) = @_;
    @imports = () unless @imports;

    my($pack,$filename,$line) = caller;

    local($@,$!);   # eval sometimes interferes with $!

    if( @imports == 1 and $imports[0] =~ /^\d+(?:\.\d+)?$/ ) {
        # probably a version check.  Perl needs to see the bare number
        # for it to work with non-Exporter based modules.
        eval <<USE;
package $pack;
use $module $imports[0];
USE
    }
    else {
        eval <<USE;
package $pack;
use $module \@imports;
USE
    }

    my $ok = $Test->ok( !$@, "use $module;" );

    unless( $ok ) {
        chomp $@;
        $@ =~ s{^BEGIN failed--compilation aborted at .*$}
                {BEGIN failed--compilation aborted at $filename line $line.}m;
        $Test->diag(<<DIAGNOSTIC);
    Tried to use '$module'.
    Error:  $@
DIAGNOSTIC

    }

    return $ok;
}

#line 769

sub require_ok ($) {
    my($module) = shift;

    my $pack = caller;

    # Try to deterine if we've been given a module name or file.
    # Module names must be barewords, files not.
    $module = qq['$module'] unless _is_module_name($module);

    local($!, $@); # eval sometimes interferes with $!
    eval <<REQUIRE;
package $pack;
require $module;
REQUIRE

    my $ok = $Test->ok( !$@, "require $module;" );

    unless( $ok ) {
        chomp $@;
        $Test->diag(<<DIAGNOSTIC);
    Tried to require '$module'.
    Error:  $@
DIAGNOSTIC

    }

    return $ok;
}


sub _is_module_name {
    my $module = shift;

    # Module names start with a letter.
    # End with an alphanumeric.
    # The rest is an alphanumeric or ::
    $module =~ s/\b::\b//g;
    $module =~ /^[a-zA-Z]\w+$/;
}

#line 870

#'#
sub skip {
    my($why, $how_many) = @_;

    unless( defined $how_many ) {
        # $how_many can only be avoided when no_plan is in use.
        _carp "skip() needs to know \$how_many tests are in the block"
          unless $Test->has_plan eq 'no_plan';
        $how_many = 1;
    }

    for( 1..$how_many ) {
        $Test->skip($why);
    }

    local $^W = 0;
    last SKIP;
}


#line 951

sub todo_skip {
    my($why, $how_many) = @_;

    unless( defined $how_many ) {
        # $how_many can only be avoided when no_plan is in use.
        _carp "todo_skip() needs to know \$how_many tests are in the block"
          unless $Test->has_plan eq 'no_plan';
        $how_many = 1;
    }

    for( 1..$how_many ) {
        $Test->todo_skip($why);
    }

    local $^W = 0;
    last TODO;
}

#line 1007

use vars qw(@Data_Stack %Refs_Seen);
my $DNE = bless [], 'Does::Not::Exist';
sub is_deeply {
    unless( @_ == 2 or @_ == 3 ) {
        my $msg = <<WARNING;
is_deeply() takes two or three args, you gave %d.
This usually means you passed an array or hash instead 
of a reference to it
WARNING
        chop $msg;   # clip off newline so carp() will put in line/file

        _carp sprintf $msg, scalar @_;
    }

    my($this, $that, $name) = @_;

    my $ok;
    if( !ref $this xor !ref $that ) {  # one's a reference, one isn't
        $ok = 0;
    }
    if( !ref $this and !ref $that ) {
        $ok = $Test->is_eq($this, $that, $name);
    }
    else {
        local @Data_Stack = ();
        local %Refs_Seen  = ();
        if( _deep_check($this, $that) ) {
            $ok = $Test->ok(1, $name);
        }
        else {
            $ok = $Test->ok(0, $name);
            $ok = $Test->diag(_format_stack(@Data_Stack));
        }
    }

    return $ok;
}

sub _format_stack {
    my(@Stack) = @_;

    my $var = '$FOO';
    my $did_arrow = 0;
    foreach my $entry (@Stack) {
        my $type = $entry->{type} || '';
        my $idx  = $entry->{'idx'};
        if( $type eq 'HASH' ) {
            $var .= "->" unless $did_arrow++;
            $var .= "{$idx}";
        }
        elsif( $type eq 'ARRAY' ) {
            $var .= "->" unless $did_arrow++;
            $var .= "[$idx]";
        }
        elsif( $type eq 'REF' ) {
            $var = "\${$var}";
        }
    }

    my @vals = @{$Stack[-1]{vals}}[0,1];
    my @vars = ();
    ($vars[0] = $var) =~ s/\$FOO/     \$got/;
    ($vars[1] = $var) =~ s/\$FOO/\$expected/;

    my $out = "Structures begin differing at:\n";
    foreach my $idx (0..$#vals) {
        my $val = $vals[$idx];
        $vals[$idx] = !defined $val ? 'undef' : 
                      $val eq $DNE  ? "Does not exist"
                                    : "'$val'";
    }

    $out .= "$vars[0] = $vals[0]\n";
    $out .= "$vars[1] = $vals[1]\n";

    $out =~ s/^/    /msg;
    return $out;
}


sub _type {
    my $thing = shift;

    return '' if !ref $thing;

    for my $type (qw(ARRAY HASH REF SCALAR GLOB Regexp)) {
        return $type if UNIVERSAL::isa($thing, $type);
    }

    return '';
}


#line 1109

#'#
sub eq_array {
    local @Data_Stack;
    local %Refs_Seen;
    _eq_array(@_);
}

sub _eq_array  {
    my($a1, $a2) = @_;

    if( grep !_type($_) eq 'ARRAY', $a1, $a2 ) {
        warn "eq_array passed a non-array ref";
        return 0;
    }

    return 1 if $a1 eq $a2;

    if($Refs_Seen{$a1}) {
        return $Refs_Seen{$a1} eq $a2;
    }
    else {
        $Refs_Seen{$a1} = "$a2";
    }

    my $ok = 1;
    my $max = $#$a1 > $#$a2 ? $#$a1 : $#$a2;
    for (0..$max) {
        my $e1 = $_ > $#$a1 ? $DNE : $a1->[$_];
        my $e2 = $_ > $#$a2 ? $DNE : $a2->[$_];

        push @Data_Stack, { type => 'ARRAY', idx => $_, vals => [$e1, $e2] };
        $ok = _deep_check($e1,$e2);
        pop @Data_Stack if $ok;

        last unless $ok;
    }

    return $ok;
}

sub _deep_check {
    my($e1, $e2) = @_;
    my $ok = 0;

    {
        # Quiet uninitialized value warnings when comparing undefs.
        local $^W = 0; 

        $Test->_unoverload(\$e1, \$e2);

        # Either they're both references or both not.
        my $same_ref = !(!ref $e1 xor !ref $e2);

        if( defined $e1 xor defined $e2 ) {
            $ok = 0;
        }
        elsif ( $e1 == $DNE xor $e2 == $DNE ) {
            $ok = 0;
        }
        elsif ( $same_ref and ($e1 eq $e2) ) {
            $ok = 1;
        }
        else {
            my $type = _type($e1);
            $type = '' unless _type($e2) eq $type;

            if( !$type ) {
                push @Data_Stack, { vals => [$e1, $e2] };
                $ok = 0;
            }
            elsif( $type eq 'ARRAY' ) {
                $ok = _eq_array($e1, $e2);
            }
            elsif( $type eq 'HASH' ) {
                $ok = _eq_hash($e1, $e2);
            }
            elsif( $type eq 'REF' ) {
                push @Data_Stack, { type => 'REF', vals => [$e1, $e2] };
                $ok = _deep_check($$e1, $$e2);
                pop @Data_Stack if $ok;
            }
            elsif( $type eq 'SCALAR' ) {
                push @Data_Stack, { type => 'REF', vals => [$e1, $e2] };
                $ok = _deep_check($$e1, $$e2);
                pop @Data_Stack if $ok;
            }
        }
    }

    return $ok;
}


#line 1211

sub eq_hash {
    local @Data_Stack;
    local %Refs_Seen;
    return _eq_hash(@_);
}

sub _eq_hash {
    my($a1, $a2) = @_;

    if( grep !_type($_) eq 'HASH', $a1, $a2 ) {
        warn "eq_hash passed a non-hash ref";
        return 0;
    }

    return 1 if $a1 eq $a2;

    if( $Refs_Seen{$a1} ) {
        return $Refs_Seen{$a1} eq $a2;
    }
    else {
        $Refs_Seen{$a1} = "$a2";
    }

    my $ok = 1;
    my $bigger = keys %$a1 > keys %$a2 ? $a1 : $a2;
    foreach my $k (keys %$bigger) {
        my $e1 = exists $a1->{$k} ? $a1->{$k} : $DNE;
        my $e2 = exists $a2->{$k} ? $a2->{$k} : $DNE;

        push @Data_Stack, { type => 'HASH', idx => $k, vals => [$e1, $e2] };
        $ok = _deep_check($e1, $e2);
        pop @Data_Stack if $ok;

        last unless $ok;
    }

    return $ok;
}

#line 1263

sub eq_set  {
    my($a1, $a2) = @_;
    return 0 unless @$a1 == @$a2;

    # There's faster ways to do this, but this is easiest.
    local $^W = 0;

    # We must make sure that references are treated neutrally.  It really
    # doesn't matter how we sort them, as long as both arrays are sorted
    # with the same algorithm.
    # Have to inline the sort routine due to a threading/sort bug.
    # See [rt.cpan.org 6782]
    return eq_array(
           [sort { ref $a ? -1 : ref $b ? 1 : $a cmp $b } @$a1],
           [sort { ref $a ? -1 : ref $b ? 1 : $a cmp $b } @$a2]
    );
}

#line 1306

sub builder {
    return Test::Builder->new;
}

#line 1446

1;
