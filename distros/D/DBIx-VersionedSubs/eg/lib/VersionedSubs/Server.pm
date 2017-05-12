package DBIx::VersionedSubs::Server;
use strict;
use base qw'Class::Accessor HTTP::Server::Simple::CGI';

=head1 NAME

DBIx::VersionedSubs::Server - HTTP server frontend for DBIx::VersionedSubs

=head1 SYNOPSIS

  ... to be done. Look at the source code and the programs
  using this code in the meanwhile ...

=cut

__PACKAGE__->mk_accessors(qw(namespace dispatch));

use vars '$VERSION';
$VERSION = '0.02';

sub new {
    my ($package,$args) = @_;
    my $namespace = delete $args->{namespace} || $package;
    my $dispatch = delete $args->{dispatch} || 'handler';
    my $post_init_hook = delete $args->{hook_post_init} || 'hook_post_init';
    
    my $loaded = eval qq{
        use $namespace;
        1
    } or warn "Error loading $namespace: $@ (might be harmless)";
    if (! $loaded) { 
        eval qq{
            package $namespace;
            use base 'DBIx::VersionedSubs'; 
            1 
        } or die $@;
    };

    if (! exists $args->{dbh}) {
        $args->{dbh} = $namespace->connect(delete @{$args}{qw(dsn user password)});
    }
    $namespace->dbh(delete $args->{dbh});

    my $self = $package->SUPER::new($args);
    $self->dispatch($dispatch);
    $self->namespace($namespace);

    $namespace->startup;

    if ($namespace->can($post_init_hook)) {
        $namespace->$post_init_hook($self)
            or die "$namespace::$post_init_hook didn't return a true value";
    }

    $self
}

sub post_setup_hook {
    my $self = shift;
    $self->SUPER::post_setup_hook();
    $self->namespace->update_code();
}

sub handle_request {
    my ($self,$cgi) = @_;
    my ($package,$meth) = ($self->namespace,$self->dispatch);
    warn "$package\::$meth(\$q)";
    eval { $package->$meth($cgi)};
    if (my $err = $@) {
        print $cgi->header('text/plain');
        print "Error: $err";
    }
}

1;
