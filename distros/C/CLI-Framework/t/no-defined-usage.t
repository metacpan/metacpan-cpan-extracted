use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More qw( no_plan );
use My::DemoNoUsage;

@ARGV = qw( );
#@ARGV = qw( a );
my $app = My::DemoNoUsage->new();
ok( $app->run() );

#my $output_printed = ?
#FIXME-TODO:need to capture the output printed to STDOUT into $output_printed)
#is( $output_printed, $app->get_default_usage(), 'default usage message was printed' );

__END__

=pod

=head1 PURPOSE

To test that usage() falls back to Getopt::Long::Descriptive usage text when
no usage_text() method is provided by the CLIF Application.

=cut
