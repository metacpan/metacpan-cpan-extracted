package App::SocialSKK::Plugin::Wikipedia;
use strict;
use warnings;
use URI;
use URI::QueryParam;
use URI::Escape;
use JSON::Syck;
use Jcode;
use Encode::JavaScript::UCS;
use base qw(App::SocialSKK::Plugin);

sub get_candidates {
    my ($self, $text) = @_;
    return if ($text || '') eq '';

    $text = Jcode->new($text, 'euc')->utf8;
    my $uri  = URI->new('http://ja.wikipedia.org/w/api.php');
       $uri->query_param(action    => 'opensearch');
       $uri->query_param(namespace => 0);
       $uri->query_param(search    => $text);
    my $res = $self->ua->get($uri);
    if ($res->is_success) {
        my $array = JSON::Syck::Load($res->content);
        map {
            my $text = Encode::JavaScript::UCS::decode('JavaScript-UCS', $_);
               $text = Jcode->new($text, 'utf8')->euc;
        } @{$array->[-1]};
    }
}

1;

__END__

=head1 NAME

App::SocialSKK::Plugin::Wikipedia - Retrieves Candidates from
Wikipedia

=head1 SYNOPSIS

  # Add a line like below into your .socialskk:
  plugins:
    - name: Wikipedia

=head1 DESCRIPTION

App::SocialSKK::Plugin::Wikipedia performs retrieval of candidates
from Wikipedia suggest API.

=head1 SEE ALSO

=over 4

=item * Wikipedia

http://ja.wikipedia.org/

=back

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>
