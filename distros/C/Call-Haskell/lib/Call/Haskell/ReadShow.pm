package Call::Haskell::ReadShow;
use version; our $VERSION = version->declare('v0.1.1');
use warnings;
use strict;
use v5.16;
# Uses ShowToPerl to serialise the output of the Haskell function

use Data::Dumper;

# This routine needs the type signature from the Haskell function.
sub showH { (my $data, my $hs_type)=@_;
    my $t=$hs_type;
    if(ref($t) eq 'ARRAY' && scalar( @{$t}) ==1) { # List 
        if ($hs_type->[0] eq 'Char') { # String
            return show_string($data); 
        } else {
            my $list_t= $t->[0];
            return show_list($data, $list_t);
        }
    } elsif (ref($t) eq 'ARRAY' && scalar( @{$t})>1) { # Tuple            
            return show_tuple($data, $t);
  } elsif (ref($t) eq 'HASH' ) { # Alg. Datatype            
            return show_algtype($data, $t);            
    } elsif ($t =~/[A-Z]/) { # Either prim, Map or Maybe
        if($hs_type =~/^([A-Z]\w*)$/) { # Prim, which means Int, Integer, Float, Double, Integral, Fractional etc or Bool. 
            my $prim_t=$1;
            return show_prim($data,$prim_t);
        } else {
            die "Something wrong (2) with the type ".Dumper($hs_type)."!\n"; 
        }
    } else {die "Something wrong (1) with the type ".Dumper($hs_type)."!\n" }
}

sub show_string { '\"'.$_[0].'\"' };

sub show_prim {
        (my $data, my $hs_type)=@_;
        if ($hs_type eq 'Bool') {
            return ($data ? 'True' : 'False')
        } else {
            return $data;
        }
}

sub show_maybe {
    (my $data, my $hs_type)=@_;
    if (defined $data) {
        return 'Just '.showH($data,$hs_type);
    } else {
        return 'Nothing';
    }
}

sub show_list {
    (my $data, my $hs_type)=@_;
    return '['.join(',', map { showH($_,$hs_type) } @{$data}).']';
}

sub show_tuple {
    (my $data, my $hs_type)=@_;
    my @hs_types=@{$hs_type}; 
    if (scalar @{$data} != scalar @hs_types) {die "Tuple type and values do not match!\n" };    
    return '('.join(',', map { showH($_,shift(@hs_types)) } @{$data}).')';
}

sub show_hash {
    (my $data,my $key_t,my $val_t)=@_;
    my @kv_list=();
    while ((my $k, my $v) = each(%{$data})) {
        push @kv_list,'('.showH($k,$key_t).','.showH($v,$val_t).')';
    }
    return 'fromList ['.join(',',@kv_list).']';
}

sub show_algtype {
    (my $data, my $hs_type)=@_;
    if ($hs_type->{'TypeName'} eq 'Map') {
        (my $key_t,my $val_t) = @{$hs_type->{'TypeArgs'}};
        show_hash($data,$key_t,$val_t);
    } elsif ($hs_type->{'TypeName'} eq 'Maybe') {
        show_maybe($data, $hs_type->{'TypeArgs'}->[0] );
    } else {
        # This is an unknown datatype. Give up
         die "Type ".  $hs_type->{'TypeName'}. " not supported, please create a Perl counterpart using the Functional::Types module\n";
    }
}

# Simply eval the string from ShowToPerl, using AUTOLOAD to clean up.
sub readH {
    (my $vts)=@_;
    my $ref=eval( $vts );
    return $ref;
}


sub AUTOLOAD {
    our $AUTOLOAD;
        my $t=$AUTOLOAD;
        $t=~s/^.+:://;
        $t eq 'True' && do{$t=1};
        $t eq 'False' && do{$t=1};
        $t eq 'Nothing' && do{$t=undef};
    if (not @_) {
        return $t;
    } else {
            return {TypeName=>$t,TypeArgs=>[@_] };
    }
}

1;
