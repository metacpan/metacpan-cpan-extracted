package Acme::Free::API::Ye;

use strict;
use warnings;

our $VERSION = '1.0.1';

use HTTP::Tiny;
use JSON            qw/decode_json/;
use Util::H2O::More qw/baptise d2o/;

use constant {
    BASEURL => "https://api.kanye.rest",
};

sub new {
    my $pkg  = shift;
    my $self = baptise { ua => HTTP::Tiny->new }, $pkg;
    return $self;
}

sub get {
    my $self = shift;
    my $resp = d2o $self->ua->get(BASEURL);
    return d2o decode_json $resp->content;
}

sub quote {
    my $self = shift;
    return $self->get->quote;
}

1;

__END__

=head1 NAME

Acme::Free::API::Ye - Perl API client for the Kanye Rest Quote API service, L<https://kanye.rest/>.

This module provides the client, "ye", that is available via C<PATH> after install.

=head1 SYNOPSIS

  #!/usr/bin/env perl
    
  use strict;
  use warnings;
  
  use Acme::Free::API::Ye qw//;
  
  my $ye = Acme::Free::API::Ye->new;

  printf "%s\n", $ye->quote;

=head2 C<ye> Commandline Client

After installing this module, simply run the command C<ye> without any arguments, and it will print
a random Kanye Rest quote to C<STDOUT>.

  shell> ye
  If I don't scream, if I don't say something then no one's going to say anything. 
  shell> ye
  Culture is the most powerful force in humanity under God
  shell>

=head1 DESCRIPTION

Contributed as part of the B<FreePublicPerlAPIs> Project described at,
L<https://github.com/oodler577/FreePublicPerlAPIs>.

This fun module is to demonstrate how to use L<Util::H2O::More> to make
creating easily make API SaaS modules and clients in a clean and idiomatic
way. These kind of APIs tracked at L<https://www.freepublicapis.com/> are
really nice for fun and practice because they don't require dealing with
API keys in the vast majority of cases.

=head1 METHODS

=over 4

=item C<new>

Instantiates object reference. No parameters are accepted.

=item C<quote>

Object method that returns the random Kanye West quote using the Kanye Rest SaaS.

=back

=head2 Internal Methods

=over 4

=item C<get>

Called internally by C<quote>. This method uses L<HTTP::Tiny> to call to the API.
Then L<Util::H2O::More::d2o> is used to deal with the resulting respons that has
an accessor called C<quote>. This is what's invoked that returns the actual quote
string.

=back

=head1 ENVIRONMENT

Nothing special required.

=head1 AUTHOR

Brett Estrade L<< <oodler@cpan.org> >>

=head1 BUGS

Please report.

=head1 LICENSE AND COPYRIGHT

Same as Perl/perl.
