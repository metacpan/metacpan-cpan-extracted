#-----------------------------------------------------------------
# App::Cmdline::Options::ExtDB
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see the POD.
#
# ABSTRACT: extended set of database-related options for command-line applications
# PODNAME: App::Cmdline::Options::ExtDB
#-----------------------------------------------------------------
use warnings;
use strict;

package App::Cmdline::Options::ExtDB;
use parent 'App::Cmdline::Options::DB';

our $VERSION = '0.1.2'; # VERSION

my @OPT_SPEC = (
    [ 'dbshow' => "show database access properties"  ],
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

    if ($opt->dbshow) {
        print "DBNAME: ", ($opt->dbname || 'n/a'), "\n";
        print "DBHOST: ", ($opt->dbhost || 'n/a'), "\n";
        print "DBPORT: ", ($opt->dbport || 'n/a'), "\n";
        print "DBUSER: ", ($opt->dbuser || 'n/a'), "\n";
        print "DBPASS: ", ($opt->dbpasswd ? '...given but not shown' : 'n/a'), "\n";
        print "DBSOCK: ", ($opt->dbsocket || 'n/a'), "\n";
    }

    return;
}

1;


=pod

=head1 NAME

App::Cmdline::Options::ExtDB - extended set of database-related options for command-line applications

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
               'App::Cmdline::Options::ExtDB',  # here are the database options added
               'App::Cmdline::Options::Basic',  # here may be other options
           )
       );
    }

=head1 DESCRIPTION

This is a kind of a I<role> module, defining a particular set of
command-line options and their validation. See more about how to write
a module that represents a command-line application and that uses this
set of options in L<App::Cmdline>.

=head1 OPTIONS

Particularly, this module extends the basic database-related options,
adding an option for showing how the database options have been
set. It inherits from L<App::Cmdline::Options::DB> module, and,
therefore, provides the same options defined there, and it adds
the following option:

    [ 'dbshow' => "show database access properties"  ],

=head2 --dbshow

It prints (on STDOUT) values given to the database-related
options. For example:

   senger@ShereKhan2:myapp --dbshow --dbname Emma --dbpasswd vrrr -dbhost 12.13.14.15
   DBNAME: Emma
   DBHOST: 12.13.14.15
   DBPORT: 3306
   DBUSER: reader
   DBPASS: ...given but not shown
   DBSOCK: n/a

=head1 AUTHOR

Martin Senger <martin.senger@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Martin Senger, CBRC - KAUST (Computational Biology Research Center - King Abdullah University of Science and Technology) All Rights Reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

