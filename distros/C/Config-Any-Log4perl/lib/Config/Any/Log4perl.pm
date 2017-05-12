#
# This file is part of Config-Any-Log4perl
#
# This software is copyright (c) 2012 by Loïc TROCHET.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Config::Any::Log4perl;
{
  $Config::Any::Log4perl::VERSION = '0.130020';
}
# ABSTRACT: Config::Any loader for Log4perl config files

use strict;
use warnings;

use Config::Any::Base;
use parent qw(Config::Any::Base);


sub extensions
{
    return qw(log4perl);
}


sub load
{
    my $class = shift;
    my $file  = shift;
    my $args  = shift || {};

    open(FILE, $file) or die "Failed to open file <$file>: $!";
    my @lines  = <FILE>;

    return {} unless grep /\S/, @lines;

    my $config = {};

    while (@lines)
    {
        local $_ = shift @lines;
        s/^\s*#.*//;
        next unless /\S/;

        while (/(.+?)\\\s*$/)
        {
            my $prev = $1;
            my $next = shift @lines;
            $next =~ s/^ +//g;
            $next =~ s/^#.*//;
            $_ = $prev . $next;
            chomp;
        }

        if (my ($key, $val) = /(\S+?)\s*=\s*(.*)/)
        {
            $val =~ s/\s+$//;
            $config->{$key} = $val;
        }
    }

    return exists $args->{config_name} ? { $args->{config_name} => $config } : $config;
}

1;

__END__

=pod

=head1 NAME

Config::Any::Log4perl - Config::Any loader for Log4perl config files

=head1 VERSION

version 0.130020

=head1 SYNOPSIS

    use Config::Any;

    ...

    my $config = Config::Any->load_files({
          files => \@files
        , use_ext => 1
        , driver_args => { Log4perl => { config_name => 'logger' }}
    });

    ...

See L<Config::Any>

=head1 DESCRIPTION

Loads Log4perl configuration files.

Example:

    ### sample.log4perl
    log4perl.logger                                   = TRACE, SCREEN
    log4perl.appender.SCREEN                          = Log::Log4perl::Appender::Screen
    log4perl.appender.SCREEN.stderr                   = 1
    log4perl.appender.SCREEN.layout                   = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.SCREEN.layout.ConversionPattern = %d %-5p [%5P] %m%n

=head1 METHODS

=head2 extensions

Return an array of valid extensions.

=over

=item I<Return value>

ARRAY - qw( log4perl ).

=back

=head2 load($file, $args)

Attempts to load a Log4perl config file.

=over

=item I<Parameters>

C<$file> - SCALAR - The Log4perl config file.

C<$args> - HASHREF - optional - Possible options:

=over

B<config_name> - A key used to store configuration.

=back

=item I<Return value>

HASHREF - Log4perl configuration.

=item I<Example>

With this Log4perl configuration file:

    ### sample.log4perl
    log4perl.logger                                   = TRACE, SCREEN
    log4perl.appender.SCREEN                          = Log::Log4perl::Appender::Screen
    log4perl.appender.SCREEN.stderr                   = 1
    log4perl.appender.SCREEN.layout                   = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.SCREEN.layout.ConversionPattern = %d %-5p [%5P] %m%n

If B<config_name> is undefined the return value is:

    {
        'log4perl.appender.SCREEN.layout' => 'Log::Log4perl::Layout::PatternLayout',
        'log4perl.appender.SCREEN.layout.ConversionPattern' => '%d %-5p [%5P] %m%n',
        'log4perl.appender.SCREEN.stderr' => '1',
        'log4perl.logger' => 'TRACE, SCREEN',
        'log4perl.appender.SCREEN' => 'Log::Log4perl::Appender::Screen'
    }

If B<config_name> is defined like this:

    config_name => 'logger'

the return value is:

    {
        'logger' => {
            'log4perl.appender.SCREEN.layout' => 'Log::Log4perl::Layout::PatternLayout',
            'log4perl.appender.SCREEN.layout.ConversionPattern' => '%d %-5p [%5P] %m%n',
            'log4perl.appender.SCREEN.stderr' => '1',
            'log4perl.appender.SCREEN' => 'Log::Log4perl::Appender::Screen',
            'log4perl.logger' => 'TRACE, SCREEN'
        }
    }

=back

=head1 SEE ALSO

L<Log::Log4perl>

=encoding utf8

=head1 AUTHOR

Loïc TROCHET <losyme@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Loïc TROCHET.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
