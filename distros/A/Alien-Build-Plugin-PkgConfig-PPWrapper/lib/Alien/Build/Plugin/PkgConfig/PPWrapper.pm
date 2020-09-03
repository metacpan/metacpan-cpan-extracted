package Alien::Build::Plugin::PkgConfig::PPWrapper;

use strict;
use warnings;
use 5.008001;
use Alien::Build;
use Alien::Build::Plugin;
use Path::Tiny qw /path/;
use File::Which ();

our $VERSION = '0.01'; # VERSION


sub init {
    my($self, $meta) = @_;

    $meta->around_hook ( build => sub {
        my ($orig, $build, @args) = @_;
        
        return if $build->install_type ne 'share';
        return if $build->meta_prop->{out_of_source};

        #  wrapper is only needed on windows
        return $orig->($build, @args)
          if not $^O =~ /mswin/i;

        my $pk = File::Which::which ($ENV{PKG_CONFIG})
              || File::Which::which ('ppkg-config')
              || File::Which::which ('pkg-config');

        if (!defined $pk) {
            $build->log ("Could not locate ppkg-config or pkg-config in your path\n");
            return $orig->($build, @args);
        }

        $pk =~ s/\.bat$//i;
        if (!(-e $pk && -e "$pk.bat")) {
            $build->log ("$pk unlikely to be pure perl");
            return $orig->($build, @args);
        }

        my $perl = $^X;
        $perl =~ s/\.exe$//i;
        foreach my $path ($perl, $pk) {
            $path =~ s{\\}{/}g;
            $path =~ s{^([a-z]):/}{/$1/}i;
            $path =~ s{\s}{\\ }g;
        }

        my $wrapper = <<'EOWRAPPER'
#!perl
system ('##perl##', '##pk##', @ARGV);
exit $?;
EOWRAPPER
  ;

        $wrapper =~ s/##perl##/$perl/gsm;
        $wrapper =~ s/##pk##/$pk/;

        $build->log ("Pure perl pkg-config detected on windows.\n");
        $build->log ("Wrapping $pk in shell script to cope with MSYS perl and paths.\n");
        my $fname = Path::Tiny->new(File::Temp::tempdir( CLEANUP => 1 ))->child('pkg-config');
        open my $fh, '>', $fname
          or die "Unable to open pkg-config wrapper $fname, $!";
        print {$fh} $wrapper;
        close ($fh);
        $build->log ("Setting \$ENV{PKG_CONFIG} to point to $fname\n");
        
        local $ENV{PKG_CONFIG} = $fname;
        
        return $orig->($build, @args);
    });

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Plugin::PkgConfig::Wrapper
- Alien::Build plugin to ensure the pure perl PkgConfig is not run by the MSYS perl 

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use alienfile
    share {
        #  other commands to download, unpack etc.,
        #  and then:
        plugin 'PkgConfig::PPWrapper';
        
        #  followed by any build commands
    };

 1;

=head1 DESCRIPTION

The pure perl L<PkgConfig> script works well, but when called by
L<Alien::Build::Plugin::Build::Autoconf> on Windows it is
called using the MSYS perl due to its shebang line.
This leads to issues with path separators in C<$ENV{PKG_CONFIG_PATH}>.

This plugin generates a wrapper script that ensures that the perl
running the alienfile is also used to call the pkg-config.pl
script.

It has (should have) no effect on non-Windows operating systems,
or when the pure-perl pkg-config is not being used.

=head1 SEE ALSO

=over 4

=item L<Alien::Build>

=back

=head1 AUTHOR

Shawn Laffan <shawnlaffan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Shawn Laffan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


