package DBIx::POS::Statement;

use overload '""' => sub { shift->{sql} };

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = shift;
    bless ($self, $class);
    return $self;
}

sub desc {
    my $self = shift;
    $self->{desc} = shift if (@_);
    return $self->{desc};
}

sub name {
    my $self = shift;
    $self->{name} = shift if (@_);
    return $self->{name};
}

sub noreturn {
    my $self = shift;
    $self->{noreturn} = shift if (@_);
    return $self->{noreturn};
}

sub param {
    my $self = shift;
    $self->{param} = shift if (@_);
    return $self->{param};
}

sub short {
    my $self = shift;
    $self->{short} = shift if (@_);
    return $self->{short};
}

sub sql {
    my $self = shift;
    $self->{sql} = shift if (@_);
    return $self->{sql};
}

package DBIx::POS;
# arch-tag: 2f764256-6fc0-415e-865d-767d9f202f02

use strict;
use warnings;
use base qw{Pod::Parser};

# Set our version
our $VERSION = '0.03';

# Hold data for our pending statement
my $info = {};

# Hold our SQL
my %sql;

# What command we're looking at
my $state;

# Does the work of creating a new instance
sub _new_instance {
    my $class = shift;
    my $file = shift;
    $class->new->parse_from_file ($file);
    bless \%sql, $class;
}

# Handle =whatever commands
sub command {
    my ($self, $command, $paragraph, $line) = @_;

    # Get rid of all trailing whitespace
    $paragraph =~ s/\s+$//ms;

    # There may be a short description right after the command
    if ($command eq 'desc') {
        $info->{short} = $paragraph || "";
    }

    # The name comes right after the command
    if ($command eq 'name') {
        $self->end_input;
        $info->{name} = $paragraph;
    }

    # The noreturn comes right after the command
    if ($command eq 'noreturn') {
        $info->{noreturn} = 1;
    }

    # Remember what command we're in
    $state = $command;
}

sub end_input {
    my ($self) = @_;

    # If there's stuff to try and construct from
    if (%{$info}) {

        # If we have the necessary bits
        if (scalar (grep {m/^(?:name|short|desc|sql)$/} keys %{$info}) == 3) {

            # Grab the entire content for the %sql hash
            $sql{$info->{name}} = DBIx::POS::Statement->new ($info);

            # Start with a new empty hashref
            $info = {};
        }

        # Something's missing
        else {

            # A nice format for dumping
            use YAML qw{Dump};

            die "Malformed entry\n" . Dump (\%sql, $info);
        }
    }
}

# Taken directly from Class::Singleton---we were already overriding
# _new_instance, and it seemed silly to have an additional dependency
# for four statements.

sub instance {
    my $class = shift;

    # get a reference to the _instance variable in the $class package 
    no strict 'refs';
    my $instance = \${ "$class\::_instance" };

    defined $$instance
        ? $$instance
        : ($$instance = $class->_new_instance(@_));
}

# Handle the blocks of text between commands
sub textblock {
    my ($parser, $paragraph, $line) = @_;

    # Collapse trailing whitespace to a \n
    $paragraph =~ s/\s+$/\n/ms;

    if ($state eq 'desc') {
        $info->{desc} .= $paragraph;
    }

    elsif ($state eq 'param') {
        $info->{param} .= $paragraph;
    }

    elsif ($state eq 'sql') {
        $info->{sql} .= $paragraph;
    }
}

# We handle verbatim sections the same way
sub verbatim {
    my ($parser, $paragraph, $line) = @_;

    # Collapse trailing whitespace to a \n
    $paragraph =~ s/\s+$/\n/ms;

    if ($state eq 'desc') {
        $info->{desc} .= $paragraph;
    }

    elsif ($state eq 'param') {
        $info->{param} .= $paragraph;
    }

    elsif ($state eq 'sql') {
        $info->{sql} .= $paragraph;
    }
}

1;

__END__

=head1 NAME

DBIx::POS - Define a dictionary of SQL statements in a POD dialect (POS)

=head1 SYNOPSIS

To define your dictionary:

  package OurSQL;

  use strict;
  use warnings;
  use base qw{DBIx::POS};
  __PACKAGE__->instance (__FILE__);

  =name testing

  =desc test the DBI::POS module

  =param

  Some arbitrary parameter

  =sql

  There is really no syntax checking done on the content of the =sql section.

  =cut

To use your dictionary:

  package main;

  use strict;
  use warnings;
  use OurSQL;

  my $sql = OurSQL->instance;

  $dbh->do ($sql->{testing});

=head1 DESCRIPTION

DBIx-POS subclasses Pod::Parser to define a POD dialect for writing a
SQL dictionary for an application, and uses code from Class::Singleton
to make the resulting structure easily accessible.

By encouraging the centralization of SQL code, it guards against SQL
statement duplication (and the update problems that can generate).

By separating the SQL code from its normal context of execution, it
encourages you to do other things with it---for instance, it is easy
to create a script that can do performance testing of certain SQL
statements in isolation, or to create generic command-line wrapper
around your SQL statements.

By giving a framework for documenting the SQL, it encourages
documentation of the intent and/or implementation of the SQL code.  It
also provides all of that information in a format from which other
documentation could be generated---say, a chunk of DocBook for
incorporation into a guide to programming the application.

=head2 EXPORT

Nothing is exported.  Aren't singletons cool?

=head1 SEE ALSO

L<DBI>, L<Pod::Parser>, L<Class::Singleton>

=head1 AUTHOR

Michael Alan Dorman, E<lt>mdorman@debian.orgE<gt>

The instance routine is from Class::Singleton

Andy Wardley, C<E<lt>abw@cre.canon.co.ukE<gt>>

Web Technology Group, Canon Research Centre Europe Ltd.

Thanks to Andreas Koenig C<E<lt>andreas.koenig@anima.deE<gt>> for providing
some significant speedup patches and other ideas.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Michael Alan Dorman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The instance routine is from Class::Singleton

Copyright (C) 1998 Canon Research Centre Europe Ltd.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under 
the term of the Perl Artistic License.

=cut
