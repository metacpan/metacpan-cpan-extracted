package App::SocialSKK::Plugin::SocialIME;
use strict;
use warnings;
use URI;
use URI::QueryParam;
use base qw(App::SocialSKK::Plugin);

sub get_candidates {
    my ($self, $text) = @_;
    return if ($text || '') eq '';

    my $uri  = URI->new('http://www.social-ime.com/api/');
       $uri->query_param(string => $text);
    my $res = $self->ua->get($uri);
    if ($res->is_success) {
        map { s|\s*$||smg; $_ } grep { $_ !~ /^\s*$/ } split /\t/, $res->content;
    }
}

1;

__END__

=head1 NAME

App::SocialSKK::Plugin::SocialIME - Retrieves Candidates from Social
IME

=head1 SYNOPSIS

  # Add a line like below into your .socialskk:
  plugins:
    - name: SocialIME

=head1 DESCRIPTION

App::SocialSKK::Plugin::SocialIME performs retrieval of candidates
from Social IME. This plugin will be used by default in socialskk.pl
without any configuration in .socialskk.

=head1 SEE ALSO

=over 4

=item * Social IME

http://www.social-ime.com/

=back

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>
