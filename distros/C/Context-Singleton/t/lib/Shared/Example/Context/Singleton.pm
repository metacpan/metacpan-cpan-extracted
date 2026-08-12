
use v5.10;
use strict;
use warnings;

use Syntax::Construct qw[ // ];

package Shared::Example::Context::Singleton;

our $VERSION = v1.0.0;

use parent q (Exporter::Tiny);

our @EXPORT = (
	qw[ it_should_export ],
	qw[ it_should_know_about_singleton ],
);

use Test::More;
use Hash::Util;

require Context::Singleton;

sub it_should_export {
	my ($name) = @_;

	ok caller->can ($name), qq (it should export $name);
}

sub it_should_know_about_rule {
	my (%params) = @_;

	Hash::Util::lock_keys %params,
		qw[ db ],
		qw[ frame ],
		qw[ singleton ],
		;

	my $db = $params{db};
	$db //= $params{frame}->db
		if exists $params{frame}
		;
	$db //= Context::Singleton::Frame::DB->instance;

	my $status = $db->search_builder_for ($params{singleton});

	ok $status, qq (should know builder(s) for singleton $params{singleton});
};

1;
