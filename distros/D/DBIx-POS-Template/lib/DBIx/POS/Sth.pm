package DBIx::POS::Sth;
use strict;
use utf8;
use Hash::Merge qw(merge);

sub new {
  #~ my ($class, $dbh, $pos) = map shift, 0..2;
  #~ my %opt = @_;
  #~ return bless [$dbh, $pos, \%opt], $class;
  my $class = shift;
  return bless \@_, $class;
}


sub sth {
  my ($dbh, $pos, $template) = @{ shift() };
  my $name = shift;
  my %arg = @_;
  die "No such name[$name] in POS-SQL dict! @{[ join ':', keys %$pos  ]}" unless $pos->{$name};

  my $sql = $pos->{$name}->template(%$template ? %arg ? %{merge($template, \%arg)} : %$template : %arg).sprintf("\n--DBIx::POS::Sth name: [%s]", $pos->{$name}->name);
  my $param = $pos->{$name}->param;
  
  my $sth;

  #~ local $dbh->{TraceLevel} = "3|DBD";
  
  if ($param && $param->{cached}) {
    $sth = $dbh->prepare_cached($sql);
    #~ warn "ST cached: ", $sth->{pg_prepare_name};
  } else {
    $sth = $dbh->prepare($sql);
  }
  
  return $sth;
  
}

1;

=pod

=encoding utf8

=head1 DBIx::POS::Sth

¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !

=head1 NAME

DBIx::POS::Sth - is a DBI statements hub. Works with L<DBIx::POS::Template> in pair.

=head1 SYNOPSIS

    my $sth = DBIx::POS::Sth->new(
      $dbh,
      $pos, # SQL dict
      foo => 'bar', # any pairs opts
      ...,
    );
    my $r = $dbh->selectrow_hashref($sth->sth('foo name'));

=head1 DESCRIPTION

Dictionary of DBI statements.

=head1 new($dbh, $pos, ...)

=head2 $dbh (first in list)

DBI handle

=head2 $pos (second in list)

An SQL dictionary object/instance of the L<DBIx::POS::Template>.

=head2 <any key=>value pairs>

Used for templates of $pos.


=head1 SEE ALSO

L<DBIx::POS::Template>

L<https://www.depesz.com/2012/12/02/what-is-the-point-of-bouncing/>

=cut


__END__
$dbh->do('PREPARE mystat AS SELECT COUNT(*) FROM pg_class WHERE reltuples < ?');
$sth = $dbh->prepare($s, {pg_server_prepare => 0,});
$sth->bind_param(1, 1, SQL_INTEGER);
$sth->{pg_prepare_name} = 'mystat';
$sth->execute(123);
DEALLOCATE  name 