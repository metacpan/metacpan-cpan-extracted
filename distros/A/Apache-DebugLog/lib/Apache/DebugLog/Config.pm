package Apache::DebugLog::Config;

use warnings FATAL => 'all';
use strict;
use Carp    ();

=head1 NAME

Apache::DebugLog::Config - Multidimensional debug logging in mod_perl

=head1 VERSION

Version 0.02

=cut

our ($VERSION, @DIRECTIVES, $IMPORT_GOT_RUN);

BEGIN {
    $VERSION        = '0.02';
    $IMPORT_GOT_RUN = 0;

    eval { require mod_perl2 };

    # this should be defined by something else
    if ($mod_perl2::VERSION) {
        require Apache2::Module;
        require Apache2::CmdParms;
        require Apache2::Const;
        Apache::Const->import(-compile => qw(TAKE1 ITERATE OR_ALL));
    }
    else {
        *Apache2::Module::add = sub { @_ } unless $Apache2::Module::{add};
        sub Apache2::Const::TAKE1   () { 'TAKE1'     }
        sub Apache2::Const::ITERATE () { 'ITERATE'   }
        sub Apache2::Const::OR_ALL  () { 'OR_ALL'    }
    }


    @DIRECTIVES = (
        {
            name            =>  'PerlDebugLogLevel',
            func            =>  __PACKAGE__ . '::_set_loglevel',
            errmsg          =>  'PerlDebugLogLevel number',
            args_how        =>  Apache2::Const::TAKE1,
            req_override    =>  Apache2::Const::OR_ALL,
        },
        {
            name            =>  'PerlDebugLogDomain',
            func            =>  __PACKAGE__ . '::_add_domain',
            errmsg          =>  'PerlDebugLogDomain first +second -third',
            args_how        =>  Apache2::Const::ITERATE,
            req_override    =>  Apache2::Const::OR_ALL,
        },
    );

}

#    Apache2::Module::add('Apache2::DebugLog', \@DIRECTIVES) 
#        if ($mod_perl2::VERSION);

#BEGIN {
#    Carp::croak(__PACKAGE__ . "loaded without call to import().") 
#        if ($mod_perl2::VERSION && $ENV{MOD_PERL} && !$IMPORT_GOT_RUN);
#}

sub import {
    Apache2::Module::add((caller)[0], \@DIRECTIVES) 
        if ($mod_perl2::VERSION && $ENV{MOD_PERL});
    $IMPORT_GOT_RUN++;
}

sub _set_loglevel {
    my ($cfg, $parms, $level) = @_;
    $cfg->{level} = $level;
    unless ($parms->path) {
        my $scfg = Apache2::Module::get_config($cfg, $parms->server);
        $scfg->{level} = $level;
    }
}

sub _add_domain {
    my ($cfg, $parms, $domain) = @_;
    my ($op) = ($domain =~ s/^[+-]//);
    $cfg->{domain} ||= {};
    $cfg->{domain}{$domain} = $op eq '-' ? 0 : 1;
    unless ($parms->path) {
        my $scfg = Apache2::Module::get_config($cfg, $parms->server);
        $scfg->{domain} ||= {};
        $scfg->{domain}{$domain} = $op eq '-' ? 0 : 1;
    }
}

=head1 SYNOPSIS

    # httpd.conf

    # without this, you won't see a thing. ;)
    LogLevel debug

    # load new configuration directives via mod_perl 2
    <IfModule mod_perl2.c>
    # presumably these use Apache2::DebugLog
    PerlLoadModule My::Module
    PerlLoadModule My::SecondModule
    PerlLoadModule My::ThirdModule
    </IfModule>

    # load new configuration directives via mod_perl 1
    <IfModule mod_perl.c>
    # presumably these use Apache::DebugLog
    PerlModule My::Module
    PerlModule My::SecondModule
    PerlModule My::ThirdModule
    </IfModule>

    # set the default log domain and range
    PerlDebugLogDomain  foo bar bitz
    PerlDebugLogLevel   3

    <Location /some_place>
    # enable all debugging categories
    PerlDebugLogDomain *
    SetHandler perl-script
    PerlHandler My::Module
    </Location>

    <Location /some_other_place>
    # raise debug log level
    PerlDebugLogLevel 9
    PerlAccessHandler My::SecondModule
    </Location>

    <Location /third_place>
    # shut this guy up
    PerlDebugLogLevel 0
    PerlTypeHandler My::ThirdModule
    </Location>

=head1 DEBUGGING

something about using this module for debugging

=head1 AUTHOR

dorian taylor, C<< <dorian@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-apache-debuglog@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Apache-DebugLog>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 dorian taylor, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Apache::DebugLog::Config
