package Chef::Knife::Cmd;
use feature qw/say/;
use Moo;

use Chef::Knife::Cmd::Client;
use Chef::Knife::Cmd::EC2;
use Chef::Knife::Cmd::Node;
use Chef::Knife::Cmd::Vault;
use Chef::Knife::Cmd::Search;
use Chef::Knife::Cmd::DataBag;
use Shell::Carapace;
use String::ShellQuote;
use JSON::MaybeXS;

our $VERSION = "0.15";

=head1 NAME

Chef::Knife::Cmd - A small wrapper around the Chef 'knife' command line utility

=head1 SYNOPSIS

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


=head1 DESCRIPTION

This module is a small wrapper around the Chef 'knife' command line utility.
It would be awesome if this module used the Chef server API, but this module is
not that awesome.

Some things worth knowing about this module:

=over 4

=item Return vaules

All commands return the output of the knife command.  

=item Logging

If you wish to log output, you should do so via the 'callback' attribute.  See
Shell::Carapace for more details.

=item Exceptions

If a knife command fails, an exception is thrown.

=back

=cut

has noop       => (is => 'rw', default => sub { 0 });
has shell      => (is => 'lazy');
has format     => (is => 'rw');
has _json_flag => (is => 'rw');

has callback   => (is => 'rw');
has output     => (is => 'rw');

has client    => (is => 'lazy');
has ec2       => (is => 'lazy');
has node      => (is => 'lazy');
has vault     => (is => 'lazy');
has search    => (is => 'lazy');
has data_bag  => (is => 'lazy');

sub _build_client    { Chef::Knife::Cmd::Client->new(knife => shift)    }
sub _build_ec2       { Chef::Knife::Cmd::EC2->new(knife => shift)       }
sub _build_node      { Chef::Knife::Cmd::Node->new(knife => shift)      }
sub _build_vault     { Chef::Knife::Cmd::Vault->new(knife => shift)     }
sub _build_search    { Chef::Knife::Cmd::Search->new(knife => shift)    }
sub _build_data_bag  { Chef::Knife::Cmd::DataBag->new(knife => shift)   }

sub _build_shell {
    my $self = shift;
    my $cb   = sub {
        my ($type, $message) = @_;
        if ($type ne 'error') {
            if ($type eq 'command') {
                $self->output('');
            }
            else {
                my $output = '';
                $output .= $self->output . "\n" if $self->output;
                $output .= $message;
                $self->output($output);
            }
        }
        $self->callback->(@_) if $self->callback;
    };

    return Shell::Carapace->shell(callback => $cb);
}

sub bootstrap {
    my ($self, $fqdn, %options) = @_;
    my @opts = $self->handle_options(%options);
    my @cmd  = (qw/knife bootstrap/, $fqdn, @opts);
    $self->run(@cmd);
}

sub handle_options {
    my ($self, %options) = @_;

    $options{format} //= $self->format if $self->format;

    $options{format} && $options{format} eq 'json'
        ? $self->_json_flag(1)
        : $self->_json_flag(0);

    my @opts;
    for my $option (sort keys %options) {
        my $value = $options{$option};
        $option =~ s/_/-/g;

        push @opts, "--$option";
        push @opts, $value if $value ne "1";
    }

    return @opts;
}

sub run {
    my ($self, @cmds) = @_;
    return shell_quote @cmds if $self->noop;
    $self->shell->run(@cmds);
    my $out = $self->output;
    return JSON->new->utf8->decode($out) if $self->_json_flag;
    return $out;
}

1;

=head1 SEE ALSO

=over 4

=item L<Capture::Tiny::Extended>

=item L<Capture::Tiny>

=item L<IPC::System::Simple>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Eric Johnson E<lt>eric.git@iijo.orgE<gt>

=cut
