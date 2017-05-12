#!/usr/bin/env perl
use strict;
use warnings;
use App::LLEvalBot::CLI;
App::LLEvalBot::CLI->run(@ARGV);

__END__

=encoding utf-8

=head1 NAME

lleval-bot.pl - IRC bot for LLeval

=head1 SYNOPSIS

    % lleval-bot.pl --channels=test --host=irc.example.com [opt]

=head2 OPTIONS

=over

=item nickname (Default: lleval_bot)

=item port

=item password

=item enable-ssl

=back

=head1 DESCRIPTION

App::LLEvalBot is IRC bot for LLeval.
