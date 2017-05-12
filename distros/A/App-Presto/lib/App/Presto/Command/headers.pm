package App::Presto::Command::headers;
our $AUTHORITY = 'cpan:MPERRY';
$App::Presto::Command::headers::VERSION = '0.010';
# ABSTRACT: HTTP header-related commands

use strict;
use warnings;
use Moo;
use MIME::Base64;
with 'App::Presto::InstallableCommand','App::Presto::CommandHasHelp', 'App::Presto::WithPrettyPrinter';

sub install {
    my $self = shift;
    my $config = $self->config;
    my $client = $self->client;
    $self->term->add_commands(
        {
            authorization => {
                minargs => 0,
                maxargs => 2,
                desc => 'GET/Set basic auth username/password',
                args => [sub { '[username]' },sub { '[password]' } ],
                proc    => sub {
                    my ( $username, $password ) = @_;
                    if($username){
                        $client->set_header(
                            Authorization => sprintf( 'Basic %s',
                                MIME::Base64::encode( "$username:$password", '' ) )
                        );
                    } elsif( my $auth = $client->get_header('Authorization') ){
                        $auth =~ s/Basic //;
                        my ($u,$p) = split(/:/, MIME::Base64::decode( $auth ), 2 );
                        print "Username: $u\nPassword: $p\n";
                    }
                },
            },
            type => {
                minargs => 1,
                desc => 'Set content-type header',
                args => sub { ['application/json','application/x-www-form-urlencoded'] },
                proc    => sub { $client->set_header( 'Content-Type', shift ) },
            },
            headers => {
                maxargs => 0,
                alias   => 'header',
            },
            header => {
                desc => 'get/set/list/clear HTTP headers',
                args => [sub {my %headers = $client->all_headers; return ['--unset','--clear', keys %headers]} ],
                proc => sub {
                    my $header = shift;
                    my @args   = @_;
                    if ( !$header ) {    # print all
                        my %headers = $client->all_headers;
                        print $self->pretty_print( \%headers );
                    } elsif ( $header eq '--clear' ) {
                        $client->clear_headers;
                    } elsif ( $header eq '--unset' ) {
                        $client->clear_header($args[0]);
                    } elsif (@args) {      # set
                        $header =~ s/:$//; # to allow pasting of an actual HTTP header from the dump
                        my $value = join ' ', @args;
                        $client->set_header( $header, $value );
                    }
                    else {    # get
                        print $self->pretty_print( { $header => $client->get_header($header) });
                    }
                },
            },
        }
    );
}

sub help_categories {
    return {
        desc => 'Configure various HTTP headers',
        cmds => [qw(authorization headers type)],
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Presto::Command::headers - HTTP header-related commands

=head1 VERSION

version 0.010

=head1 AUTHORS

=over 4

=item *

Brian Phillips <bphillips@cpan.org>

=item *

Matt Perry <matt@mattperry.com> (current maintainer)

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Brian Phillips and Shutterstock Images (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
