package DBD::Google::parser;

# ----------------------------------------------------------------------
# This package needs to subclass SQL::Parser, in order that the
# functions defined can be used.  WIth SQL::Parser 1.005, the
# SELECT_CLAUSE method needs to be overridden.
#
# Jeff Zucker tells me that SQL::Parser 1.006 is coming out
# soon, and that it will support more functions and such.  There
# might need to be some logic in here to ensure that an incompatible
# version of SQL::Parser is not being used.
# ----------------------------------------------------------------------

use strict;
use base qw(SQL::Parser);
use vars qw($VERSION $FIELD_RE $FUNC_RE);

use Carp qw(carp);
use File::Spec::Functions qw(catfile);
use HTML::Entities qw(encode_entities);
use SQL::Parser;
use URI::Escape qw(uri_escape);

$VERSION = "2.00";

# Package-scoped variables
# These are not lexicals so that they can be used in tests
$FIELD_RE = '[a-zA-Z][a-zA-Z0-9_]';
$FUNC_RE = qr/$FIELD_RE*(?:::$FIELD_RE*)*(?:[-]>$FIELD_RE*)?/; # methods?
$FIELD_RE = qr/$FIELD_RE*/;

my @default_columns = sort qw( title url snippet summary
                               cachedSize directoryTitle
                               hostName directoryCategory
                             );
my %allowed_columns = map { $_ => 1 }
                      map { $_, lc $_, uc $_ }
                      @default_columns;
for my $dc (@default_columns) {
    $dc =~ s/([A-Z])/_\l$1/g;
    $allowed_columns{$dc} = 1;
}

# All functions are passed two items: the Net::Google::Search
# instanace and the text to be fiddled with.
my %functions = (
    'default'       => sub { $_[1]                  },
    'uri_escape'    => sub { uri_escape($_[1])      },
    'html_escape'   => sub { encode_entities($_[1]) },
    'count'         => \&count,
    'html_strip'    => \&striphtml,
);
$functions{''} = $functions{'default'};

# ----------------------------------------------------------------------
# new(@stuff)
# 
# Override SQL::Parser's new method, but only so that default values
# can be used.
# ----------------------------------------------------------------------
sub new { return shift->SUPER::new("Google", @_) }

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
#   package::function(field)
#
#   package::function(field) AS alias
#
#   package::function(field) AS "alias"
#
#   package->method(field)
#
#   package->method(field) AS alias
#
#   package->method(field) AS "alias"
#
# ----------------------------------------------------------------------
sub SELECT_CLAUSE {
    my ($self, $sql) = @_;
    #warn "Got: \$sql => '$sql'\n";
    my ($columns, $limit, @columns, @limit, $where, $parsed);

    # SQL::Parser::clean_sql does funny things to strings
    # that look like methods
    $sql = $self->unclean_cleaned_sql($sql);

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
                          ($FUNC_RE\s*\([^)]+\))   # $1 => function
                        |
                          ($FIELD_RE)               # $2 => field name
                        | (\*)                      # $3 => '*' 
                        )

                        # possible alias
                        (?:
                            \s+
                            [aA][sS]
                            \s+
                            (['"]?)                   # $4 => possibly quoted
                              \s*
                              ($FIELD_RE)             # $5 => alias (no spaces allowed!)
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
            #   3. Function defined we don't know about
            #       3a. Function/method to be loaded
            #       3b. Error
            if ($f) {
                if (defined $functions{$f}) {
                    # Common case:
                    #
                    #   SELECT html_strip(title) FROM google ...
                    #
                    # A pre-defined function.
                    $f = $functions{$f};
                }
                else {
                    # If a user specifies a function like:
                    #
                    #   SELECT Digest::MD5::md5_hex(title) FROM google ...
                    #
                    # or:
                    #
                    #   SELECT URI->new(URL) FROM google ...
                    #
                    if (my ($package, $type, $func) = $f =~ /(.*)(::|[-]>)(.*)/) {

                        eval "use $package;";
                        if ($@) {
                            $$errstr = $@;
                            return;
                        }
                        else {
                            if ($type eq '::') {
                                if (defined(my $g = \&{"$package\::$func"})) {
                                    $f = sub { shift; &$g(@_) };
                                } else {
                                    $$errstr = "Can't load $package\::$func";
                                }
                            }
                            elsif ($type eq '->') {
                                $f = sub { shift; $package->$func(@_) };
                            }
                            else {
                                $f = $functions{'default'};
                            }
                        }
                    }
                    else {
                        # Function that matches $FUNC_RE but doesn't contain
                        # :: or ->; might be a built-in, such as uc, lc, 
                        # gethostbyname, unlink, or even
                        # 'system("GET www.pr0n.com | mail ceo@my.company")'.
                        #
                        # This sucks, BTW.
                        $f = eval qq(sub { $f(\$_[1]) };);
                    }
                }
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

# ----------------------------------------------------------------------
# decompose()
#
# Returns a data structure, similar to the structure() method, that
# contains only what DBD::Google::db needs to pass to Net::Google.
# The data structure looks like:
#
# {
#   QUERY => "query string",
#   COLUMNS => [
#               {
#                 FIELD => "Net::Google methodname",
#                 FUNCTION => sub { },
#                 ALIAS => "alias",
#               },
#              ],
#   LIMIT => {
#               limit => X,
#               offset => Y,
#            },
# }
# ----------------------------------------------------------------------
sub decompose {
    my $self = shift;
    my $struct = $self->structure;
    my %data = ();

    # Limit (use defaults of 0, 10)
    $data{'LIMIT'} = $struct->{'limit_clause'} || { offset => 0, limit => 10 };

    # Where
    $data{'WHERE'} = $struct->{'where_clause'}->{'arg2'}->{'value'} || "";
    $data{'WHERE'} =~ tr/'"//d;

    # Columns
    $data{'COLUMNS'} = [
        map { { FIELD    => $struct->{'ORG_NAME'}->{$_},
                FUNCTION => $struct->{'column_functions'}->{$_},
                ALIAS    => $struct->{'column_aliases'}->{$_},
            } }          @{ $struct->{'column_names'} }
    ];

    return wantarray ? %data : \%data;
}

# ----------------------------------------------------------------------
# unclean_cleaned_sql($sql)
#
# Undo some of the damage that SQL::Parser::clean_sql does to functions
# that look like Perl methods, e.g., Foo::Bar->new(title) gets turned
# into Foo::Bar- > new (title), which is no good.
# ----------------------------------------------------------------------
sub unclean_cleaned_sql {
    my ($self, $sql) = @_;

    $sql =~ s/\s*([-<>])\s*/$1/g;

    return $sql;
}

# ----------------------------------------------------------------------
# striphtml($ng, $text)
#
# A function for stripping HTML.  Very naive; it it becomes an
# issue, I'll include TCHRIST's striphtml.
# ----------------------------------------------------------------------
sub striphtml {
    my $text = $_[1];
    $text =~ s#</?[^>]*>##smg;
    return $text;
}

# ----------------------------------------------------------------------
# count($ng)
#
# Returns the total number of results.
# ----------------------------------------------------------------------
sub count {
    my $ngs = shift; # Net::Google::Search instance
    my $res = $ngs->response;
    return $res->estimateTotalResultsNumber;
}

1;

__END__

NOTES

Tim Buunce suggested count(*) as a way to get the total number of search results.

Data structure of SQL::Parser instance after parsing looks like:

                 'struct' => {
                               'org_table_names' => [
                                                      'google'
                                                    ],
                               'column_names' => [
                                                   '*'
                                                 ],
                               'table_alias' => {},
                               'command' => 'SELECT',
                               'table_names' => [
                                                  'GOOGLE'
                                                ],
                               'org_col_names' => [
                                                    '*'
                                                  ]
                             },

