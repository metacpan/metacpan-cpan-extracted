package DBI::Test::DSN::Provider::Config;

use strict;
use warnings;

use parent qw(DBI::Test::DSN::Provider::Base);

require Cwd;
require File::Spec;

my $json;
my $have_config_any;
my $have_file_configdir;
my $have_file_find_rule;

BEGIN
{
    foreach my $mod (qw(JSON JSON::PP))
    {
        eval "require $mod";
        $@ and next;
        $json = $mod->new();
        last;
    }

    # $json or die "" . __PACKAGE__ . " requires a JSON parser";
    # finally ... Config::Any could be enough, and most recent
    # perl5 are coming with JSON::PP

    $have_file_configdir = 0;
    eval { require File::ConfigDir; ++$have_file_configdir; };

    $have_config_any = 0;
    eval { require Config::Any; ++$have_config_any; };

    $have_file_find_rule = 0;
    eval { require File::Find::Rule; ++$have_file_find_rule; };

    1;    # shadow whatever we did :D
}

sub relevance { 100 };

$have_file_configdir
  or *find_config_dirs = sub {
    my @confdirs = ( Cwd::getcwd(), $ENV{HOME} );
    return @confdirs;
  };

$have_file_configdir
  and *find_config_dirs = sub {
    # XXX File::ConfigDir could support config files per what-ever,
    # if we use
    #   config_dirs("dbi-test")

    my @confdirs = File::ConfigDir::config_dirs();
    return @confdirs;
  };

$have_config_any
  or *get_config_pattern = sub {
    my @pattern;
    $json and push( @pattern, "json" );
    @pattern;
  };

$have_config_any
  and *get_config_pattern = sub {
    my @pattern = Config::Any->extensions();
    return @pattern;
  };

$have_file_find_rule
  or *find_config_files = sub {
    my ( $self, $ns ) = @_;
    my @cfg_pattern = map { "dbi-test" . $_ } $self->get_config_pattern();
    my @cfg_dirs = $self->find_config_dirs();
    my @cfg_files;

    foreach my $dir (@cfg_dirs)
    {
        foreach my $pat (@cfg_pattern)
        {
            my $fn = File::Spec->catfile( $dir, $pat );
            -f $fn and -r $fn and push( @cfg_files, $fn );
        }
    }

    return @cfg_files;
  };

$have_file_find_rule
  and *find_config_files = sub {
    my ( $self, $ns ) = @_;
    my @cfg_pattern = map { "dbi-test" . $_ } $self->get_config_pattern();
    my @cfg_dirs    = $self->find_config_dirs();
    my @cfg_files   = File::Find::Rule->file()->name(@cfg_pattern)->maxdepth(1)->in(@cfg_dirs);
  };

$have_config_any
  or *read_config_files = sub {
    my ( $self, @config_files ) = @_;

    my $all_cfg;
    foreach my $cfg_fn (@config_files)
    {
        my $fh;
        open( $fh, "<", $cfg_fn ) or next;    # shouldn't happen, shall we die instead?
        local $/;
        my $cfg_cnt = <$fh>;
        close($fh);
        $all_cfg->{$cfg_fn} = $json->decode($cfg_cnt);
    }

    return $all_cfg;
  };

$have_config_any
  and *read_config_files = sub {
    my ( $self, @config_files ) = @_;

    my $all_cfg = Config::Any->load_files(
                                           {
                                             files           => [@config_files],
                                             use_ext         => 1,
                                             flatten_to_hash => 1,
                                           }
                                         );

    return $all_cfg;
  };

sub get_config
{
    my ($self) = @_;

    my %cfg;

    my @config_files = $self->find_config_files();
    my $all_cfg      = $self->read_config_files(@config_files);
    foreach my $filename (@config_files)
    {
        defined( $all_cfg->{$filename} )
          or next;    # file not found or not parsable ...
                      # merge into default and previous loaded config ...
        %cfg = ( %cfg, %{ $all_cfg->{$filename} } );
    }
    return %cfg;
}

sub get_dsn_creds
{
    my ( $self, $test_case_ns, $default_creds ) = @_;
    my %connect_details = ();
    $test_case_ns->can("connect_details")
      and %connect_details =
      ( %connect_details, %{ $test_case_ns->connect_details($test_case_ns) } );

    my %cfg = $self->get_config($test_case_ns);
    defined( $cfg{$test_case_ns} ) and return $cfg{$test_case_ns};
    defined( $cfg{"DBI::Test"} )   and return $cfg{"DBI::Test"};

    return;
}

1;

=head1 NAME

DBI::Test::DSN::Provider::Config - provides DSN based on config file

=head1 DESCRIPTION

This DSN provider delivers connection attributes based on a config
file.

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
