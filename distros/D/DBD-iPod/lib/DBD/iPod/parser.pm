=head1 NAME

DBD::iPod::parser - parse iPod SQL queries

=head1 SYNOPSIS

Go away.

=head1 DESCRIPTION

Shamelessly copy/pasted from Darren Chamberlain's DBD::Google::parser.
Darren says:

"This package needs to subclass SQL::Parser, in order that the
functions defined can be used.  WIth SQL::Parser 1.005, the
SELECT_CLAUSE method needs to be overridden.

"Jeff Zucker tells me that SQL::Parser 1.006 is coming out
soon, and that it will support more functions and such.  There
might need to be some logic in here to ensure that an incompatible
version of SQL::Parser is not being used."

=head1 AUTHOR

Author E<lt>allenday@ucla.eduE<gt>

=head1 SEE ALSO

L<SQL::Parser>, L<DBD::Google::parser>.

=head1 COPYRIGHT AND LICENSE

GPL

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a '_'.  Methods are
in alphabetical order for the most part.

=cut

package DBD::iPod::parser;
use strict;
use base qw(SQL::Parser);
our $VERSION = '0.01';

use vars qw($FIELD_RE $FUNC_RE);

use Carp qw(carp);
use Data::Dumper;
use SQL::Parser;

# Package-scoped variables
# These are not lexicals so that they can be used in tests
$FIELD_RE = '[a-zA-Z][a-zA-Z0-9_]';
$FUNC_RE  = qr/$FIELD_RE*/; # methods?
$FIELD_RE = qr/$FIELD_RE*/;

my @default_columns = sort qw(
                              bitrate
                              fdesc
                              stoptime
                              songs
                              time
                              srate
                              rating
                              cdnum
                              cds
                              playcount
                              starttime
                              id
                              prerating
                              volume
                              songnum
                              path
                              genre
                              filesize
                              artist
                              album
                              comment
                              title
                              uniq
                             );

my %allowed_columns = map { $_ => 1 } @default_columns;
for my $dc (@default_columns) {
  $dc =~ s/([A-Z])/_\l$1/g;
  $allowed_columns{$dc} = 1;
}

# All functions are passed two items: the Net::Google::Search
# instanace and the text to be fiddled with.
my %functions = (
    'default'       => sub { $_[1]                  },
    'count'         => \&count,
);
$functions{''} = $functions{'default'};

# ----------------------------------------------------------------------
# new(@stuff)
# 
# Override SQL::Parser's new method, but only so that default values
# can be used.
# ----------------------------------------------------------------------
sub new { return shift->SUPER::new("iPod", @_) }

# ----------------------------------------------------------------------
# SELECT_CLAUSE($sql)
#
# Parses the SELECT portion of $sql, which contains only the pieces
# between SELECT and WHERE.  Understands the following syntax:
#
#   field
#
#   field AS alias
#
#   field AS "alias"
#
#   function(field)
#
#   function(field) AS alias
#
#   function(field) AS "alias"
#
# ----------------------------------------------------------------------
sub SELECT_CLAUSE {
  my ($self, $sql) = @_;
  #warn "Got: \$sql => '$sql'\n";
  my ($columns, $limit, @columns, @limit, $where, $parsed);

  # Internal data structures, given shorter names
  my $column_names =  $self->{'struct'}->{'column_names'}     = [ ];
  my $ORG_NAME     =  $self->{'struct'}->{'ORG_NAME'}         = { };
  my $functions    =  $self->{'struct'}->{'column_functions'} = { };
  my $aliases      =  $self->{'struct'}->{'column_aliases'}   = { };
  my $errstr       = \$self->{'struct'}->{'errstr'};

  # columns
  while ($sql =~ /\G

                        # Field name, including possible function
                        (?:
                          ($FUNC_RE\s*\([^)]+\))    # $1 => function
                        |
                          ($FIELD_RE)               # $2 => field name
                        | (\*)                      # $3 => '*'
                        )

                        # possible alias
                        (?:
                            \s+
                            [aA][sS]
                            \s+
                            (['"]?)                 # $4 => possibly quoted
                              \s*
                              ($FIELD_RE)           # $5 => alias (no spaces allowed!)
                              \s*
                            \4?
                        )?
                        \s*
                        ,?
                        \s*
                       /xsmg) {
    my $alias = $5 || "";
    my $function = $1 || "";

    #warn "\$function => '$function'\n\$alias => '$alias'\n";

    if (defined $3) {
      # SELECT * -> expanded to all column names
      my $df = $functions{'default'};
      for (@default_columns) {
        my $uc_ = uc $_;

        push @$column_names   => $_  ;
        $ORG_NAME->{  $uc_ }  =  $_  ;
        $functions->{ $uc_ }  =  $df ;
        $aliases->{   $uc_ }  =  $_  ;
      }
    }
    elsif ($function) {
      # SELECT foo(bar)
      my $original = $function;
      $original =~ /($FUNC_RE)\s*\((.*?)\)/;

      # XXX $n here might contains arguments; needs to be
      # passed to String::Shellquote to extract tokens
      my ($f, $n) = ($1, $2);
      $n =~ s/(^\s*|\s*$)//g;
      $f = "" unless defined $f;

      unless ($allowed_columns{$n}) {
        $$errstr = "Unknown column name '$n'";
        return;
      }

      # Possible cases include:
      #   1. No function defined
      #   2. Function defined that we know about
      if (defined $functions{$f}) {
        # Common case:
        #
        #   SELECT html_strip(title) FROM google ...
        #
        # A pre-defined function.
        $f = $functions{$f};
      }
      else {
        # No function:
        #
        #   SELECT title FROM google ...
        $f = $functions{'default'};
      }

      my $uc = uc $n;
      push @$column_names, $n;
      $ORG_NAME->{  $uc } = $n;
      $functions->{ $uc } = $f;
      $aliases->{   $uc } = $alias ? $alias : $n;
    }
    elsif (defined $2) {
      my $lc = lc $2;
      my $uc = uc $2;
      if ($allowed_columns{$lc}) {
        push @$column_names, $lc;
        $ORG_NAME->{  $uc } = $lc;
        $functions->{ $uc } = $functions{'default'};
        $aliases->{   $uc } = $alias ? $alias : $lc;
      } else {
        $$errstr = "Unknown column name '$2'";
        return;
      }
    }
  }

  1;
}

1;

__END__
