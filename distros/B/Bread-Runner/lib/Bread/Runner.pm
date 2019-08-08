package Bread::Runner;
use 5.020;
use strict;
use warnings;

# ABSTRACT: run ALL the apps via Bread::Board

our $VERSION = '0.902';

use Carp;
use Module::Runtime qw(use_module);
use Scalar::Util qw(blessed);
use Getopt::Long;
use Log::Any qw($log);
use Try::Tiny;


sub run {
    my ( $class, $bb_class, $opts ) = @_;

    my ($bb, $service) = $class->setup($bb_class, $opts);

    $class->_hook( 'pre_run', $bb, $service, $opts ) if $opts->{pre_run};

    my $run_methods = $opts->{run_method} || ['run'];
    $run_methods = [$run_methods] unless ref($run_methods) eq 'ARRAY';
    my $method;
    foreach my $m (@$run_methods) {
        next unless $service->can($m);
        $method = $m;
        last;
    }
    unless ($method) {
        my $msg = ref($service)." does not provide any run_method: "
            . join( ', ', @$run_methods );
        $log->error($msg);
        croak $msg;
    }

    my $rv = try {
        $log->infof("Running %s->%s",ref($service), $method) unless $opts->{no_startup_logmessage};
        return $service->$method;
    }
    catch {
        my $e = $_;
        my $msg;
        if ( blessed($e) && $e->can('message') ) {
            $msg = $e->message;
        }
        else {
            $msg = $e;
        }
        $log->errorf( "%s died with %s", $method, $msg );
        croak $msg;
    };

    $class->_hook( 'post_run', $bb, $service, $opts ) if $opts->{post_run};
    return $rv;
}


sub setup {
    my ( $class, $bb_class, $opts ) = @_;
    $opts ||= {};

    my $service_name = $opts->{service} || $0;
    $service_name =~ s{^(?:.*\bbin/)(.+)$}{$1};
    $service_name =~ s{/}{_}g;

    my $bb = $class->_compose_breadboard( $bb_class, $opts );

    my $bb_container = $opts->{container} || 'App';
    my $service_bb = try {
        $bb->fetch( $bb_container . '/' . $service_name );
    }
    catch {
        $log->error($_);
        croak $_;
    };

    my $service_class = $service_bb->class;
    use_module($service_class);

    my $service;
    if ( $service_bb->has_parameters ) {
        my $params = $service_bb->parameters;
        my @spec;
        while ( my ( $name, $def ) = each %$params ) {
            my $spec = "$name";
            if ( my $isa = $def->{isa} ) {
                if    ( $isa eq 'Int' )      { $spec .= "=i" }
                elsif ( $isa eq 'Str' )      { $spec .= "=s" }
                elsif ( $isa eq 'Bool' )     { $spec .= '!' }
                elsif ( $isa eq 'ArrayRef' ) { $spec .= '=s@' }
            }

            # TODO required
            # TODO default
            # TODO maybe we can use MooseX::Getopt?
            push( @spec, $spec );
        }
        my %commandline;

        GetOptions( \%commandline, @spec );
        $service = $service_bb->get( \%commandline );
    }
    else {
        $service = $service_bb->get;
    }

    return ($bb, $service);
}

sub _compose_breadboard {
    my ( $class, $bb_class, $opts ) = @_;

    use_module($bb_class);
    my $init_method = $opts->{init_method} || 'init';
    if ( $bb_class->can($init_method) ) {
        return $bb_class->$init_method($opts);
    }
    else {
        my $msg =
            "$bb_class does not implement a method $init_method (to compose the Bread::Board)";
        $log->error($msg);
        croak $msg;
    }
}

sub _hook {
    my ( $class, $hook_name, $bb, $service, $opts ) = @_;

    my $hook = $opts->{$hook_name};
    try {
        $log->infof( "Running hook %s", $hook_name );
        $hook->( $service, $bb, $opts );
    }
    catch {
        $log->errorf( "Could not run hook %s: %s", $hook_name, $_ );
        croak $_;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bread::Runner - run ALL the apps via Bread::Board

=head1 VERSION

version 0.902

=head1 SYNOPSIS

  # Define the components of your app in a Bread::Board
  container 'YourProduct' => as {
      container 'App' => as {
          service 'api.psgi' => (
              # ...
          );
          service 'some_script' => (
              # ...
          )
      };
  };
  
  # Write one generic wrapper script to run all your services
  # bin/generic_runner.pl
  use Bread::Runner;
  Bread::Runner->run('YourProduct');
  
  # Symlink this generic runner to filenames matchin your services
  ln -s bin/generic_runner.pl bin/api.psgi
  ln -s bin/generic_runner.pl bin/some_script
  
  # Never write a wrapper script again!

=head1 DESCRIPTION

C<Bread::Runner> provides an easy way to re-use your L<Bread::Board>
to run all your scripts via a simple and unified method.

This of course only makes sense for big-ish apps which consist of more
than just one script. But in my experience this is true for all apps,
as you will need countless helper scripts, importer, exporter,
cron-jobs, fixups etc.

If you still keep the code of your scripts in your scripts, I strongly
encourage you to join us in the 21st century and move all your code
into proper classes and replace your scripts by thin wrappers that
call those classes. And if you use C<Bread::Runner>, you'll only need
one wrapper (though you can have as many as you like, as TIMTOWTDI)

=head2 Real-Live Example

TODO

=head2 Guessing the service name from $0

TODO

=head1 METHODS

=head2 run

  Bread::Runner->run('YourProduct', \%opts);

  Bread::Runner->run('YourProduct', {
      service => 'some_script.pl'
  });

Initialize your Bread::Board, find the correct service, initialize the
service, and then run it!

=head2 setup

  my ($bread_board, $service) = Bread::Runner->_setup( 'YourProduct',  \%opts );

Initialize and compose your C<Bread::Board> and find and initialize the correct C<service>.

Usually you will just call L<run>, but maybe you want to do something fancy..

=head1 OPTIONS

L<setup> and L<run> take the following options as a hashref

=head3 service

Default: C<$0> modulo some cleanup magic, see L<Guessing the service name from $0>

The name of the service to use.

If you do not want to use this magic, pass in the explizit service
name you want to use. This could be hardcoded, or you could come up
with an alternative implementation to get the service name from the
environment available to a generic wrapper script.

=head3 container

Default: "App"

The name of the C<Bread::Board> container containing your services.

=head3 init_method

Default: "init"

The name of the method in the class implementing your C<Bread::Board>
that will return the topmost container.

=head3 run_method

Default: ["run"]

An arrayref of names of potential methods call in your services to
make them do their job.

Useful for running legacy classes via C<Bread::Runner>.

=head3 pre_run

A subref to be called just before C<run> is called.

Gets the following things as a list in this order

=over

=item * the C<Bread::Board> container

=item * the initated service

=item * the opts hashref (so you can pass on more stuff from your wrapper)

=back

You could use this hook to do some further initalistion, setup etc
that might not be doable in C<Bread::Board> itself.

=head3 post_run

A subref to be called just after C<run> is called.

Gets the same stuff like C<pre_run>.

Could be used for cleanup etc.

=head3 no_startup_logmessage

Set this to a true value to prevent the startup log message.

=head1 THANKS

Thanks to

=over

=item *

L<validad.com|http://www.validad.com/> for supporting Open Source.

=item *

L<Klaus Ita|https://metacpan.org/author/KOKI> for feedback & input during inital in-house development

=back

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 - 2019 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
