package CGI::Application::Plugin::Output::XSV;

use strict;
use warnings;

use Carp;
require Text::CSV_XS;
require Exporter;

our @ISA= qw(Exporter);

our @EXPORT= qw(
  xsv_report_web
);

our @EXPORT_OK= qw(
  add_to_xsv
  clean_field_names
  xsv_report
);

our %EXPORT_TAGS= (
  all => [ @EXPORT, @EXPORT_OK ],
);

our $VERSION= '1.02';

##

sub xsv_report {
  my $args = shift || {};

  croak "argument to xsv_report must be a hash reference"
    if ref( $args ) ne 'HASH';

  my %defaults = (
    headers         => undef,
    headers_cb      => \&clean_field_names,
    include_headers => 1,
    fields          => undef,
    values          => undef,
    row_filter      => undef,
    iterator        => undef,
    line_ending     => "\n",
    csv_opts        => {},
    maximum_iters   => 1_000_000, # XXX reasonable default?
    stream          => 0,
  );

  my %opts = ( %defaults, %$args );

  my $was_buffering = $|;
  local $| = $was_buffering;
  $| = 1 if $opts{stream};

  # deprecated option
  if ( $opts{get_row_cb} ) {
    if ( $opts{row_filter} ) {
      carp "ignoring use of deprecated get_row_cb when row_filter specified";
    }
    else {
      $opts{row_filter} = $opts{get_row_cb};
      carp "get_row_cb is deprecated, please use row_filter instead";
    }
  }

  croak "need array reference of values or iterator to do anything"
    if   ! ( $opts{values}   && ref( $opts{values} )   eq 'ARRAY' )
      && ! ( $opts{iterator} && ref( $opts{iterator} ) eq 'CODE'  );

  croak "can't supply both values and iterator"
    if $opts{values} && $opts{iterator};

  # list of fields to include in report
  my $fields = [];

  if ( $opts{fields} ) {
    # user-specified
    $fields = $opts{fields};
  }
  elsif ( $opts{values} ) {
    # try to determine field names from provided values
    if ( @{ $opts{values} } ) {
      my $list_type = ref( $opts{values}[0] );

      # field list from first entry in value list
      if ( $list_type eq 'HASH' ) {
        $fields = [ keys %{ $opts{values}[0] } ];
      }
      # or simply array indices
      elsif ( $list_type eq 'ARRAY' ) {
        $fields = [ 0..$#{$opts{values}[0]} ];
      }
      else {
        croak "unknown list type [$list_type]";
      }
    }
    else {
      croak "can't determine field names (values is an empty list), aborting";
    }
  }
  else {
    # using iterator, empty field list
  }

  # function to filter each row of data from $opts{values}
  my $row_filter;

  if ( $opts{row_filter} ) {
    # user-specified
    $row_filter = $opts{row_filter};
  }
  elsif ( $opts{values} && @{ $opts{values} } ) {
    # simple defaults for slices
    my $list_type = ref( $opts{values}[0] );

    if ( $list_type eq 'HASH' ) {
      $row_filter = sub { my ($row, $fields)= @_; return [ @$row{@$fields} ] };
    }
    elsif ( $list_type eq 'ARRAY' ) {
      $row_filter = sub { my ($row, $fields)= @_; return [ @$row[@$fields] ] };
    }
    else {
      croak "unknown list type [$list_type]";
    }
  }
  else {
    # using iterator, no filter
    $row_filter = sub { $_[0] };
  }

  my $csv = Text::CSV_XS->new( $opts{csv_opts} );
  my $output = '';

  if ( $opts{include_headers} ) {
    if ( ! $opts{headers} ) {
      if ( ! ($opts{headers_cb} && ref( $opts{headers_cb} ) eq 'CODE') ) {
        croak "need headers or headers_cb to include headers";
      }
      elsif ( ! @{$fields} ) {
        carp "passing empty fields list to headers_cb";
      }
    }

    # formatted column headers
    my $readable_headers = $opts{headers} || $opts{headers_cb}->( $fields )
      or croak "can't generate headers";

    croak "return value from headers_cb is not an array reference, aborting"
      if ref ( $readable_headers ) ne 'ARRAY';

    $output .= add_to_xsv( $csv, $readable_headers, $opts{line_ending} );

    if ( $opts{stream} ) {
      print $output;
      $output = '';
    }
  }

  if ( $opts{values} ) {
    foreach my $list_ref ( @{ $opts{values} } ) {
      $output .= add_to_xsv(
        $csv, $row_filter->($list_ref, $fields), $opts{line_ending}
      );

      if ( $opts{stream} ) {
        print $output;
        $output = '';
      }
    }
  }
  # using iterator
  else {
    my $iterations = 0;

    while ( my $list_ref = $opts{iterator}->($fields) ) {
      croak "return value from iterator is not an array reference, aborting"
        if ref( $list_ref ) ne 'ARRAY';

      # XXX infinite loop?
      croak "iterator exceeded maximum iterations ($opts{maximum_iters})"
        if ++$iterations > $opts{maximum_iters};

      $output .= add_to_xsv(
        $csv, $row_filter->($list_ref, $fields), $opts{line_ending}
      );

      if ( $opts{stream} ) {
        print $output;
        $output = '';
      }
    }
  }

  return $output;
}

# send xsv output directly to browser for download
# same params as xsv_report, plus
#   filename => 'download.csv',
sub xsv_report_web {
  my ($self, $args) = @_;
  $args ||= {};

  croak "argument to xsv_report_web must be a hash reference"
    if ref( $args ) ne 'HASH';

  my %defaults = (
    filename => 'download.csv',
  );

  my %opts = ( %defaults, %$args );

  my %headers = (
    -type                  => 'application/x-csv',
    '-content-disposition' => "attachment; filename=$opts{filename}",
  );

  # we're doing our own output
  if ( $opts{stream} ) {
    $self->header_type('none');
    print $self->query->header( %headers );
  }
  else {
    $self->header_props( %headers );
  }

  # consider use of magic goto in case of croak() inside xsv_report
  return xsv_report( \%opts );
}

# default field name generator:
#   underscores to spaces, upper case first letter of each word
sub clean_field_names {
  my $fields = shift;

  # using temp var to avoid modifying $fields
  my @fields_copy = @{$fields};

  return [
    map { tr/_/ /; s/\b(\w+)/\u$1/g; $_ } @fields_copy
  ];
}

sub add_to_xsv {
  my ($csv, $fields, $line_ending) = @_;
  croak "add_to_xsv: fields argument (required) must be an array reference"
    if ! ($fields && ref( $fields ) eq 'ARRAY');

  # XXX redundant for empty string (or 0)
  $line_ending ||= '';

  return $line_ending if ! @{$fields};

  $csv->combine( @{$fields} )
    or croak "Failed to add [@{$fields}] to csv: " . $csv->error_input();

  return $csv->string() . $line_ending;
}

1;

__END__

=head1 NAME

CGI::Application::Plugin::Output::XSV - generate csv output from a CGI::Application runmode

=head1 SYNOPSIS

  use CGI::Application::Plugin::Output::XSV;
  ...

  # in some runmode...

  # $sth is a prepared DBI statement handle
  my $members = $sth->fetchall_arrayref( {} );

  my @headers = qw( member_id first_name last_name ... );

  return $self->xsv_report_web({
    fields     => \@headers,
    values     => $members,
    csv_opts   => { sep_char => "\t" },
    filename   => 'members.csv',
  });


  # or, generate the list on the fly:

  sub get_members { $sth->fetchrow_arrayref() }

  return $self->xsv_report_web({
    iterator   => \&get_members,
    csv_opts   => { sep_char => "\t" },
    filename   => 'members.csv',
  });

=head1 DESCRIPTION

C<CGI::Application::Plugin::Output::XSV> provides csv-related routines
useful for web applications (via L<Text::CSV_XS|Text::CSV_XS>).

A method, C<xsv_report_web> is exported by default. Three other
functions, C<xsv_report>, C<clean_field_names>, and C<add_to_xsv>
are available for optional export.

You may export all four routines by specifying the export tag C<:all>:

  use CGI::Application::Plugin::Output::XSV qw(:all);

=head1 PURPOSE

On many websites, I had code to retrieve a list of data items for use
in an L<HTML::Template|HTML::Template(3)> TMPL_LOOP. Usually this code
would use the L<DBI|DBI(3)> routine C<fetchall_arrayref()> to get a
list of hash references, one for each data item.

  my $users = $sth->fetchall_arrayref( {} );

  my $template = $self->load_tmpl( ... );

  $template->param( users => $users );

  return $template->output;

At some point, it would become apparent that an "export to spreadsheet"
feature would be useful, so I'd add another runmode, which almost always
looked the same:

    my @fields = qw(keys to each data item);

    my $csv = Text::CSV_XS->new();

    foreach my $user ( @{$users} ) {
      $csv->combine( [ @{$user}{@fields} ] );
      $output .= $csv->string() . "\n";
    }

    $self->header_props(
      -type                  => 'application/x-csv',
      '-content-disposition' => "attachment; filename=export.csv",
    );

    return $output;

The purpose of this module is to provide a simple method, C<xsv_report_web>,
that wraps the above code while offering a fair amount of programmer
flexibility.

For example, the programmer may control the naming of header columns,
filter each row of data before it is passed to L<Text::CSV_XS|Text::CSV_XS(3)>,
and set the filename that is supplied to the user's browser.

Please see the documentation below for C<xsv_report_web> for a list of
available options.

=head1 METHODS

=over 4

=item B<xsv_report_web>

  ## METHOD 1. Pre-generated list of values for csv

  # in a runmode

  my @members = (
    { member_id  => 1,
      first_name => 'Chuck',
      last_name  => 'Berry', },
    ...
  );

  my @headers = ("Member ID", "First Name", "Last Name");

  my @fields  = qw(member_id first_name last_name);

  return $self->xsv_report_web({
    fields     => \@fields,
    headers    => \@headers,
    values     => \@members,
    csv_opts   => { sep_char => "\t" },
    filename   => 'members.csv',
  });


  ## METHOD 2. Generate list on the fly

  # in a runmode

  sub get_members { $sth->fetchrow_arrayref() }

  my @headers = ("Member ID", "First Name", "Last Name");

  return $self->xsv_report_web({
    headers    => \@headers,
    iterator   => \&get_members,
    csv_opts   => { sep_char => "\t" },
    filename   => 'members.csv',
    stream     => 1,
  });

This method generates a csv file that is sent directly to the user's
web browser. It sets the content-type header to 'application/x-csv' and sets
the content-disposition header to 'attachment'.

It should be invoked through a
L<CGI::Application|CGI::Application(3)> subclass object.

It takes a reference to a hash of named parameters. All except for
C<values> or C<iterator> are optional:

=over 8

=item csv_opts

  csv_opts   => { sep_char => "\t" },

A reference to a hash of options passed to the constructor of
L<Text::CSV_XS|Text::CSV_XS(3)>. The default is an empty hash.

=item fields

  fields => [ qw(member_id first_name last_name) ],

  # or array indices
  fields => [ 1, 2, 0 ],

A reference to a list of field names or array indices. This parameter
specifies the order of fields in each row of output.

If C<fields> is not supplied, a list will be generated using the first
entry in the C<values> list. Note, however, that in this case, if the
C<values> parameter is a list of hashes, the field
order will be random because the field names are extracted from a hash.
If the C<values> parameter is a list of lists, the field order will be
the same as the data provided.

If C<fields> is not supplied and C<iterator> is used instead of C<values>,
the field list will be empty.

=item filename

  filename => 'members.csv',

The name of the file which will be sent in the HTTP content-disposition
header. The default is "download.csv".

=item headers

  headers => [ "Member ID", "First Name", "Last Name" ],

A reference to a list of column headers to be used as the first row
of the csv report.

If C<headers> is not supplied (and C<include_headers> is not set
to a false value), C<headers_cb> will be called with C<fields>
as a parameter to generate column headers.

=item headers_cb

  # replace underscores with spaces
  headers_cb => sub {
    my $fields = shift;

    # using temp var to avoid modifying $fields
    my @fields_copy = @{$fields};

    return [
      map { tr/_/ /; $_ } @fields_copy
    ];
  },

A reference to a subroutine used to generate column
headers from the field names.

A default routine is provided in C<clean_field_names>. This
function is passed a reference to the list of fields (C<fields>)
as a parameter and should return a reference to a list of column headers.

=item include_headers

  include_headers => 1,

A true or false value indicating whether to include C<headers>
(or automatically generated headers) as the first row of output.

The default is true.

=item line_ending

  line_ending     => "\n",

The value appended to each line of csv output. The default is "\n".

=item values

  values => [
    { member_id  => 1,
      first_name => 'Chuck',
      last_name  => 'Berry', },
  ],

  # or a list of lists
  values => [
    [ 1, 'Chuck', 'Berry', ],
  ],

A reference to a list of hash references (such as
that returned by the L<DBI|DBI(3)> C<fetchall_arrayref( {} )> routine),
or a reference to a list of list references.

Either this argument or C<iterator> must be provided.

=item iterator

  iterator => sub { $sth->fetchrow_arrayref() },

A reference to a subroutine that is used to generate each row
of data. It is passed a reference to the list of fields (C<fields>)
as a parameter and should return a reference to a list (which
will be passed to C<add_to_xsv()>).

It will be called repeatedly to generate each row of data until
it returns a false value.

This may be preferred to C<values> when the data set is large
or expensive to generate up-front. Thanks to Mark Stosberg for
suggesting this option.

Either this argument or C<values> must be provided.

=item maximum_iters

  maximum_iters => 1_000_000,

This is the maximum number of times the C<iterator> will be called
before an exception is raised. This is a basic stopgap to
prevent a runaway iterator that never returns false.

The default is one million.

=item row_filter

  # uppercase all values
  # (each row is a list of hash references)
  row_filter => sub {
    my ($row, $fields) = @_;

    return [ map { uc } @{$row}{@$fields} ];
  },

A reference to a subroutine used to filter each row of data
(other than the header row) before it is passed to C<add_to_xsv>.
When the C<values> parameter is
supplied, a default filter is provided that produces each row
in the order specified by C<headers>. For example, the default
filter for a C<values> list of hash references is shown below.

  row_filter => sub {
    my ($row, $fields) = @_;

    return [ @{$row}{@$fields} ];
  },

This subroutine is passed two parameters for each row:

=over 12

=item *

the current row (reference to a list of hashes or lists)

=item *

the field list (C<fields> - reference to a list of hash keys or array indices)

=back

Note: This parameter used to be named C<get_row_cb>. That name is
deprecated and a warning will be issued if it is used instead of
C<row_filter>.

=item stream

  stream => 1,

This flag controls whether or not output is printed immediately or
collected and returned to the caller. Set to a true value to remove
buffering on STDOUT and to emit output as it is generated. This can
save memory in the case of a large document, for example.

The default is false to retain backwards-compatibility. In general, it
is probably more efficient to set this to a true value, but note that it
breaks with the standard L<CGI::Application|CGI::Application(3)>
convention of returning generated content from your runmodes rather than
printing it yourself.


=back

=back

=head1 FUNCTIONS

=over 4

=item B<add_to_xsv>

   # $sth is a prepared DBI statement handle
   my $values  = $sth->fetchall_arrayref( {} );
   my @headers = qw/foo bar baz/;
   my $output;

   # $csv is a Text::CSV_XS object
   foreach my $href ( @{$values} ) {
      $output .= add_to_xsv( $csv, [ @{$href}{@headers} ], "\r\n" );
   }

This function, used internally by C<xsv_report>/C<xsv_report_web>,
formats a list of values for inclusion a csv file. The return value is
from C<< $csv->string() >>, where C<$csv> is a L<Text::CSV_XS|Text::CSV_XS(3)> object.

It takes three parameters:

=over 8

=item *

A L<Text::CSV_XS|Text::CSV_XS(3)> object

=item *

A reference to a list of values

=item *

The line ending

=back

On an error from L<Text::CSV_XS|Text::CSV_XS(3)>, the function raises an exception.

On receiving an empty list of values, the function returns the
line ending only.

=item B<clean_field_names>

  my $fields  = [ qw/first_name foo bar baz/ ];
  my $headers = clean_field_names( $fields );

  # $headers is now [ 'First Name', 'Foo', 'Bar', 'Baz' ]

This function takes a reference to a list of strings and returns
a reference to a new list in which the strings are reformatted
as such:

  1. Underscores ('_') are changed to spaces
  2. The first letter of each word is capitalized

This function is used by C<xsv_report> and C<xsv_report_web>
if the C<headers_cb> parameter is not supplied.

=item B<xsv_report>

  # $sth is a prepared DBI statement handle
  my $members = $sth->fetchall_arrayref( {} );

  my @headers = qw( member_id first_name last_name ... );

  my $output = $self->xsv_report({
    fields     => \@headers,
    values     => $members,
    csv_opts   => { sep_char => "\t" },
  });

  # do something with $output

This function generates a string containing csv data and returns it.

This may be useful
when you want to do some manipulation of the data before sending it to
the user's browser or elsewhere. It takes the same named parameters
(via a reference to a hash) as C<xsv_report_web> except for C<filename>,
which is not applicable to this function.

=back

=head1 EXAMPLES

=over 4

=item Specify (almost) everything

  return $self->xsv_report_web({
    values          => [
      { first_name => 'Jack',
        last_name  => 'Tors',
        phone      => '555-1212' },
      { first_name => 'Frank',
        last_name  => 'Rizzo',
        phone      => '555-1515' },
    ],
    headers         => [ "First Name", "Last Name", "Phone" ],
    fields          => [ qw(first_name last_name phone) ],
    include_headers => 1,
    line_ending     => "\n",
    csv_opts        => { sep_char => "\t" },
    filename        => 'download.csv',
  });

  __END__
  "First Name"  "Last Name"     Phone
  Jack  Tors    555-1212
  Frank Rizzo   555-1515

=item Use defaults

  # ends up with same options and output as above

  return $self->xsv_report_web({
    values          => [
      { first_name => 'Jack',
        last_name  => 'Tors',
        phone      => '555-1212' },
      { first_name => 'Frank',
        last_name  => 'Rizzo',
        phone      => '555-1515' },
    ],
    headers         => [ "First Name", "Last Name", "Phone" ],
    fields          => [ qw(first_name last_name phone) ],
  });

=item Use header generation provided by module

  # headers generated will be [ "First Name", "Last Name", "Phone" ]

  # same output as above

  return $self->xsv_report_web({
    values          => [
      { first_name => 'Jack',
        last_name  => 'Tors',
        phone      => '555-1212' },
      { first_name => 'Frank',
        last_name  => 'Rizzo',
        phone      => '555-1515' },
    ],
    fields          => [ qw(first_name last_name phone) ],
  });

=item Use custom header generation

  # headers generated will be [ "first", "last", "phone" ]

  return $self->xsv_report_web({
    values          => [
      { first_name => 'Jack',
        last_name  => 'Tors',
        phone      => '555-1212' },
      { first_name => 'Frank',
        last_name  => 'Rizzo',
        phone      => '555-1515' },
    ],
    fields          => [ qw(first_name last_name phone) ],
    headers_cb      => sub {
      my @h = @{ +shift };
      s/_name$// foreach @h;
      return \@h;
    },
  });

  __END__
  first,last,phone
  Jack,Tors,555-1212
  Frank,Rizzo,555-1515

=item If order of fields doesn't matter

  # headers and fields will be in random order (but consistent
  # throughout data processing) due to extraction from hash

  # (headers will be generated automatically)

  return $self->xsv_report_web({
    values          => [
      { first_name => 'Jack',
        last_name  => 'Tors',
        phone      => '555-1212' },
      { first_name => 'Frank',
        last_name  => 'Rizzo',
        phone      => '555-1515' },
    ],
  });

  __END__
  Phone,"Last Name","First Name"
  555-1212,Tors,Jack
  555-1515,Rizzo,Frank

=item No header row

  return $self->xsv_report_web({
    values          => [
      { first_name => 'Jack',
        last_name  => 'Tors',
        phone      => '555-1212' },
      { first_name => 'Frank',
        last_name  => 'Rizzo',
        phone      => '555-1515' },
    ],
    fields          => [ qw(first_name last_name phone) ],
    include_headers => 0,
  });

  __END__
  Jack,Tors,555-1212
  Frank,Rizzo,555-1515

=item Filter data as it is processed

  sub plus_one {
    my ($row, $fields) = @_;

    return [ map { $_ + 1 } @{$row}{@$fields} ];
  }

  # each row (other than header row) will be
  # passed through plus_one()
  return $self->xsv_report_web({
    fields     => [ qw(foo bar baz) ],
    values     => [ { foo => 1, bar => 2, baz => 3 }, ],
    row_filter => \&plus_one,
  });

  __END__
  Foo,Bar,Baz
  2,3,4

=item Pass list of lists (instead of hashes)

  # each row will be processed in order
  # since fields parameter is omitted

  $self->xsv_report_web({
    include_headers => 0,
    values          => [
      [ 1, 2, 3 ],
      [ 4, 5, 6 ],
    ],
  });

  __END__
  1,2,3
  4,5,6

=item Generate each row on the fly

  my @vals = qw(one two three four five six);

  sub get_vals {
    while ( @vals ) {
      return [ splice @vals, 0, 3 ]
    }
  };

  $self->xsv_report_web({
    include_headers => 0,
    iterator        => \&get_vals,
  });

  __END__
  one,two,three
  four,five,six

=item Generate each row on the fly using a DBI iterator

  my $get_vals = sub { $sth->fetchrow_arrayref() };

  $self->xsv_report_web({
    include_headers => 0,
    iterator        => $get_vals,
  });

=item Use a DBI iterator, increment each value extracted

  $self->xsv_report_web({
    include_headers => 0,
    iterator        => sub { $sth->fetchrow_arrayref() };
    row_filter      => sub {
      my $row = shift;
      return [ map { $_ + 1 } @{$row} ];
    },
  });

=back

=head1 ERROR HANDLING

The function C<add_to_xsv> will raise an exception when
C<< Text::CSV_XS->combine >> fails. Please see the L<Text::CSV_XS|Text::CSV_XS(3)>
documentation for details about what type of input causes a failure.

=head1 AUTHOR

Evan A. Zacks C<< <zackse@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-cgi-application-plugin-output-xsv@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI-Application-Plugin-Output-XSV>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<Text::CSV_XS>, L<CGI::Application>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006,2010 CommonMind, LLC. All rights reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
