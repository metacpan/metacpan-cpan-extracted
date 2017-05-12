package Config::PP;
use strict;
use warnings;

use parent 'Exporter';
our @EXPORT  = qw(config_get config_set);

use Data::Dumper;
use File::Spec;
use Carp;

our $VERSION = '0.04';
our $DIR     = File::Spec->catfile($ENV{HOME}, '.ppconfig');

# path: $DIR/${namespace}.pl

sub config_get ($) {
    my $namespace = shift;
    my $path = path($namespace);
    local $@;
    return (do $path or Carp::croak "$!$@" ? "$!$@: $path" : "Can't find config: $path");
}

sub config_set ($$) {
    my ($namespace, $data) = @_;
    my $path = path($namespace);

    open my $fh, ">", $path or Carp::croak "$!: $path";
    print {$fh} Dumper($data);
    close $fh or Carp::croak $!;
}

sub path {
    my $namespace = shift;

    unless (-d $DIR) {
        mkdir $DIR, 0700 or Carp::croak "Can't mkdir: $DIR";
    }

    File::Spec->catfile($DIR, "${namespace}.pl");
}

1;
__END__

=head1 NAME

Config::PP - lightweight configuration file manager that uses Pure Perl to serialize.

=head1 SYNOPSIS

  use Config::PP; # exports config_set() and config_get()

  config_set "example.com", {
    email    => 'foo@example.com'
    password => 'barbaz'
  };

  print Dumper config_get "example.com";

=head1 DESCRIPTION

Config::PP is lightweight configuration file manager that uses Pure Perl to serialize.

=head1 FUNCTIONS

C<config_set()> and C<config_get()> throw exception on error.

=head2 config_set $namespace, $configuration

Saves configuration file into C<"$Config::PP::DIR/$namespace.pl">.

=head2 config_get $namespace

Loads configuration from C<"$Config::PP::DIR/$namespace.pl">.

=head1 Configuration Variables

=head2 C<$Config::PP::DIR>

Default directory is C<"$ENV{HOME}/.ppconfig">.

You can configure the path to save configuration file.

=head1 AUTHOR

punytan E<lt>punytan@gmail.comE<gt>

=head1 SEE ALSO

L<Config::Pit>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
