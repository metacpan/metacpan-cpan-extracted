package App::SocialSKK::Plugin::HatenaBookmark;
use strict;
use warnings;
use XML::RSS;
use Jcode;
use base qw(App::SocialSKK::Plugin);

__PACKAGE__->mk_accessors(qw(limit));

sub get_candidates {
    my ($self, $text) = @_;
    return if ($text || '') eq '';

    my @candidates;
    $text = Jcode->new($text, 'euc')->utf8;
    if ($text =~ /(?:はてぶにんききじ|ほってんとり)/) {
        my $rss   = XML::RSS->new(version => '1.0');
        my $uri   = URI->new('http://feedproxy.google.com/hatena/b/hotentry');
        my $res   = $self->ua->get($uri);
        my $limit = $self->limit || 10;
        if ($res->is_success) {
            eval { $rss->parse($res->content) };
            return if $@;

            my $i = 0;
            for my $entry (@{$rss->{items}}) {
                last if ++$i >= $limit;
                my $candidate = sprintf '%s;%s',
                    $entry->{title} || '', $entry->{description} || '';
                push @candidates, Jcode->new($candidate, 'utf8')->euc;
            }
            return @candidates;
        }
    }
}

1;

__END__

=head1 NAME

App::SocialSKK::Plugin::HatenaBookmark - Retrieves Candidates from
Hatena::Bookmark

=head1 SYNOPSIS

  # Add a line like below into your .socialskk:
  plugins:
    - name: Hatena::Bookmark
      config:
        limit: 5

=head1 DESCRIPTION

App::SocialSKK::Plugin::HatenaBookmakr performs retrieval of
candidates from Hatena::Bookmark

=head1 SEE ALSO

=over 4

=item * Hatena::Bookmark

http://b.hatena.ne.jp/

=back

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentaro@cpan.orgE<gt>
