[![Build Status](https://travis-ci.org/kablamo/p5-chef-knife-cmd.svg?branch=master)](https://travis-ci.org/kablamo/p5-chef-knife-cmd) [![Coverage Status](https://img.shields.io/coveralls/kablamo/p5-chef-knife-cmd/master.svg)](https://coveralls.io/r/kablamo/p5-chef-knife-cmd?branch=master)
# NAME

Chef::Knife::Cmd - A small wrapper around the Chef 'knife' command line utility

# SYNOPSIS

    use Chef::Knife::Cmd;

    # See Shell::Carapace for details about the callback attribute
    my $knife = Chef::Knife::Cmd->new(
        callback => sub { ... }, # optional. useful for logging realtime output; 
    );

    # knife bootstrap
    $knife->bootstrap($fqdn, %options);

    # knife client
    $knife->client->delete($client, %options);

    # knife ec2
    $knife->ec2->server->list(%options);
    $knife->ec2->server->create(%options);
    $knife->ec2->server->delete(\@nodes, %options);

    # knife node
    $knife->node->show($node, %options);
    $knife->node->list($node, %options);
    $knife->node->create($node, %options);
    $knife->node->delete($node, %options);
    $knife->node->flip($node, $environment, %options);
    $knife->node->from->file($file, %options);
    $knife->node->run_list->add($node, \@entries, %options);

    # knife vault commands
    # hint: use $knife->vault->item() instead of $knife->vault->show()
    $knife->vault->list(%options);
    $knife->vault->show($vault, $item_name, %options);
    $knife->vault->create($vault, $item, $values, %options);
    $knife->vault->update($vault, $item, $values, %options);
    $knife->vault->delete($vault, $item, %options);
    $knife->vault->remove($vault, $item, $values, %options);
    $knife->vault->download($vault, $item, $path, %options);

    # knife search commands
    $knife->search->node($query, %options);
    $knife->search->client($query, %options);

    # knife data bag commands
    $knife->data_bag->show($data_bag, %options);

    # All methods return the output of the cmd as a string
    my $out = $knife->node->show('mynode');
    # => 
    # Node Name:   mynode
    # Environment: production
    # FQDN:        
    # IP:          12.34.56.78
    # Run List:    ...
    # ...

    # All methods return the output of the cmd as a hashref when '--format json' is used
    my $hashref = $knife->node->show('mynode', format => 'json');
    # =>
    # {
    #     name             => "mynode",
    #     chef_environment => "production",
    #     run_list         => [...],
    #     ...
    # }

# DESCRIPTION

This module is a small wrapper around the Chef 'knife' command line utility.
It would be awesome if this module used the Chef server API, but this module is
not that awesome.

Some things worth knowing about this module:

- Return vaules

    All commands return the output of the knife command.  

- Logging

    If you wish to log output, you should do so via the 'callback' attribute.  See
    Shell::Carapace for more details.

- Exceptions

    If a knife command fails, an exception is thrown.

# SEE ALSO

- [Capture::Tiny::Extended](https://metacpan.org/pod/Capture::Tiny::Extended)
- [Capture::Tiny](https://metacpan.org/pod/Capture::Tiny)
- [IPC::System::Simple](https://metacpan.org/pod/IPC::System::Simple)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Eric Johnson <eric.git@iijo.org>
