
    my ($r, $image, $filters, $args) = @_ ;

    $image->Set(size=>'30x105');
    $image->Read('gradient:#00f685-#0083f8');
    $image->Rotate(-90);
    $image->Raise('6x6');
    
    $args -> {font}         = '/usr/msrc/fonts/arial.ttf' ;
    $args -> {gravity}      = 'Center' ;
    $args -> {pointsize}    = 18 ;

    push @$filters, 'Annotate' ;

    1 ;

