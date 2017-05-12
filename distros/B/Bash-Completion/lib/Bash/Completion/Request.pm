package Bash::Completion::Request;
{
  $Bash::Completion::Request::VERSION = '0.008';
}

# ABSTRACT: Abstract a completion request

use strict;
use warnings;


sub line { return $_[0]{line} }



sub word { return $_[0]{word} }



sub args { return @{$_[0]{args}} }



sub count { return $_[0]{count} }



sub point { return $_[0]{point} }



sub new {
  my ($class) = @_;

  return bless {
    candidates => [],

    line  => $ENV{COMP_LINE},
    point => $ENV{COMP_POINT},
    _get_completion_word(),
    _get_arguments(),
  }, $class;
}



sub candidates {
  my $self = shift;
  my $c    = $self->{candidates};

  return @$c unless @_;

  push @$c, @_;
}


#######
# Utils

## Stolen from http://github.com/yanick/dist-zilla/blob/master/contrib/dzil-complete
sub _get_completion_word {
  my $comp = substr $ENV{'COMP_LINE'}, 0, $ENV{'COMP_POINT'};
  $comp =~ s/.*\s//;
  return word => $comp;
}

sub _get_arguments {
  my $comp = substr $ENV{'COMP_LINE'}, 0, $ENV{'COMP_POINT'};
  my @args = split(/\s+/, $comp);

  return args => \@args, count => scalar(@args);
}


1;

__END__
=pod

=head1 NAME

Bash::Completion::Request - Abstract a completion request

=head1 VERSION

version 0.008

=head1 ATTRIBUTES

=head2 line

The full command line as given to us by bash.

=head2 word

The word to be completed.

=head2 args

The command line, up to and including the word to be completed, as a list of terms.

The split of the command line into terms is very very basic. There might be dragons here.

=head2 count

Number of words in the command line before the completion point.

=head2 point

The index in the command line where the shell cursor is.

=head1 METHODS

=head2 new

Constructs a completion request object based on the bash environment
variables: C<COMP_LINE> and C<COMP_POINT>.

=head2 candidates

Accepts a list of completion candidates and passes them on to the shell.

=head1 AUTHOR

Pedro Melo <melo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Pedro Melo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

