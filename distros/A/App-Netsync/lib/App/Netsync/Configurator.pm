package App::Netsync::Configurator;

=head1 NAME

App::Netsync::Configurator - configuration file support

=head1 DESCRIPTION

This package makes using a configuration file simple.

=head1 SYNOPSIS

=over 2

=item F<foobar.ini>

 [testGroup]
 fooSetting = barValue
 barSetting = bazValue
 bazSetting = foo,bar,baz

=item F<foobar.pl>

 #!/usr/bin/env perl

 use feature 'say';

 use App::Netsync::Configurator;

 configurate 'foobar.ini';
 say  App::Netsync::Configurator::config('testGroup','fooSetting');
 say (App::Netsync::Configurator::config('testGroup','bazSetting'))[2];
 say {App::Netsync::Configurator::config('testGroup')}->{'barSetting'};

=back

 $ perl foobar.pl
 > barValue
 > baz
 > bazValue

=cut


use 5.006;
use strict;
use warnings FATAL => 'all';
use feature 'say';
use autodie; #XXX Is autodie adequate?

use File::Basename;
use Config::Simple;
use version;

our ($SCRIPT,$VERSION);
our %config;

BEGIN {
    ($SCRIPT)  = fileparse ($0,"\.[^.]*");
    ($VERSION) = version->declare('v4.0.0');

    require Exporter;
    our @ISA = ('Exporter');
    our @EXPORT_OK = ('configurate');
}


=head1 METHODS

=head2 configurate

reads a configuration file into the App::Netsync::Configurator namespace

I<Note: It will return any configurations in the file found under the E<lt>script nameE<gt> group.>

B<Arguments>

I<[ ( $file [, \%overrides [, \%defaults ] ] ) ]>

=over 3

=item file

a configuration file (.ini) to use

default: F</etc/E<lt>script nameE<gt>/E<lt>script nameE<gt>.ini>

=item overrides

settings that should override the configuration

=item defaults

default settings

=back

=cut

sub configurate {
    warn 'too many arguments' if @_ > 3;
    my ($file,$overrides,$defaults) = @_;
    $file      //= '/etc/'.$SCRIPT.'/'.$SCRIPT.'.ini';
    $overrides //= {};
    $defaults  //= {};

    {
        open (my $ini,'<',$file);
        my $parser = Config::Simple->new($file);
        my $syntax = $parser->guess_syntax($ini);
        unless (defined $syntax and $syntax eq 'ini') {
            say 'The configuration file "'.$file.'" is malformed.';
            return undef;
        }
        close $ini;
    }

    $config{$_} = $defaults->{$_} foreach keys %$defaults;

    {
        my %imports;
        Config::Simple->import_from($file,\%imports);
        foreach (keys %imports) {
            $config{$_} = $imports{$_} unless ref $imports{$_} and not defined $imports{$_}[0];
        }
    }

    $config{$_} = $overrides->{$_} foreach keys %$overrides;

    my %settings;
    foreach (keys %config) {
        $settings{$+{'setting'}} = $config{$_} if /^$SCRIPT\.(?<setting>.*)$/;
    }
    return %settings;
}


=head2 config

returns an individual setting or group of settings

I<Note: configurate needs to be run first!>

B<Arguments>

I<( $group [, $query ] )>

=over 3

=item group

the group of the configuration(s) to retrieve

=item query

the name of the configuration to retrieve

=back

=cut

sub config {
    warn 'too few arguments'  if @_ < 1;
    warn 'too many arguments' if @_ > 2;
    my ($group,$query) = @_;

    return $config{$group.'.'.$query} if defined $query;

    my $responses;
    foreach (keys %config) {
        if (/^(?<grp>[^.]*)\.(?<qry>.*)$/) {
            $responses->{$+{'qry'}} = $config{$_} if $+{'grp'} eq $group;
        }
    }
    return $responses;
}


=head2 dump

prints the current configuration (use sparingly)

I<Note: configurate needs to be run first!>

=cut

sub dump {
    warn 'too many arguments' if @_ > 0;

    say $_.' = '.($config{$_} // 'undef') foreach sort keys %config;
}


=head1 AUTHOR

David Tucker, C<< <dmtucker at ucsc.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-netsync at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Netsync>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

 perldoc App::Netsync

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Netsync>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Netsync>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Netsync>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Netsync/>

=back

=head1 LICENSE

Copyright 2013 David Tucker.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut


1;
