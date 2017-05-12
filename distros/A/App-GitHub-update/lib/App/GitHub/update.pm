package App::GitHub::update;
BEGIN {
  $App::GitHub::update::VERSION = '0.0011';
}
# ABSTRACT: Update a github repository (description, homepage, etc.) from the commandline


use strict;
use warnings;

use Config::Identity::GitHub;
use LWP::UserAgent;
use Getopt::Long qw/ GetOptions /;
my $agent = LWP::UserAgent->new;

sub update {
    my $self = shift;
    my %given = @_;
    my ( $login, $token, $repository, $description, $homepage );

    ( $repository, $description, $homepage ) = @given{qw/ repository description homepage /};
    defined $_ && length $_ or die "Missing repository\n" for $repository;

    ( $login, $token ) = @given{qw/ login token /};
    unless( defined $token && length $token ) {
        my %identity = Config::Identity::GitHub->load;
        ( $login, $token ) = @identity{qw/ login token /};
    }

    my @arguments;
    push @arguments, 'values[description]' => $description if defined $description;
    push @arguments, 'values[homepage]' => $homepage if defined $homepage;

    my $uri = "https://github.com/api/v2/json/repos/show/$login/$repository";
    my $response = $agent->post( $uri,
        [ login => $login, token => $token, @arguments ] );

    unless ( $response->is_success ) {
        die $response->status_line, "\n", $response->decoded_content, "\n";
    }

    return $response;
}

sub usage (;$) {
    my $error = shift;
    my $exit = 0;
    if ( defined $error ) {
        if ( $error ) {
            if ( $error =~ m/^\-?\d+$/ ) { $exit = $error }
            else {
                chomp $error;
                warn $error, "\n";
                $exit = -1;
            }
        }
    }
    warn <<_END_;

Usage: github-update [opt]

    --login ...         Your github login
    --token ...         The github token associated with the given login

                        Although required, if a login/token are not given,
                        github-create will attempt to load it from 
                        \$HOME/.github or \$HOME/.github-identity (see
                        Config::Identity for more information)

    --repository ...    The repository to update

    --description ...   The new description of the repository
    --homepage ...      A homepage for the repository

    --help, -h, -?      This help


_END_

#    --dzpl              Guess repository and description from Dist::Dzpl
#                        configuration (name and abstract, respectively)

    exit $exit;
}

sub guess_dzpl {
    my $self = shift;
    my %guess;

    eval {
        # Oh god this is hacky
        package App::GitHub::update::Sandbox;
BEGIN {
  $App::GitHub::update::Sandbox::VERSION = '0.0011';
}
        local @ARGV;
        do './dzpl';
        my $dzpl = $Dzpl::dzpl;
        $dzpl = $Dzpl::dzpl;
        $dzpl->zilla->_setup_default_plugins;
        $_->gather_files for ( @{ $dzpl->zilla->plugins_with(-FileGatherer) } );
        $guess{repository} = $dzpl->zilla->name;
        $guess{description} = $dzpl->zilla->abstract;
    };
    die $@ if $@;

    return %guess;
}

sub run {
    my $self = shift;
    my @arguments = @_;

    usage 0 unless @arguments;

    my ( $login, $token, $repository, $dzpl, $help );
    my ( $homepage, $description );
    {
        local @ARGV = @arguments;
        GetOptions(
            'help|h|?' => \$help,

            'login=s' => \$login,
            'token=s' => \$token,
            'repository=s' => \$repository,

            'dzpl' => \$dzpl,

            'description=s' => \$description,
            'homepage=s' => \$homepage,
        );
    }

    usage 0 if $help;

    if ( $dzpl ) {
        my %guess = $self->guess_dzpl;
        $repository ||= $guess{repository};
        $description ||= $guess{description};
    }
    
    eval {
        my $response = $self->update(
            login => $login, token => $token, repository => $repository,
            description => $description, homepage => $homepage,
        );

        print $response->as_string, "\n";
    };
    if ($@) {
        usage <<_END_;
github-update: $@
_END_
    }
}

1;

__END__
=pod

=head1 NAME

App::GitHub::update - Update a github repository (description, homepage, etc.) from the commandline

=head1 VERSION

version 0.0011

=head1 SYNOPSIS

    # Update the description of github:alice/example
    github-update --login alice --token 42fe60... --repository example --description "Xyzzy"

    # Pulling login and token from $HOME/.github
    github-update --repository example --description "Xyzzy"

    # With homepage
    github-update --repository example --description "The incredible Xyzzy" --homepage http://example/xyzzy

    # Print usage
    github-update --help

=head1 DESCRIPTION

A simple tool for setting the description and homepage of a github repository

=head1 GitHub identity format ($HOME/.github or $HOME/.github-identity)

    login <login>
    token <token>

(Optionally GnuPG encrypted; see L<Config::Identity>)

=head1 SEE ALSO

L<App::GitHub::create>

L<Config::Identity>

=head1 AUTHOR

  Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

