#!/usr/bin/perl

BEGIN { $ENV{TESTING} = 1 }

use strict;
use warnings;
use Test::More;
use Data::Dumper qw/Dumper/;
use Capture::Tiny qw/capture/;
use App::Git::Workflow;
use App::Git::Workflow::Command qw/get_options/;
use lib 't/lib';
use Mock::App::Git::Workflow::Repository;

our $name = 'test';
my $git = Mock::App::Git::Workflow::Repository->git;
%App::Git::Workflow::Command::p2u_extra = ( -exitval => 'NOEXIT', );

options();
done_testing();

sub options {
    my @data = (
        [
            # @ARGV
            [qw/--version/],
            # Mock Git
            [],
            # STDOUT
            qr/\Atest Version = $App::Git::Workflow::Command::VERSION\n\Z/,
            { version => 1 },
        ],
        [
            # @ARGV
            [qw/--help/],
            # Mock Git
            [],
            # STDOUT
            qr/^\s+Stuff$/xms,
            { help => 1 },
        ],
        [
            # @ARGV
            [qw/--man/],
            # Mock Git
            [],
            # STDOUT
            qr/Test/xms,
            { man => 1 },
        ],
        [
            # @ARGV
            [qw/--unknown/],
            # Mock Git
            [],
            # STDOUT
            qr/^\s+Stuff$/xms,
            {},
        ],
        #[
        #    # @ARGV
        #    [qw/--version/],
        #    # Mock Git
        #    [],
        #    # STDOUT
        #    '',
        #],
    );

    for my $data (@data) {
        @ARGV = @{ $data->[0] };
        $git->mock_add(@{ $data->[1] });
        my $option = {};
        my ($stdout, $stderr) = capture { get_options($option) };
        like $stdout, $data->[2], 'Ran ' . join ' ', @{ $data->[0] }
            or diag 'STDOUT matches', Dumper $stdout, $data->[2];
        is_deeply $option, $data->[3], 'Options set correctly'
            or diag 'Options not set correctly: ', Dumper $option, $data->[3];
    }
}

__DATA__

=head1 NAME

Test

=head1 SYNOPSIS

 Stuff

=cut
