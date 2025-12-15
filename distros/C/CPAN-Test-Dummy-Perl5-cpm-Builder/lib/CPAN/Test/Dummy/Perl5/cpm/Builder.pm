package CPAN::Test::Dummy::Perl5::cpm::Builder;
use strict;
use warnings;

use CPAN::Meta ();
use ExtUtils::Helpers ();
use ExtUtils::Install ();
use ExtUtils::InstallPaths ();
use File::Copy ();
use File::Find ();
use File::Spec ();
use Getopt::Long ();
use JSON::PP ();

our $VERSION = '2.1';

my $BUILD_TEMPLATE = <<'TEMPLATE';
#!perl
use strict;
use warnings;
use CPAN::Test::Dummy::Perl5::cpm::Builder;
use JSON::PP ();

CPAN::Test::Dummy::Perl5::cpm::Builder::function_that_only_exists_in_v2();

my $config_argv = JSON::PP->new->utf8->decode(<<'EOF');
  %s
EOF
CPAN::Test::Dummy::Perl5::cpm::Builder::Build($config_argv, @ARGV);
TEMPLATE

sub function_that_only_exists_in_v2 {
}

sub Build_PL {
    if ($ENV{PERL_MB_OPT}) {
        push @ARGV, ExtUtils::Helpers::split_like_shell($ENV{PERL_MB_OPT});
    }
    Getopt::Long::GetOptions 'install_base=s' => \my $install_base, 'config=s@' => \my @config or die;
    my $config_argv = JSON::PP->new->canonical->encode({ install_base => $install_base, config => \@config });
    open my $fh, ">", "Build" or die;
    printf {$fh} $BUILD_TEMPLATE, $config_argv;
    close $fh;
    ExtUtils::Helpers::make_executable("Build");
    File::Copy::copy("META.json", "MYMETA.json") or die;
}

sub Build {
    my $config_argv = shift;
    my $action = shift || "build";

    if ($action eq "build") {
        my @lib = _find( qr/\.pm$/, "lib");
        my @script = _find( qr/(?:)/, "bin", "script" );
        ExtUtils::Install::pm_to_blib( { map { ($_, File::Spec->catfile("blib", $_)) } @lib, @script } );
        ExtUtils::Helpers::make_executable($_) for map { File::Spec->catfile("blib", $_) } @script;
    } elsif ($action eq "test") {
        # noop
    } elsif ($action eq "install") {
        my $meta = CPAN::Meta->load_file("META.json");
        my $paths = ExtUtils::InstallPaths->new(
            dist_name => $meta->name,
            $config_argv->{install_base} ? (install_base => $config_argv->{install_base}) : (),
        );
        ExtUtils::Install::install( $paths->install_map );
    } else {
        die "unknown action: $action\n";
    }
}

sub _find {
    my $regexp = shift;
    my @dir = grep { -d $_ } @_;
    return if !@dir;
    my @file; my $wanted = sub { push @file, $_ if -f $_ && $_ =~ /$regexp/ };
    File::Find::find( { wanted => $wanted, no_chdir => 1 }, @dir );
    return @file;
}

1;
__END__

=encoding utf-8

=head1 NAME

CPAN::Test::Dummy::Perl5::cpm::Builder - a dummy builder

=head1 SYNOPSIS

  use CPAN::Test::Dummy::Perl5::cpm::Builder;
  CPAN::Test::Dummy::Perl5::cpm::Builder::Build_PL();

=head1 DESCRIPTION

CPAN::Test::Dummy::Perl5::cpm::Builder is a dummy module
created to demonstrate issues that can occur during CPAN module installation.

See L<https://github.com/skaji/cpm/issues/269>.

=head1 COPYRIGHT AND LICENSE

Copyright 2025 Shoichi Kaji <skaji@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
