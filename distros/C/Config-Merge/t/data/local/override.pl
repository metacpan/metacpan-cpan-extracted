{
    main => {    
        db => {
            servers => {
                server1 => {
                    host  => 'host4',
                    user  => 'user4',
                },
                server3 => {
                    host  => 'host3',
                    user  => 'user3',
                },
                list  => [qw(server3)],
            }
        }
    }
}
