let $PERL5LIB = join( filter( map ( [ 'lib' ], { idx, val -> getcwd() . '/' . val } ), { idx, val -> isdirectory( val ) } ), ':' )  . ':' . $PERL5LIB
