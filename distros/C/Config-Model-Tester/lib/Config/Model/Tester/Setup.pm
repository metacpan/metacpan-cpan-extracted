#
# This file is part of Config-Model-Tester
#
# This software is Copyright (c) 2013-2018 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Tester::Setup;
# ABSTRACT: Common test setup functions for Config::Model
$Config::Model::Tester::Setup::VERSION = '3.004';
use warnings;
use strict;
use locale;
use utf8;
use 5.10.1;

use Test::More;
use Log::Log4perl 1.11 qw(:easy :levels);
use Path::Tiny;
#use File::Copy::Recursive qw(fcopy rcopy dircopy);
use Getopt::Std;

#use Test::Warn;
#use Test::Exception;
#use Test::File::Contents ;
#use Test::Differences;
#use Test::Memory::Cycle ;

# use eval so this module does not have a "hard" dependency on Config::Model
# This way, Config::Model can build-depend on Config::Model::Tester without
# creating a build dependency loop.
eval {
    require Config::Model;
    require Config::Model::Exception;
} ;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(init_test setup_test_dir);

sub init_test {
    my %opts;
    getopts('tel', \%opts);

    if ($opts{e}) {
        Config::Model::Exception::Any->Trace(1);
    }

    if (not $opts{l}) {
        Log::Log4perl->easy_init( $ERROR );
    }

    my $model = Config::Model->new( );

    ok( $model, "compiled" );

    return ($model, $opts{t});
}

sub setup_test_dir {
    my %args = @_;

    my $script = path($0);
    my $name = path($0)->basename('.t');

    my $wr_root = path('wr_root')->child($name);
    note("Running tests in $wr_root");
    $wr_root->remove_tree;
    $wr_root->mkpath;

    # TODO: remove stringify once Config::Model::Instance can handle Path::Tiny
    return $args{stringify} ? $wr_root->stringify.'/' : $wr_root;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Tester::Setup - Common test setup functions for Config::Model

=head1 VERSION

version 3.004

=head1 SYNOPSIS

 # in t/some_test.t
 use warnings;
 use strict;

 use Config::Model::Tester::Setup qw/init_test setup_test_dir/;

 my ($model, $trace) = init_test(shift);

 # pseudo root where config files are written by config-model as setup
 # by init_test
 my $wr_root = setup_test_dir();

=head1 DESCRIPTION

This module provide 2 functions to setup a test environment that can
be used in most test involving L<Config::Model>.

=head1 FUNCTIONS

=head2 init_test

Scan test command line options and initialise a L<Config::Model> object.

Returns a list containing a L<Config::Model> object and a
boolean. This boolean is true if option C<-t> was used.
''t'.

Options are:

=over

=item *

C<-e>: When set, error handled by L<Config::Model::Exception> shows a
strack trace when dying.

=item *

C<-l>: When set, L<Log::Log4perl> uses the config from file
C<~/.log4config-model> or the default config provided by
L<Config::Model>. Without 'l', only Error level and above are shown.
Experimental.

=back

=head2 setup_test_dir

Cleanup and create a test directory in
C<wr_root/test-script-name>. For instance this function creates
directory C<wr_root/foo> for test C<t/foo.t>

Returns a L<Path::Tiny> object of the test directory or a string if
C<setup_test_dir> is called with C<< stringify => 1 >>.

=head1 SEE ALSO

=over 4

=item *

L<Config::Model>

=item *

L<Test::More>

=back

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013-2018 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
