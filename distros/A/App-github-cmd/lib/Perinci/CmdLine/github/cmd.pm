package Perinci::CmdLine::github::cmd;

our $DATE = '2020-04-08'; # DATE
our $VERSION = '0.008'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use parent 'Perinci::CmdLine::Lite';

sub hook_before_parse_argv {
    my ($self, $r) = @_;

    # we want to run 'setup' when user runs 'github-cmd' the first time (without
    # any subcommand) and without login/pass or token specified in the config
    # file
  RUN_SETUP:
    {
        $self->_parse_argv1($r);
        last if $r->{subcommand_name};
        $self->_read_config($r) unless $r->{config};
        last if defined($r->{config}{GLOBAL}{login}) &&
            defined($r->{config}{GLOBAL}{pass}) ||
            defined($r->{config}{GLOBAL}{access_token});
        log_trace "User does not have defined login+pass or token in ".
            "configuration, running setup ...";
        require Term::ReadKey;
        my ($login, $pass);
        while (1) {
            print "Setting up github-cmd. Please enter GitHub login: ";
            chomp($login = <STDIN>);
            last if $login =~ /\A\w+\z/;
        }
        while (1) {
            print "Please enter GitHub password: ";
            Term::ReadKey::ReadMode('noecho');
            chomp($pass = <STDIN>);
            Term::ReadKey::ReadMode('normal');
            print "\n";
            last if length $login;
        }
        require PERLANCAR::File::HomeDir;
        my $path = PERLANCAR::File::HomeDir::get_my_home_dir() .
            "/github-cmd.conf";
        require Config::IOD;
        my $iod = Config::IOD->new;
        require Config::IOD::Document;
        my $doc = (-f $path) ? $iod->read_file($path) :
            Config::IOD::Document->new;
        $doc->insert_section({ignore=>1}, 'GLOBAL');
        $doc->insert_key({replace=>1}, 'GLOBAL', 'login', $login);
        $doc->insert_key({replace=>1}, 'GLOBAL', 'pass', $pass);
        open my $fh, ">", $path or die "Can't write config '$path': $!";
        print $fh $doc->as_string;
        close $fh;

        # early exit
        print "Setup done, please run 'github-cmd' again.\n";
        exit 0;
    } # RUN_SETUP
}

1;
# ABSTRACT: Subclass for github-cmd

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::github::cmd - Subclass for github-cmd

=head1 VERSION

This document describes version 0.008 of Perinci::CmdLine::github::cmd (from Perl distribution App-github-cmd), released on 2020-04-08.

=head1 DESCRIPTION

This subclass adds a hook at the C<before_parse_argv> phase to run setup
(prompting login+pass, then writing configuration file) if login+pass are not
found in configuration.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-github-cmd>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-github-cmd>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-github-cmd>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
