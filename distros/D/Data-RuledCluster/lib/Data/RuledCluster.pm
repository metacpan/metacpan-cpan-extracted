package Data::RuledCluster;
use 5.008_001;
use strict;
use warnings;
use Carp ();
use Class::Load ();
use Data::Util qw(is_array_ref is_hash_ref);

our $VERSION = '0.07';

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    bless \%args, $class;
}

sub resolver {
    my ($self, $strategy) = @_;

    my $pkg = $strategy;
    $pkg = $pkg =~ s/^\+// ? $pkg : "Data::RuledCluster::Strategy::$pkg";
    Class::Load::load_class($pkg);
    $pkg;
}

sub config {
    my ($self, $config) = @_;
    $self->{config} = $config if $config;
    $self->{config};
}

sub resolve {
    my ($self, $cluster_or_node, $args, $options) = @_;

    Carp::croak("missing mandatory config.") unless $self->{config};

    if ($self->is_cluster($cluster_or_node)) {
        my ($resolved_node, @keys) = $self->_delegate(resolve => $cluster_or_node, $args, $options);
        return $self->resolve($resolved_node, \@keys);
    }
    elsif ($self->is_node($cluster_or_node)) {
        return $self->_make_node_hashref($cluster_or_node);
    }

    Carp::croak("$cluster_or_node is not defined.");
}

sub resolve_node_keys {
    my ($self, $cluster_or_node, $keys, $args, $options) = @_;
    my $orig_args = $args;

    if ( is_hash_ref $args ) {
        $args = {%$args}; # shallow copy
        $args->{strategy} ||= 'Key';
        $args->{key}        = $keys;
    }
    else {
        $args = $keys;
    }

    my %node_keys = $self->_delegate(resolve_node_keys => $cluster_or_node, $args, $options);
    for my $cluster_or_node (keys %node_keys) {
        next if $self->is_node($cluster_or_node);
        if ($self->is_cluster($cluster_or_node)) {
            my $cluster  = $cluster_or_node;
            my @key_info = @{ delete $node_keys{$cluster_or_node} };
            for my $key_info (@key_info) {
                my %child_node_keys = $self->resolve_node_keys($cluster, $key_info->{next}, $orig_args, $options);
                for my $node (keys %child_node_keys) {
                    push @{ $node_keys{$node} ||= [] } => $key_info->{root};
                }
            }
            next;
        }

        Carp::croak("$cluster_or_node is not defined.");
    }
    return wantarray ? %node_keys : \%node_keys;
}

sub _delegate {
    my ($self, $method, $cluster, $args, $options) = @_;

    Carp::croak("missing mandatory config.") unless $self->{config};

    if ( is_hash_ref($args) ) {
        Carp::croak("args has not 'strategy' field") unless $args->{strategy};
        return $self->resolver($args->{strategy})->$method(
            $self,
            $cluster,
            $args,
            $options,
        );
    }

    my $cluster_info = $self->cluster_info($cluster);
    if (is_array_ref($cluster_info)) {
        return $self->resolver('Key')->$method(
            $self,
            $cluster,
            +{ key => $args, },
            $options,
        );
    }
    elsif (is_hash_ref($cluster_info)) {
        return $self->resolver($cluster_info->{strategy})->$method(
            $self,
            $cluster,
            +{ %$cluster_info, key => $args, },
            $options,
        );
    }

    Carp::croak('$cluster_info is invalid.');
}

sub _make_node_hashref {
    my ($self, $node) = @_;
    return {
        node      => $node,
        node_info => $self->{config}->{node}->{$node},
    };
}

sub cluster_info {
    my ($self, $cluster) = @_;
    $self->{config}->{clusters}->{$cluster};
}

sub clusters {
    my ($self, $cluster) = @_;
    my $cluster_info = $self->cluster_info($cluster);
    my @nodes = is_array_ref($cluster_info) ? @$cluster_info : @{ $cluster_info->{nodes} };
    wantarray ? @nodes : \@nodes;
}

sub is_cluster {
    my ($self, $cluster) = @_;
    exists $self->{config}->{clusters}->{$cluster} ? 1 : 0;
}

sub is_node {
    my ($self, $node) = @_;
    exists $self->{config}->{node}->{$node} ? 1 : 0;
}

1;
__END__

=for stopwords dr

=head1 NAME

Data::RuledCluster - clustering data resolver

=head1 VERSION

This document describes Data::RuledCluster version 0.07.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

# TODO

=head1 METHOD

=over 4

=item my $dr = Data::RuledCluster->new($config)

create a new Data::RuledCluster instance.

=item $dr->config($config)

set or get config.

=item $dr->resolve($cluster_or_node, $args)

resolve cluster data.

=item $dr->resolve_node_keys($cluster, $keys, $args)

Return hash resolved node and keys.

=item $dr->is_cluster($cluster_or_node)

If $cluster_or_node is cluster, return true.
But $cluster_or_node is not cluster, return false.

=item $dr->is_node($cluster_or_node)

If $cluster_or_node is node, return true.
But $cluster_or_node is not node, return false.

=item $dr->cluster_info($cluster)

Return cluster info hash ref.

=item $dr->clusters($cluster)

Retrieve cluster member node names as Array.

=back

=head1 DEPENDENCIES

L<Class::Load>

L<Data::Util>

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Atsushi Kobayashi E<lt>nekokak@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, Atsushi Kobayashi. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
