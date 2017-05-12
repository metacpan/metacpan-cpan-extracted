use utf8;
use strict;
use warnings;

package DBIx::DR::ByteStream;

=head1 NAME

DBIx::DR::ByteStream - ByteStream

=head1 SYNOPSIS

    use DBIx::DR::ByteStream;

    my $str = DBIx::DR::ByteStream->new('abc');

    print "%s\n", $str->content;

=head1 METHODS

=head2 new

Constructor.

=head2 content

Returns content.

=cut


sub new {
    my ($class, $str) = @_;
    return bless \$str => ref($class) || $class;
}

sub content {
    my ($self) = @_;
    return $$self;
}

=head1 COPYRIGHT

 Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

 This program is free software, you can redistribute it and/or
 modify it under the terms of the Artistic License.

=cut

1;
