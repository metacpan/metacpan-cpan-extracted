package Catalyst::Plugin::ErrorCatcher::Plugin::CleanUp::Pg::TransactionAborted;
$Catalyst::Plugin::ErrorCatcher::Plugin::CleanUp::Pg::TransactionAborted::VERSION = '0.0.8.18';
{
  $Catalyst::Plugin::ErrorCatcher::Plugin::CleanUp::Pg::TransactionAborted::DIST = 'Catalyst-Plugin-ErrorCatcher';
}
use strict;
use warnings;

sub tidy_message {
    my $plugin      = shift;
    my $errstr_ref  = shift;

    #  ERROR:  current transaction is aborted, commands ignored until end of
    #  transaction block [for Statement
    ${$errstr_ref} =~ s{
        \A
        .+?
        DBI \s Exception:
        .+?
        ERROR:\s+
        (
            current \s transaction \s is \s aborted, \s
            commands \s ignored \s until \s end \s of \s transaction \s block
        )
        \s \[ for \s Statement
        \s+
        .+
        $
    }{$1}xmsg;

    $errstr_ref;
}

1;
# ABSTRACT: cleanup transaction aborted messages from Pg

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Plugin::ErrorCatcher::Plugin::CleanUp::Pg::TransactionAborted - cleanup transaction aborted messages from Pg

=head1 VERSION

version 0.0.8.18

=head2 tidy_message($self, $stringref)

Tidy up Postgres messages where the error is related to an I<aborted transaction>.

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
