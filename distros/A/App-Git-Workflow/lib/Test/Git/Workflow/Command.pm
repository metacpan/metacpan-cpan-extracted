package Test::Git::Workflow::Command;

# Created on: 2014-09-23 06:44:54
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;
use base qw/Exporter/;
use Test::More;
use Capture::Tiny qw/capture/;
use App::Git::Workflow;
use Mock::App::Git::Workflow::Repository;

our $VERSION     = version->new(1.1.4);
our @EXPORT      = qw/command_ok/;
our @EXPORT_OK   = qw/command_ok/;
our %EXPORT_TAGS = ();
our $workflow    = 'App::Git::Workflow';

our $git = Mock::App::Git::Workflow::Repository->git;
%App::Git::Workflow::Command::p2u_extra = ( -exitval => 'NOEXIT', );

sub command_ok ($$) {  ## no critic
    my ($module, $data) = @_;
    subtest $data->{name} => sub {
        no strict qw/refs/;  ## no critic

        if ($data->{skip} && $data->{skip}->()) {
            plan skip_all => "Skipping $data->{name}";
            return;
        }
        local $TODO;
        if ($data->{todo}) {
            $TODO = $data->{todo};
        }

        # initialise
        $git->mock_reset();
        $git->mock_add(@{ $data->{mock} });

        $git->{ran} = [];
        %{"${module}::option"} = ();
        ${"${module}::workflow"} = $workflow->new(git => $git);
        if ($data->{workflow}) {
            ${"${module}::workflow"}->{$_} = $data->{workflow}{$_} for keys %{ $data->{workflow} };
        }

        local @ARGV = @{ $data->{ARGV} };
        local %ENV = %ENV;
        if ($data->{ENV}) {
            $ENV{$_} = $data->{ENV}{$_} for keys %{ $data->{ENV} };
        }
        my $stdin;
        $data->{STD}{IN} ||= '';
        open $stdin, '<', \$data->{STD}{IN};

        # run the code
        my $error;
        my ($stdout, $stderr) = capture { local *STDIN = $stdin; eval { $module->run() }; $error = $@; };

        ## Tests
        if ($error) {
            #die $error, $stderr if !$data->{error};
            is $error, $data->{error}, "Error matches"
                or ( ref $error && diag explain $error, $data->{error} );
        }

        # STDOUT
        if ( !ref $data->{STD}{OUT} ) {
            is $stdout, $data->{STD}{OUT}, "STDOUT $data->{name} run"
                or diag explain $stdout, $data->{STD}{OUT};
        }
        elsif ( ref $data->{STD}{OUT} eq 'Regexp' ) {
            like $stdout, $data->{STD}{OUT}, "STDOUT $data->{name} run"
                or diag explain $stdout, $data->{STD}{OUT};
        }
        elsif ( ref $data->{STD}{OUT} eq 'HASH' ) {
            my $actual   = $data->{STD}{OUT_PRE} ? eval { $data->{STD}{OUT_PRE}->($stdout) } : $stdout;
            #diag explain [$stdout, $data, $@] if $@;
            is_deeply $actual, $data->{STD}{OUT}, "STDOUT $data->{name} run"
                or diag explain $actual, $data->{STD}{OUT};
        }

        # STDERR
        if ( !ref $data->{STD}{ERR} ) {
            is $stderr, $data->{STD}{ERR}, "STDERR $data->{name} run"
                or diag explain $stderr, $data->{STD}{ERR};
        }
        elsif ( ref $data->{STD}{ERR} eq 'Regexp' ) {
            like $stderr, $data->{STD}{ERR}, "STDERR $data->{name} run"
                or diag explain $stderr, $data->{STD}{ERR};
        }
        elsif ( ref $data->{STD}{ERR} eq 'HASH' ) {
            my $actual   = $data->{STD}{ERR_PRE} ? $data->{STD}{ERR_PRE}->($stdout) : $stdout;
            is_deeply $actual, $data->{STD}{ERR}, "STDERR $data->{name} run"
                or diag explain $actual, $data->{STD}{ERR};
        }

        is_deeply \%{"${module}::option"}, $data->{option}, 'Options set correctly'
            or diag explain \%{"${module}::option"}, $data->{option};
        ok !@{ $git->{data} }, "All data setup is used"
            or diag explain $git->{data}, [ map {keys %$_} @{ $data->{mock} } ];
    };
}

1;

__END__

=head1 NAME

Test::Git::Workflow::Command - Test Git::Workflow::Command::* files

=head1 VERSION

This documentation refers to Test::Git::Workflow::Command version 1.1.4

=head1 SYNOPSIS

   use Test::Git::Workflow::Command;

   command_ok('Test::Git::Workflow::Command::SomeCommand', {...});

=head1 DESCRIPTION

Helper module to test L<Git::Worflow::Commands>s

=head1 SUBROUTINES/METHODS

=head2 C<command_ok ( $module, $data )>

Tests C<$module> with the supplied <C$data>

C<$data> keys

=over 4

=item ARGV

The commands command line input

=item mock

The mock data to supply to the L<Mock::App::Git::Workflow::Repository> object

=item STD

=over 4

=item IN

STDIN

=item OUT

STDOUT

=item ERR

STDERR

=back

=item option

What the C<%option>s hash should contain at the end of everything

=item name

Name of the test

=back

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
