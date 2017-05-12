package Catalyst::Plugin::ErrorCatcher::Plugin::CleanUp::TxnDo;
$Catalyst::Plugin::ErrorCatcher::Plugin::CleanUp::TxnDo::VERSION = '0.0.8.18';
{
  $Catalyst::Plugin::ErrorCatcher::Plugin::CleanUp::TxnDo::DIST = 'Catalyst-Plugin-ErrorCatcher';
}
use strict;
use warnings;

sub tidy_message {
    my $plugin      = shift;
    my $errstr_ref  = shift;

    # DBIx::Class::Schema::txn_do(): ... ... line XX
    ${$errstr_ref} =~ s{
        DBIx::Class::Schema::txn_do\(\):
        \s+
        (.+?)
        \s+at\s+
        \S+
        \s+
        line
        \s+
        .*
        $
    }{$1}xmsg;

    $errstr_ref;
}

1;
# ABSTRACT: cleanup txn_do messages from Pg

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Plugin::ErrorCatcher::Plugin::CleanUp::TxnDo - cleanup txn_do messages from Pg

=head1 VERSION

version 0.0.8.18

=head2 tidy_message($self, $stringref)

Tidy up Postgres messages where the error is related to a I<DBIx::Class::Schema::txn_do>.

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
