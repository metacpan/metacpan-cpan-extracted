package Alien::Build::Plugin::Cleanse::BuildDir;

use strict;
use warnings;
use 5.008001;
use Alien::Build;
use Alien::Build::Plugin;
use File::Path qw /remove_tree/;
use Cwd qw /getcwd/;
use Path::Tiny qw /path/;


our $VERSION = '0.06'; # VERSION


sub init {
    my($self, $meta) = @_;

    $meta->after_hook ( build => sub {
        my($build) = @_;
        
        return if $build->install_type ne 'share';
        return if $build->meta_prop->{out_of_source};

        my $build_dir = path ($build->install_prop->{extract})->absolute;

        if (!defined $build_dir) {
            $build->log ("Unable to determine build dir\n");
            return;
        }

        #  a spot of paranoia        
        #return if $build_dir !~ /\b_alien\b/;

        $build->log ("Going to delete $build_dir\n");
        $build->log ("Currently in " . getcwd() . "\n");

        my $curdir = getcwd();
        if (path($curdir)->subsumes ($build_dir)) {
            $build->log ("Going to parent of build directory\n");
            chdir "$build_dir/..";
        }
        
        my $count = eval {
            remove_tree ($build_dir, {
                safe => 1,
                #verbose => 1,
            });
        } || 0;
        $build->log ("Deleted $count items\n"); 
    });

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Alien::Build::Plugin::Cleanse::BuildDir - Alien::Build plugin to cleanse the build dir after the build phase

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use alienfile
    share {
        #  other commands to download, unpack and build etc.,
        #  and then:
        plugin 'Cleanse::BuildDir';
    };

 1;

=head1 DESCRIPTION

This plugin deletes the build directory after the alien module's build phase.
This is useful if your alien has a large build size.  It was
developed because the L<Alien::gdal> build footprint is enormous,
and was filling up disk space on cpan testers.

You should use it conditionally in your alienfile,
for example when you know the
build dir contents are not needed later.

Has no effect if you are running a non-share install,
or are using an out of source build
(although these are currently untested).

=head1 SEE ALSO

=over 4

=item L<Alien::Build>

=back

=head1 AUTHOR

Shawn Laffan <shawnlaffan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Shawn Laffan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


