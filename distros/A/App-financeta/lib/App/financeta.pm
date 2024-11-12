package App::financeta;
use strict;
use warnings;
use 5.10.0;
use App::financeta::utils qw(dumper log_filter);
use Log::Any '$log', filter => \&App::financeta::utils::log_filter;
use Log::Any::Adapter 'Stderr';
use App::financeta::gui;

our $VERSION = '0.15';
$VERSION = eval $VERSION;

sub print_banner {
    my $pkg = shift || __PACKAGE__;
    my $this_year = (gmtime)[5] + 1900;
    my $license = <<"LICENSE";
    $pkg  Copyright (C) 2013-$this_year  Vikas N Kumar <vikas\@cpan.org>
    This program comes with ABSOLUTELY NO WARRANTY; for details read the LICENSE
    file in the distribution.This is free software, and you are welcome to
    redistribute it under certain conditions. The developers are not responsible
    for any profits or losses incurred due to the use of this software. Use at your own
    risk and with your own intelligence.
LICENSE
    print STDERR $license, "\n";
    return;
}

sub get_version { return $VERSION; }

sub print_version_and_exit {
    die __PACKAGE__ . " Version $VERSION\n";
}

sub run {
    my @args = @_;
    shift @args if (@args and ($args[0] eq __PACKAGE__ or ref($args[0]) eq __PACKAGE__));
    my %opts = @args;
    delete $opts{help};
    delete $opts{version};
    my $log_level;
    $opts{verbose} //= 0;
    if ($opts{verbose} >= 3) {
        $log_level = 'trace';
    } elsif ($opts{verbose} eq 2 or $opts{debug}) {
        $log_level = 'debug';
    } elsif ($opts{quiet} or $opts{verbose} eq 0) {
        $log_level = 'warn';
    } else {
        $log_level = 'info';
    }
    delete $opts{quiet};
    Log::Any::Adapter->set('Stderr', log_level => $log_level);
    $log->debug("Options sent to the Gui: " . dumper(\%opts));
    $log->debug("Setting log level to $log_level");
    my $gui = App::financeta::gui->new(
        log_level => $log_level,
        debug => $opts{debug},
        brand => __PACKAGE__,
        plot_engine => $opts{plot_engine} // 'gnuplot',
    );
    return $gui->run;
}

1;
__END__
### COPYRIGHT: 2013-2023 Vikas N. Kumar. All Rights Reserved.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>
### DATE: 15th Aug 2014
### LICENSE: Refer LICENSE file

=head1 NAME

App::financeta

=head1 SYNOPSIS

App::financeta is a high level module that uses App::financeta::gui and invokes it
as an application. It handles command line processing of C<financeta>.

=head1 VERSION

0.15

DESCRIPTION

The documentation is detailed at http://vikasnkumar.github.io/financeta/

The github repository is at https://github.com/vikasnkumar/financeta.git

=head1 METHODS

=over

=item B<run>

This function starts the graphical user interface (GUI) and parses command line
arguments. It invokes L<App::financeta::gui>.

=item B<print_warning>

This function prints license and disclaimer to C<STDERR>.

=back

=head1 SEE ALSO

=over

=item L<App::financeta::gui>

This is the GUI internal details being used by C<App::financeta>.

=item L<financeta>

The commandline script that calls C<App::financeta>.

=back

=head1 DEPENDENCIES FOR DEVELOPERS

=over

=item B<Linux>

For Linux, such as Debian/Ubuntu based systems like Debian Bullseye or Ubuntu 20.04 LTS, you want the following packages installed:

    libheif-dev libwebp-dev libxpm-dev libgtk-3-dev libgtkmm-3.0-dev libpng-dev libjpeg-dev libtiff-dev gnuplot

Then you build L<Prima>, L<PDL>, L<PDL::Graphics::Gnuplot>, L<PDL::Graphics::Simple>, L<Mo>, L<IO::All>.

=item B<Windows>

For Windows you need Strawberry Perl installed and install L<Prima>, L<PDL>, L<PDL::Graphics::Prima>, L<PDL::Graphics::Gnuplot>, L<PDL::Graphics::Simple>.

You will want to install Gnuplot 5.2.8 from their website. The version that is 5.4 and above is not supported at the moment due to issues with IPC.

=item B<Mac OSX>

It is quite a lot of work to get this working on Mac OSX. We have tested it on Monterey. You will need HomeBrew from <https://brew.sh> setup and install the following packages: B<gnuplot>, B<xorg-server>, B<cmake>, B<openssl>, B<perl>, B<xinit>, B<fribidi>, B<pkg-config>, B<xquartz>, B<dk/libthai/libthai>, B<libheif>, B<gtk+3>.

It may or may not work here.

=back

=head1 COPYRIGHT

Copyright (C) 2013-2023. Vikas N Kumar <vikas@cpan.org>. All Rights Reserved.

=head1 LICENSE

This is free software. You can redistribute it or modify it under the terms of
GNU General Public License version 3. Refer LICENSE file in the top level source directory for more
information.
