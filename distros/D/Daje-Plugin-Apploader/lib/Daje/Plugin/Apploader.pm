package Daje::Plugin::Apploader;
use Mojo::Base 'Mojolicious::Plugin', -signatures;
use v5.42;

use Data::Dumper;
use List::Util;
use Mojo::Loader qw {load_class find_modules};
use Daje::Database::Migrator;
use CPAN;

# NAME
# ====
#
# Daje::Plugin::Apploader - Loads stuff from a config file
# during starup of the Daje server
#
# SYNOPSIS
# ========
#
#   load_ables => {
#             namespaces => {
#                 plugins => [
#                     {
#                         name => ''
#                    }
#                 ],
#                 routes => [
#                     {
#                         name => ''
#                    }
#                 ]
#             },
#          plugin => [
#                 {
#                    name => '',
#                    options => [
#                        {
#                            name => '',
#                           option => ''
#                       }
#                   ]
#               }
#           ],
#           helper => [
#               {
#                   name => '',
#                   class => '',
#                   options => ''
#               }
#           ],
#           routes => [
#               {
#                   route => '',
#                   target => '',
#                   method => ''
#               }
#           ]
#     }
#     use Daje::Plugin::Apploader;
#
#     sub register ($self, $app)
#
# DESCRIPTION
# ===========
#
# Daje::Plugin::Apploader is a simple apploader for the Daje server.
# It automatically installs missing / updates to newer versions of
# modules from cpan if told to.
#
# LICENSE
# =======
#
# Copyright (C) janeskil1525.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# AUTHOR
# ======
#
# janeskil1525 E<lt>janeskil1525@gmail.comE<gt>
#

our $VERSION = "0.25";

sub register ($self, $app, $config) {

    my $modules;
    $app->log->debug("Daje::Plugin::Apploader::register start");
    $self->_setup_database($app);

    $app->log->debug("_setup_database done");

    try {
        my $pg = $app->pg;
        my $loadables = $app->config("load_ables");

        if(exists $loadables->{namespaces}->{plugins}) {
            my $length = scalar @{$loadables->{namespaces}->{plugins}};
            for(my $i = 0; $i < $length; $i++) {
                my $module;
                push @{$app->plugins->namespaces}, @{$loadables->{namespaces}->{plugins}}[$i]->{name};
                @{$module->{modules}} = find_modules @{$loadables->{namespaces}->{plugins}}[$i]->{name};
                $module->{namespace} = @{$loadables->{namespaces}->{plugins}}[$i]->{name};
                push @{$modules}, $module;
            }
        }

        $app->log->debug("plugin namespace done");
        if(exists $loadables->{namespaces}->{routes}) {
            my $length = scalar @{$loadables->{namespaces}->{routes}};
            for(my $i = 0; $i < $length; $i++) {
                push @{$app->routes->namespaces}, @{$loadables->{namespaces}->{routes}}[$i]->{name}
            }
        }

        $app->log->debug("routes namespace done");
        if(exists $loadables->{plugin}) {
            my $length = scalar @{$loadables->{plugin}};
            my @install = ();
            for(my $i = 0; $i < $length; $i++) {
                $self->_find_missing_modules(@{$loadables->{plugin}}[$i]->{name}, $modules, \@install);
            }
            for(my $i = 0; $i < $length; $i++) {
                if (exists @{$loadables->{plugin}}[$i]->{options}) {
                    my %plugin = $self->_plugin_options(
                        $app,
                        @{$loadables->{plugin}}[$i]->{name},
                        @{$loadables->{plugin}}[$i]->{options}
                    );
                    $app->plugin(
                        %plugin
                    );
                } else {
                    $app->plugin(@{$loadables->{plugin}}[$i]->{name});
                }
            }
        }

        $app->log->debug("plugin loading done");
        if(exists $loadables->{helper}) {
            my $length = scalar @{$loadables->{helper}};
            for(my $i = 0; $i < $length; $i++) {
                my $class = @{$loadables->{helper}}[$i]->{class};
                if (my $e = load_class $class) {
                    $app->log->fatal($e);
                }
                my $name = @{$loadables->{helper}}[$i]->{name};
                $app->helper($name => sub{ state $var = $class->new()});
                # self->helper(jwt => sub {state $jwt = Daje::Tools::JWT->new()});
            }
        }

        $app->log->debug("helper loading done");
        if(exists $loadables->{routes}) {
            my $length = scalar @{$loadables->{routes}};
            for(my $i = 0; $i < $length; $i++) {
                # ???
            }
        }

        $app->log->debug("route loading done");
        my $test = 1;
    } catch ($e) {
        my $error = $e;
        $app->log->fatal($e);
    }
}

sub _find_missing_modules($self, $plugin, $modules, $install) {
    my $length = scalar @{$modules};

    for(my $i = 0; $i < $length; $i++) {
        my $class = @{$modules}[$i]->{namespace} . "::" . $plugin;
        if (!grep(/^$class$/, @{$modules})) {
            if (!grep(/^$class$/, @{$install})) {
                push @{$install}, $class;
            } elsif (grep(/^$class$/, @{$install})) {
                my $index = 0;
                $index++ until @{$install}[$index] eq $class;
                splice(@{$install}, $index, 1);
            }
        }
    }
}

sub _install_modules($self, $install) {
    my $length = scalar @{$install};
    if( $length > 0 ) {
        CPAN::HandleConfig->load;
        CPAN::Shell::setup_output;
        CPAN::Index->reload;
        for (my $i = 0; $i < $length; $i++) {
            CPAN::Shell->install(@{$install}[$i]);
        }
    }
}

sub _setup_database($self, $app) {

    try {
        Daje::Database::Migrator->new(
            pg         => $app->pg,
            migrations => $app->config('migrations'),
        )->migrate();
    } catch($e) {
        $app->log->error($e);
    };
}

sub _plugin_options($self, $app, $name, $options) {

    my %plugin = ();
    my %result = ();

    my $length = scalar @{$options};
    for (my $i = 0; $i < $length; $i++) {
        my $plug = @{$options}[$i]->{name};
        my $data = @{$options}[$i]->{option};
        %plugin =  ($plug => eval $data);
    }

    $result{$name} = \%plugin;

    return %result;
}
1;
__END__








#################### pod generated by Pod::Autopod - keep this line to make pod updates possible ####################

=head1 NAME


Daje::Plugin::Apploader - Loads stuff from a config file
during starup of the Daje server



=head1 SYNOPSIS


  load_ables => {
            namespaces => {
                plugins => [
                    {
                        name => ''
                   }
                ],
                routes => [
                    {
                        name => ''
                   }
                ]
            },
         plugin => [
                {
                   name => '',
                   options => [
                       {
                           name => '',
                          option => ''
                      }
                  ]
              }
          ],
          helper => [
              {
                  name => '',
                  class => '',
                  options => ''
              }
          ],
          routes => [
              {
                  route => '',
                  target => '',
                  method => ''
              }
          ]
    }
    use Daje::Plugin::Apploader;

    sub register ($self, $app)



=head1 DESCRIPTION


Daje::Plugin::Apploader is a simple apploader for the Daje server.
It automatically installs missing / updates to newer versions of
modules from cpan if told to.



=head1 REQUIRES

L<CPAN> 

L<Daje::Database::Migrator> 

L<Mojo::Loader> 

L<List::Util> 

L<Data::Dumper> 

L<v5.42> 

L<Mojo::Base> 


=head1 METHODS

=head2 register

 register();


=head1 AUTHOR


janeskil1525 E<lt>janeskil1525@gmail.comE<gt>



=head1 LICENSE


Copyright (C) janeskil1525.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.



=cut

