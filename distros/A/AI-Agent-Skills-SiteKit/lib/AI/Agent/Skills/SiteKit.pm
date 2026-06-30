package AI::Agent::Skills::SiteKit;
use strict;
use warnings;
use Exporter 'import';
use URI::Escape qw(uri_escape);

our $VERSION = '0.1.0';
our @EXPORT_OK = qw(home_url skills_url search_url submit_url blog_url category_url skill_url url_for metadata);

sub base_url { return 'https://aiagentskills.net' }
sub clean_slug { my $s = shift // ''; $s =~ s!^/+!!; $s =~ s!/+$!!; return $s; }
sub url_for { my $clean = clean_slug(shift // ''); return $clean eq '' ? base_url() : base_url() . '/' . $clean . '/'; }
sub home_url { return base_url() }
sub skills_url { return url_for('skills') }
sub submit_url { return url_for('submit') }
sub blog_url { return url_for('blog') }
sub category_url { return url_for('category/' . clean_slug(shift)) }
sub skill_url { return url_for('skill/' . clean_slug(shift)) }
sub search_url { my $q = shift // ''; $q =~ s/^\s+|\s+$//g; return $q eq '' ? skills_url() : base_url() . '/skills/?q=' . uri_escape($q); }
sub metadata {
    return {
        name => 'AI Agent Skills',
        homepage => base_url(),
        description => 'Curated directory for Claude skills, Codex skills, and AI agent workflows.',
        tags => [qw(aiagentskills skills agents claude codex)],
    };
}
1;
__END__

=head1 NAME

AI::Agent::Skills::SiteKit - URL helpers for AI Agent Skills

=head1 SYNOPSIS

  use AI::Agent::Skills::SiteKit qw(skills_url search_url);
  my $skills = skills_url();
  my $search = search_url('codex skills');

=head1 DESCRIPTION

Small metadata and URL helpers for L<AI Agent Skills|https://aiagentskills.net>.

=cut
