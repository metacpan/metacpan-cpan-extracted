# NAME

Data::RuledCluster - clustering data resolver

# VERSION

This document describes Data::RuledCluster version 0.07.

# SYNOPSIS

    use Data::RuledCluster;
    
    my $config = +{
        clusters => +{
            USER_W => [qw/USER001_W USER002_W/],
            USER_R => [qw/USER001_R USER002_R/],
        },
        node => +{
            USER001_W => ['dbi:mysql:user001', 'root', '',],
            USER002_W => ['dbi:mysql:user002', 'root', '',],
            USER001_R => ['dbi:mysql:user001', 'root', '',],
            USER002_R => ['dbi:mysql:user002', 'root', '',],
        },
    };
    my $dr = Data::RuledCluster->new(
        config => $config,
    );
    my $resolved_data = $dr->resolve('USER_W', $user_id);
    # or
    my $resolved_data = $dr->resolve('USER001_W');
    # $resolved_data: +{ node => 'USER001_W', node_info => ['dbi:mysql:user001', 'root', '',]}

# DESCRIPTION

\# TODO

# METHOD

- my $dr = Data::RuledCluster->new($config)

    create a new Data::RuledCluster instance.

- $dr->config($config)

    set or get config.

- $dr->resolve($cluster\_or\_node, $args)

    resolve cluster data.

- $dr->resolve\_node\_keys($cluster, $keys, $args)

    Return hash resolved node and keys.

- $dr->is\_cluster($cluster\_or\_node)

    If $cluster\_or\_node is cluster, return true.
    But $cluster\_or\_node is not cluster, return false.

- $dr->is\_node($cluster\_or\_node)

    If $cluster\_or\_node is node, return true.
    But $cluster\_or\_node is not node, return false.

- $dr->cluster\_info($cluster)

    Return cluster info hash ref.

- $dr->clusters($cluster)

    Retrieve cluster member node names as Array.

# DEPENDENCIES

[Class::Load](https://metacpan.org/pod/Class::Load)

[Data::Util](https://metacpan.org/pod/Data::Util)

# BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

# SEE ALSO

[perl](https://metacpan.org/pod/perl)

# AUTHOR

Atsushi Kobayashi <nekokak@gmail.com>

# LICENSE AND COPYRIGHT

Copyright (c) 2012, Atsushi Kobayashi. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
