package CLIDTest::Sub::Cmd::Help;

use strict;
use warnings;
use base qw( CLI::Dispatch::Help );

sub extra_namespaces {qw( CLIDTest::Manual )}

1;

__END__

=head1 名称

CLIDTest::Sub::Cmd::Help - ヘルプ

=head1 概要

ヘルプを表示する
