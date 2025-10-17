package Astro::ADS;
$Astro::ADS::VERSION = '1.91';
use Moo;

use Carp;
use Data::Dumper::Concise;
use Feature::Compat::Try;
use Mojo::Base -strict;
use Mojo::URL;
use Mojo::UserAgent;
use Types::Standard qw( StrMatch );

# suppress warning for native perl 5.36 try/catch
no if $] >= 5.018, 'warnings', 'experimental';

my $DEBUG = 0;

has ua    => ( is => 'lazy' );
has proxy => ( is => 'lazy' );
has token => ( is => 'lazy', isa => StrMatch[qr/\A\w{20,50}\z/] );

has base_url => (
    is      => 'ro',
    default => sub { Mojo::URL->new('https://api.adsabs.harvard.edu/v1/') },
);

sub _build_ua {
    my ($self) = @_;
    return Mojo::UserAgent->new;
}

sub _build_proxy {
    my ($self, $proxy) = @_;
    $self->ua->proxy->https( $proxy );
    return $proxy;
}

sub _build_token {
    my ($self) = @_;

    return $ENV{ADS_DEV_KEY} if $ENV{ADS_DEV_KEY};

    # consider using File::HomeDir
    my $dev_key_file = Mojo::File->new($ENV{HOME} . '/.ads/dev_key');
    if (-e $dev_key_file) {
        my $key = $dev_key_file->slurp;
        chomp $key; # remove this line to create a Bad Request
        return $key;
    }

    croak "You need to provide an API token.\nSee https://metacpan.org/pod/Astro::ADS#Getting-Started\n";
}

sub get_response {
    my ($self, $url) = @_;

    my $tx = $self->ua->build_tx( GET => $url );
    $tx->req->headers->authorization( 'Bearer ' . $self->token );
    warn $tx->req->to_string if $DEBUG;
   
    try { $tx = $self->ua->start($tx) }
    catch ($error) {
        carp "Got this error: ", $error;
    }

    my $res;
    try { $res = $tx->result } # call to result dies on connection error
    catch ($error) {
        carp "Connection error: ", $error;
        return;
    }
    if    ($res->is_success)  { warn $res->body if $DEBUG > 1 }
    elsif ($res->is_error)    { carp 'HTTP Error: ', $res->message }
    elsif ($res->code == 301) { carp 'Redirected: ', $res->headers->location if $DEBUG }

    return $res;
}

sub post_response {
    my ($self, $url, $hash) = @_;

    my $tx = $self->ua->build_tx( POST => $url, json => $hash );
    $tx->req->headers->authorization( 'Bearer ' . $self->token );
    carp "Request sent to $url\n\n", $tx->req->to_string if $DEBUG;
   
    try { $tx = $self->ua->start($tx) }
    catch ($error) {
        carp "Got this error: ", $error;
    }

    return $tx->result;
}

1; # Perl is my Igor

=pod

=encoding UTF-8

=head1 NAME

Astro::ADS - Perl library to connect with the Harvard Astrophysical Data Service

=head1 VERSION

version 1.91

=head1 SYNOPSIS

    my $client = Astro::ADS->new({
        proxy => '...', # your web proxy
    });

    my $search = $client->search( q => 'star', fl => 'bibcode' );

=head1 DESCRIPTION

The Harvard Astrophysics Data System (ADS) is a digital library
portal for researchers in astronomy and physics, maintaining
large bibliographic collections. Through the ADS, you can search
abstracts and full-text of major astronomy and physics publications.

Astro::ADS is the base class for accessing the ADS API using Perl
and will grow as more services are added.

It handles methods common to all services such as setting the UserAgent and
including your API key in all request headers.

=head2 Getting Started

If you don't have one already, you will need to register an
L<ADS account|https://ui.adsabs.harvard.edu/user/account/register> .
Generate an L<API token|https://ui.adsabs.harvard.edu/user/settings/token> and
put it in an environment variable named C<ADS_DEV_KEY> or in a file under your
home directory, B<~/.ads/dev_key>.

Find more help on the L<Quick Start|https://ui.adsabs.harvard.edu/help/api/> page.

=head2 Terms and Conditions

B<NOTE: the ADS does not hold the copyright for the abstracts and articles, and their use is free for personal use only>

Use of this module does not imply the granting of any rights to
the publications found through this API. Please refer to the
L<ADS Terms and Conditions of Use|http://adsabs.github.io/help/terms/>

To acknowledge the ADS in a publication, refer to the text at the
bottom of L<About ADS|https://ui.adsabs.harvard.edu/about/>.
To acknowlegde use of this module, it will be sufficient to mention
I<Perl's Astro::ADS is available at https://metacpan.org/pod/Astro::ADS>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Boyd Duffee.

This is free software, licensed under:

  The MIT (X11) License

=cut
