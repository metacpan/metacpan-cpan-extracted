#
# This file is part of Config-Model-Tester
#
# This software is Copyright (c) 2013-2020 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Tester::Setup 4.007;
# ABSTRACT: Common test setup functions for Config::Model

use warnings;
use strict;
use locale;
use utf8;
use 5.10.1;

use Test::More;
use Log::Log4perl 1.11 qw(:easy :levels);
use Path::Tiny;
use Getopt::Long;

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
    my @option_specs = qw/trace error log/;
    push @option_specs, @_;

    GetOptions( \my %opts,  @option_specs)
        || die "Unknown option. Expected options are '--".join("', '--",@option_specs)."'\n";

    if ($opts{error}) {
        Config::Model::Exception::Any->Trace(1);
    }

    my $model = Config::Model->new( );

    if ($opts{log}) {
        note("enabling logs and disabling test logs");
        $model->initialize_log4perl;
    }
    else {
        Log::Log4perl->easy_init( $ERROR );
        require Test::Log::Log4perl;
        Test::Log::Log4perl->import;
        Test::Log::Log4perl->ignore_priority("info");
    }

    ok( $model, "compiled" );

    return ($model, $opts{trace}, \%opts);
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

version 4.007

=head1 SYNOPSIS

 # in t/some_test.t
 use warnings;
 use strict;

 use Config::Model::Tester::Setup qw/init_test setup_test_dir/;

 my ($model, $trace) = init_test();

 # pseudo root where config files are written by config-model as setup
 # by init_test
 my $wr_root = setup_test_dir();

=head1 DESCRIPTION

This module provide 2 functions to setup a test environment that can
be used in most test involving L<Config::Model>.

=head1 FUNCTIONS

=head2 init_test

Scan test command line options and initialise a L<Config::Model> object.

Returns a list containing a L<Config::Model> object, a boolean and a
hash. The boolean is true if option C<--trace> was used on the command
line.

Default command options are:

=over

=item *

C<--error>: When set, error handled by L<Config::Model::Exception> shows a
strack trace when dying.

=item *

C<--log>: When set, L<Log::Log4perl> uses the config from file
C<~/.log4config-model> or the default config provided by
L<Config::Model>. By default, only Error level and above are shown.
Note that log tests are disabled when this option is set, so you may see a lot of
harmless Warning messages during tests (which depend on the tests to be run).
Experimental.

=back

More options can be passed to C<init_test> using option definitions
like the one defined in L<Getopt::Long> . The value of the command
line options are returned in the 3rd returned value.

For instance, for a test named C<t/my_test.t> calling :

  init_test('foo', 'bar=s')

The test file can be run with:

  perl t/my_test.t --foo --bar=baz --log --trace

C<init_test> returns:

  ($model, 1, { foo => 1, bar => 'baz', log => 1 , trace => 1, error => 0 })

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

This software is Copyright (c) 2013-2020 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
