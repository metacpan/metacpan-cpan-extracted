package Config::PL;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.02";

use Carp ();
use Cwd ();
use File::Basename ();

our @EXPORT = qw/config_do/;
our %CONFIG;

sub import {
    my ($pkg, @args) = @_;
    my $caller = caller;

    my @export;
    if (@args) {
        push @export, shift(@args) while $args[0] && $args[0] !~ '^:';
        my %conf = @args;
        $CONFIG{path} = $conf{':path'} if exists $conf{':path'};
    }
    @export = @EXPORT unless @export;

    for my $func (@export) {
        Carp::croak "'$func' is not exportable function" unless grep {$_ eq $func} @EXPORT;

        no strict 'refs';
        *{"$caller\::$func"} = \&$func;
    }
}

sub config_do($) {
    my $config_file = shift;
    my (undef, $file,) = caller;

    my $config;
    {
        local @INC = (Cwd::getcwd, File::Basename::dirname($file));
        push @INC, $CONFIG{path} if defined $CONFIG{path};

        $config = do $config_file;
    }

    Carp::croak $@ if $@;
    Carp::croak $! unless defined $config;
    unless (ref $config eq 'HASH') {
        Carp::croak "$config_file does not return HashRef.";
    }

    wantarray ? %$config : $config;
}

1;
__END__

=encoding utf-8

=head1 NAME

Config::PL - Using '.pl' file as a configuration

=head1 SYNOPSIS

    use Config::PL;
    my $config = config_do 'config.pl';
    my %config = config_do 'config.pl';

=head1 DESCRIPTION

Config::PL is a utility module for using '.pl' file as a configuration.

This module provides C<config_do> function for loading '.pl' file.

Using '.pl' file which returns HashRef as a configuration is good idea.
We can write flexible and DRY configuration by it.
(But, sometimes it becomes too complicated :P)

C<< do "$file" >> idiom is often used for loading configuration.

But, there is some problems and L<< Config::PL >> cares these problems.

=head2 Ensure returns HashRef

C<< do EXPR >> function of Perl core is not sane because it does not die
when the file contains parse error or is not found.

C<config_do> function croaks errors and ensures that the returned value is HashRef.

=head2 Expected file loading

C<< do "$file" >> searches files in C<< @INC >>. It sometimes causes intended file loading.

C<< config_do >> function limits the search path only in C<< cwd >> and C<< basename(__FILE__) >>.

You can easily load another configuration file in the config files as follows.

    # config.pl
    use Config:PL;
    config_do "$ENV{PLACK_ENV}.pl";

You need not write C<< do File::Spec->catfile(File::Basename::dirname(__FILE__), 'config.pl') ... >> any more!

You can add search path by specifying path as follows. (EXPERIMENTAL)

    use Config::PL ':path' => 'path/config/dir';

B<THIS SOFTWARE IS IN ALPHA QUALITY. IT MAY CHANGE THE API WITHOUT NOTICE.>

=head1 FUNCTION

=head2 C<< my ($conf|%conf) = config_do $file_name; >>

Loading configuration from '.pl' file.

=head1 LICENSE

Copyright (C) Masayuki Matsuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=cut

