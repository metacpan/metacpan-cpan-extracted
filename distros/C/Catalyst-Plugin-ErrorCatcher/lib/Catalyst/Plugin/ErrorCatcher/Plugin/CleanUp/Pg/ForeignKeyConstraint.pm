package Catalyst::Plugin::ErrorCatcher::Plugin::CleanUp::Pg::ForeignKeyConstraint;
$Catalyst::Plugin::ErrorCatcher::Plugin::CleanUp::Pg::ForeignKeyConstraint::VERSION = '0.0.8.18';
{
  $Catalyst::Plugin::ErrorCatcher::Plugin::CleanUp::Pg::ForeignKeyConstraint::DIST = 'Catalyst-Plugin-ErrorCatcher';
}
use strict;
use warnings;

sub tidy_message {
    my $plugin      = shift;
    my $errstr_ref  = shift;

    # update or delete on table "foo" violates foreign key constraint
    # "foobar_fkey" on table "baz" 
    ${$errstr_ref} =~ s{
        \A
        .+?
        DBI \s Exception:
        .+?
        ERROR:\s+
        update \s or \s delete \s on \s table \s
        "(.+?)" \s
        violates \s foreign \s key \s constraint \s
        "(.+?)" \s
        on \s table \s
        "(.+?)"
        \s+
        .+
        $
    }{Foreign key constraint violation: $1 -> $3 [$2]}xmsg;

    $errstr_ref;
}

1;
# ABSTRACT: cleanup foreign key violation messages from Pg

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Plugin::ErrorCatcher::Plugin::CleanUp::Pg::ForeignKeyConstraint - cleanup foreign key violation messages from Pg

=head1 VERSION

version 0.0.8.18

=head2 tidy_message($self, $stringref)

Tidy up Postgres messages where the error is related to a I<foreign key constraint violation>.

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
