package Apache::LogRegex;
$Apache::LogRegex::VERSION = '1.71';
use strict;
use warnings;

sub new {
    my ($class, $format) = @_;

    die __PACKAGE__ . '->new() takes 1 argument' unless @_ == 2;
    die __PACKAGE__ . '->new() argument 1 (FORMAT) is false' unless $format;

    my $self = bless {}, $class;

    $self->{_format} = $format;

    $self->{_regex} = '';
    $self->{_regex_fields} = undef;

    $self->_parse_format();

    return $self;
}

sub _parse_format {
    my ($self) = @_;

    sub quoted_p {
        $_[0] =~ m/^\\\"/;
    }

    chomp $self->{_format};
    $self->{_format} =~ s#[ \t]+# #;
    $self->{_format} =~ s#^ ##;
    $self->{_format} =~ s# $##;

    my @format_elements = split /\s+/, $self->{_format};
    my $regex_string = '';

    for (my $i = 0; $i < @format_elements; $i++) {
        my $element = $format_elements[$i];
        my $quoted = quoted_p($element);

        if ($quoted) {
            $element =~ s/^\\\"//;
            $element =~ s/\\\"$//;
        }

        push @{ $self->{_regex_fields} }, $self->rename_this_name($element);

        my $group = '(\S*)';

        if ($quoted) {
            if ($element eq '%r' or $element =~ m/{Referer}/ or $element =~ m/{User-Agent}/) {
                $group = qr/"([^"\\]*(?:\\.[^"\\]*)*)"/;
            }
            else {
                $group = '\"([^\"]*)\"';
            }
        }
        elsif ($element =~ m/^%.*t$/) {
            $group = '(\[[^\]]+\])';
        }
        elsif ($element eq '%U') {
            $group = '(.+?)';
        }

        $regex_string .= $group;

        # expect elements separated by whitespace
        if ($i < $#format_elements) {
            my $next_element = $format_elements[$i + 1];
            if ($quoted && quoted_p($next_element)) {
                # tolerate multiple whitespaces iff both elements are quoted
                $regex_string .= '\s+';
            } else {
                $regex_string .= '\s';
            }
        }
    }

    $self->{_regex} = qr/^$regex_string\s*$/;
}

sub parse {
    my ($self, $line) = @_;

    die __PACKAGE__ . '->parse() takes 1 argument' unless @_ == 2;
    die __PACKAGE__ . '->parse() argument 1 (LINE) is undefined' unless defined $line;

    if (my @temp = $line =~ $self->{_regex}) {
        my %data;
        @data{ @{ $self->{_regex_fields} } } = @temp;
        return wantarray ? %data : \%data;
    }

    return;
}

sub generate_parser {
    my ($self, %args) = @_;

    my $regex = $self->{_regex};
    my @fields = @{ $self->{_regex_fields} };

    no warnings 'uninitialized';

    if ($args{reuse_record}) {
        my $record = {};
        return sub {
            if (@$record{@fields} = $_[0] =~ $regex) {
                return $record;
            } else {
                return;
            }
        }
    } else {
        return sub {
            my $record = {};
            if (@$record{@fields} = $_[0] =~ $regex) {
                return $record;
            } else {
                return;
            }
        }
    }
}

sub names {
    my ($self) = @_;

    die __PACKAGE__ . '->names() takes no argument' unless @_ == 1;

    return @{ $self->{_regex_fields} };
}

sub regex {
    my ($self) = @_;

    die __PACKAGE__ . '->regex() takes no argument' unless @_ == 1;

    return $self->{_regex};
}

sub rename_this_name {
    my ($self, $name) = @_;

    return $name;
}

1;

=head1 NAME

Apache::LogRegex - Parse a line from an Apache logfile into a hash

=head1 VERSION

version 1.71

=head1 SYNOPSIS

  use Apache::LogRegex;

  my $lr;

  eval { $lr = Apache::LogRegex->new($log_format) };
  die "Unable to parse log line: $@" if ($@);

  my %data;

  while ( my $line_from_logfile = <> ) {
      eval { %data = $lr->parse($line_from_logfile); };
      if (%data) {
          # We have data to process
      } else {
          # We could not parse this line
      }
  }

  # or generate a closure for better performance

  my $parser = $lr->generate_parser;

  while ( my $line_from_logfile = <> ) {
      my $data = $parser->($line_from_logfile) or last;
      # We have data to process
  }

=head1 DESCRIPTION

=head2 Overview

A simple class to parse Apache access log files. It will construct a
regex that will parse the given log file format and can then parse
lines from the log file line by line returning a hash of each line.

The field names of the hash are derived from the log file format. Thus if
the format is '%a %t \"%r\" %s %b %T \"%{Referer}i\" ...' then the keys of
the hash will be %a, %t, %r, %s, %b, %T and %{Referer}i.

Should these key names be unusable, as I guess they probably are, then subclass
and provide an override rename_this_name() method that can rename the keys
before they are added in the array of field names.

This module supports variable spacing between elements that are
surrounded by quotes, so if you have more than one space between those
elements in your format or in your log file, that should be OK.

=head1 SUBROUTINES/METHODS

=head2 Constructor

=over 4

=item Apache::LogRegex->new( FORMAT )

Returns a Apache::LogRegex object that can parse a line from an Apache
logfile that was written to with the FORMAT string. The FORMAT
string is the CustomLog string from the httpd.conf file.

=back

=head2 Class and object methods

=over 4

=item parse( LINE )

Given a LINE from an Apache logfile it will parse the line and return
all the elements of the line indexed by their corresponding format
string. In scalar context this takes the form of a hash reference, in
list context a flat paired list. In either context, if the line cannot
be parsed a false value will be returned.

=item generate_parser( LIST )

Generate and return a closure that, when called with a line, will
return a hash reference containing the parsed fields, or undef if the
parse failed. If LIST is supplied, it is interpreted as a flattened
hash of arguments. One argument is recognised; if C<reuse_record> is a
true value, then the closure will reuse the same hash reference each
time it is called. The default is to allocate a new hash for each
result.

Calling this closure is significantly faster than the C<parse> method.

=item names()

Returns a list of field names that were extracted from the data. Such as
'%a', '%t' and '%r' from the above example.

=item regex()

Returns a copy of the regex that will be used to parse the log file.

=item rename_this_name( NAME )

Use this method to rename the keys that will be used in the returned hash.
The initial NAME is passed in and the method should return the new name.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Perl 5

=head1 DIAGNOSTICS

The various custom time formats could be problematic but providing that
they are encased in '[' and ']' all should be fine.

=over 4

=item Apache::LogRegex->new() takes 1 argument

When the constructor is called it requires one argument. This message is
given if more or less arguments were supplied.

=item Apache::LogRegex->new() argument 1 (FORMAT) is undefined

The correct number of arguments were supplied with the constructor call,
however the first argument, FORMAT, was undefined.

=item Apache::LogRegex->parse() takes 1 argument

When the method is called it requires one argument. This message is
given if more or less arguments were supplied.

=item Apache::LogRegex->parse() argument 1 (LINE) is undefined

The correct number of arguments were supplied with the method call,
however the first argument, LINE, was undefined.

=item Apache::LogRegex->names() takes no argument

When the method is called it requires no arguments. This message is
given if some arguments were supplied.

=item Apache::LogRegex->regex() takes no argument

When the method is called it requires no arguments. This message is
given if some arguments were supplied.

=back

=head1 BUGS

None so far

=head1 FILES

None

=head1 SEE ALSO

mod_log_config for a description of the Apache format commands

=head1 THANKS

Peter Hickman wrote the original module and maintained it for
several years. He kindly passed maintainership on just prior to
the 1.51 release. Most of the features of this module are the
fruits of his work. If you find any bugs they are my doing.

=head1 AUTHOR

Original code by Peter Hickman <peterhi@ntlworld.com>

Additional code by Andrew Kirkpatrick <ubermonk@gmail.com>

=head1 LICENSE AND COPYRIGHT

Original code copyright (c) 2004-2006 Peter Hickman. All rights reserved.

Additional code copyright (c) 2013 Andrew Kirkpatrick. All rights reserved.

This module is free software. It may be used, redistributed and/or
modified under the same terms as Perl itself.

=cut
