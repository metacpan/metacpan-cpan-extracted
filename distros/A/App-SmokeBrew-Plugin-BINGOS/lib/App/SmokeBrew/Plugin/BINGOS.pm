package App::SmokeBrew::Plugin::BINGOS;
$App::SmokeBrew::Plugin::BINGOS::VERSION = '0.16';
#ABSTRACT: a smokebrew plugin to configure things like BINGOS does

use strict;
use warnings;
use Moose;

extends 'App::SmokeBrew::Plugin::CPANPLUS::YACSmoke';

has 'relay' => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has 'port' => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

sub _boxed {
my $self = shift;
return q+
BEGIN {
    use strict;
    use warnings;

    use Config;
    use FindBin;
    use File::Spec;
    use File::Spec::Unix;

    use vars qw[@RUN_TIME_INC $LIB_DIR $BUNDLE_DIR $BASE $PRIV_LIB];
    $LIB_DIR        = File::Spec->catdir( $FindBin::Bin, qw[.. lib] );
    $BUNDLE_DIR     = File::Spec->catdir( $FindBin::Bin, qw[.. inc bundle] );

    my $who     = getlogin || getpwuid($<) || $<;
    $BASE       = File::Spec->catfile(
                            $FindBin::Bin, '..', '.cpanplus', $who);
    $PRIV_LIB   = File::Spec->catfile( $BASE, 'lib' );

    @RUN_TIME_INC   = ($PRIV_LIB, @INC);
    unshift @INC, $LIB_DIR, $BUNDLE_DIR;

    $ENV{'PERL5LIB'} = join $Config{'path_sep'}, grep { defined }
                        $PRIV_LIB,              # to find the boxed config
                        $LIB_DIR,               # the CPANPLUS libs
                        $ENV{'PERL5LIB'};       # original PERL5LIB

}

use FindBin;
use File::Find                          qw[find];
use CPANPLUS::Error;
use CPANPLUS::Configure;
use CPANPLUS::Internals::Constants;
use CPANPLUS::Internals::Utils;

{   for my $dir ( ($BUNDLE_DIR, $LIB_DIR) ) {
        my $base_re = quotemeta $dir;

        find( sub { my $file = $File::Find::name;
                return unless -e $file && -f _ && -s _;

                return if $file =~ /\._/;   # osx temp files

                $file =~ s/^$base_re(\W)?//;

                return if $INC{$file};

                my $unixfile = File::Spec::Unix->catfile(
                                    File::Spec->splitdir( $file )
                                );
                my $pm       = join '::', File::Spec->splitdir( $file );
                $pm =~ s/\.pm$//i or return;    # not a .pm file

                #return if $pm =~ /(?:IPC::Run::)|(?:File::Spec::)/;

                eval "require $pm ; 1";

                if( $@ ) {
                    push @failures, $unixfile;
                }
            }, $dir );
    }

    delete $INC{$_} for @failures;

    @INC = @RUN_TIME_INC;
}


my $ConfObj     = CPANPLUS::Configure->new;
my $Config      = CONFIG_BOXED;
my $Util        = 'CPANPLUS::Internals::Utils';
my $ConfigFile  = $ConfObj->_config_pm_to_file( $Config => $PRIV_LIB );

{   ### no base dir even, set it up
    unless( IS_DIR->( $BASE ) ) {
        $Util->_mkdir( dir => $BASE ) or die CPANPLUS::Error->stack_as_string;
    }

    unless( -e $ConfigFile ) {
        $ConfObj->set_conf( base    => $BASE );     # new base dir
        $ConfObj->set_conf( verbose => 1     );     # be verbose
        $ConfObj->set_conf( prereqs => 1     );     # install prereqs
        $ConfObj->set_conf( prefer_bin => 1 );
        $ConfObj->set_conf( prefer_makefile => 1 ); # prefer Makefile.PL because of v5.10.0
        $ConfObj->set_conf( enable_custom_sources => 0 ); # install prereqs
        $ConfObj->set_conf( hosts => + . $self->_mirrors . q+ );
        $ConfObj->set_program( sudo => undef );
        $ConfObj->save(     $Config => $PRIV_LIB ); # save the pm in that dir
    }
}

{
    $Module::Load::Conditional::CHECK_INC_HASH = 1;
    use CPANPLUS::Backend;
    my $cb = CPANPLUS::Backend->new( $ConfObj );
    my $su = $cb->selfupdate_object;

    $cb->module_tree( 'Test::More' )->install() if $] == 5.010000; # need this because 'version'
    $cb->module_tree( 'parent' )->install() if $] < 5.010001; # need this because 'version'
    $cb->module_tree( 'version' )->install(); # Move this here too because EUMM icky is icky :S
    $cb->module_tree( 'ExtUtils::MakeMaker' )->install(); # Move this here because icky is icky >:)
    $cb->module_tree( 'Module::Build' )->install(); # Move this here because perl-5.10.0 is icky

    $su->selfupdate( update => 'dependencies', latest => 1 );
    $cb->module_tree( $_ )->install() for
      qw(
          CPANPLUS
          File::Temp
          Compress::Raw::Bzip2
          Compress::Raw::Zlib
          Compress::Zlib
          ExtUtils::CBuilder
          ExtUtils::ParseXS
          ExtUtils::Manifest
          Log::Message::Simple
          Test::Reporter::Transport::Socket
          CPANPLUS::YACSmoke
      );
    $_->install() for map { $su->modules_for_feature( $_ ) } qw(prefer_makefile md5 storable cpantest);
}
+;
}

sub _cpconf {
  my $self = shift;
  my $cpconf = q+
use strict;
use warnings;
use Getopt::Long;
use CPANPLUS::Configure;

my $mx;
my $email;

GetOptions( 'mx=s', \$mx, 'email=s', \$email );

my $conf = CPANPLUS::Configure->new();
$conf->set_conf( verbose => 1 );
$conf->set_conf( prefer_bin => 1 );
$conf->set_conf( cpantest => 'dont_cc' );
$conf->set_conf( 'cpantest_reporter_args' =>
    {
      transport       => 'Socket',
      transport_args  => [ host => +;
  $cpconf .= sprintf( "'%s', port => '%s' ] } );", $self->relay, $self->port );
  $cpconf .= q+
$conf->set_conf( email => $email );
$conf->set_conf( makeflags => 'UNINST=1' );
$conf->set_conf( buildflags => 'uninst=1' );
$conf->set_conf( enable_custom_sources => 0 );
$conf->set_conf( show_startup_tip => 0 );
$conf->set_conf( write_install_logs => 0 );
$conf->set_conf( hosts => +;
  $cpconf .= $self->_mirrors() . ');';
  $cpconf .= q+
$conf->set_program( sudo => undef );
$conf->save();
exit 0;
+;
return $cpconf;
}

no Moose;

__PACKAGE__->meta->make_immutable;

qq[Smokin'];

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SmokeBrew::Plugin::BINGOS - a smokebrew plugin to configure things like BINGOS does

=head1 VERSION

version 0.16

=head1 SYNOPSIS

  # smokebrew.cfg

  [BINGOS]
  relay = myrelay
  port = 8080

  # then run

  $ smokebrew --plugin App::SmokeBrew::Plugin::BINGOS

=head1 DESCRIPTION

App::SmokeBrew::Plugin::BINGOS is a L<App::SmokeBrew::Plugin> for L<smokebrew> which
configures the built perl installations for CPAN Testing with L<CPANPLUS::YACSmoke> and
sending test reports to a L<metabase-relayd> host using L<Test::Reporter::Transport::Socket>.

It will set up the L<CPANPLUS> / L<CPANPLUS::YACSmoke> base locations to be in the C<conf> directory
under the given C<prefix> directory with a directory for each perl version.

=head1 CONFIGURATION

This plugin requires two attributes: C<relay> - the hostname or IP address of a L<metabase-relayd>
host and C<port> - the TCP port of the L<metabase-relayd> on that host.

These attributes should be specified in the C<smokebrew.cfg> file under a named section:

  [BINGOS]

  relay = some.host
  port = 8080

=head1 METHODS

=over

=item C<configure>

Called by L<smokebrew> to perform the CPAN Testing configuration.

=back

=head1 SEE ALSO

L<App::SmokeBrew::Plugin>

L<smokebrew>

L<CPANPLUS>

L<CPANPLUS::YACSmoke>

L<metabase-relayd>

L<Test::Reporter::Transport::Socket>

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
