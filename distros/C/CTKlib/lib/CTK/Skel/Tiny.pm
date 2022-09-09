package CTK::Skel::Tiny;
use strict;
use utf8;

=encoding utf8

=head1 NAME

CTK::Skel::Tiny - Tiny project skeleton for CTK::Helper

=head1 VIRSION

Version 1.02

=head1 SYNOPSIS

none

=head1 DESCRIPTION

Tiny project skeleton for CTK::Helper

no public methods

=head2 build, dirs, pool

Main methods. For internal use only

=head1 SEE ALSO

L<CTK::Skel>, L<CTK::Helper>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use constant SIGNATURE => "tiny";

use vars qw($VERSION);
$VERSION = '1.02';

sub pool {
    my $self = shift;
    my $pos =  tell DATA;
    my $data = scalar(do { local $/; <DATA> });
    seek DATA, $pos, 0;
    $self->{pools}{(SIGNATURE)} = $data;
    $self->maybe::next::method();
    return 1;
}

1;

__DATA__

-----BEGIN FILE-----
Name: %PROJECT_NAMEL%
File: %PROJECT_NAMEL%
Mode: 711

#!/usr/bin/perl -w
use strict;

%PODSIG%head1 NAME

%PROJECT_NAMEL% - blah-blah-blah

%PODSIG%head1 SYNOPSIS

    %PROJECT_NAMEL% [options] [commands [args]]

    %PROJECT_NAMEL% [-dvlty] [-c /path/to/%PROJECT_NAMEL%.conf] [commands [args]]

%PODSIG%head1 OPTIONS

%PODSIG%over

%PODSIG%item B<-c /path/to/file.conf, --config=/path/to/file.conf>

Sets config file

Default: /etc/%PROJECT_NAMEL%/%PROJECT_NAMEL%.conf

%PODSIG%item B<-d, --debug>

Print debug information on STDOUT

%PODSIG%item B<-h, --help>

Show short help information and quit

%PODSIG%item B<-H, --longhelp>

Show long help information and quit

%PODSIG%item B<-l, --log>

Writing debug information in log

%PODSIG%item B<-t, --test>

Enable test mode

%PODSIG%item B<-v, --verbose>

Verbose option. Include Verbose debug data in the STDOUT and to error-log output

%PODSIG%item B<-y, --yes>

Example of custom flag

%PODSIG%back

%PODSIG%head1 COMMANDS

%PODSIG%over

%PODSIG%item B<test>

Test of the project

    %PROJECT_NAMEL% test

%PODSIG%back

%PODSIG%head1 DESCRIPTION

blah-blah-blah

See C<README> file

%PODSIG%head1 HISTORY

See C<Changes> file

%PODSIG%head1 TO DO

See C<TODO> file

%PODSIG%head1 SEE ALSO

L<CTK>

%PODSIG%head1 AUTHOR

%AUTHOR% L<%HOMEPAGE%> E<lt>%ADMIN%E<gt>

%PODSIG%head1 COPYRIGHT

Copyright (C) %YEAR% %AUTHOR%. All Rights Reserved

%PODSIG%head1 LICENSE

This program is distributed under the GNU GPL v3.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

%PODSIG%cut

use Getopt::Long;
use Pod::Usage;
use CTK::App;

use constant {
        PROJECTNAME => '%PROJECT_NAME%',
    };

my %options;
Getopt::Long::Configure("bundling");
GetOptions(\%options,
    # NoUsed keys map:
    #
    # a A b B   C   D e E
    # f F g G     i I j J
    # k K   L m M n N o O
    # p P q Q r R s S   T
    # u U   V w W x X   Y
    # z Z
    "help|usage|h",         # Show help page
    "longhelp|H",           # Show long help page
    "debug|d",              # Debug mode
    "verbose|v",            # Verbose mode
    "log|l",                # Log mode (monm_debug.log)
    "test|testmode|t",      # Test mode
    "config|c=s",           # Config file
    "yes|y",                # Use defaults
) || pod2usage(-exitval => 1, -verbose => 0, -output => \*STDERR);
pod2usage(-exitval => 0, -verbose => 1) if $options{help};
pod2usage(-exitval => 0, -verbose => 2) if $options{longhelp};
my $command = shift(@ARGV);
my @arguments = @ARGV ? @ARGV : ();

# CTK Singleton instance
my $app = CTK::App->new(
        project => '%PROJECT_NAME%',
        #ident   => '%PROJECT_NAMEL%',
        options => {%options},
        debug   => $options{debug},
        verbose => $options{verbose},
        log     => $options{log},
        test    => $options{test},
        $options{config} ? (configfile => $options{config}) : (),
    );

$app->register_handler(
    handler     => "test",
    description => sprintf("%s Testing", PROJECTNAME),
    MyCustomDirective => "Blah-Blah-Blah",
    params => {
            Foo => "one",
            Bar => 123,
        },
    code => sub {
### CODE:
    my ($self, $meta, @arguments) = @_;
    printf("Testing \"%s\" project...\n", $self->project);

    printf "CLI arguments      : %s\n", join(", ", @arguments) if @arguments;
    printf "Config file        : %s\n", $self->configfile;
    printf "Config status      : %s\n", $self->conf("loadstatus")
            ? "loaded"
            : "not loaded. use --config=/path/to/foo.conf";
    printf "The \"Yes\" option   : %s\n", $self->option("yes") ? "on" : "off";
    printf "Debug mode         : %s\n", $self->debugmode ? "on" : "off";
    printf "Verbose mode       : %s\n", $self->verbosemode ? "on" : "off";
    printf "Log mode           : %s\n", $self->logmode ? "on" : "off";
    printf "Test mode          : %s\n", $self->testmode ? "on" : "off";
    printf "Time               : %s\n", $self->tms;
    printf "CTK status         : %s\n", $self->status ? "ok" : "error";
    printf "CTK error          : %s\n", $self->error || '';
    printf "CTK version        : %s\n", $self->VERSION;
    printf "CTK revision       : %s\n", $self->revision;
    printf "CTK prefix         : %s\n", $self->prefix;
    printf "CTK suffix         : %s\n", $self->suffix;
    printf "Data dir           : %s\n", $self->datadir;
    printf "Log dir            : %s\n", $self->logdir;
    printf "Temp dir           : %s\n", $self->tempdir;
    printf "Root dir           : %s\n", $self->root;
    printf "Exe dir            : %s\n", $self->exedir;
    printf "Log file           : %s\n", $self->logfile;
    printf "Temp file          : %s\n", $self->tempfile;
    $self->debug("Debug test string");
    $self->log_debug("Log debug test string");
    return 1;
});

pod2usage(-exitval => 1, -verbose => 99, -sections => 'SYNOPSIS|OPTIONS|COMMANDS', -output => \*STDERR)
    unless $command && grep {$_ eq $command} ($app->list_handlers());

# Run
my $exitval = $app->run($command, @arguments) ? 0 : 1;
printf STDERR "%s: %s\n", $app->project, $app->error if $exitval && $app->error;

exit $exitval;
-----END FILE-----
