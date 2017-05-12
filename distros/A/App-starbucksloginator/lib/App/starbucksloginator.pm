package App::starbucksloginator;
{
  $App::starbucksloginator::VERSION = '0.0012';
}
# ABSTRACT: Access the wireless at Starbucks (via AT&T)

use strict;
use warnings;


use Getopt::Long qw/ GetOptions /;
use Getopt::Usaginator <<_END_;
Usage: starbucksloginator <options>

    --agent <agent>         The agent to pass the loginator off as (user agent string).
                            Windows Firefox by default
_END_

use WWW::Mechanize;

my $__agent__ = WWW::Mechanize->new;
$__agent__->agent( "Mozilla/5.0 (Windows; U; Windows NT 6.0; en-GB; rv:1.9.0.6) Gecko/2009011913 Firefox/3.0.6" );
sub agent { $__agent__ }

sub try {
    my $self = shift;
    my $site = shift;
    my $response = agent->get( "http://$site" );
    my $success = $response->decoded_content !~ m/<title>[^<]*Starbucks.*?</i;
    return ( $success, $response );
}

sub try_to_get_out {
    my $self = shift;
    my ( $success, $response );
    for my $site ( qw/ google.com example.com bing.com yahoo.com / ) {
        ( $success, $response ) = $self->try( $site );
        return ( $success, $response ) unless $success;
    }
    return ( $success, $response );
}

sub say { 
    print "> ", @_, "\n";
}

sub run {
    my $self = shift;
    my @arguments = @_;
    
    my ( $help, $agent );
    {
        local @ARGV = @arguments;
        GetOptions(
            'agent=s' => \$agent,
            'help|h|?' => \$help,
        );
    }

    usage 0 if $help;

    agent->agent( $agent ) if defined $agent;

    my ( $connected, $response );
    ( $connected, $response ) = $self->try_to_get_out;

    if ( $connected ) { 
        say "It looks like you can already get out -- Cancelling login";
        exit 0;
    }
    else {
        say "Unable to get out -- Attempting to login";
    }

    if ( agent->form_number( 1 ) ) {
        say "Attempting to connect";
        $response = agent->submit_form( 
            fields => {
                aupAgree => 1,
            },
        );
    }
    else {
        say "Unable to find connect form -- Cancelling login";
        print $response->as_string;
        exit -1;
    }

    ( $connected ) = $self->try_to_get_out;

    if ( $connected ) {
        say "Connected -- Login successful";
        exit 0;
    }

    say "Unable to get out -- Login failed";
    print $response->as_string;
    exit -1;
}

1;

__END__
=pod

=head1 NAME

App::starbucksloginator - Access the wireless at Starbucks (via AT&T)

=head1 VERSION

version 0.0012

=head1 SYNOPSIS

    $ starbucksloginator

=head1 DESCRIPTION

    AT&T/Starbucks has an annoying connection screen needed access their wireless.

    This is a commandline-based, no-hassle way to connect

=head1 USAGE

    Usage: starbucksloginator <options>

        --agent <agent>         The agent to pass the loginator off as (user agent string).
                                Windows Firefox by default

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

