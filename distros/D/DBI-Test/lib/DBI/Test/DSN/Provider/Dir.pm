package DBI::Test::DSN::Provider::Dir;

use strict;
use warnings;

use parent qw(DBI::Test::DSN::Provider::Base);

use File::Basename;
use File::Path;
use File::Spec;

use Carp qw(carp croak);

my $test_dir;
END { defined( $test_dir ) and rmtree $test_dir }

sub test_dir
{
    unless( defined( $test_dir ) )
    {
        $test_dir = File::Spec->rel2abs( File::Spec->curdir () );
        $test_dir = File::Spec->catdir ( $test_dir, "test_output_" . $$ );
        $test_dir = VMS::Filespec::unixify($test_dir) if $^O eq 'VMS';
        rmtree $test_dir;
        mkpath $test_dir;
        # There must be at least one directory in the test directory,
        # and nothing guarantees that dot or dot-dot directories will exist.
        mkpath ( File::Spec->catdir( $test_dir, '000_just_testing' ) );
    }

    return $test_dir;
}

sub get_dsn_creds
{
    my ($self, $test_case_ns, $default_creds) = @_;
    $default_creds or return;
    $default_creds->[0] or return;
    (my $driver = $default_creds->[0]) =~ s/^dbi:(\w*?)(?:\((.*?)\))?:.*/DBD::$1/i;
    # my $drh = $DBI::installed_drh{$driver} || $class->install_driver($driver)
    #   or die "panic: $class->install_driver($driver) failed";    
    eval "require $driver;";
    $@ and return;
    $driver->isa("DBD::File") or return;

    my @creds = @$default_creds;
    $creds[3]->{f_dir} = test_dir();
    return \@creds;
}

1;

=head1 NAME

DBI::Test::DSN::Provider::Dir - provide DSN in own directory

=head1 DESCRIPTION

This DSN provider delivers an owned directory for connection
attributes.

=head1 AUTHOR

This module is a team-effort. The current team members are

  H.Merijn Brand   (Tux)
  Jens Rehsack     (Sno)
  Peter Rabbitson  (ribasushi)

=head1 COPYRIGHT AND LICENSE

Copyright (C)2013 - The DBI development team

You may distribute this module under the terms of either the GNU
General Public License or the Artistic License, as specified in
the Perl README file.

=cut
