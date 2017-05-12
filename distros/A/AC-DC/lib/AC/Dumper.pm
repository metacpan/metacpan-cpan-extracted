# -*- perl -*-

# Copyright (c) 2008 by Jeff Weisberg
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Created: 2008-Dec-11 23:20 (EST)
# Function: dump data all pretty-like
#
# $Id$

package AC::Dumper;
use AC::Import;

our @EXPORT = 'dumper';

sub dumper {
    my $val = shift;

    return _dump( $val, {} );
}

sub _dump {
    my $val  = shift;
    my $seen = shift;
    
    return '<NULL>' unless defined $val;
    return $val     unless ref($val);

    # detect infinite loop
    return '<LOOP>' if $seen->{$val};
    $seen->{$val} = 1 if ref $val;

    if( ref($val) && $val =~ 'SCALAR' ){
        return '<REF>' . $$val;
    }

    if( ref($val) && $val =~ 'HASH' ){
        return '{}' unless keys %$val;
        my $out  = "{\n";
	# align nicely
        my $maxl = 0;
        $maxl = (length($_) > $maxl) ? length($_) : $maxl for keys %$val;
        for my $k (sort keys %$val){
            my $v = _dump($val->{$k}, $seen);
            $v =~ s/\n(.)/\n  $1/gm;	 # indent
            $out .= sprintf "  %-${maxl}s => %s\n", $k, $v;
        }
        $out .= "}";
        return $out;
    }

    if( ref($val) && $val =~ 'ARRAY' ){
        return '[]' unless @$val;
        my $out = "[\n";
        for my $k (@$val){
            my $v = _dump($k, $seen);
            $v =~ s/^/  /gm;
            $out .= $v . "\n";
        }
        $out .= "]";
        return $out;
    }
    
    return "<$val>";	# can't dump this
}

1;

