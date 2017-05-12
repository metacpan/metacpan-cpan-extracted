# Class::CSV
#  Class Based CSV Parser/Writer
# Written by DJ <dj@boxen.net>
#
# $Id: CSV.pm,v 1.2 2005/03/07 02:43:48 david Exp $

# Class::CSV::Base
package Class::CSV::Base;

use strict;
use warnings;

BEGIN {
  ## Modules
  # Core
  use Carp qw/confess/;

  # Base
  use base qw(Class::Accessor);

  ## Constants
  use constant TRUE => 1;
  use constant FALSE => 0;

  ## Variables
  use vars qw($VERSION);
  $VERSION = do { my @r=(q$Revision: 1.3 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r};
}

sub _build_fields {
  my ($self, $fields) = @_;

  confess "Field list must be an array reference\n"
    unless (defined $fields and ref $fields eq 'ARRAY');

  $self->{_field_list} = $fields;

  # make the accessors via Class::Accessor
  __PACKAGE__->mk_accessors(@{$fields});

  foreach my $field (@{$fields}) {
    $self->{__fields}->{$field} = TRUE;
  }
}

sub set {
  my ($self, %items) = @_;

  foreach my $field (keys %items) {
    if (exists $self->{__fields}->{$field}) {
      $self->_set($field, $items{$field});
    } else {
      confess "Cannot set field: ". $field. " as it doesnt exist!\n";
    }
  }
}

sub _set {
  my ($self, $key, $value) = @_;

  return $self->{$key} = $value;
}

sub get {
  my ($self, @fields) = @_;

  # sanity check
  foreach my $field (@fields) {
    unless (exists $self->{__fields}->{$field}) {
      confess "Cannot get field: ". $field. " as it doesnt exist!\n";
    }
  }

  return $self->_get(@fields);
}

sub _get {
  my $self = shift;

  if(@_ == 1) {
    return $self->{$_[0]};
  } elsif( @_ > 1 ) {
    return @{$self}{@_};
  }

  return;
}

1;

# Class::CSV::CSV_XS_Options
package Class::CSV::CSV_XS_Options;

BEGIN {
  ## Modules
  # Core
  use Carp qw/confess/;

  ## Constants
  use constant TRUE => 1;
  use constant FALSE => 0;

  # Base
  use base qw(Class::CSV::Base);
}

sub new {
  my ($class, $opts) = @_;

  my $self = bless({}, $class);

  $self->_build_fields([qw/quote_char eol escape_char sep_char binary
                        types always_quote/]);

  if (defined $opts) {
    if (ref $opts eq 'HASH') {
      $self->set(%{$opts});
    } else {
      confess "Please provide csv_xs_options as a HASH ref!\n";
    }
  }

  return $self;
}

sub set {
  my ($self, %items) = @_;

  foreach my $field (keys %items) {
    unless (exists $self->{__fields}->{$field}) {
      $self->{__fields}->{$field} = TRUE;
      $self->mk_accessors($field);
    }
    $self->_set($field => $items{$field});
  }
}

sub to_hash_ref {
  my ($self) = @_;

  my $hash = {};
  foreach my $field (keys %{$self->{__fields}}) {
    my $value = $self->get($field);
    if (defined $value) {
      $hash->{$field} = $value;
    }
  }

  return $hash;
}

# Class::CSV::Line
package Class::CSV::Line;

BEGIN {
  ## Modules
  # Core
  use Carp qw/confess/;

  # CPAN
  use Text::CSV_XS;

  ## Constants
  use constant TRUE => 1;
  use constant FALSE => 0;

  # Base
  use base qw(Class::CSV::Base);
}

sub new {
  my ($class, %opts) = @_;

  confess "Please provide a list of fields\n"
    unless (exists $opts{fields});

  my $self = bless({}, $class);

  $self->{__csv_xs_options} = $opts{csv_xs_options};

  $self->_build_fields($opts{fields});
  $self->_do_parse($opts{line}) if (exists $opts{line});

  return $self;
}

sub parse {
  my ($class, %opts) = @_;

  confess "Please provide a line to parse\n"
    unless (exists $opts{line});

  my $self = $class->new(%opts);

  $self->_do_parse($opts{line});

  return $self;
}

sub _build_fields {
  my ($self, $fields) = @_;

  confess "Field list must be an array reference\n"
    unless (defined $fields and ref $fields eq 'ARRAY');

  $self->{_field_list} = $fields;

  # make the accessors via Class::Accessor
  __PACKAGE__->mk_accessors(@{$fields});

  foreach my $field (@{$fields}) {
    $self->{__fields}->{$field} = TRUE;
    $self->_set($field, undef);
  }
}

sub _do_parse {
  my ($self, $line) = @_;

  confess "Unable to find field array ref to build object with\n"
    unless (defined $self->{_field_list}
      and ref $self->{_field_list} eq 'ARRAY');

  my $csv = new Text::CSV_XS($self->{__csv_xs_options}->to_hash_ref());
  my $r = $csv->parse($line);
  if (defined $r and $r) {
    my @columns = $csv->fields();
    for (my $i = 0; $i < @columns; $i++) {
      $self->set(${$self->{_field_list}}[$i], $columns[$i]);
    }
  } else {
    if ($csv->error_input()) {
      confess "Failed to parse line: ". $csv->error_input(). "\n";
    } else {
      confess "Failed to parse line: unknown reason\n";
    }
  }
}

sub string {
  my ($self) = @_;

  confess "Uninitiated Line Objects cannot be converted to a string!\n"
    unless (exists $self->{_field_list}
    and ref $self->{_field_list} eq 'ARRAY');

  my @cols = ();
  foreach my $field (@{$self->{_field_list}}) {
    push(@cols, $self->_get($field));
  }

  my $csv = new Text::CSV_XS($self->{__csv_xs_options}->to_hash_ref());
  my $r = $csv->combine(@cols);
  if ($r) {
    return $csv->string();
  } else {
    confess "Failed to create CSV line from line: ". $csv->error_input(). "\n"
  }
}

1;


# Class::CSV
package Class::CSV;

BEGIN {
  ## Modules
  # Core
  use Carp qw/confess/;

  # Base
  use base qw(Class::CSV::Base);

  ## Constants
  use constant TRUE => 1;
  use constant FALSE => 0;

  use constant DEFAULT_LINE_SEPARATOR => "\n";

  ## Setup Accessors
  __PACKAGE__->mk_ro_accessors(qw(fields));
  __PACKAGE__->mk_accessors(qw(lines line_separator csv_xs_options));
}

sub new {
  my ($class, %opts) = @_;

  my $self = bless({}, $class);

  confess "Please provide an array ref of fields\n"
    unless (exists $opts{fields}
      and ref $opts{fields} eq 'ARRAY');

  $self->_private_set(
    line_separator  => $opts{line_separator} || DEFAULT_LINE_SEPARATOR,
    csv_xs_options  =>
      new Class::CSV::CSV_XS_Options($opts{csv_xs_options}),
    fields          => $opts{fields},
    lines           => []
  );

  return $self;
}

sub parse {
  my ($class, %opts) = @_;

  my $self = $class->new(%opts);

  if (exists $opts{classdbi_objects}) {
    $opts{objects} = $opts{classdbi_objects};
    delete($opts{classdbi_objects});
  }

  if (exists $opts{filename} or exists $opts{filehandle}) {
    $self->_do_parse(%opts);
  } elsif (exists $opts{objects}) {
    $self->_do_parse_objects(%opts);
  } else {
    confess "Please provide objects or a filename/filehandle to parse\n";
  }

  return $self;
}

sub _do_parse {
  my ($self, %opts) = @_;

  my @CSV_Content = ();
  if (exists $opts{'filename'} and defined $opts{'filename'}) {
    confess "Cannot find filename: ". $opts{'filename'}. "\n"
      unless (-f $opts{'filename'});
    confess "Cannot read filename: ". $opts{'filename'}. "\n"
      unless (-r $opts{'filename'});
    open(CSV, $opts{'filename'})
      or confess "Failed to open filename: ". $opts{'filename'}. ': '. $!. "\n";
    while (my $line = <CSV>) {
      push(@CSV_Content, $self->strip_crlf($line));
    }
    close(CSV);
  } elsif (exists $opts{'filehandle'} and defined $opts{'filehandle'}) {
    confess "filehandle provided is not a file handle\n"
      unless (defined(fileno($opts{'filehandle'})));
    my $fh = $opts{'filehandle'};
    while (my $line = <$fh>) {
      push(@CSV_Content, $self->strip_crlf($line));
    }
  } else {
    confess "Please provide a filename/filehandle to parse\n";
  }

  foreach my $line (@CSV_Content) {
    unless ($line and $line !~ /^([,"']|\s)+$/) {
      # Skip empty lines
      next;
    }
    push(@{$self->{lines}}, $self->new_line(undef, { line => $line }));
  }
}

sub _do_parse_objects {
  my ($self, %opts) = @_;

  confess "Please specify objects as an ARRAY ref!\n"
    unless (ref $opts{objects} eq 'ARRAY');

  foreach my $object (@{$opts{objects}}) {
    my $line = $self->new_line();

    foreach my $field (@{$self->fields()}) {
      confess ((ref $object). " does not contain method ". $field. "\n")
        unless ($object->can($field));

      $line->set( $field => $object->$field );
    }

    push(@{$self->{lines}}, $line);
  }
}

sub new_line {
  my ($self, $args, $opts) = @_;

  my %opts = ();
  if ($opts and ref $opts eq 'HASH') {
    %opts = %{$opts};
  }

  my $line = new Class::CSV::Line(
    fields         => $self->fields(),
    csv_xs_options => $self->csv_xs_options(),
    %opts
  );

  confess "Failed to create new line\n"
    unless ($line);

  if (defined $args) {
    if (ref $args eq 'ARRAY') {
      my @dr_array = @{$args};
      foreach my $field (@{$self->fields()}) {
        my $value = shift @dr_array;
        $line->set( $field => $value );
      }
    } elsif (ref $args eq 'HASH') {
      foreach my $field (keys %{$args}) {
        $line->set( $field => $args->{$field} );
      }
    } else {
      confess "Need the arguments passed as either an ARRAY ref or a HASH ref!\n";
    }
  }

  return $line;
}

sub add_line {
  my ($self, $args) = @_;

  confess "Cannot call add_line without an argument!\n"
    unless (defined $args and $args);

  my $line = $self->new_line($args);

  push(@{$self->{lines}}, $line);
}

sub string {
  my ($self) = @_;

  confess "No lines to write!\n" unless (ref $self->lines() eq 'ARRAY');

  my @string = ();
  map { push(@string, $_->string()); } @{$self->lines()};

  return join($self->line_separator(), @string). $self->line_separator();
}

sub print {
  my ($self) = @_;

  print $self->string();
}

sub strip_crlf {
  my ($self, $string) = @_;

  $string =~ s/[\n\r]+$//g;

  return $string;
}

sub _private_set {
  my ($self, %items) = @_;

  foreach my $field (keys %items) {
    $self->{$field} = $items{$field};
    $self->{__fields}->{$field} = TRUE;
  }
}

1;

__END__

=head1 NAME

Class::CSV - Class based CSV parser/writer

=head1 SYNOPSIS

  use Class::CSV;

  my $csv = Class::CSV->parse(
    filename => 'test.csv',
    fields   => [qw/item qty sub_total/]
  );

  foreach my $line (@{$csv->lines()}) {
    $line->sub_total('$'. sprintf("%0.2f", $line->sub_total()));

    print 'Item:     '. $line->item(). "\n".
          'Qty:      '. $line->qty(). "\n".
          'SubTotal: '. $line->sub_total(). "\n";
  }

  my $cvs_as_string = $csv->string();

  $csv->print();

  my $csv = Class::CSV->new(
    fields         => [qw/userid username/],
    line_separator => "\r\n";
  );

  $csv->add_line([2063, 'testuser']);
  $csv->add_line({
    userid   => 2064,
    username => 'testuser2'
  });

=head1 DESCRIPTION

This module can be used to create objects from I<CSV> files, or to create I<CSV>
files from objects. L<Text::CSV_XS> is used for parsing and creating I<CSV> file
lines, so any limitations in L<Text::CSV_XS> will of course be inherant in this
module.

=head2 EXPORT

None by default.

=head1 METHOD

=head2 CONSTRUCTOR

=over

=item B<parse>

the parse constructor takes a hash as its paramater, the various options
that can be in this hash are detailed below.

=over 4

=item B<Required Options>

=over 4

=item *

B<fields> - an array ref containing the list of field names to use for each row.
there are some reserved words that cannot be used as field names, there is no
checking done for this at the moment but it is something to be aware of. the
reserved field names are as follows: C<string>, C<set>, C<get>. also field
names cannot contain whitespace or any characters that would not be allowed
in a method name.

=back

=item B<Source Options> (only one of these is needed)

=over 4

=item *

B<filename> - the path of the I<CSV> file to be opened and parsed.

=item *

B<filehandle> - the file handle of the I<CSV> file to be parsed.

=item *

B<objects> - an array ref of objects (e.g. L<Class::DBI> objects). for this
to work properly the field names provided in B<fields> needs to correspond to
the field names of the objects in the array ref.

=item *

B<classdbi_objects> - B<depreciated> use objects instead - using
classdbi_objects will still work but its advisable to update your code.

=back

=item B<Optional Options>

=over 4

=item *

B<line_separator> - the line seperator to be included at the end of every
line. defaulting to C<\n> (unix carriage return).

=back

=back

=item B<new>

the I<new> constructor takes a hash as its paramater, the same options detailed
in B<parse> apply to I<new> however no B<Source Options> can be used. this
constructor creates a blank I<CSV> object of which lines can be added
via B<add_line>.

=back

=head2 ACCESSING

=over

=item B<lines>

returns an array ref containing objects of each I<CSV> line (made via
L<Class::Accessor>). the field names given upon construction are available
as accessors and can be I<set> or I<get>. for more information please see
the notes below or the perldoc for L<Class::Accessor>. the B<lines>
accessor is also able to be updated/retrieved in the same way as individual
lines fields (examples below).

=over 4

=item B<Example>

retrieving the lines:

=over 4

  my @lines = @{$csv->lines()};

=back

removing the first line:

=over 4

  pop @lines;

  $csv->lines(\@lines);

=back

sorting the lines:

=over 4

  @lines = sort { $a->userid() <=> $b->userid() } @lines:

  $csv->lines(\@lines);

=back

sorting the lines (all-in-one way):

=over 4

  $csv->lines([ sort { $a->userid() <=> $b->userid() } @{$csv->lines()} ]);

=back

=item B<Retrieving a fields value>

there is two ways to retrieve a fields value (as documented in
L<Class::Accessor>). firstly you can call the field name on the object
and secondly you can call C<get> on the object with the field name
as the argument (multiple field names can be specified to retrieve an
array of values). examples are below.

=over 4

  my $value = $line->test();

=back

I<OR>

=over 4

  my $value = $line->get('test');

=back

I<OR>

=over 4

  my @values = $line->get(qw/test test2 test3/);

=back

=item B<Setting a fields value>

setting a fields value is simmilar to getting a fields value. there
are two ways to set a fields value (as documented in L<Class::Accessor>).
firstly you can simply call the field name on the object with the value
as the argument or secondly you can call C<set> on the object with a hash
of fields and their values to set (this isn't standard in L<Class::Accessor>,
i have overloaded the C<set> method to allow this). examples are below.


=over 4

  $line->test('123');

=back

I<OR>

=over 4

  $line->set( test => '123' );

=back

I<OR>

=over 4

  $line->set(
    test  => '123',
    test2 => '456'
  );

=back

=item B<Retrieving a line as a string>

to retrieve a line as a string simply call C<string> on the object.

=over 4

  my $string = $line->string();

=back

=back

=item B<new_line>

returns a new line object, this can be useful for to C<splice> a line into
B<lines> (see example below). you can pass the values of
the line as an I<ARRAY> ref or a I<HASH> ref.

=over 4

=item B<Example>

  my $line = $csv->new_line({ userid => 123, domainname => 'splicey.com' });
  my @lines = $csv->lines();
  splice(@lines, 1, 0, $line);

I<OR>

  splice(@{$csv->lines()}, 1, 0, $csv->new_line({ userid => 123, domainname => 'splicey.com' }));

=back

=item B<add_line>

adds a line to the B<lines> stack. this is mainly useful when the B<new>
constructor is used but can of course be used with any constructor. it will
add a new line to the end of the B<lines> stack. you can pass the values of
the line as an I<ARRAY> ref or a I<HASH> ref. examples of how to use this
are below.

=over 4

=item B<Example>

  $csv->add_line(['house', 100000, 4]);

  $csv->add_line({
    item     => 'house',
    cost     => 100000,
    bedrooms => 4
  });

=back


=back

=head2 OUTPUT

=over

=item B<string>

returns the object as a string (I<CSV> file format).

=item B<print>

calls C<print> on B<string> (prints the I<CSV> to STDOUT).

=back

=head1 SEE ALSO

L<Text::CSV_XS>, L<Class::Accessor>

=head1 AUTHOR

David Radunz, E<lt>david@boxen.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by David Radunz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
