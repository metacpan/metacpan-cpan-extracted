package Catalyst::Plugin::ErrorCatcher::Plugin::CleanUp::Pg::UniqueConstraintViolation;
$Catalyst::Plugin::ErrorCatcher::Plugin::CleanUp::Pg::UniqueConstraintViolation::VERSION = '0.0.8.18';
{
  $Catalyst::Plugin::ErrorCatcher::Plugin::CleanUp::Pg::UniqueConstraintViolation::DIST = 'Catalyst-Plugin-ErrorCatcher';
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
        duplicate \s+ key \s+ value \s+
        violates \s unique \s constraint \s
        "(.+?)" \s
        .+?
        Key \s+ \(
            (.+?)
        \)
        \= \(
            (.+?)
        \)
        \s+ already \s+ exists
        .+
        $
    }{Unique constraint violation: $2 -> $3 [$1]}xmsg;

    $errstr_ref;
}

1;
# ABSTRACT: cleanup foreign key violation messages from Pg

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Plugin::ErrorCatcher::Plugin::CleanUp::Pg::UniqueConstraintViolation - cleanup foreign key violation messages from Pg

=head1 VERSION

version 0.0.8.18

=head2 tidy_message($self, $stringref)

Tidy up Postgres messages where the error is related to a I<duplicate key with a unique constraint>.

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
