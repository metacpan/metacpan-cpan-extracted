use 5.20.0;
use strict;
use warnings;
package App::Addex::AddressBook::AppleScript;
$App::Addex::AddressBook::AppleScript::VERSION = '0.008';
use parent qw(App::Addex::AddressBook);
use experimental 'postderef';
# ABSTRACT: Mac::Glue-less Addex adapter for Apple Address Book and Addex

#pod =head1 SYNOPSIS
#pod
#pod This module implements the L<App::Addex::AddressBook> interface for Mac OS X's
#pod Address Book application, using I<a horrible hack> to get entries from the
#pod address book.
#pod
#pod A much cleaner interface would be to use L<App::Addex::AddressBook::Apple>,
#pod which uses L<Mac::Glue> to access the address book.  Unfortunately, Mac::Glue
#pod does not work in many recent builds of Perl, and will cease to work as the
#pod Carbon API is killed off.
#pod
#pod The AppleScript adapter builds an AppleScript program that prints out a dump of
#pod relevant address book entries, then runs it, then parses its output.  The
#pod format of the intermediate form may change for all kinds of crazy reasons.
#pod
#pod =cut

use App::Addex::Entry;
use App::Addex::Entry::EmailAddress;
use Encode ();

use File::Temp ();

sub _produce_applescript {
  my @fields = (
    'company', # true / false
    'organization',
    'first name',
    'middle name',
    'last name',
    'nickname',
    'suffix',
    'note',
  );

  my $dumper = '';
  for my $field (@fields) {
    $dumper .= <<"END_FIELD_DUMPER";
      set _this to get $field of _person
      if $field of _person is not missing value then
        set _answer to _answer & "- BEGIN $field\n"
        set _answer to _answer & ($field of _person) & "\n"
        set _answer to _answer & "- END $field\n"
      end if
END_FIELD_DUMPER
  }

  my $osascript = <<'END_APPLESCRIPT';
  tell application "Address Book"
    set _people to (get people)

    set _answer to ""

    repeat with _person in _people
      repeat 1 times
        if count of email of _person = 0 then
          exit repeat
        end if

        set _answer to _answer & "--- BEGIN " & id of _person & "\n"

        $dumper

        set _answer to _answer & "- BEGIN email\n"
        repeat with _email in (get email of _person)
          set _answer to _answer & (label of _email) & "\n"
          set _answer to _answer & (value of _email) & "\n"
        end repeat
        set _answer to _answer & "- END email\n"

        set _answer to _answer & "--- END " & id of _person & "\n\n"
      end repeat
    end repeat

    _answer
  end tell
END_APPLESCRIPT

  $osascript =~ s/\$dumper/$dumper/;

  return $osascript;
}

sub _produce_scriptfile {
  my ($self) = @_;

  my $osascript = $self->_produce_applescript;

  my ($fh, $filename) = File::Temp::tempfile(UNLINK => 1);

  $fh->print($osascript);
  $fh->close or die "can't close $filename: $!";

  return $filename;
}

sub entries {
  my ($self) = @_;

  my $script = $self->_produce_scriptfile;
  my @output = `/usr/bin/osascript $script`;

  @output = map {; Encode::decode('utf-8', $_) } @output;

  my @people;
  my $this;
  LINE: while (my $line = shift @output) {
    unless ($this) {
      next LINE unless $line =~ /\A--- BEGIN (.+)\Z/;
      $this = { id => $1 };
      push @people, $this;
      next LINE;
    }

    my @input;
    if ($line =~ /\A- BEGIN (.+)\Z/) {
      my $field = $1;
      push @input, shift @output until @input and $input[-1] =~ /\A- END $1\Z/;
      pop @input;
      $this->{ $field } = join q{}, @input;
      chomp $this->{ $field };

      if ($field eq 'email') {
        $this->{emails} = [ split /\n/, delete $this->{email} ];
      }
    }

    if ($line =~ /\A--- END \Q$this->{id}\E\Z/) {
      undef $this;
      next LINE;
    }
  }

  my @entries = map {; $self->_entrify($_) } @people;

  return @entries;
}

sub _entrify {
  my ($self, $person) = @_;

  my %fields;
  if (my $note = $person->{note} // '') {
    my @lines = grep { length } split /\R/, $note;
    for my $line (@lines) {
      next if $line =~ /^--/; # comment

      my $tmpname
        = join q{ }, grep $_,
          $person->@{'first name', 'middle name', 'last name', 'suffix'};

      warn("bogus line in notes on $tmpname: $line\n"), next
        unless $line =~ /\A([^:]+):\s*(.+?)\Z/;
      $fields{$1} = $2;
    }
  }

  my $fname   = $person->{'first name'}  // '';
  my $mname   = $person->{'middle name'}  // '';
  my $lname   = $person->{'last name'}  // '';
  my $suffix  = $person->{suffix} // '';

  $mname = '' unless $fields{'use middle'} // 1;

  my $name;
  if ($person->{company} eq 'true') {
    $name = $person->{organization};
  } else {
    $name = $fname
          . (length $mname  ? " $mname"  : '')
          . (length $lname  ? " $lname"  : '')
          . (length $suffix ? " $suffix" : '');
  }

  unless (length $name) {
    warn "couldn't figure out a name for this entry\n";
    return;
  }

  my @emails;
  my @kv = @{ $person->{emails} };

  for (my $i = 0; $i < $#kv; $i += 2) {
    push @emails, App::Addex::Entry::EmailAddress->new({
      address => $kv[ $i + 1 ],
      label   => $kv[ $i ],
    });
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

  my $arg = {
    name   => $name,
    nick   => $person->{nickname},
    emails => \@emails,
    fields => \%fields,
  };

  return App::Addex::Entry->new($arg);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Addex::AddressBook::AppleScript - Mac::Glue-less Addex adapter for Apple Address Book and Addex

=head1 VERSION

version 0.008

=head1 SYNOPSIS

This module implements the L<App::Addex::AddressBook> interface for Mac OS X's
Address Book application, using I<a horrible hack> to get entries from the
address book.

A much cleaner interface would be to use L<App::Addex::AddressBook::Apple>,
which uses L<Mac::Glue> to access the address book.  Unfortunately, Mac::Glue
does not work in many recent builds of Perl, and will cease to work as the
Carbon API is killed off.

The AppleScript adapter builds an AppleScript program that prints out a dump of
relevant address book entries, then runs it, then parses its output.  The
format of the intermediate form may change for all kinds of crazy reasons.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
