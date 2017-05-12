use strict;
use warnings;
use lib qw( ./lib ../lib );

use Cwd;
use CSS::Inliner;

my $url = shift || 'http://www.cpan.org/index.html';

my $inliner = CSS::Inliner->new({ post_fetch_filter => \&post_fetch_filter });
$inliner->fetch_file({ url => $url });
my $inlined = $inliner->inlinify();

warn "================ FINAL HTML ===============";

print $inlined;

warn "================ ERRORS ===============";
foreach my $warning (@{$inliner->content_warnings}) {
  warn $warning;
}

sub post_fetch_filter { 
  my ($params) = @_;

  warn "execute filter";

  return $$params{html};
};
