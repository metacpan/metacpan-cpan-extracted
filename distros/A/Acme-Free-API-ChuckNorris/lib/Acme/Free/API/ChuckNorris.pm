package Acme::Free::API::ChuckNorris;

use v5.10;
use strict;
use warnings;

our $VERSION = '0.9.10';

use HTTP::Tiny;
use JSON            qw/decode_json/;
use Util::H2O::More qw/baptise ddd d2o h2o/;

use constant {
    BASEURL => "https://api.chucknorris.io/jokes",
};

sub new {
    my $pkg  = shift;
    my $self = baptise { ua => HTTP::Tiny->new }, $pkg;
    return $self;
}

# Util::H2O::More::d2o needs a "find_json_string_and_decode_it" option ...
sub get {
    my ( $self, $endpoint ) = @_;
}

sub categories {
    my $self = shift;
    my $URL  = sprintf "%s/%s", BASEURL, "categories";
    my $resp = h2o $self->ua->get($URL);
    my $ret  = d2o decode_json $resp->content;
    return scalar $ret;
}

sub random {
    my $self  = shift;
    my $args  = d2o {@_};
    my $query = ( $args->category ) ? sprintf( "?category=%s", $args->category ) : "";
    my $URL   = sprintf "%s/%s%s", BASEURL, "random", $query;
    my $resp  = d2o $self->ua->get($URL);
    die sprintf( "fatal cnq: API did not a useful response (status: %d)\n", $resp->status ) if ( $resp->status != 200 );
    my $ret = d2o decode_json $resp->content;
    return $ret->value;
}

sub search {
    my $self  = shift;
    my $args  = h2o {@_};
    my $terms = $args->terms;
    my $URL   = sprintf "%s/%s?query=%s", BASEURL, "search", $terms;
    my $resp = d2o $self->ua->get($URL);
    my $ret  = d2o decode_json $resp->content;
    return scalar $ret;
}

1;

__END__

=head1 NAME

Acme::Free::API::ChuckNorris - Perl API client for the Chuck Norris Quote API service, L<https://api.chucknorris.io>.

This module provides the client, "cnq", that is available via C<PATH> after install.

=head1 SYNOPSIS

  #!/usr/bin/env perl
    
  use strict;
  use warnings;
  
  use Acme::Free::API::ChuckNorris qw//;
  
  my $cnq = Acme::Free::API::ChuckNorris->new;

  printf "%s\n", $cnq->random;

=head2 C<cnq> Commandline Client

After installing this module, simply run the command C<cnq> without any arguments,
and you will get a random quote.

  shell> cnq
  Calculator's refuse to work around Chuck Norris in fear of outsmarting him
  shell>

=head1 DESCRIPTION

This fun module is to demonstrate how to use L<Util::H2O::More> and
L<Dispatch::Fu> to make creating easily make API SaaS modules and
clients in a clean and idiomatic way. These kind of APIs tracked at
L<https://www.freepublicapis.com/> are really nice for fun and practice
because they don't require dealing with API keys in the vast majority of cases.

=head1 METHODS

=over 4

=item C<new>

Instantiates object reference. No parameters are accepted.

=item C<categories>

Makes the SaaS API call to get the list of categories. It accepts no arguments.

=item C<< random([category => STRING]) >>

Returns a random quote. Accepts a single optional parameter that will select the
random quote from a specific category.

=item C<< search( terms => STRING ) >>

Requires a single named parameter to specify the search terms. The resulting quotes
are returned as a L<Util::H2O::More> object. The following example is pulled right
out of the C<cnq> utilitye,

  my $cnq    = Acme::Free::API::ChuckNorris->new;
  my $ret    = $cnq->search(terms => $terms);
  my $quotes = $ret->result;
  printf STDERR "Found %d quotes\n", $ret->total;
  if ($ret->total == 0) {
    warn "warning: cnq: no results for '$terms'\n";
    exit;
  }
  foreach my $quote ($quotes->all) {
    say $quote->value;
  }

=back

=head1 C<cnq> OPTIONS

=over 4

=item C<categories>

Lists categories supported by the Chuck Norris Quote SaaS, this is as the
SaaS reports it presently (it uses an API call).

  shell> cnq categories
  Found 16 categories
   animal
   career
   celebrity
   dev
   explicit
   fashion
   food
   history
   money
   movie
   music
   political
   religion
   science
   sport
   travel

The first line is output via C<STDERR>, so you don't have to filter it out
if you wanted to do something wacky, like printing out 1 random quote for
each currently supported category:

  shell>cnq categories | xargs -I% cnq random --category %

=item C<random [--category STRING]>

The command that returns the random Chuch Noris quote. It is the default
command if none is specified:

  shell> cnq random
  Chuck Norris dunks onion rings in his morning coffee.
  shell> nq random
  Chuck Norris savors the sweet taste of ax-murder.
  shell> cnq random
  Chuck Norris puts the "hurt" in yoghurt.
  shell> cnq
  Chuck Norris' leg kicks hit hard enough to knock the polio vaccine out of your body
  shell>

There's an optional named a parameter, C<category>, that will narrow down
the quote to a category supported by the SaaS. To see what catagories are
available, use the C<categories> command. Only one C<--category> at a time
is supported.

The following command does what you expect,

  shell>cnq categories | xargs -I% cnq random --category %

=item C<search SEARCHTERMS>

This allows you to get some set of Chuck Norris Quotes based on search terms,
e.g.:

  shell> cnq search his computer
  Found 7 quotes
  Chuck Norris can gag you with a horrendous stinch simply by typing the word "fart" on his computer keyboard.
  Chuck Norris is so strong, he can roundhouse a bubbled paladin and blow his computer up.
  Whenever Chuck Norris watches pornography, his computer gets an erection.
  Chuck Norris drugged Bill Cosby. Cosby woke up nine hours later in front of his computer, where he realized he just told the net to meme him.
  When Chuck Norris switches on his computer, it skips the bootup process and goes straight to the desktop.
  Chuck Norris regularly smashes open his computer to eat the cookies within.
  a man once heard two guys talking about Chuck Norris.He went home and decided to look up who Chuck Norris is? He was suprised when it came to a blank screen, he tryed to click out of it untill a window popped up please wait. He waited a while a bar appeared saying now uploading Chuck Norris.He looked stuned when Chuck Norris crawled out of his computer to round house kick him in the face. this man now knows every fact about Chuck Norris.
  
Like C<categories>, the first line is printed via C<STDERR>.

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
