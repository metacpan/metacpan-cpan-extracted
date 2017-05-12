# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Oct-28 16:35 (EDT)
# Function: 
#
# $Id: Block.pm,v 1.1 2010/11/01 18:42:00 jaw Exp $

package AC::MrGamoo::Submit::Compile::Block;
use strict;

my $UCLASS = 'AC::MrGamoo::User';

sub new {
    my $class = shift;

    return bless {}, $class;
}

sub compile {
    my $me   = shift;
    my $inc  = shift;

    my $prog = "{\n";

    my $class = $me->{attr}{in_package} || $UCLASS;
    $prog .= "package $class;\n";
    if( $class eq $UCLASS ){
        $prog .= "our \$R;\n";
    }else{
        $prog .= "our \$R = \$$UCLASS\::R;\n";
    }

    if( !defined($me->{attr}{use_strict}) || $me->{attr}{use_strict} ){
        $prog .= "use strict;\n";
    }

    if( $inc ){
        $prog .= $inc;
    }

    if( $me->{init} ){
        $prog .= $me->{init};
    }

    $prog .= " {\n";
    $prog .= _compile_attr( $me->{attr} );
    for my $k qw(code cleanup){
        next unless $me->{$k};
        next if( ref $me->{$k} );

        $prog .= "  $k => sub {\n$me->{$k}\n  },\n";
    }
    $prog .= " };\n}\n";

    return $prog;
}

sub _compile_attr {
    my $h = shift;

    my $x = "  attr => {\n";
    for my $k (keys %$h){
        my $v = $h->{$k};
        next if ref $v;
        next if $k =~ /\W/;
        $v =~ s/(["\\])/\\$1/g;
        $x .= "   \"$k\" => \"$v\",\n";
    }

    $x .= "  },\n";
}


1;
