use 5.008;
use strict;
use warnings;

package App::Addex::AddressBook::Apple;
{
  $App::Addex::AddressBook::Apple::VERSION = '0.018';
}
use base qw(App::Addex::AddressBook);
# ABSTRACT: use Apple Address Book as the addex source (doomed)

use App::Addex::Entry::EmailAddress;
use Encode ();

use Mac::Glue qw(:glue);


sub _glue {
  return $_[0]->{_abook_glue} ||= Mac::Glue->new("Address_Book");
}

sub _demsng {
  return if ! $_[1] or $_[1] eq 'msng';
  return $_[1];
}

sub _fix_str {
  my ($self, $str) = @_;

  return '' unless defined $str;
  return $str if Encode::is_utf8($str);
  return Encode::decode(MacRoman => $str);
}

sub _fix_prop {
  my ($self, $prop) = @_;
  my $str = $self->_demsng($prop->get);
  return $self->_fix_str($str);
}

sub _entrify {
  my ($self, $person) = @_;

  return unless my @emails = map {
    App::Addex::Entry::EmailAddress->new({
      address => $self->_demsng($_->prop('value')->get),
      label   => $self->_demsng($_->prop('label')->get),
    });
  } $person->prop("email")->get;

  my %fields;
  if (my $note = scalar $self->_demsng($person->prop('note')->get)) {
    while ($note =~ /^(\S+):\s*([^\x20\t]+)$/mg) {
      $fields{$1} = $2;
    }
  }

  my $name;

  if (my $fname = $self->_demsng($person->prop('first name')->get)) {
       $fname  = $self->_fix_str($fname);
    my $mname  = $self->_fix_prop($person->prop('middle name'));
    my $lname  = $self->_fix_prop($person->prop('last name'));
    my $suffix = $self->_fix_prop($person->prop('suffix'));

    $name = $fname
          . (length $mname  ? " $mname"  : '')
          . (length $lname  ? " $lname"  : '')
          . (length $suffix ? " $suffix" : '');
  } else {
    $name  = $self->_fix_prop($person->prop('name'));
  }

  CHECK_DEFAULT: {
    if (@emails > 1 and my $default = $fields{default_email}) {
      my $check;
      if ($default =~ m{\A/(.+)/\z}) {
        $default = qr/$1/;
        $check   = sub { $_[0]->address =~ $default };
      } else {
        $check   = sub { $_[0]->label eq $default };
      }

      for my $i (0 .. $#emails) {
        if ($check->($emails[$i])) {
          unshift @emails, splice @emails, $i, 1 if $i != 0;
          last CHECK_DEFAULT;
        }
      }

      warn "no email found for $name matching $fields{default_email}\n";
    }
  }

  return App::Addex::Entry->new({
    name   => $name,
    nick   => scalar $self->_demsng($person->prop('nickname')->get),
    emails => \@emails,
    fields => \%fields,
  });
}

sub entries {
  my ($self) = @_;

  my @entries = map { $self->_entrify($_) } $self->_glue->prop("people")->get;
}

1;

__END__

=pod

=head1 NAME

App::Addex::AddressBook::Apple - use Apple Address Book as the addex source (doomed)

=head1 VERSION

version 0.018

=head1 SYNOPSIS

B<Achtung!>  Using this requires L<Mac::Glue>.  Mac::Glue is not going to work
on more recent OS X.  Instead, check out
L<App::Addex::AddressBook::AppleScript>.

This module implements the L<App::Addex::AddressBook> interface for Mac OS X's
Address Book application, using L<Mac::Glue> to get entries from the address
book.

You may need to set up glue for Address Book before this will work.  You can do
this using F<gluemac> from L<Mac::Glue>

    gluemac /Applications/Address\ Book.app

You will probably need to run this program with F<sudo>; just prepend C<sudo>
to the command above.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
