package Catalyst::Plugin::File::RotateLogs;
use strict;
use warnings;
use MRO::Compat;
our $VERSION = "0.05";

sub setup {
    my $c = shift;
    my $home = $c->config->{home};
    my $config = $c->config->{'File::RotateLogs'} || {
        logfile  => "${home}/root/error_log.%Y%m%d%H",
        linkname => "${home}/root/error_log",
        rotationtime => 86400, #default 1day
        maxage => 86400 * 3,   #3day
        autodump => 0,
    };
    $config->{maxage} = int eval($config->{maxage});
    $c->log((__PACKAGE__ . '::Backend')->new($config));
    return $c->maybe::next::method(@_);
}

package Catalyst::Plugin::File::RotateLogs::Backend;
use Moose;
use Time::Piece;
use File::RotateLogs;

BEGIN { extends 'Catalyst::Log' }

my $ROTATE_LOGS; 
my $CALLER_DEPTH = 1; 
my $AUTODUMP     = 0;

sub new {
    my $class = shift;
    my $config  = shift;

    $AUTODUMP = $config->{autodump} //= 0;
    delete $config->{autodump};

    my $self  = $class->next::method();
    $ROTATE_LOGS = File::RotateLogs->new($config);

    return $self;
}

{
    foreach my $handler (qw/debug info warn error fatal/) {
        override $handler => sub {
            my ($self, $message) = @_; 
            if ($AUTODUMP && ref($message) ) {
                local $Data::Dumper::Terse = 1;
                local $Data::Dumper::Indent = 0;
                local $Data::Dumper::Sortkeys = 1;
                $message = Data::Dumper::Dumper($message);
            }
            my ($package, $file, $line) = caller($CALLER_DEPTH); 
            #todo: enables to change a format
            $ROTATE_LOGS->print(sprintf(qq{%s: [%s] [%s] %s at %s line %s\n},
                    localtime->datetime, uc $handler, $package, $message, $file, $line));
        };

    }
}

1;
__END__

=pod

=head1 NAME

Catalyst::Plugin::File::RotateLogs - Catalyst Plugin for File::RotateLogs

=head1 SYNOPSIS

    # plugin is loaded
    use Catalyst qw/ 
        ConfigLoader
        Static::Simple
        File::RotateLogs
    /;

    $c->log->info("hello catalyst"); 

    # Catalyst configuration by default (e. g. in YAML format):
    File::RotateLogs:
        logfile: '/[absolute path]/root/error.log.%Y%m%d%H' 
        linkname: '/[absolute path]/root/error.log'
        rotationtime: 86400
        maxage: 86400 * 3
        autodump: 0

=head1 DESCRIPTION

This module allows you to initialize File::RotateLogs within the application's configuration. File::RotateLogs is utility for file logger and very simple logfile rotation. I wanted easier catalyst log rotation.

=head1 SEE ALSO

=over 2

=item L<Catalyst::Log>

=item L<File::RotateLogs>

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

masakyst E<lt>masakyst.public@gmail.comE<gt>

=cut
