# -*- perl -*-
use lib qw(t lib);
use strict;
use Test;
use TestConfig;

plan(tests => 9);

my $t = new TestConfig(
    config => [
	base => '/etc',
	'file.passwd.mode' => '0644',
	'file.passwd.root.uid' => 0,
	'file.passwd.root.dir' => '/root',
    ],
    lexicon => {
	base => 1,
	file => {
	    section => {
		passwd => {
		    section => {
			mode => 1,
			root => {
			    section => {
				uid => 1,
				dir => 1
			    }
			},
		    }
		},
  	        skel => 1
	    }
	},
	other => {
	    section => {
		x => {
		    section => {
			y => 1
		    }
		}
	    }
	}
    });

ok($t->base->is_leaf);
ok($t->base, '/etc');
ok($t->file->is_section);
ok($t->file->passwd->is_section);
ok($t->file->passwd->root->dir);
ok($t->file->passwd->root->dir,'/root');
ok($t->file->skel->is_null);
eval { $t->nonexistent };
ok($@ =~ m{Can't locate object method "nonexistent" via package "Config::AST::Follow"});
ok($t->other->x->y->is_null);
