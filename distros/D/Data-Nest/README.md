# NAME

Data::Nest - nest array of hash easily. and calculate optional measurements corresponding to results of nest.

# SYNOPSIS

    use Data::Nest;

    my $nest = Data::Nest->new();
    $nest->key("mykey");
    my $nested = $nest->entries([
      {mykey => 1, val => 1},
      {mykey => 2, val => 2},
      {mykey => 1, val => 3},
      {mykey => 1, val => 4},
      {mykey => 2, val => 5},
    ]);
    print Dumper $nested;

    # [
    #   {key => 1, values => [
    #     {mykey => 1, val => 1},
    #     {mykey => 1, val => 3},
    #     {mykey => 1, val => 4},
    #   ]},
    #   {key => 2, values => [
    #     {mykey => 2, val => 2},
    #     {mykey => 2, val => 5},
    #   ]},
    # ]

# DESCRIPTION

Data::Nest is array of hash nesting utility.
Easily add measurements like "sum", "sumsq", "average",....
It's easy to nest data for prepareing data mining and data visualization.

# LICENSE

Copyright (C) muddydixon.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

muddydixon <muddydixon@gmail.com>
