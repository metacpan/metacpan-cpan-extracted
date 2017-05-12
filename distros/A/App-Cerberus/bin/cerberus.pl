#!/usr/bin/env perl

use FindBin;
use lib 'lib';
use App::Cerberus();
use File::Spec::Functions qw(catfile);
use YAML qw(LoadFile);
use Pod::Usage;

use Carp;

my $conf_path;
my @args = @ARGV;
while ( my $val = shift @args ) {
    if ( $val eq '-h' or $val eq '--help' ) {
        pod2usage(0);
    }
    next unless $val eq '--conf';
    $conf_path = shift @args || '';
    last;
}
croak "No config path specified. Use --conf"
    unless $conf_path;

my $conf     = LoadFile($conf_path);
my $cerberus = App::Cerberus->new($conf);
my $app      = sub { $cerberus->request(@_) };

unless (caller) {
    require Plack::Runner;
    my $runner = Plack::Runner->new;
    my @plack_opts;
    for ( @{ $conf->{plack} || [] } ) {
        if ( ref eq 'HASH' ) {
            my ( $key, $val ) = %$_;
            push @plack_opts, "--$key", $val;
        }
        else {
            push @plack_opts, "--$_";
        }
    }
    $runner->parse_options( @plack_opts, @ARGV );
    return $runner->run($app);
}
return $app;

# ABSTRACT: Run App::Cerberus as a server
# PODNAME:  cerberus.pl

__END__

=pod

=encoding UTF-8

=head1 NAME

cerberus.pl - Run App::Cerberus as a server

=head1 VERSION

version 0.11

=head1 USAGE

Help instructions:

    cerberus.pl --help | -h

Run Cerbrus on port 5000 with basic PSGI server:

    cerberus.pl --conf /path/to/cerberus.yml

Run a Cerberus daemon on port 5001 with Starman:

    cerberus.pl --conf /path/to/cerberus.yml --port 5001 -s Starman -D

See L<http://metacpan.org/module/plackup> for more options which can be
passed to L<cerberus.pl>

See L<App::Cerberus/CONFIGURING CERBERUS> for more information.

=head1 AUTHOR

Clinton Gormley <drtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Clinton Gormley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
