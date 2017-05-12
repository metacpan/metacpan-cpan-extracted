use 5.008001;
use strict;
use warnings;

package Dancer2::Session::JSON;
# ABSTRACT: Dancer 2 session storage in files with JSON

our $VERSION = '0.002';

use Moo;
use Dancer2::Core::Types;
use JSON -convert_blessed_universally;

#--------------------------------------------------------------------------#
# Attributes
#--------------------------------------------------------------------------#

has _suffix => (
    is      => 'ro',
    isa     => Str,
    default => sub { ".json" },
);

has _encoder => (
    is      => 'lazy',
    isa     => InstanceOf ['JSON'],
    handles => {
        '_freeze' => 'encode',
        '_thaw'   => 'decode'
    },
);

sub _build__encoder {
    my ($self) = @_;
    return JSON->new->allow_blessed->convert_blessed;
}

#--------------------------------------------------------------------------#
# Role composition
#--------------------------------------------------------------------------#

with 'Dancer2::Core::Role::SessionFactory::File';

sub _freeze_to_handle {
    my ( $self, $fh, $data ) = @_;
    binmode $fh;
    print {$fh} $self->_freeze($data);
    return;
}

sub _thaw_from_handle {
    my ( $self, $fh ) = @_;
    binmode($fh);
    return $self->_thaw(
        do { local $/; <$fh> }
    );
}

1;

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Session::JSON - Dancer 2 session storage in files with JSON

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This module implements Dancer 2 session engine based on L<JSON> files.

This backend can be used in single-machine production environments, but two
things should be kept in mind: The content of the session files is not
encrypted or protected in anyway and old session files should be purged by a
CRON job.

=head1 CONFIGURATION

The setting B<session> should be set to C<JSON> in order to use this session
engine in a Dancer2 application.

Files will be stored to the value of the setting C<session_dir>, whose default
value is C<appdir/sessions>.

Here is an example configuration that use this session engine and stores session
files in /tmp/dancer-sessions

    session: "JSON"

    engines:
      session:
        JSON:
          session_dir: "/tmp/dancer-sessions"

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/PerlDancer/dancer2-session-json/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/PerlDancer/dancer2-session-json>

  git clone https://github.com/PerlDancer/dancer2-session-json.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Jason A. Crome

Jason A. Crome <jason@crome-plated.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut

__END__


# vim: ts=4 sts=4 sw=4 et:
