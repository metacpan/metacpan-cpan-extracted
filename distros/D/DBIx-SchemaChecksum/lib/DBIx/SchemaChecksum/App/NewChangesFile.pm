package DBIx::SchemaChecksum::App::NewChangesFile;
use 5.010;

# ABSTRACT: Generate a new changes-file

use MooseX::App::Command;
extends qw(DBIx::SchemaChecksum::App);

option '+sqlsnippetdir' => ( required => 1);
option 'change_name' => (
    is=>'ro',
    isa=>'Str',
    documentation=>'Short description of the change, change file name will be based on this value',
    default=>sub {
        'unnamed_change_'.time(),
    }
);

sub run {
    my $self = shift;

    my $name = my $change_desc = $self->change_name;
    $name=~s/[^a-z0-9\-\._]/_/gi;

    my $file = Path::Class::Dir->new($self->sqlsnippetdir)->file($name.'.sql');
    my $current_checksum = $self->checksum;
    my $tpl = $self->tpl;
    $tpl=~s/%CHECKSUM%/$current_checksum/;
    $tpl=~s/%NAME%/$change_desc/;

    $file->parent->mkpath;
    $file->spew(iomode => '>:encoding(UTF-8)', $tpl);

    say "New change-file ready at ".$file->stringify;
}

sub tpl {
    return <<EOSNIPPET;
-- preSHA1sum:  %CHECKSUM%
-- postSHA1sum: xxx-New-Checksum-xxx
-- %NAME%

EOSNIPPET
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::SchemaChecksum::App::NewChangesFile - Generate a new changes-file

=head1 VERSION

version 1.102

=head1 DESCRIPTION

Generate a new, empty changes file template in C<sqlsnippetdir> with
the current checksum autofilled in. You can provide a
C<--change_name>, which will be used to generate the filename, and
will be stored as a comment inside the file. If you do not specify the
C<change_name>, defaults to C<unnamed_change_EPOCH>.

=head1 AUTHORS

=over 4

=item *

Thomas Klausner <domm@cpan.org>

=item *

Maroš Kollár <maros@cpan.org>

=item *

Klaus Ita <koki@worstofall.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Thomas Klausner, Maroš Kollár, Klaus Ita.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
