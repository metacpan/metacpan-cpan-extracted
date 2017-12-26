edit(
    insert => {
        src   => $src,
        stype => 'element',
        dest  => $dest,
        dpath => '/bar/*[1]',
        dtype => 'element',
    } );
