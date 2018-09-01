
use strict;
use warnings;

use Syntax::Construct qw[ // ];

package Shared::Example::Context::Singleton;

our $VERSION = v1.0.0;

use parent 'Exporter::Tiny';

our @EXPORT = (
	qw[ it_should_export ],
	qw[ it_should_know_about_singleton ],
);

use Test::More;
use Hash::Util;

require Context::Singleton;

sub it_should_export {
	my ($name) = @_;

	ok caller->can ($name), "it should export $name";
}

sub it_should_know_about_rule {
    my (%params) = @_;

	Hash::Util::lock_keys %params,
		qw[ db ],
		qw[ frame ],
		qw[ singleton ],
		;

    my $db = $params{db};
	$db //= $params{frame}->db if exists $params{frame};
	$db //= Context::Singleton::Frame::DB->instance;

    my $status = $db->find_builder_for ($params{singleton});

	ok $status, "should know builder(s) for singleton $params{singleton}";
};

1;
