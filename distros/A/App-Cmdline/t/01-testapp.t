#!/usr/bin/env perl
use strict;
use warnings;

package TestApp;
use parent 'App::Cmdline';
use Data::Dumper;

#use Test::More qw(no_plan);
use Test::More tests => 11;

BEGIN {
    diag( "Inside TestApp" );
}
sub opt_spec {
    my $self = shift;
    ok (1);

    my @got = $self->composed_of ([]);
    is (scalar @got, 2, "Wrong array size");
    is_deeply ($got[0], [], "No options given");
    ok (ref ($got[-1]), "Reference expected");
    is (ref ($got[-1]), 'HASH', "HASH reference expected");
    is_deeply ($got[-1]->{getopt_conf},
               ['no_bundling', 'no_ignore_case', 'auto_abbrev'],
               "Default getopt_conf");

    @got = $self->composed_of ('App::Cmdline::Options::Basic');
    is (scalar @got, 3, "(2) Wrong array size");
    ok (ref ($got[0]), "(2) Reference expected");
    is (ref ($got[0]), 'ARRAY', "ARRAY reference expected");
    is (scalar @{$got[0]}, 2, "(3) Wrong array size");
    is ($got[0]->[0], 'h', "-h expected");

    return @got;
}

sub execute {
    my ($self, $opt, $args) = @_;
}

1;

package main;
TestApp->import()->run();
#TestApp->run();


__END__
# Define your own options, and add some predefined sets.
sub opt_spec {
    my $self = shift;
    return $self->check_for_duplicates (
        [ 'check|c' => "only check the configuration"  ],
        [],
        $self->composed_of (
            'App::Cmdline::Options::ExtDB',
            [],
            'App::Cmdline::Options::Basic',
        )
        );
}

# sub opt_spec {
#     my $self = shift;
#     my @db_options = $self->composed_of ('App::Cmdline::Options::Basic');
#     pop @db_options;
#     return
# #     @db_options,
# #     [ 'latitude|y=s'  => "geographical latitude"  ],
# #     [ 'longitude|x=s' => "geographical longitude" ],
# #     [ 'xpoint|x'      => 'make an X point'],
# #     [ 'ypoint|y'      => 'make a  Y point'],
#       [ 'number|n=i'    => 'expected number of arguments'],
#       $self->composed_of (
#           'App::Cmdline::Options::ExtBasic',
#       );
# }



# Use this for validating your options (and remaining arguments).
# sub validate_args {
#      my ($self, $opt, $args) = @_;
#      $self->SUPER::validate_args ($opt, $args);
#      if ($opt->number and scalar @$args != $opt->number) {
#        $self->usage_error ("Option --number does not correspond with the number of arguments");
#      }
#  }

# Use this for changing the first line of the Usage message.
# sub usage_desc {
#     my $self = shift;
#     return $self->SUPER::usage_desc() . " <some arguments...>";
# }

# Use this to change (App::Cmdline's) default configuration of Getopt::Long
#sub getopt_conf {
#    return [ 'bundling' ];
#}

#-----------------------------------------------------------------
# The main job is done here. Mandatory method.
#-----------------------------------------------------------------
sub execute {
    my ($self, $opt, $args) = @_;
}

1;
__END__

=pod

=head1 SYNOPSIS

   A synopsis.

=head1 DESCRIPTION

This is myapp.

=cut
