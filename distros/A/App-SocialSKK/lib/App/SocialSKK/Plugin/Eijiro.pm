package App::SocialSKK::Plugin::Eijiro;
use strict;
use warnings;
use URI;
use URI::QueryParam;
use URI::Escape;
use Jcode;
use base qw(App::SocialSKK::Plugin);

sub get_candidates {
    my ($self, $text) = @_;
    return if ($text || '') eq '';

    $text = Jcode->new($text, 'euc')->utf8;
    my $uri = URI->new('http://eowbeta.alc.co.jp/eow/sg/?q=');
       $uri->query_param(q => $text);
    my $res = $self->ua->get($uri);
    if ($res->is_success) {
        map {
            my $word = uri_unescape($_);
            Jcode->new($word, 'utf8')->euc;
        } $res->content =~ m!<word>(.+?)</word>!g;
    }
}

1;

__END__

=head1 NAME

App::SocialSKK::Plugin::Eijiro - Retrieves Candidates from Eijiro

=head1 SYNOPSIS

  # Add a line like below into your .socialskk:
  plugins:
    - name: Eijiro

=head1 DESCRIPTION

App::SocialSKK::Plugin::Wikipedia performs retrieval of candidates
from Eijiro incremental search API.

=head1 SEE ALSO

=over 4

=item * Eijiro

http://eowbeta.alc.co.jp/

=back

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>
