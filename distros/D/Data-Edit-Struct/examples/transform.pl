$dest = { a => '1', 'b' => 2 };

edit(
    transform => {
        dest     => $dest,
        dpath    => '/*',
        callback => sub {
            my ( $point, $data ) = @_;
            ${ $point->ref } .= $point->attrs->key;
        },
    },
);
