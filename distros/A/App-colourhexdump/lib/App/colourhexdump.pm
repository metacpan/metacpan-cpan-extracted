use 5.006;    # our
use strict;
use warnings;

package App::colourhexdump;

our $VERSION = '1.000003';

# ABSTRACT: HexDump, but with character-class highlighting.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( has with );
use MooseX::Getopt::Dashes 0.37;
with qw( MooseX::Getopt::Dashes );

use Getopt::Long::Descriptive;
use Term::ANSIColor 3.00 qw( colorstrip );
use App::colourhexdump::Formatter;
use namespace::autoclean;

has colour_profile => (
  metaclass     => 'Getopt',
  isa           => 'Str',
  is            => 'rw',
  default       => 'DefaultColourProfile',
  cmd_aliases   => [qw/ C color-profile /],
  documentation => 'Backend to use for colour highlighting (DefaultColourProfile)',
);

has row_length => (
  metaclass     => 'Getopt',
  isa           => 'Int',
  is            => 'ro',
  default       => 32,
  cmd_aliases   => [qw/ r row /],
  documentation => 'Number of bytes per display row (32).',

);

has chunk_length => (
  metaclass     => 'Getopt',
  isa           => 'Int',
  is            => 'rw',
  default       => 4,
  cmd_aliases   => [qw/ x chunk /],
  documentation => 'Number of bytes per display hex display group (4).',
);

has _files => (
  metaclass     => 'Getopt',
  isa           => 'ArrayRef[Str]',
  is            => 'rw',
  default       => sub { [] },
  cmd_flag      => 'file',
  cmd_aliases   => [qw/ f /],
  documentation => 'Add a file to the list of files to process. \'-\' for STDIN.',

);

has 'show_file_prefix' => (
  metaclass     => 'Getopt',
  isa           => 'Bool',
  is            => 'rw',
  default       => 0,
  documentation => 'Enable printing the filename on the start of every line ( off ).',

);
has 'show_file_heading' => (
  metaclass     => 'Getopt',
  isa           => 'Bool',
  is            => 'rw',
  default       => 0,
  documentation => 'Enable printing the filename before the hexdump output. ( off ).',
);
has 'colour' => (
  metaclass     => 'Getopt',
  isa           => 'Bool',
  is            => 'rw',
  default       => 1,
  cmd_aliases   => [qw/ c color /],
  documentation => 'Enable coloured output ( on ). --no-colour to disable.',

);

__PACKAGE__->meta->make_immutable;
no Moose;









sub BUILD {
  my $self = shift;
  push @{ $self->_files() }, @{ $self->extra_argv };
  return $self;

}









sub get_filehandle {
  my ( undef, $filename ) = @_;
  if ( q[-] eq $filename ) {
    return \*STDIN;
  }
  require Carp;
  open my $fh, '<', $filename or Carp::confess("Cant open $_ , $!");
  return $fh;
}









sub run {
  my $self = shift;
  if ( not @{ $self->_files } ) {
    push @{ $self->_files }, q[-];
  }
  ## no critic ( Variables::RequireLocalizedPunctuationVars )
  local $ENV{ANSI_COLORS_DISABLED} = $ENV{ANSI_COLORS_DISABLED};
  if ( not $self->colour ) {
    $ENV{ANSI_COLORS_DISABLED} = 1;
  }
  for ( @{ $self->_files } ) {
    my $prefix = q{};
    if ( $self->show_file_prefix ) {
      $prefix = $_;
    }
    if ( length $prefix ) {
      $prefix .= q{:};
    }
    ## no critic ( RequireCheckedSyscalls );
    if ( $self->show_file_heading ) {
      print qq{- Contents of $_ --\n};
    }
    my $formatter = App::colourhexdump::Formatter->new(
      colour_profile => $self->colour_profile,
      row_length     => $self->row_length,
      chunk_length   => $self->chunk_length,
    );

    $formatter->format_foreach_in_fh(
      $self->get_filehandle($_),
      sub {
        print $prefix . shift;
      },
    );
  }
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::colourhexdump - HexDump, but with character-class highlighting.

=head1 VERSION

version 1.000003

=head1 SYNOPSIS

    usage: colourhexdump [-?Ccfrx] [long options...]
        -? --usage --help                     Prints this usage information.
        --color-profile -C --colour-profile   Backend to use for colour highlighting (DefaultColourProfile)
        --row -r --row-length                 Number of bytes per display row (32).
        --chunk -x --chunk-length             Number of bytes per display hex display group (4).
        -f --file                             Add a file to the list of files to process. '-' for STDIN.
        --show-file-prefix                    Enable printing the filename on the start of every line ( off ).
        --show-file-heading                   Enable printing the filename before the hexdump output. ( off ).
        --color -c --colour                   Enable coloured output ( on ). --no-colour to disable.

It can be used like so

    colourhexdump  file/a.txt file/b.txt -- --this-is-treated-like-a-file.txt

If you are using an HTML-enabled POD viewer, you should see a screenshot of this in action:

( Everyone else can visit L<http://kentnl.github.io/App-colourhexdump/media/Screenshot.png> )

=for html <center><img src="http://kentnl.github.io/App-colourhexdump/media/Screenshot.png" alt="Screenshot with explanation of colours" width="826" height="838"/></center>

=head1 METHODS

=head2 BUILD

This just pushes extra_argv from getopt into the files list.

B<INTERNAL>

=head2 get_filehandle

    my $fh = $self->get_filehandle( $filename_or_stdindash );

B<INTERNAL>

=head2 run

Run the app.

    App::colourhexdump->new_with_options()->run();

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
