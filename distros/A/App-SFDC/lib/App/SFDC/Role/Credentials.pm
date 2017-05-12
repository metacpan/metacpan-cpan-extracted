package App::SFDC::Role::Credentials;
# ABSTRACT: Handle credential command-line input

use strict;
use warnings;
use 5.10.0;

our $VERSION = '0.16'; # VERSION

use Config::Properties;
use Data::Dumper;
use File::HomeDir;
use Log::Log4perl ':easy';
use WWW::SFDC 0.33;

use Moo::Role;
use MooX::Options;


option 'username',
    is => 'rw',
    short => 'u',
    format => 's';


option 'password',
    is => 'rw',
    short => 'p',
    format => 's';


option 'url',
    is => 'rw',
    format => 's',
    default => 'https://login.salesforce.com';


option 'apiversion',
    is => 'rw',
    format => 'i',
    default => 34;


option 'credfile',
    doc => 'The file from which to read credentials.',
    is => 'ro',
    format => 's',
    lazy => 1,
    default => File::HomeDir->my_home."/.salesforce.properties",
    isa => sub {
        LOGDIE "The credentials file ".$_[0]." doesn't exist!"
            unless -e $_[0];
    };


option 'environment',
    is => 'ro',
    short => 'e',
    format => 's';

has '_session',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        $self->_readOptionsFromFile if $self->environment
            and (!$self->username or !$self->password);

        WWW::SFDC->new(
            username => $self->username,
            password => $self->password,
            url => $self->url,
            apiVersion => $self->apiversion,
        )
    };

sub _readOptionsFromFile {
    my ($self) = @_;

    my $environment = $self->environment;

    INFO "Reading options for $environment from "
        . $self->credfile;

    my %environments = %{
      Config::Properties
        ->new(file => $self->credfile)
        ->splitToTree()
    };

    LOGDIE "Couldn't find credentials for $environment in "
        .$self->credfile
        unless $environments{$environment};

    for (qw'username password url apiversion'){
        if (exists($environments{$environment}->{$_})){
            DEBUG "Setting $_ with ".$environments{$environment}->{$_}.".";
            $self->$_($environments{$environment}->{$_});
        }
    }

}

1;

__END__

=pod

=head1 NAME

App::SFDC::Role::Credentials - Handle credential command-line input

=head1 VERSION

version 0.16

=head1 OPTIONS

=head2 --username -u

=head2 --password -p

=head2 --url

=head2 --apiversion

=head2 --credfile

A config file containing details of your enviroments, similar to the ant
deployment.properties file. For each environment, this file may specify the
credentials for that environment as:

    envname.username = username@example.com
    envname.password = PASSWORDthenTOKEN
    envname.url = https://login.salesforce.com

    sandboxname.username = username@example.com.sandbox
    sandboxname.password = PASSWORDthenTOKEN
    sandboxname.url = https://test.salesforce.com

By default, App::SFDC will look at ~/.salesforce.properties. This setting is
ignored unless you specify an enviroment.

=head2 --environment -e

Used in conjuction with a configuration file to specify which environment to use
for the operation.

=head1 AUTHOR

Alexander Brett <alexander.brett@sophos.com> L<http://alexander-brett.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Sophos Limited L<https://www.sophos.com/>.

This is free software, licensed under:

  The MIT (X11) License

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
