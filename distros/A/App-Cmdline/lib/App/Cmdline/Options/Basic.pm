#-----------------------------------------------------------------
# App::Cmdline::Options::Basic
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see the POD.
#
# ABSTRACT: set of basic options for command-line applications
# PODNAME: App::Cmdline::Options::Basic
#-----------------------------------------------------------------
use warnings;
use strict;

package App::Cmdline::Options::Basic;

our $VERSION = '0.1.2'; # VERSION

my @OPT_SPEC = (
    [ 'h'         => "display a short usage message"  ],
    [ 'version|v' => "display a version"              ],
    );

# ----------------------------------------------------------------
# Return definition of my options
# ----------------------------------------------------------------
sub get_opt_spec {
    return @OPT_SPEC;
}

# ----------------------------------------------------------------
# Do typical actions with my options.
#
# Why am I first trying with $opt->can? Just in case, somebody called
# composed_of (which instaled a call here) but has not returned (from
# opt_spec) what the composed_of returned him).
# ----------------------------------------------------------------
sub validate_opts {
    my ($class, $app, $caller, $opt, $args) = @_;

    # show help and exit
    if ($opt->can ('h') and $opt->h) {
        print "Usage: " . $caller->usage();
        if ($^S) { die "Okay\n" } else { exit (0) };
    }

    # show version and exit
    if ($opt->can ('version') and $opt->version) {
        ## no critic
        no strict;    # because the $VERSION will be added only when
        no warnings;  # the distribution is fully built up
        print ${"${app}::VERSION"} . "\n";
        if ($^S) { die "Okay\n" } else { exit (0) };
    }

    return;
}

1;


=pod

=head1 NAME

App::Cmdline::Options::Basic - set of basic options for command-line applications

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

   # In your module that represents a command-line application:
   sub opt_spec {
       my $self = shift;
       return $self->check_for_duplicates (
           [ 'check|c' => "only check the configuration"  ],
           ...,
           $self->composed_of (
               'App::Cmdline::Options::Basic',  # here are the basic options added
               'App::Cmdline::Options::DB',     # here may be other options
           )
       );
    }

=head1 DESCRIPTION

This is a kind of a I<role> module, defining a particular set of
command-line options and their validation. See more about how to write
a module that represents a command-line application and that uses this
set of options in L<App::Cmdline>.

=head1 OPTIONS

Particularly, this module specifies the basic options, usually used by
any command-line application:

    [ 'h'         => "display a short usage message"  ],
    [ 'version|v' => "display a version"              ],

=head2 -h

It prints a short usage message, something like this:

   Usage: myapp [non-bundled short or long options]
        -h             display a short usage message
        -v --version   display a version

=head2 --version

It print the version of the application and exits in one of the two
possible ways: If it is called from and C<eval> expression, it dies
(so you can catch it and continue). Otherwise, it exists with the exit
code zero.

=head1 AUTHOR

Martin Senger <martin.senger@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Martin Senger, CBRC - KAUST (Computational Biology Research Center - King Abdullah University of Science and Technology) All Rights Reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

