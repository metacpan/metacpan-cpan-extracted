package DBIx::AbstractStatement;
use strict;

=head1 NAME

DBIx::AbstractStatement - SQL command kept together with the bindings

=head1 SYNOPSIS

  use DBIx::AbstractStatement qw(sql sql_join);

  my $statement = sql('
    SELECT * FROM customer c WHERE c.deleted is null');
  # ordinary binding
  if ($customer_id){
      $statement->append(' AND c.id = :customer_id')
        ->bind_param(':customer_id', $customer_id);
  }

  # binding with sql
  $statement->append(' AND :dt_created > :created')
  $statement->bind_param(':created', $created || sql('sysdate'));
 
  # execute  
  $statement->dbh($dbh)->execute;
  while(my @ary = $statement->sth->fetchrow_array){
  }
  ...

  # join
  my $where = sql_join(
    ($customer_name
      ? sql('customer_name = :value')->bind_param(':value', $customer_name)
      : ()),
    ($from
      ? sql('created >= :value')->bind_param(':value', $from)
      : ()),
    map {
        sql("$_ = :$_")->bind_param(":$_", $args{$_})
    } keys %args);

=head1 DESCRIPTION

The purpose of DBIx::AbstractStatement is to keep together 
the SQL command and host variables bindings so
you can compose your SQL and bind host variables 
simultaneously before DBH->prepare is called.

A database handle to a statement can be supplied anytime before execute
is called or never if the particular statement is not about to be executed
but just used as a part of another statement.

When execute is called on DBIx::AbstractStatement object,
the statement handle is prepared, all stored bindings performed on it, 
and execute is called.

=head2 FUNCTIONS IMPORTED ON DEMAND

=over 4

=cut

our @EXPORT_OK = qw(sql sql_param sql_param_inout is_sql sql_join);
our @ISA = qw(Exporter Class::Accessor);
our $VERSION=0.09;
require Exporter;

use Class::Accessor;
__PACKAGE__->mk_accessors(qw(text bindings numbered_params dbh));

use constant 'BOUND_PARAM_SUFFIX' => '_dxas';

# setter returns the object
sub set { my $this = shift; $this->SUPER::set(@_); $this }

# Exported methods - just shortcuts
sub sql             { __PACKAGE__->new(@_) }
sub sql_param       { __PACKAGE__->new(':v')->bind_param(':v', @_) }
sub sql_param_inout { __PACKAGE__->new(':v')->bind_param_inout(':v', @_) }
sub is_sql          { UNIVERSAL::isa(shift(), __PACKAGE__) }
sub sql_join {
    my($sep, @sql) = @_;
    __PACKAGE__->new(
      join($sep, map $_->text, @sql),
      'bindings' => [ map @{$_->bindings}, @sql ]);
}

=item sql($TEXT, %PARAMS)

  my $statement = DBIx::AbstractStatement->new("SELECT * FROM customer");
  # or with imported sql 
  my $statement = sql("SELECT * FROM customer", 'numbered_params' => 1);
  
A constructor (shortcut of Akar::DBI::Staement->new). 
The $TEXT parameter is by no means required to be 
a valid SQL statement. 

The parameters can be 'dbh' or 'numbered_params' described 
as setter-getters further.

=cut

sub new {
    my $proto  = shift;
    my($text, %params) = @_;

    $params{'text'}      = defined($text)? $text: '';
    $params{'bindings'} ||= [];
    $proto->SUPER::new(\%params);
}

=item sql_join($SEPARATOR, $SQL1, $SQL2, ...)
    
    my $sql = sql("SELECT * FROM customer WHERE ")->append(
      sql_join(" AND ", map {
         sql("$_ => :$_")->bind_param(":$_", $params{$_}) 
        } keys(%params)));

Returns a new sql. Joins both the texts and the bindings.

=back

=head1 METHODS

=over 4

=item bind_param($NAME, $VALUE)

=item bind_param_inout($NAME, $VALUEREF, $SIZE)

  $statement->bind_param(':customer_id', $this->customer_id); 

  # Oracle piece of PL/SQL decomposing an object into individual items
  # Can be inserted into more complicated SQL statements
  my $statement = sql("
      :customer_id := l_payload.customer_id;
      :action      := l_payload.action;\n)
    ->bind_param_inout(':customer_id', \$$this{'customer_id'}, 12)
    ->bind_param_inout(':action', \$$this{'action'}, 128)

  # binding with statement 
  my $sql = sql("SELECT * FROM customer WHERE inserted > :inserted");
  $sql->bind_param(':inserted', sql('sysdate'));

  # or even
  $sql->bind_param(':inserted', 
    sql('sysdate - :days')->bind_param('days', $days));

Stores an input or output binding for later usage. 
Both methods accept the same parameters as their C<$sth-E<gt>bind_param>, 
C<$sth-E<gt>bind_param_inout> DBI counterparts.
Both methods return the invocant.

The name has to be :IDENTIFIER not :NUMBER.

Value to bind can be DBIx::AbstractStatement object.
In this case every occurence of this parameter is 
replaced by the text of the value.

When parameter is bound an unique suffix is prepended to its name
to prevent name clash.

=cut

sub bind_param { shift(@_)->_bind_param('bind_param', @_) } 

sub bind_param_inout { shift(@_)->_bind_param('bind_param_inout', @_) } 

sub _param_re { 
    my $param_name = shift; 
    qr(\Q$param_name\E\b);
}

# the bind variables have unique names
my $Cnt = 0;

sub _bind_param {
    my $this = shift;
    my($method, $param_name, $value, @rest) = @_;

    my(@bindings, $replacement);
    if (is_sql($value)){
        # value is statement (is replaced in text)
        $replacement = $value->text;
        @bindings = @{$value->bindings};
    } 
    else {
        # value is value to bind
        $replacement = $param_name. BOUND_PARAM_SUFFIX. ++$Cnt;
        @bindings = DBIx::AbstractStatement::Binding->new({
          'method' => $method,
          'param_name' => $replacement,
          'rest' => [$value, @rest]});
    }
    my $re   = _param_re($param_name);
    my $text = $this->text; $text =~ s/$re/$replacement/sg
    or die sprintf "No occurence of %s in SQL string\n%s\n ", $param_name, $text;
    $this->text($text);
    push @{$this->bindings}, @bindings;
    $this;
}

=item has_param($NAME)

  $sql->bind_param(':created', sql('sysdate')) if $sql->has_param(':created');

Returns true if statement contains the parameter.

=cut

# checks for param with certain name
sub has_param {
    my $this = shift;
    my($param_name) = @_;

    $this->text =~ _param_re($param_name); 
}

=item get_param_name($NAME)

  my $suffixed = $sql->get_param_name('customer_id');

Simillar to has_param, but returns the name of the parameter -
suffixed if the parameter has already been bound.

=cut

# returns the new name of bind parameter 
sub get_param_name {
    my $this = shift;
    my($param_name) = @_;

    # looking for  
    my $re = "\Q$param_name". "(?:". BOUND_PARAM_SUFFIX . "\\d+|\\b)";
    my %names = map { 
        my($order) = /(\d+)$/;
        $_ => $order || 0; 
    } $this->text =~ /($re)/sg;
    # names are ordered by the parameter suffix
    my @names = sort { $names{$a} <=> $names{$b} } keys %names;
    wantarray? @names: $names[-1]; 
}

=item dbh

  $statement->dbh($dbh); # setter
  my $dbh = $statement->dbh; # getter

Setter/getter for a database handle. 

=item sth

  my @ary = $this->sth->fetchrow_array

Returns prepared (or prepared and executed) statement handle.
Calls dbh->prepare when called for the first time.

=cut

sub sth {
    my $this = shift;
    $$this{'_sth'} ||= do {
        $this->_renumber_params if $this->numbered_params; 
        $this->dbh->prepare($this->text);
    };
}

=item execute

  $statement->execute

Prepares statement handle, performs all bindings and calls execute on the handle. 

=cut

sub execute {
    my $this = shift;

    my $sth = $this->sth;
    # process bindings
    for my $binding (@{$this->bindings}){
        my $method = $binding->method;
        $sth->$method($binding->param_name, @{$binding->rest});
    }
    $sth->execute;
}

=item numbered_params

  $sql->numbered_params(1);

Setter-getter. If set to true, parameters in text and bindings 
are modified from :IDENTIFIER style to C<?> and :NUMBER style
right before the statement is prepared.

=cut

=item append

  $statement->append($text, $text2, ...);
  $statement->append($statement, $statement, ...);

Joins the statement. Accepts a list of statements or strings 
(which are turned into statements).
The SQLs and bindings of these statements are appended to the invocant's 
SQL and bindings. Returns the modified invocant.

=cut

sub append {
    my $this = shift;

    my @list = _statement_list(@_);
    $this->text( join('', map {$_->text} $this, @list));
    push @{$this->bindings}, @{$_->bindings} for @list;
    $this;
}

=item prepend

  $statement->prepend($text, $text2, ...);
  $statement->prepend($statement, $statement, ...);

Simillar to append. The SQLs of statements are
joined together and prepended before the invocant's SQL.
Returns the modified invocant.

=cut

sub prepend {
    my $this = shift;

    my @list = _statement_list(@_);
    $this->text(join('', map {$_->text} @list, $this));
    push @{$this->bindings}, @{$_->bindings} for @list;
    $this;
}

=item sprintf

  $statement->sprintf($text, $text2, ...);
  $statement->sprintf($statement, $statement, ...);

Simillar to append and prepend. The bindings of statements are 
appended to the bindings of the invocant, while the invocant's 
new SQL code is composed using sprintf with old SQL being the format.
Returns the modified invocant.

=cut

sub sprintf {
    my $this = shift;
        
    my @list = _statement_list(@_);
    $this->text(sprintf($this->text, map {$_->text} @list));
    push @{$this->bindings}, @{$_->bindings} for @list;
    $this;
}

# makes list of statements from the mixed list of statements and strings 
sub _statement_list {
    map {ref($_)? $_: __PACKAGE__->new($_)} @_;
}

# params changes from :statement_id, :type_id to 1, 2
sub _renumber_params {
    my $this = shift;

    return unless @{$this->bindings};

    my %bindings = map {$_->param_name => $_} @{$this->bindings};
    my @new_bindings;
    my $replace_binding = sub {
        my($param_name) = @_;
        my $binding = $bindings{$param_name};

        push @new_bindings, $binding->new({
          'param_name' => scalar(@new_bindings + 1),
          'method' => $binding->method,
          'rest'   => $binding->rest});
        '?';
    };

    my $text = $this->text; 
    # reverse - longer names first
    my $re = '('. join('|', map {$_->param_name} reverse @{$this->bindings}) . ')';
    $text =~ s/$re/&$replace_binding($1)/sge;

    $this->text($text);
    $this->bindings(\@new_bindings);
}

{
    package DBIx::AbstractStatement::Binding;
    use base qw(Class::Accessor);
    __PACKAGE__->mk_accessors(qw(method param_name rest));
}


=back

=cut 

=head1 AUTHOR

Roman Daniel <roman.daniel@gtsnovera.cz>

=cut

1;

