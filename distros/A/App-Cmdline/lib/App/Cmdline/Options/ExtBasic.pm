#-----------------------------------------------------------------
# App::Cmdline::Options::ExtBasic
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see the POD.
#
# ABSTRACT: set of basic options for command-line applications
# PODNAME: App::Cmdline::Options::ExtBasic
#-----------------------------------------------------------------
use warnings;
use strict;

package App::Cmdline::Options::ExtBasic;
use parent 'App::Cmdline::Options::Basic';

our $VERSION = '0.1.2'; # VERSION

use Pod::Usage;
use Pod::Find qw(pod_where);

my @OPT_SPEC = (
    [ 'help'      => "display a full usage message"   ],
    [ 'man|m'     => "display a full manual page"     ],
    [ 'quiet|q'   => "skip various progress messages" ],
    );

# ----------------------------------------------------------------
# Return definition of my options
# ----------------------------------------------------------------
sub get_opt_spec {
    return shift->SUPER::get_opt_spec(), @OPT_SPEC;
}

# ----------------------------------------------------------------
# Do typical actions with my options
# ----------------------------------------------------------------
sub validate_opts {
    my ($class, $app, $caller, $opt, $args) = @_;
    $class->SUPER::validate_opts ($app, $caller, $opt, $args);

    # show various levels of help and exit
    my $pod_where = pod_where ({-inc => 1}, $app);
    pod2usage (-input => $pod_where, -verbose => 1, -exitval => 'NOEXIT')
        if $opt->can ('help') and $opt->help;
    pod2usage (-input => $pod_where, -verbose => 2, -exitval => 'NOEXIT')
        if $opt->can ('man') and $opt->man;
    if ( ($opt->can ('help') and $opt->help) or ($opt->can ('man') and $opt->man) ) {
        if ($^S) { die "Okay\n" } else { exit (0) };
    }
    return;
}

1;


=pod

=head1 NAME

App::Cmdline::Options::ExtBasic - set of basic options for command-line applications

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
               'App::Cmdline::Options::ExtBasic',  # here are the options added
           )
       );
    }

=head1 DESCRIPTION

This is a kind of a I<role> module, defining a particular set of
command-line options and their validation. See more about how to write
a module that represents a command-line application and that uses this
set of options in L<App::Cmdline>.

=head1 OPTIONS

Particularly, this module extends the basic options, adding mostly
more documentation options. It inherits from
L<App::Cmdline::Options::Basic> module, and, therefore, provides the
same basic options defined there, and it adds the following options:

    [ 'help'      => "display a full usage message"   ],
    [ 'man|m'     => "display a full manual page"     ],
    [ 'quiet|q'   => "skip various progress messages" ],

=head2 --help

It uses L<Pod::Usage> module to print a (potentially) longer usage
message created from embedded POD documentation, using its I<SYNOPSIS>
section, along with any section entitled I<OPTIONS>, I<ARGUMENTS>, or
I<OPTIONS AND ARGUMENTS>. The POD documentation is taken from the
module that represents your application (not from the command-line
script that uses your application module).

After producing this message, it exits in one of the two possible
ways: If it is called from and C<eval> expression, it dies (so you can
catch it and continue). Otherwise, it exists with the exit code zero.

=head2 --man

It uses L<Pod::Usage> module to print a full manual page from embedded
POD documentation. Then, it exits in the same way as described din the
L<-help|"-help"> option.

=head2 --quiet

It creates a method C<$opt-E<gt>quiet> that can be used in your
application to ignore some messages. For example (remember that the
full job in you application is done in its C<execute()> method):

   sub execute {
      my ($self, $opt, $args) = @_;
      print STDERR "Started...\n" unless $opt->quiet;
      ...
   }

=head1 AUTHOR

Martin Senger <martin.senger@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Martin Senger, CBRC - KAUST (Computational Biology Research Center - King Abdullah University of Science and Technology) All Rights Reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

