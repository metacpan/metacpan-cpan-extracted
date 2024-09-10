package Acme::Free::Dog::API;

use v5.10;
use strict;
use warnings;

our $VERSION = '0.9.9';

use HTTP::Tiny;
use JSON            qw/decode_json/;
use Util::H2O::More qw/baptise ddd HTTPTiny2h2o h2o/;

use constant {
    BASEURL => "https://dog.ceo/api",
};

sub new {
    my $pkg  = shift;
    my $self = baptise { ua => HTTP::Tiny->new }, $pkg;
    return $self;
}

# used by:bin/fletch breeds
sub breeds  {
    my $self   = shift;

    # https://dog.ceo/api/breeds/list/all
    my $URL    = sprintf "%s/%s", BASEURL, "breeds/list/all";

    my $resp   = HTTPTiny2h2o $self->ua->get($URL);
    die sprintf( "fatal: API did not provide a useful response (status: %d)\n", $resp->status ) if ( $resp->status != 200 );

    return $resp->content->message;
}

# used by: bin/fletch subbreeds --breed BREED
sub subbreeds  {
    my $self   = shift;
    my $params = h2o {@_}, qw/breed/;

    # https://dog.ceo/api/breed/hound/list
    my $URL    = sprintf "%s/breed/%s/list", BASEURL, $params->breed;

    my $resp   = HTTPTiny2h2o $self->ua->get($URL);
    die sprintf( "fatal: API did not provide a useful response (status: %d)\n", $resp->status ) if ( $resp->status != 200 );

    return $resp->content->message;
}

# used by: bin/fletch images --breed BREED
# Note: API doesn't support getting images by subbreed
sub images {
    my $self   = shift;
    my $params = h2o {@_}, qw/breed/;

    #  https://dog.ceo/api/breed/hound/images
    my $URL    = sprintf "%s/breed/%s/images", BASEURL, $params->breed;

    my $resp   = HTTPTiny2h2o $self->ua->get($URL);
    die sprintf( "fatal: API did not provide a useful response (status: %d)\n", $resp->status ) if ( $resp->status != 200 );

    return $resp->content->message;
}

# used by: bin/fletch random [--breed BREED]
sub random {
    my $self   = shift;
    my $params = h2o {@_}, qw/breed/;

    #  https://dog.ceo/api/breeds/image/random Fetch!
    my $URL    = sprintf "%s/breeds/image/random", BASEURL;

    # handle optional, 'breed => BREED'
    if ($params->breed) {
      # https://dog.ceo/api/breed/affenpinscher/images/random 
      $URL    = sprintf "%s/breed/%s/images/random", BASEURL, lc $params->breed;
    }

    my $resp   = HTTPTiny2h2o $self->ua->get($URL);
    die sprintf( "fatal: API did not provide a useful response (status: %d)\n", $resp->status ) if ( $resp->status != 200 );

    return $resp->content->message;
}

1;

__END__

=head1 NAME

Acme::Free::Dog::API - Perl API client for the Dog API service, L<https://dog.ceo/dog-api>.

This module provides the client, "fletch", that is available via C<PATH> after install.

=head1 SYNOPSIS

  #!/usr/bin/env perl
    
  use strict;
  use warnings;
  
  use Acme::Free::Dog::API qw//;
  
  my $fletch = Acme::Free::Dog::API->new;

  printf "%s\n", $fletch->random;

=head2 C<fletch> Commandline Client

After installing this module, simply run the command C<fletch> without any argum
ents to get a URL for a random dog image. See below for all subcommands.

  shell> fletch
  https://images.dog.ceo/breeds/basenji/n02110806_2249.jpg
  shell>

=head1 DESCRIPTION

This is the Perl API for the Dog API, profiled at L<https://www.freepublicapis.com/dog-api>. 

Contributed as part of the B<FreePublicPerlAPIs> Project described at,
L<https://github.com/oodler577/FreePublicPerlAPIs>.

This fun module is to demonstrate how to use L<Util::H2O::More> and
L<Dispatch::Fu> to make creating easily make API SaaS modules and
clients in a clean and idiomatic way. These kind of APIs tracked at
L<https://www.freepublicapis.com/> are really nice for fun and practice
because they don't require dealing with API keys in the vast majority of cases.

This module is the first one written using L<Util::H2O::More>'s C<HTTPTiny2h2o>
method that looks for C<JSON> in the C<content> key returned via L<HTTP::Tiny>'s
response C<HASH>.

=head1 METHODS

=over 4

=item C<new>

Instantiates object reference. No parameters are accepted.

=item C<breeds>

Makes the SaaS API call to get the list of all breeds. It accepts no arguments.

This list determines what is valid when specifying the breed in using C<random>.

=item C<< images(breed => STRING) >>

Fetches a long list of images URLs for the specified breed. There seemed to be now
way to get an imagine for a subbreed, so for breeds that do have subbreeds, the
list of image URLs contains some random assortment of all subbreeds. 

=item C<< random([breed => STRING]) >>

Returns a random dog image URL. You may specify the breed with the named parameter,
C<breed>.

=item C<< subreeds(breed => STRING) >>

Given the named parameter, C<breeds>, returns a list of subbreeds if they exist.

=back

=head1 C<fletch> OPTIONS

=over 4

=item C<breeds>

Prints out a list of supported breeds. Useful for determining what is accepted
upstream when using the C<random> with the C<--breed> flag used.

If the a breed has 1 or more subbreeds, it is indicated with a C<+> sign.

This command can be used in combination with the C<subbreeds> subcommand, e.g.,

  fletch breeds | awk '{ if ($2 == "+") print $1 }' | xargs -I% fletch subbreeds --breed %

In fact, any subcommand that takes that C<--breed> argument can be combined with
this subcommand in a way that makes for some very powerful commandline dog-fu!

=item C<images --breed BREED>

The C<--breed> argument is required.

Provides a list of all URLs for the specified C<BREED>. The API call behind this subcommand
doesn't support listing image URLs by subbreed, so for breeds that are further categorized
by subbreed the results contain a mix of them.

This comand can be used incombination with the C<breeds> subcommand to get a bunch of images
for each breed (no support in the API for subbreed image fetching).

  fletch breeds | awk '{print $1}' | xargs -I% fletch images --breed %

=item C<random [--breed BREED]>

Prints the random dog image URL to C<STDOUT>. You may optionally specify a breed.

This command can be used in combination with the C<breeds> command to get a random image
URL for all breeds.

  fletch breeds | awk '{print $1}' | xargs -I% fletch random --breed %

=item C<subbreeds --breed BREED>

The C<--breed> argument is required.

Given a breed, lists out the subbreeds. It handles breeds that have no subbreeds, but this
command can be used in combination with the C<breeds> command to fetch all subbreeds for
only breeds that have 1 or more subbreeds. See the section on the C<breeds> subcommand
for more..

=back

=head2 Internal Methods

There are no internal methods to speak of.

=head1 ENVIRONMENT

Nothing special required.

=head1 AUTHOR

Brett Estrade L<< <oodler@cpan.org> >>

=head1 BUGS

Please report.

=head1 LICENSE AND COPYRIGHT

Same as Perl/perl.
