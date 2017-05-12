# $Id: ESQL.pm,v 1.20 2001/06/05 12:45:05 matt Exp $

package AxKit::XSP::ESQL;
use strict;
use vars qw/@ISA $VERSION $NS @RESULTS @NAMES @STH @COUNT/;

@ISA = ('Apache::AxKit::Language::XSP');

$VERSION = "1.4";
$NS = "http://apache.org/xsp/SQL/v2";

use Apache::AxKit::Language::XSP;
use DBI;
use AxKit::XSP::Util;

AxKit::XSP::Util->register();

# DBI->trace(1);

sub new_query {
    unshift @RESULTS, {};
    unshift @NAMES, [];
    unshift @STH, undef;
    unshift @COUNT, 0;
#    warn "new_query: ", scalar @STH, "\n";
}

sub end_query {
    shift @RESULTS;
    shift @NAMES;
    my $sth = shift @STH;
    $sth->finish();
    shift @COUNT;
#    warn "end_query: ", scalar @STH, "\n";
}

sub prepare {
    my ($dbh, $query) = @_;
    $STH[0] = $dbh->prepare($query);
}

sub execute {
    my (@params) = set_null_params(@_);
    my $rv = $STH[0]->execute(@params);
    $NAMES[0] = $STH[0]->{NAME_lc};
    my %hash;
    my $rc = $STH[0]->bind_columns(\@hash{ @{$NAMES[0]} });
    $RESULTS[0] = \%hash;
    return $rv;
}

sub execute_from_update {
    my (@params) = set_null_params(@_);
    return $STH[0]->execute(@params);
}

sub set_null_params {
    map { $_ eq 'NULL' ? undef : $_ } @_;
}

sub get_sth {
    my ($ancestor) = @_;
    $ancestor ||= 0;
    $STH[$ancestor];
}

sub get_row {
    my ($ancestor) = @_;
    $ancestor ||= 0;
    my $res = $STH[$ancestor]->fetch;
    $COUNT[$ancestor]++ if $res;
    return $res;
}

sub get_column {
    my ($column, $ancestor) = @_;
    $ancestor ||= 0;
    if (DBI::looks_like_number($column)) {
        return $RESULTS[$ancestor]{ $NAMES[$ancestor][$column - 1] };
    }
    else {
        return $RESULTS[$ancestor]{$column};
    }
}

sub column_name {
    my ($column, $ancestor) = @_;
    $ancestor ||= 0;
    return $STH[$ancestor]->{NAME}->[column_number($column)];
}

sub column_number {
    my ($col, $ancestor) = @_;
    $ancestor ||= 0;
    if (DBI::looks_like_number($col)) {
        return $col - 1;
    }
    else {
        my $num = 0;
        for (@{$NAMES[$ancestor]}) {
            last if $_ eq $col;
            $num++;
        }
        return $num;
    }
}

sub get_columns {
    my ($ancestor) = @_;
    $ancestor ||= 0;
    return @{$NAMES[$ancestor]};
}

sub get_count {
    my ($ancestor) = @_;
    $ancestor ||= 0;
    warn("get_count: returning " . $COUNT[$ancestor] . "\n");
    return $COUNT[$ancestor];
}

sub parse_char {
    my ($e, $text) = @_;

    if ($e->current_element() ne 'query') {
        $text =~ s/^\s*//;
        $text =~ s/\s*$//;
    }

    return '' unless $text;

    $text =~ s/\|/\\\|/g;
    return ". q|$text|";
}

sub parse_start {
    my ($e, $tag, %attribs) = @_;
    
    if ($tag eq 'connection') {
        $e->manage_text(0);
        return "{\nmy (\$dbh, \$connect_count, \$driver, \$transactions, \$dburl, \$user, \$pass);\n";
    }
    elsif ($tag eq 'driver') {
        my $transactions = 1;
        if (lc($attribs{transactions}) eq 'no') {
            $transactions = 0;
        }
        elsif (lc($attribs{transactions}) eq 'yes') {
            $transactions = 1;
        }
        elsif (exists($attribs{transactions})) {
            die "<esql:driver transactions='$attribs{transactions}'> is invalid. Use 'yes' or 'no'";
        }
        
        return '$transactions = ' . $transactions . ';$driver = "dbi:"';
    }
    elsif ($tag eq 'dburl') {
        return '$dburl = ""';
    }
    elsif ($tag eq 'username') {
        return '$user = ""';
    }
    elsif ($tag eq 'password') {
        return '$pass = ""';
    }
    elsif ($tag eq 'pool') {
        die "esql:pool not supported";
    }
    elsif ($tag eq 'execute-query') {
        $e->manage_text(0);
        return <<'EOT';
$dbh = DBI->connect($driver . ($dburl ? ":$dburl" : ''),
        $user, $pass,
        {
            PrintError => 0,
            AutoCommit => $transactions ? 0 : 1,
            RaiseError => 1,
        }) unless $connect_count;
$connect_count++;
AxKit::XSP::ESQL::new_query();
{
my ($query, $max_rows, $skip_rows, @params, $rv);
$max_rows = 0; $skip_rows = 0;
EOT
    }
    elsif ($tag eq 'max-rows') {
        return '$max_rows = ""';
    }
    elsif ($tag eq 'skip-rows') {
        return '$skip_rows = ""';
    }
    elsif ($tag eq 'query') {
        return '$query = ""';
    }
    elsif ($tag eq 'parameter') {
        return ". '?'; push(\@params, ''";
    }
    elsif ($tag eq 'results') {
        $e->manage_text(0);
        return <<'EOT';
{
AxKit::XSP::ESQL::prepare($dbh, $query);
$rv = AxKit::XSP::ESQL::execute(@params);
my ($col, $ancestor, $format);
if ($skip_rows) {
  1 while (AxKit::XSP::ESQL::get_count() < $skip_rows && AxKit::XSP::ESQL::get_row());
}
if (AxKit::XSP::ESQL::get_row()) {
EOT
    }
    elsif ($tag eq 'row-results') {
        $e->manage_text(0);
        return <<'EOT';
do {
EOT
    }
    elsif ($tag eq 'get-columns') {
        my $ancestor = $attribs{ancestor} || 0;
        my $case = $attribs{'tag-case'};
        my $function = '';
        if ($case eq 'upper') { $function = 'uc'; }
        if ($case eq 'lower') { $function = 'lc'; }
        $e->append_to_script("for my \$col (AxKit::XSP::ESQL::get_columns($ancestor)) {\nmy \$ancestor = $ancestor;\n");
        my $xsp_element = { 
                    Name => 'element', 
                    NamespaceURI => $AxKit::XSP::Core::NS, 
                    Attributes => [],
                };
        $e->start_element($xsp_element);
        my $xsp_name = {
                    Name => 'name',
                    NamespaceURI => $AxKit::XSP::Core::NS,
                    Attributes => [],
#                    Parent => $xsp_element,
                };
        $e->start_element($xsp_name);
        my $xsp_expr = {
                    Name => 'expr',
                    NamespaceURI => $AxKit::XSP::Core::NS,
                    Attributes => [],
#                    Parent => $xsp_name,
                };
        $e->start_element($xsp_expr);
        return '$col';
    }
    elsif ($tag eq 'encoding') {
        # not supported yet!
        die "esql:encoding not supported";
    }
    elsif ($tag eq 'column') {
        return '$col = ""';
    }
    elsif ($tag =~ /^get-(column|string|boolean|double|float|int|long|short)$/) {
        $e->start_expr($tag);
        my $code = '$col = ""; $ancestor = 0; $format = "";';
        if (my $col = lc($attribs{column})) {
            $code .= '$col = q|' . $col . '|;';
        }
        $code .= '$ancestor = ' . ($attribs{ancestor} || 0) . ';';
        return $code;
    }
    elsif ($tag =~ /^get-(date|time|timestamp)$/) {
        $e->start_expr($tag);
        my $code = '$col = ""; $ancestor = 0; $format = "";';
        if (my $col = lc($attribs{column})) {
            $code .= '$col = q|' . $col . '|;';
        }
        if (my $format = $attribs{format}) {
            $code .= '$format = q|' . $format . '|;';
        }
        $code .= '$ancestor = ' . ($attribs{ancestor} || 0) . ';';
        return $code;
    }
    elsif ($tag eq 'get-xml') {
        my $code = '$col = ""; $ancestor = 0; $format = "";';
        if (my $col = lc($attribs{column})) {
            $code .= '$col = q|' . $col . '|;';
        }
        $code .= '$ancestor = ' . ($attribs{ancestor} || 0) . ';';
        return $code;
    }
    elsif ($tag eq 'get-row-position') {
        $e->start_expr($tag);
        my $code = '$col = ""; $ancestor = 0; $format = "";';
        $code .= '$ancestor = ' . ($attribs{ancestor} || 0) . ';';
        return $code;
    }
    elsif ($tag eq 'get-column-name') {
        $e->start_expr($tag);
        my $code = '$col = ""; $ancestor = 0; $format = "";';
        if (my $col = lc($attribs{column})) {
            $code .= '$col = q|' . $col . '|;';
        }
        $code .= '$ancestor = ' . ($attribs{ancestor} || 0) . ';';
        return $code;
    }
    elsif ($tag eq 'get-column-label') {
        $e->start_expr($tag);
        my $code = '$col = ""; $ancestor = 0; $format = "";';
        if (my $col = lc($attribs{column})) {
            $code .= '$col = q|' . $col . '|;';
        }
        $code .= '$ancestor = ' . ($attribs{ancestor} || 0) . ';';
        return $code;
    }
    elsif ($tag eq 'get-column-type-name') {
        $e->start_expr($tag);
        my $code = '$col = ""; $ancestor = 0; $format = "";';
        if (my $col = lc($attribs{column})) {
            $code .= '$col = q|' . $col . '|;';
        }
        $code .= '$ancestor = ' . ($attribs{ancestor} || 0) . ';';
        return $code;
    }
    elsif ($tag eq 'no-results') {
        $e->manage_text(0);
        return <<'EOT';
if (AxKit::XSP::ESQL::get_count() == 0) {
my ($col, $ancestor, $format);
EOT
    }
    elsif ($tag eq 'update-results') {
        $e->manage_text(0);
        return <<'EOT';
{
AxKit::XSP::ESQL::prepare($dbh, $query);
$rv = AxKit::XSP::ESQL::execute_from_update(@params);
if ($rv) {
EOT
    }
    else {
        die "Unknown ESQL tag: $tag";
    }
}
    
sub parse_end {
    my ($e, $tag) = @_;
    if ($tag eq 'connection') {
        return "\n} # /connection\n";
    }
    elsif ($tag eq 'driver') { }
    elsif ($tag eq 'dburl') { }
    elsif ($tag eq 'username') { }
    elsif ($tag eq 'password') { }
    elsif ($tag eq 'pool') { }
    elsif ($tag eq 'execute-query') {
        return <<'EOT';
} # </execute-query>
AxKit::XSP::ESQL::end_query();
$connect_count--;
unless ($connect_count) {
    $dbh->disconnect();
    undef $dbh;
}
EOT
    }
    elsif ($tag eq 'max-rows') { }
    elsif ($tag eq 'skip-rows') { }
    elsif ($tag eq 'query') {
        return ";\n";
    }
    elsif ($tag eq 'parameter') {
        return ");\n\$query .= ''";
    }
    elsif ($tag eq 'results') {
        return <<'EOT';
} # end - if (rows existed)
} # </results>
$dbh->commit if $transactions;
EOT
    }
    elsif ($tag eq 'row-results') {
        return <<'EOT';
if ($max_rows && AxKit::XSP::ESQL::get_count() >= $max_rows) {
  last;
}
} while (AxKit::XSP::ESQL::get_row()); # while(get_row) </row-results>
EOT
    }
    elsif ($tag eq 'get-columns') {
        my $xsp_element = { 
                    Name => 'element', 
                    NamespaceURI => $AxKit::XSP::Core::NS, 
                    Attributes => [],
                };
        my $xsp_name = {
                    Name => 'name',
                    NamespaceURI => $AxKit::XSP::Core::NS,
                    Attributes => [],
                    Parent => $xsp_element,
                };
        my $xsp_expr = {
                    Name => 'expr',
                    NamespaceURI => $AxKit::XSP::Core::NS,
                    Attributes => [],
                    Parent => $xsp_name,
                };
        $e->end_element($xsp_expr);
        $e->end_element($xsp_name);
        delete $xsp_expr->{Parent};
        $e->start_element($xsp_expr);
        $e->append_to_script('AxKit::XSP::ESQL::get_column($col, $ancestor)');
        $e->end_element($xsp_expr);
        $e->end_element($xsp_element);
        return "\n} # </get-columns>\n";
    }
    elsif ($tag eq 'encoding') {
    }
    elsif ($tag eq 'column') {
    }
    elsif ($tag =~ /^get-(column|string)$/) {
        $e->append_to_script('AxKit::XSP::ESQL::get_column($col, $ancestor)');
        $e->end_expr();
        return '';
    }
    elsif ($tag =~ /^get-(date|time|timestamp)$/) {
        $e->append_to_script('AxKit::XSP::ESQL::get_column($col, $ancestor)');
        $e->end_expr();
        return '';
    }
    elsif ($tag eq 'get-boolean') {
        $e->append_to_script('AxKit::XSP::ESQL::get_column($col, $ancestor) ? XML::XPath::Boolean->True : XML::XPath::Boolean->False');
        $e->end_expr();
        return '';
    }
    elsif ($tag =~ /^get-(double|float)$/) {
        $e->append_to_script('sprintf("%e", AxKit::XSP::ESQL::get_column($col, $ancestor))');
        $e->end_expr();
        return '';
    }
    elsif ($tag =~ /^get-(int|long|short)$/) {
        $e->append_to_script('sprintf("%d", AxKit::XSP::ESQL::get_column($col, $ancestor))');
        $e->end_expr();
        return '';
    }
    elsif ($tag eq 'get-xml') {
        my $util_include_expr = { 
                    Name => 'include-expr', 
                    NamespaceURI => $AxKit::XSP::Util::NS, 
                    Attributes => [],
                };
        my $xsp_expr = {
                    Name => 'expr',
                    NamespaceURI => $AxKit::XSP::Core::NS,
                    Attributes => [],
                };
        $e->start_element($util_include_expr);
        $e->start_element($xsp_expr);
        $e->append_to_script('AxKit::XSP::ESQL::get_column($col, $ancestor)');
        $e->end_element($xsp_expr);
        $e->end_element($util_include_expr);
        return '';
        }
    elsif ($tag eq 'get-row-position') {
        $e->append_to_script('AxKit::XSP::ESQL::get_count($ancestor)');
        $e->end_expr();
        return '';
    }
    elsif ($tag eq 'get-column-name') {
        $e->append_to_script('lc(AxKit::XSP::ESQL::column_name($col, $ancestor))');
        $e->end_expr();
        return '';
    }
    elsif ($tag eq 'get-column-label') {
        $e->append_to_script('AxKit::XSP::ESQL::column_name($col, $ancestor)');
        $e->end_expr();
        return '';
    }
    elsif ($tag eq 'get-column-type-name') {
        $e->append_to_script('$dbh->type_info(AxKit::XSP::ESQL::get_sth($ancestor)->{TYPE}->[AxKit::XSP::ESQL::column_number($col)])->{TYPE_NAME}');
        $e->end_expr();
        return '';
    }
    elsif ($tag eq 'no-results') {
        $e->{ESQL_NodeMode} = 0;
        return "\n} # </no-results>\n";
    }
    elsif ($tag eq 'update-results') {
        $e->{ESQL_NodeMode} = 0;
        return <<'EOT';
} # end - if (update occured)
} # </update-results>
$dbh->commit if $transactions;
EOT
    }
    
    return ";";
}    	

1;
__END__

=head1 NAME

AxKit::XSP::ESQL - An Extended SQL taglib for AxKit eXtensible Server Pages

=head1 SYNOPSIS

Add the esql: namespace to your XSP C<<xsp:page>> tag:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:esql="http://apache.org/xsp/SQL/v2"
    >

And add this taglib to AxKit (via httpd.conf or .htaccess):

    AxAddXSPTaglib AxKit::XSP::ESQL

=head1 DESCRIPTION

This tag library provides extensive support for executing SQL statements
from within XSP. This tag library is the same as the Cocoon ESQL taglib.

=head1 TAG REFERENCE

Note that below we use the esql: prefix as a convention, however you can
use whatever prefix you like provided it is mapped to the appropriate
namespace.

=head2 C<<esql:connection>>

  parent: none

This is the required 'wrapper' element that declares your connection.

=head2 C<<esql:driver>>

  parent: <esql:connection>

The contents of this element define the DBI driver to be used. For
example, Pg, Sybase, Oracle.

You can also add an optional attribute: B<transactions='no'> to the
driver element, to indicate that this driver does not support
transactions (or just that you don't want to use transactions).

=head2 C<<esql:dburl>>

  parent: <esql:connection>

The name of this tag is a hang-over from the Cocoon (Java) version. In
the AxKit version this is simply anything that goes after the driver in
the connection string. So for PostgreSQL you might have in here 
C<dbname=axkit>, to connect to the "axkit" database. The full connect 
string is constructed as follows:

  "dbi:$driver" . ($dburl ? ":$dburl" : "")

See your DBD driver documentation for more details on what is valid for
the connection string.

=head2 C<<esql:username>>

  parent: <esql:connection>

The username to connect to the database with.

=head2 C<<esql:password>>

  parent: <esql:connection>

The password to use to connect to the database.

=head2 C<<esql:execute-query>>

  parent: <esql:connection>

This tag is a 'wrapper' tag around queries. You may have as many queries
as you like within a single C<<esql:connection>> tag.

=head2 C<<esql:skip-rows>>

  parent: <esql:execute-query>

The contents of this tag (which may be an <xsp:expr>) define a number of
rows to skip forward in the result set.

=head2 C<<esql:max-rows>>

  parent: <esql:execute-query>

The maximum number of rows to return.

=head2 C<<esql:query>>

  parent: <esql:execute-query>

The contents of this tag define the query to be executed.

=head2 C<<esql:parameter>>

  parent: <esql:query>

This tag can be put in your SQL query everywhere you might put a ? in
your SQL in DBI. ESQL is intelligent enough to create a cached statement
when you do this, and only execute your code when necessary. You
put an expression (or another taglib) within the parameter tag (see
the example below).

=head2 C<<esql:results>>

  parent: <esql:execute-query>

The contents of this tag are "executed" whenever the query returns some
results.

=head2 C<<esql:row-results>>

  parent: <esql:results>

The contents of this tag are "executed" for each row of the results

=head2 C<<esql:get-columns>>

  parent: <esql:row-results>

This tag gets all of the columns in the current row, and outputs them
as C<<column_name>>C<value</column_name>>. If you specify an attribute
C<tag-case="upper">, all columns are upper case. Alternatively, "lower"
gives you all tags in lower case. An ancestor attribute is also allowed,
see "Nested Results" below for more details.

=head2 get-*

  parent: <esql:row-results>

These are:

  get-column
  get-string
  get-boolean
  get-double
  get-float
  get-int
  get-long
  get-short

(and more below)

Each of these takes either an attribute column="name", or a child tag,
C<<esql:column>> which gives the column name. Alternatively either the
attribute or child element can be an integer (starting at 1) specifying
the column number.

Also allowed is an ancestor attribute, which is an integer (default 0),
which indicates how far up the nested results you go. See Nested Results
below.

=head2 C<<esql:get-date>>, C<<esql:get-time>>, C<<esql:get-timestamp>>

  parent: <esql:row-results>

These tags are the same as get-* above, except they also take a 
C<format="..."> attribute, which contains a strftime formatting string.

=head2 C<<esql:get-xml>>

  parent: <esql:row-results>

Again the same as get-* above. This tag assumes the contents of the
column are valid XML, and appends that XML into the result tree.

=head2 C<<esql:get-row-position>>

  parent: <esql:row-results>

Gets the current row number. Optional C<ancestor> attribute.

=head2 C<<esql:get-column-name>>

  parent: <esql:row-results>

Gets the column name indicated by the numbered column in the 
C<column="..."> attribute, or the child C<<esql:column>> element. The
attribute/child can actually be a string (name), but then what is
the point of that?

=head2 C<<esql:get-column-label>>

  parent: <esql:row-results>

Gets the label of the column. This is a hang-over from the Cocoon java
implementation where sadly nobody seems to know what label is compared
with name. In this case, get-column-name is always lower case, whereas
get-column-label is returned in the case that the DBD driver returns it
as.

=head2 C<<esql:get-column-type-name>>

  parent: <esql:row-results>

Returns the TYPE_NAME of the column indicated as other get-* elements.
See the DBI docs for more details.

=head2 C<<esql:no-results>>

  parent: <esql:execute-query>

The contents of this element are executed when the SQL returned no rows.

=head2 C<<esql:update-results>>

  parent: <esql:execute-query>

The contents of this element are executed when the SQL was an update
statement. The number of rows updated are in the C<$rv> variable.

=head1 Nested Results

With the ESQL taglib it is quite possible to do nested results. This is
a way to emulate outer joins, or just better organise things. See below
for an example of this.

When using nested results, you can use the ancestor attribute on any of
the get-* elements to get results from higher up the ancestry of results.

=head1 Errors

Unlike the original Cocoon version of this taglib, we let you handle
errors however you choose to, using the exception taglib. If an error
occurs, ESQL will throw an exception. If you don't capture this exception
it will propogate up to the core of AxKit, and either give a 500 internal
server error, or execute the AxErrorStylesheet if one is defined. See
L<AxKit>.

=head1 EXAMPLE

  <esql:connection>
  <esql:driver>Pg</esql:driver>
  <esql:dburl>dbname=axkit</esql:dburl>
  <esql:username>postgres</esql:username>
  <esql:password></esql:password>
  <esql:execute-query>
    <esql:query>
      select id,name from department_table where foo = 
      <esql:parameter><xsp:expr>4 + 5</xsp:expr></esql:parameter>
    </esql:query>
    <esql:results>
      <header>header info</header>
      <esql:row-results>
        <department>
          <id><esql:get-int column="id"/></id>
          <name><esql:get-string column="name"/></name>
          <esql:connection>
            <esql:driver>org.postgresql.Driver</esql:driver>
            <esql:dburl>jdbc:postgresql://localhost/test</esql:dburl>
            <esql:username>test</esql:username>
            <esql:password>test</esql:password>
            <esql:execute-query>
              <esql:query>select name from user_table where department_id = <esql:parameter type="int"><esql:get-int ancestor="1" column="id"/></esql:parameter></esql:query>
              <esql:results>
                <esql:row-results>
                  <user><esql:get-string column="name"/></user>
                </esql:row-results>
              </esql:results>
              <esql:no-results>
                <user>No employees</user>
              </esql:no-results>
            </esql:execute-query>
          </esql:connection>
        </department>
      </esql:row-results>
      <footer>footer info</footer>
    </esql:results>
    <esql:no-results>
      <department>No departments</department>
    </esql:no-results>
  </esql:execute-query>
  </esql:connection>

=head1 AUTHOR

Matt Sergeant, matt@axkit.com. Original Cocoon taglib by Donald Ball

=head1 COPYRIGHT

Copyright 2001 AxKit.com Ltd. You may use this module under the same
terms as AxKit itself.

=head1 SEE ALSO

L<AxKit>, L<DBI>, L<Apache::AxKit::Language::XSP>, the AxKit.org pages at
http://axkit.org/

=cut
