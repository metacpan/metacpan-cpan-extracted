package App::financeta::utils;
use strict;
use warnings;
use 5.10.0;
use Data::Dumper ();
use Exporter qw(import);
use Log::Any '$log', filter => \&log_filter;
use Try::Tiny;
use File::ShareDir 'dist_file';
use File::Spec::Functions qw(rel2abs catfile);
use Cwd qw(getcwd);

our $VERSION = '0.13';
$VERSION = eval $VERSION;
our @EXPORT_OK = (
    qw(dumper log_filter get_icon_path)
);

sub dumper {
    Data::Dumper->new([@_])->Indent(1)->Sortkeys(1)->Terse(1)->Useqq(1)->Dump;
}

sub log_filter {
    my ($c, $l) = (shift, shift);
    ## copied from Log::Any::Adapter::Util
    my %levels = (
        0 => 'EMERGENCY',
        1 => 'ALERT',
        2 => 'CRITICAL',
        3 => 'ERROR',
        4 => 'WARNING',
        5 => 'NOTICE',
        6 => 'INFO',
        7 => 'DEBUG',
        8 => 'TRACE',
    );
    return "[$levels{$l}]($c) @_";
}

sub get_icon_path {
    my @args = @_;
    my $icon_path;
    my $filename = 'chart-line-solid.png';#'icon.gif';
    my $distname = 'App-financeta';
    try {
        $icon_path = dist_file($distname, $filename);
    } catch {
        $log->warn("Failed to find icon. Error: $_");
        $icon_path = undef;
    };
    unless ($icon_path) {
        my $dist_share_path = rel2abs(catfile(getcwd, 'share'));
        try {
            $log->debug("icon backup dist-share path: $dist_share_path");
            ## find all packages and search for all of them
            if (@args) {
                foreach (@args) {
                    $File::ShareDir::DIST_SHARE{$_} = $dist_share_path;
                }
            }
            $File::ShareDir::DIST_SHARE{$distname} = $dist_share_path;
            $icon_path = dist_file($distname, $filename);
        } catch {
            $log->warn("Failed to find icon in $dist_share_path. Error: $_");
            $icon_path = undef;
        };
    };
    $log->debug("Icon path: $icon_path") if defined $icon_path;
    if (defined $icon_path and -e $icon_path) {
        return $icon_path;
    } else {
        $log->warn("No icon found, using system icon");
        return undef;
    }
}

1;
__END__
### COPYRIGHT: 2014-2023 Vikas N. Kumar. All Rights Reserved.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>
### DATE: 1st Jan 2023
### LICENSE: Refer LICENSE file

=head1 NAME

App::financeta::utils

=head1 SYNOPSIS

App::financeta::utils is an internal utility library for App::financeta.

=head1 VERSION

0.11


=head1 METHODS

=over

=item B<dumper>

L<Data::Dumper> with the Terse option set.

=back

=head1 SEE ALSO

=over

=item L<App::financeta::gui>

This is the GUI internal details being used by C<App::financeta>.

=item L<financeta>

The commandline script that calls C<App::financeta>.

=back

=head1 COPYRIGHT

Copyright (C) 2013-2023. Vikas N Kumar <vikas@cpan.org>. All Rights Reserved.

=head1 LICENSE

This is free software. You can redistribute it or modify it under the terms of
GNU General Public License version 3. Refer LICENSE file in the top level source directory for more
information.
