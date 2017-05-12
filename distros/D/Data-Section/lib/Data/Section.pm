use strict;
use warnings;
package Data::Section;
# ABSTRACT: read multiple hunks of data out of your DATA section
$Data::Section::VERSION = '0.200006';
use Encode qw/decode/;
use MRO::Compat 0.09;
use Sub::Exporter 0.979 -setup => {
  groups     => { setup => \'_mk_reader_group' },
  collectors => { INIT => sub { $_[0] = { into => $_[1]->{into} } } },
};

# =head1 SYNOPSIS
#
#   package Letter::Resignation;
#   use Data::Section -setup;
#
#   sub quit {
#     my ($class, $angry, %arg) = @_;
#
#     my $template = $self->section_data(
#       ($angry ? "angry_" : "professional_") . "letter"
#     );
#
#     return fill_in($$template, \%arg);
#   }
#
#   __DATA__
#   __[ angry_letter ]__
#   Dear jerks,
#
#     I quit!
#
#   -- 
#   {{ $name }}
#   __[ professional_letter ]__
#   Dear {{ $boss }},
#
#     I quit, jerks!
#
#
#   -- 
#   {{ $name }}
#
# =head1 DESCRIPTION
#
# Data::Section provides an easy way to access multiple named chunks of
# line-oriented data in your module's DATA section.  It was written to allow
# modules to store their own templates, but probably has other uses.
#
# =head1 WARNING
#
# You will need to use C<__DATA__> sections and not C<__END__> sections.  Yes, it
# matters.  Who knew!
#
# =head1 EXPORTS
#
# To get the methods exported by Data::Section, you must import like this:
#
#   use Data::Section -setup;
#
# Optional arguments may be given to Data::Section like this:
#
#   use Data::Section -setup => { ... };
#
# Valid arguments are:
#
#   encoding     - if given, gives the encoding needed to decode bytes in
#                  data sections; default; UTF-8
#
#                  the special value "bytes" will leave the bytes in the string
#                  verbatim
#
#   inherit      - if true, allow packages to inherit the data of the packages
#                  from which they inherit; default: true
#
#   header_re    - if given, changes the regex used to find section headers
#                  in the data section; it should leave the section name in $1
#
#   default_name - if given, allows the first section to has no header and set
#                  its name
#
# Three methods are exported by Data::Section:
#
# =head2 section_data
#
#   my $string_ref = $pkg->section_data($name); 
#
# This method returns a reference to a string containing the data from the name
# section, either in the invocant's C<DATA> section or in that of one of its
# ancestors.  (The ancestor must also derive from the class that imported
# Data::Section.)
#
# By default, named sections are delimited by lines that look like this:
#
#   __[ name ]__
#
# You can use as many underscores as you want, and the space around the name is
# optional.  This pattern can be configured with the C<header_re> option (see
# above).  If present, a single leading C<\> is removed, so that sections can
# encode lines that look like section delimiters.
#
# When a line containing only C<__END__> is reached, all processing of sections
# ends.
#
# =head2 section_data_names
#
#   my @names = $pkg->section_data_names;
#
# This returns a list of all the names that will be recognized by the
# C<section_data> method.
#
# =head2 merged_section_data
#
#   my $data = $pkg->merged_section_data;
#
# This method returns a hashref containing all the data extracted from the
# package data for all the classes from which the invocant inherits -- as long as
# those classes also inherit from the package into which Data::Section was
# imported.
#
# In other words, given this inheritance tree:
#
#   A
#    \
#     B   C
#      \ /
#       D
#
# ...if Data::Section was imported by A, then when D's C<merged_section_data> is
# invoked, C's data section will not be considered.  (This prevents the read
# position of C's data handle from being altered unexpectedly.)
#
# The keys in the returned hashref are the section names, and the values are
# B<references to> the strings extracted from the data sections.
#
# =head2 merged_section_data_names
#
#   my @names = $pkg->merged_section_data_names;
#
# This returns a list of all the names that will be recognized by the
# C<merged_section_data> method.
#
# =head2 local_section_data
#
#   my $data = $pkg->local_section_data;
#
# This method returns a hashref containing all the data extracted from the
# package on which the method was invoked.  If called on an object, it will
# operate on the package into which the object was blessed.
#
# This method needs to be used carefully, because it's weird.  It returns only
# the data for the package on which it was invoked.  If the package on which it
# was invoked has no data sections, it returns an empty hashref.
#
# =head2 local_section_data_names
#
#   my @names = $pkg->local_section_data_names;
#
# This returns a list of all the names that will be recognized by the
# C<local_section_data> method.
#
# =cut

sub _mk_reader_group {
  my ($mixin, $name, $arg, $col) = @_;
  my $base = $col->{INIT}{into};

  my $default_header_re = qr/
    \A                # start
      _+\[            # __[
        \s*           # any whitespace
          ([^\]]+?)   # this is the actual name of the section
        \s*           # any whitespace
      \]_+            # ]__
      [\x0d\x0a]{1,2} # possible cariage return for windows files
    \z                # end
  /x;

  my $header_re = $arg->{header_re} || $default_header_re;
  $arg->{inherit} = 1 unless exists $arg->{inherit};

  my $default_encoding = defined $arg->{encoding} ? $arg->{encoding} : 'UTF-8';

  my %export;
  my %stash = ();

  $export{local_section_data} = sub {
    my ($self) = @_;

    my $pkg = ref $self ? ref $self : $self;

    return $stash{ $pkg } if $stash{ $pkg };

    my $template = $stash{ $pkg } = { };

    my $dh = do { no strict 'refs'; \*{"$pkg\::DATA"} }; ## no critic Strict
    return $stash{ $pkg } unless defined fileno *$dh;
    binmode( $dh, ":raw :bytes" );

    my ($current, $current_line);
    if ($arg->{default_name}) {
        $current = $arg->{default_name};
        $template->{ $current } = \(my $blank = q{});
    }
    LINE: while (my $line = <$dh>) {
      if ($line =~ $header_re) {
        $current = $1;
        $current_line = 0;
        $template->{ $current } = \(my $blank = q{});
        next LINE;
      }

      last LINE if $line =~ /^__END__/;
      next LINE if !defined $current and $line =~ /^\s*$/;

      Carp::confess("bogus data section: text outside of named section")
        unless defined $current;

      $current_line++;
      unless ($default_encoding eq 'bytes') {
        my $decoded_line = eval { decode($default_encoding, $line, Encode::FB_CROAK) }
          or warn "Invalid character encoding in $current, line $current_line\n";
        $line = $decoded_line if defined $decoded_line;
      }
      $line =~ s/\A\\//;

      ${$template->{$current}} .= $line;
    }

    return $stash{ $pkg };
  };

  $export{local_section_data_names} = sub {
    my ($self) = @_;
    my $method = $export{local_section_data};
    return keys %{ $self->$method };
  };

  $export{merged_section_data} =
    !$arg->{inherit} ? $export{local_section_data} : sub {

    my ($self) = @_;
    my $pkg = ref $self ? ref $self : $self;

    my $lsd = $export{local_section_data};

    my %merged;
    for my $class (@{ mro::get_linear_isa($pkg) }) {
      # in case of c3 + non-$base item showing up
      next unless $class->isa($base);
      my $sec_data = $class->$lsd;

      # checking for truth is okay, since things must be undef or a ref
      # -- rjbs, 2008-06-06
      $merged{ $_ } ||= $sec_data->{$_} for keys %$sec_data;
    }

    return \%merged;
  };

  $export{merged_section_data_names} = sub {
    my ($self) = @_;
    my $method = $export{merged_section_data};
    return keys %{ $self->$method };
  };

  $export{section_data} = sub {
    my ($self, $name) = @_;
    my $pkg = ref $self ? ref $self : $self;

    my $prefix = $arg->{inherit} ? 'merged' : 'local';
    my $method = "$prefix\_section_data";

    my $data = $self->$method;

    return $data->{ $name };
  };

  $export{section_data_names} = sub {
    my ($self) = @_;

    my $prefix = $arg->{inherit} ? 'merged' : 'local';
    my $method = "$prefix\_section_data_names";
    return $self->$method;
  };

  return \%export;
}

# =head1 TIPS AND TRICKS
#
# =head2 MooseX::Declare and namespace::autoclean
#
# The L<namespace::autoclean|namespace::autoclean> library automatically cleans
# foreign routines from a class, including those imported by Data::Section.
#
# L<MooseX::Declare|MooseX::Declare> does the same thing, and can also cause your
# C<__DATA__> section to appear outside your class's package.
#
# These are easy to address.  The
# L<Sub::Exporter::ForMethods|Sub::Exporter::ForMethods> library provides an
# installer that will cause installed methods to appear to come from the class
# and avoid autocleaning.  Using an explicit C<package> statement will keep the
# data section in the correct package.
#
#    package Foo;
#
#    use MooseX::Declare;
#    class Foo {
#
#      # Utility to tell Sub::Exporter modules to export methods.
#      use Sub::Exporter::ForMethods qw( method_installer );
#
#      # method_installer returns a sub.
#      use Data::Section { installer => method_installer }, -setup;
#
#      method my_method {
#         my $content_ref = $self->section_data('SectionA');
#
#         print $$content_ref;
#      }
#    }
#
#    __DATA__
#    __[ SectionA ]__
#    Hello, world.
#
# =head1 SEE ALSO
#
# =begin :list
#
# * L<article for RJBS Advent 2009|http://advent.rjbs.manxome.org/2009/2009-12-09.html>
#
# * L<Inline::Files|Inline::Files> does something that is at first look similar,
# but it works with source filters, and contains the warning:
#
#   It is possible that this module may overwrite the source code in files that
#   use it. To protect yourself against this possibility, you are strongly
#   advised to use the -backup option described in "Safety first".
#
# Enough said.
#
# =end :list
#
# =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Section - read multiple hunks of data out of your DATA section

=head1 VERSION

version 0.200006

=head1 SYNOPSIS

  package Letter::Resignation;
  use Data::Section -setup;

  sub quit {
    my ($class, $angry, %arg) = @_;

    my $template = $self->section_data(
      ($angry ? "angry_" : "professional_") . "letter"
    );

    return fill_in($$template, \%arg);
  }

  __DATA__
  __[ angry_letter ]__
  Dear jerks,

    I quit!

  -- 
  {{ $name }}
  __[ professional_letter ]__
  Dear {{ $boss }},

    I quit, jerks!


  -- 
  {{ $name }}

=head1 DESCRIPTION

Data::Section provides an easy way to access multiple named chunks of
line-oriented data in your module's DATA section.  It was written to allow
modules to store their own templates, but probably has other uses.

=head1 WARNING

You will need to use C<__DATA__> sections and not C<__END__> sections.  Yes, it
matters.  Who knew!

=head1 EXPORTS

To get the methods exported by Data::Section, you must import like this:

  use Data::Section -setup;

Optional arguments may be given to Data::Section like this:

  use Data::Section -setup => { ... };

Valid arguments are:

  encoding     - if given, gives the encoding needed to decode bytes in
                 data sections; default; UTF-8

                 the special value "bytes" will leave the bytes in the string
                 verbatim

  inherit      - if true, allow packages to inherit the data of the packages
                 from which they inherit; default: true

  header_re    - if given, changes the regex used to find section headers
                 in the data section; it should leave the section name in $1

  default_name - if given, allows the first section to has no header and set
                 its name

Three methods are exported by Data::Section:

=head2 section_data

  my $string_ref = $pkg->section_data($name); 

This method returns a reference to a string containing the data from the name
section, either in the invocant's C<DATA> section or in that of one of its
ancestors.  (The ancestor must also derive from the class that imported
Data::Section.)

By default, named sections are delimited by lines that look like this:

  __[ name ]__

You can use as many underscores as you want, and the space around the name is
optional.  This pattern can be configured with the C<header_re> option (see
above).  If present, a single leading C<\> is removed, so that sections can
encode lines that look like section delimiters.

When a line containing only C<__END__> is reached, all processing of sections
ends.

=head2 section_data_names

  my @names = $pkg->section_data_names;

This returns a list of all the names that will be recognized by the
C<section_data> method.

=head2 merged_section_data

  my $data = $pkg->merged_section_data;

This method returns a hashref containing all the data extracted from the
package data for all the classes from which the invocant inherits -- as long as
those classes also inherit from the package into which Data::Section was
imported.

In other words, given this inheritance tree:

  A
   \
    B   C
     \ /
      D

...if Data::Section was imported by A, then when D's C<merged_section_data> is
invoked, C's data section will not be considered.  (This prevents the read
position of C's data handle from being altered unexpectedly.)

The keys in the returned hashref are the section names, and the values are
B<references to> the strings extracted from the data sections.

=head2 merged_section_data_names

  my @names = $pkg->merged_section_data_names;

This returns a list of all the names that will be recognized by the
C<merged_section_data> method.

=head2 local_section_data

  my $data = $pkg->local_section_data;

This method returns a hashref containing all the data extracted from the
package on which the method was invoked.  If called on an object, it will
operate on the package into which the object was blessed.

This method needs to be used carefully, because it's weird.  It returns only
the data for the package on which it was invoked.  If the package on which it
was invoked has no data sections, it returns an empty hashref.

=head2 local_section_data_names

  my @names = $pkg->local_section_data_names;

This returns a list of all the names that will be recognized by the
C<local_section_data> method.

=head1 TIPS AND TRICKS

=head2 MooseX::Declare and namespace::autoclean

The L<namespace::autoclean|namespace::autoclean> library automatically cleans
foreign routines from a class, including those imported by Data::Section.

L<MooseX::Declare|MooseX::Declare> does the same thing, and can also cause your
C<__DATA__> section to appear outside your class's package.

These are easy to address.  The
L<Sub::Exporter::ForMethods|Sub::Exporter::ForMethods> library provides an
installer that will cause installed methods to appear to come from the class
and avoid autocleaning.  Using an explicit C<package> statement will keep the
data section in the correct package.

   package Foo;

   use MooseX::Declare;
   class Foo {

     # Utility to tell Sub::Exporter modules to export methods.
     use Sub::Exporter::ForMethods qw( method_installer );

     # method_installer returns a sub.
     use Data::Section { installer => method_installer }, -setup;

     method my_method {
        my $content_ref = $self->section_data('SectionA');

        print $$content_ref;
     }
   }

   __DATA__
   __[ SectionA ]__
   Hello, world.

=head1 SEE ALSO

=over 4

=item *

L<article for RJBS Advent 2009|http://advent.rjbs.manxome.org/2009/2009-12-09.html>

=item *

L<Inline::Files|Inline::Files> does something that is at first look similar,

but it works with source filters, and contains the warning:

  It is possible that this module may overwrite the source code in files that
  use it. To protect yourself against this possibility, you are strongly
  advised to use the -backup option described in "Safety first".

Enough said.

=back

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
