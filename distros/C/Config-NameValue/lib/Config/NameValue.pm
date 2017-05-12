package Config::NameValue;

# ABSTRACT: Round trip simple name/value config file handling.

# VERSION


use strict;
use warnings;
use namespace::autoclean;

use Carp;
use File::Slurp qw( slurp );
use Scalar::Util qw( blessed );
use POSIX qw( strftime );

our $VERSION = 1.00;

{  # Quick! Hide!

  my $error;


  sub new {

    my ( $class, $file ) = @_;

    croak 'Calling new as a function is not supported'
      unless $class && $class ne '';

    my $self = bless {}, ref $class || $class;

    $self->load( $file )
      if $file && $file ne '';

    return $self;

  }


  sub load {

    my ( $self, $file ) = @_;

    croak 'Calling load as a function is not supported'
      unless blessed $self;

    if ( ! $file || $file eq '' ) {

      croak 'No file to load'
        unless exists $self->{ file } && $self->{ file } ne '';

      $file = $self->{ file };

    }

    my @lines = slurp( $file, { chomp => 1 } );

    for ( my $i = 0 ; $i < @lines ; $i++ ) {

      my $line = $lines[ $i ];

      next if $line =~ /^\s*(#.*)?$/;  # Ignore blank lines and comment lines
      $line =~ s/(?<!\\)#.*$//;        # Strip comment on a valid line, ignoring escaped #'s

      $line =~ s/^\s*(.*?)\s*$/$1/;    # Strip leading and trailing whitespace

      my @data = split /\s*=\s*/, $line, 2;
      $data[ 0 ] =~ s/^\s*(.*)/$1/;
      $data[ 1 ] =~ s/^(["'])(.*)\1$/$2/;
      $data[ 1 ] =~ s/\\#/#/g;

      $self->{ name }{ $data[ 0 ] } = { value => $data[ 1 ], line => $i, modified => 0 };

    }

    $self->{ file }     = $file;
    $self->{ lines }    = \@lines;
    $self->{ count }    = scalar @lines;
    $self->{ modified } = 0;

    return 1;

  } ## end sub load


  sub save {

    my ( $self, $file ) = @_;

    croak 'Calling save as a function is not supported'
      unless blessed $self;

    if ( ! $file || $file eq '' ) {

      croak 'No file to save'
        unless exists $self->{ file } && $self->{ file } ne '';

      $file = $self->{ file };

    } elsif ( $file eq $self->{ file } ) {

      croak 'No changes, not saving'
        unless $self->{ modified };

    }

    if ( $self->{ modified } ) {

      my @modified = grep { $self->{ name }{ $_ }{ modified } } keys %{ $self->{ name } };

      for my $name ( @modified ) {

        my ( $value, $line ) = @{ $self->{ name }{ $name } }{ qw( value line ) };
        $self->{ lines }[ $line ] =~ s/^(\s*(["'])$name\2\s*=\s*)(["'])(?:.*)\3\s*$/$1$3$value$3/;

      }
    }

    my $work_file = "$file.work";

    require IO::Handle;

    open my $FH, '>', $work_file
      or croak "Unable to open $work_file: $!";

    print $FH "$_\n" for @{ $self->{ lines } };

    $FH->close
      or carp "Unable to close $work_file: $!\n";  # How do I test this to satisfy Devel::Cover?

    rename $work_file, $file
      or croak "Unable to rename $work_file to $file: $!";

  } ## end sub save


  sub get {

    my ( $self, $name ) = @_;

    croak 'Calling get as a function is not supported'
      unless blessed $self;

    croak "Nothing loaded"
      if ! exists $self->{ count } || $self->{ count } == 0;

    croak "Can't get nothing (no name passed)"
      if $name eq '';

    do { $error = "$name does not exist"; return }
      unless exists $self->{ name }{ $name };

    return $self->{ name }{ $name }{ value };

  } ## end sub get


  sub set {

    my ( $self, $name, $value ) = @_;

    croak 'Calling set as a function is not supported'
      unless blessed $self;

    croak "Nothing loaded"
      if ! exists $self->{ count } || $self->{ count } == 0;

    croak "Can't set nothing (no name passed)"
      if $name eq '';

    if ( ! exists $self->{ name }{ $name } ) {

      #    my $date = do {
      #
      #      my @d = localtime( time );
      #      $d[5] += 1900;
      #      $d[4]++;
      #
      #      join '-', @d[4,3,5];
      #
      #    };

      $value =~ s/#/\\#/;

      my $comment = sprintf '# %s added by %s on %s', $name, __PACKAGE__, strftime( '%F', gmtime );

      push @{ $self->{ lines } }, $comment;
      push @{ $self->{ lines } }, "$name=\"$value\"";

      $self->{ count }++;
      $self->{ name }{ $name } = { value => $value, line => $self->{ count }++, modified => 0, };

    } else {

      @{ $self->{ name }{ $name } }{ qw( value modified ) } = ( $value, 1 );

    }

    $self->{ modified } = 1;

    return 1;

  } ## end sub set


  sub error { $error }

}  # You can come out now!

1;

__END__
=pod

=for :stopwords Alan Young

=encoding utf-8

=head1 NAME

Config::NameValue - Round trip simple name/value config file handling.

=head1 VERSION

  This document describes v1.03 of Config::NameValue - released February 09, 2012 as part of Config-NameValue.

=head1 SYNOPSIS

  use Config::NameValue;
  my $c = Config::NameValue->new( 'config.file' );

=head1 DESCRIPTION

Load simple name=value pair configuration files and save them.

Blank lines and comments are ignored.

  # Begin config file

  # Everything up to here will be ignored but continued in saved file.

  name1=value1
  name2=value2 # everything after the octothorpe will be ignored but be saved in the file when changes are made

=head1 METHODS

=head2 new

Returns a Config::NameValue object.  Can optionally be passed a filename, which will be loaded via the C<load> command.

=head2 load

Loads and parses the specified configuration file.

Leading and trailing whitespace are stripped.

  name1=value1
    name1=value1   # are equivalent

=head2 save

Saves the configuration, with any changes, to a file.

If no filename is passed the original file is overwritten, otherwise a new file will be created.

As a special case, if the original filename is explicitly passed to save and there have been no changes an exception will be thrown.

=head2 get

Returns the value for the requested name, undef for nonexistant or empty names.

=head2 set

Modifies the requested name with the supplied value.

If the name does not exist it will be created and saved with a comment
indicating that it was added by this program

=head2 error

Returns the most recent error

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AUTHOR

Alan Young <harleypig@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alan Young.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

