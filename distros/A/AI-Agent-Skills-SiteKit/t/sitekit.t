use strict;
use warnings;
use Test::More tests => 8;
use lib 'lib';
use AI::Agent::Skills::SiteKit qw(home_url skills_url search_url submit_url blog_url category_url skill_url metadata);

is(home_url(), 'https://aiagentskills.net', 'homepage');
is(skills_url(), 'https://aiagentskills.net/skills/', 'skills');
is(submit_url(), 'https://aiagentskills.net/submit/', 'submit');
is(blog_url(), 'https://aiagentskills.net/blog/', 'blog');
is(category_url('agent-workflows'), 'https://aiagentskills.net/category/agent-workflows/', 'category');
is(skill_url('seo-article-writer'), 'https://aiagentskills.net/skill/seo-article-writer/', 'skill');
is(search_url('codex skills'), 'https://aiagentskills.net/skills/?q=codex%20skills', 'search');
is(metadata()->{homepage}, 'https://aiagentskills.net', 'metadata homepage');
