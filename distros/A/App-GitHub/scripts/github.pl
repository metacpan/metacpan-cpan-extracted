#!/usr/bin/perl

package    # hidden from PAUSE
  github;

# ABSTRACT: GitHub Command Tools

use strict;
use warnings;

use App::GitHub;
use Pod::Usage;

use Getopt::Long;
Getopt::Long::Configure("bundling");

use 5.010;

if ( @ARGV == 0 ) {
    App::GitHub->new->run(@ARGV);
}
else {

    # Let's define some options!
    my ( $create, $username, $password, $key, $name, $fork, $help );
    GetOptions(
        'create|c=s'   => \$create,
        'key|k=s'      => \$key,
        'name|n=s'     => \$name,
        'fork|f=s'     => \$fork,
        'username|u=s' => \$username,
        'password|p=s' => \$password,
        'help'         => \$help,
    );

    my $github = App::GitHub->new( silent => 1 );
    if ($help) {
        pod2usage(1);
    }

    unless ( $username and $password ) {
        $github->set_loadcfg;
    }
    else {
        $github->set_login("$username $password");
    }

    if ($create) {
        eval { $github->repo_create($create); };

        if ($@) {
            say STDERR "Could not create repo $create";
            print STDERR $@;
        }
        else {
            say "Created repo $create";
        }
    }
    elsif ($key) {
        say STDERR "Provide a name for the key with -n" if not $name;

        eval { $github->user_pub_keys( "add", $name, $key ); };

        if ($@) {
            say STDERR "Could not add key";
            print STDERR $@;
        }
        else {
            say "Added pubkey";
        }
    }
    elsif ($fork) {
        eval { $github->run_basic_repo_cmd( 'repos', 'create_fork', $fork ); };

        if ($@) {
            say STDERR "Could not fork $fork";
            print STDERR $@;
        }
        else {
            say "Forked repo $fork";
        }
    }
}

1;

=pod

=head1 NAME

github - GitHub Command Tools

=head1 VERSION

version 1.0.1

=head1 SYNOPSIS

github.pl [options]

When run with no options, drops you to the github command line.

If --username and --password aren't passed in, github.user and github.pass from .gitconfig are used

Options:

    --username='username'
    --password='password'
    --create='name of repo to create'
    --key='pubkey' --name='name of key'
    --fork='name of repo to fork'
    --help

=head1 NAME

github.pl - Interact with github.com through the command line

=head1 OPTIONS

=over 8

=item B<--create>

Creates a new repo on github

=item B<--key --name>

Adds a key with a given name (passed by --name) to a github account

=item B<--fork>

Fork the given github repo to your account

=item B<--help>

Print help text and exit

=item B<--username>

Github username 

=item B<--password>

Github password

=back

=head1 AUTHOR

William Orr <will@worrbase.com>

Please report bugs L<here|https://github.com/worr/perl-app-github/>

=head1 AUTHORS

=over 4

=item *

Fayland Lam <fayland@gmail.com>

=item *

William Orr <will@worrbase.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
