package Catalyst::Plugin::Log4perl::Simple;
{
  $Catalyst::Plugin::Log4perl::Simple::DIST = 'Catalyst-Plugin-Log4perl-Simple';
}
{
  $Catalyst::Plugin::Log4perl::Simple::VERSION = '0.005';
}
# ABSTRACT: Simple Log4perl setup for Catalyst application
use Moose;
use Log::Log4perl::Catalyst;
use List::Util qw( first );
use namespace::autoclean;



sub setup {
    my $package = shift;
    my $pkgname = ref $package || $package;
    my $confname = lc $pkgname;
    $confname =~ s/::/_/g;

    my $logpath = first { -s $_ } (
        "${confname}_log.conf", "log.conf",
        "../${confname}_log.conf", "../log.conf",
        "/etc/${confname}_log.conf", "/etc/$confname/log.conf"
    );
    if (defined $logpath) {
        $package->log(Log::Log4perl::Catalyst->new($logpath));
    } else {
        $package->log(Log::Log4perl::Catalyst->new());
        $package->log->warn('no log4perl configuration found');
    }

    $package->maybe::next::method(@_);
}


__PACKAGE__->meta->make_immutable;

__END__
=pod

=head1 NAME

Catalyst::Plugin::Log4perl::Simple - Simple Log4perl setup for Catalyst application

=head1 VERSION

version 0.005

=head1 SYNOPSIS

 use Catalyst qw/ ... Log4Perl::Simple /;

 $c->log->warn("Now we're logging through Log4perl");

=head1 DESCRIPTION

This is a trivial Catalyst plugin that searches for a log4perl configuration
file and uses it to configure Log::Log4perl::Catalyst as the logger for your
application. If no configuration is found, a sensible default is provided.

For an application My::App, the following locations are searched:

=over 4

=item my_app_log.conf

=item log.conf

=item ../my_app_log.conf

=item ../log.conf

=item /etc/my_app_log.conf

=item /etc/my_app/log.conf

=back

=for test_synopsis my $c;

=head1 METHODS

=head2 setup

Called by Catalyst to set up the plugin. You should not need to call this yourself.

=head1 BUGS

There is no test suite.

=head1 SEE ALSO

Log::Log4perl::Catalyst

=head1 AUTHOR

Peter Corlett <abuse@cabal.org.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Peter Corlett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

