#!/usr/bin/perl
use strict;
use warnings;

package App::Addex::AddressBook::Abook;
{
  $App::Addex::AddressBook::Abook::VERSION = '0.008';
}
use base qw(App::Addex::AddressBook);
# ABSTRACT: use the "abook" program as the addex source

use App::Addex::Entry::EmailAddress;

use File::HomeDir;
use File::Spec;

{
  package
    App::Addex::AddressBook::Abook::INI::Reader;
  use Config::INI::Reader; # probably already loaded, but... -- rjbs, 2007-05-09
  BEGIN { our @ISA = 'Config::INI::Reader' }

  sub can_ignore {
    my ($self, $line) = @_;
    return $line =~ /\A\s*(?:[;#]|$)/ ? 1 : 0;
  }

  sub preprocess_line {
    my ($self, $line) = @_;
    ${$line} =~ s/\s+[;#].*$//g;
  }
}


sub new {
  my ($class, $arg) = @_;

  my $self = bless {} => $class;

  $arg->{filename} ||= File::Spec->catfile(
    File::HomeDir->my_home,
    '.abook',
    'addressbook',
  );

  eval {
    $self->{config} = App::Addex::AddressBook::Abook::INI::Reader
                    ->read_file($arg->{filename});
  };
  Carp::croak "couldn't read abook address book file: $@" if $@;

  $self->{$_} = $arg->{$_} for qw(sig_field folder_field);

  return $self;
}

sub _entrify {
  my ($self, $person) = @_;

  return unless my @emails =
    map { App::Addex::Entry::EmailAddress->new($_) }
    split /\s*,\s*/, ($person->{email}||'');

  my %field;
  $field{ $_ } = $person->{ $self->{"$_\_field"} } for qw(sig folder);

  return App::Addex::Entry->new({
    name   => $person->{name},
    nick   => $person->{nick},
    emails => \@emails,
    fields => \%field,
  });
}

sub entries {
  my ($self) = @_;

  my @entries = map { $self->_entrify($self->{config}{$_}) }
                sort grep { /\A\d+\z/ }
                keys %{ $self->{config} };
}

1;

__END__

=pod

=head1 NAME

App::Addex::AddressBook::Abook - use the "abook" program as the addex source

=head1 VERSION

version 0.008

=head1 SYNOPSIS

This module implements the L<App::Addex::AddressBook> interface for the
Mutt-friendly "abook" program.

=head1 CONFIGURATION

The following configuration options are valid:

 filename  - the address book file to read; defaults to ~/.abook/addressbook
 sig_field - the address book entry property that stores the "sig" field
 folder_field - the address book entry property that stores the "sig" field

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
