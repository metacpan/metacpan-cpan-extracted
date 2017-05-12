package App::financeta;
use strict;
use warnings;
use 5.10.0;

our $VERSION = '0.10';
$VERSION = eval $VERSION;

use App::financeta::gui;
use Carp;

sub print_warning {
    my $pkg = shift || __PACKAGE__;
    my $license = <<"LICENSE";
    $pkg  Copyright (C) 2014  Vikas N Kumar <vikas\@cpan.org>
    This program comes with ABSOLUTELY NO WARRANTY; for details read the LICENSE
    file in the distribution.
    This is free software, and you are welcome to redistribute it
    under certain conditions.
    The developers are not responsible for any profits or losses due to use of this software.
    Use at your own risk and with your own intelligence.
LICENSE
    print STDERR "$license\n";
}

sub run {
    my @args = @_;
    shift @args if (@args and $args[0] eq __PACKAGE__);
    my %opts = @args;
    if ($opts{version}) {
        print __PACKAGE__ . " Version $VERSION\n";
        return;
    }
    if ($opts{help}) {
        print "Help: Coming soon\n";
        return;
    }
    my $gui = App::financeta::gui->new(debug => $opts{debug},
        brand => __PACKAGE__,
    );
    $gui->run;
}

1;
__END__
### COPYRIGHT: 2014 Vikas N. Kumar. All Rights Reserved.
### AUTHOR: Vikas N Kumar <vikas@cpan.org>
### DATE: 15th Aug 2014
### LICENSE: Refer LICENSE file

=head1 NAME

App::financeta

=head1 SYNOPSIS

App::financeta is a high level module that uses App::financeta::gui and invokes it
as an application. It handles command line processing of C<financeta>.

=head1 VERSION

0.10

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

=head1 COPYRIGHT

Copyright (C) 2013-2014. Vikas N Kumar <vikas@cpan.org>. All Rights Reserved.

=head1 LICENSE

This is free software. You can redistribute it or modify it under the terms of
GNU General Public License version 3. Refer LICENSE file in the top level source directory for more
information.
