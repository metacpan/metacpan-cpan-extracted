package DBIO::Oracle::Storage::AutoIncrement;
# ABSTRACT: Auto-increment / sequence detection for Oracle

use strict;
use warnings;

use DBIO::Carp;



sub _dbh_get_autoinc_seq {
  my ($self, $dbh, $source, $col) = @_;

  my $sql_maker = $self->sql_maker;
  my ($ql, $qr) = map { $_ ? (quotemeta $_) : '' } $sql_maker->_quote_chars;

  my $source_name;
  if (ref $source->name eq 'SCALAR') {
    $source_name = ${$source->name};
    $source_name = uc($source_name) if $source_name !~ /\"/;
  }
  else {
    $source_name = $source->name;
    $source_name = uc($source_name) unless $ql;
  }

  local $dbh->{LongReadLen} = 64 * 1024 if ($dbh->{LongReadLen} < 64 * 1024);
  local $sql_maker->{bindtype} = 'normal';

  my ($schema, $table) = $source_name =~ /( (?:${ql})? \w+ (?:${qr})? ) \. ( (?:${ql})? \w+ (?:${qr})? )/x;
  $schema ||= \'= USER';

  my ($sql, @bind) = $sql_maker->select(
    'ALL_TRIGGERS',
    [qw/TRIGGER_BODY TABLE_OWNER TRIGGER_NAME/],
    {
      OWNER => $schema,
      TABLE_NAME => $table || $source_name,
      TRIGGERING_EVENT => { -like => '%INSERT%' },
      TRIGGER_TYPE => { -like => '%BEFORE%' },
      STATUS => 'ENABLED',
    },
  );

  my @triggers = (map {
    my %inf; @inf{qw/body schema name/} = @$_; \%inf
  } (grep {
    $_->[0] =~ /\:new\.${ql}${col}${qr} | \:new\.$col/xi
  } @{ $dbh->selectall_arrayref($sql, {}, @bind) }
  ));

  @triggers = map {
    my @seqs = $_->{body} =~ / ( [\.\w\"\-]+ ) \. nextval /xig;
    @seqs ? { %$_, sequences => \@seqs } : ()
  } @triggers;

  my $chosen_trigger;

  if (@triggers == 1) {
    if (@{$triggers[0]{sequences}} == 1) {
      $chosen_trigger = $triggers[0];
    }
    else {
      $self->throw_exception(sprintf(
        "Unable to introspect trigger '%s' for column '%s.%s' (references multiple sequences). "
        . "You need to specify the correct 'sequence' explicitly in '%s's column_info.",
        $triggers[0]{name}, $source_name, $col, $col,
      ));
    }
  }
  elsif (@triggers > 1) {
    my @candidates = grep { $_->{body} =~ / into \s+ \:new\.$col /xi } @triggers;
    if (@candidates == 1 && @{$candidates[0]{sequences}} == 1) {
      $chosen_trigger = $candidates[0];
    }
    else {
      $self->throw_exception(sprintf(
        "Unable to reliably select a BEFORE INSERT trigger for column '%s.%s' (possibilities: %s). "
        . "You need to specify the correct 'sequence' explicitly in '%s's column_info.",
        $source_name, $col, (join ', ', map { "'$_->{name}'" } @triggers), $col,
      ));
    }
  }

  if ($chosen_trigger) {
    my $seq_name = $chosen_trigger->{sequences}[0];
    $seq_name = "$chosen_trigger->{schema}.$seq_name" unless $seq_name =~ /\./;
    return \$seq_name if $seq_name =~ /\"/;
    return $seq_name;
  }

  $self->throw_exception(sprintf(
    "No suitable BEFORE INSERT triggers found for column '%s.%s'. "
    . "You need to specify the correct 'sequence' explicitly in '%s's column_info.",
    $source_name, $col, $col,
  ));
}

sub _dbh_last_insert_id {
  my ($self, $dbh, $source, @columns) = @_;
  my @ids;
  for my $col (@columns) {
    my $seq = ($source->column_info($col)->{sequence} ||= $self->get_autoinc_seq($source, $col));
    push @ids, $self->_sequence_fetch('CURRVAL', $seq);
  }
  return @ids;
}

sub _sequence_fetch {
  my ($self, $type, $seq) = @_;
  my $sth = $self->_dbh->prepare_cached(
    $self->sql_maker->select('DUAL', [ ref $seq ? \"$$seq.$type" : "$seq.$type" ] )
  );
  $sth->execute;
  my ($id) = $sth->fetchrow_array;
  $sth->finish;
  return $id;
}

sub get_autoinc_seq {
  my ($self, $source, $col) = @_;
  $self->dbh_do('_dbh_get_autoinc_seq', $source, $col);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Storage::AutoIncrement - Auto-increment / sequence detection for Oracle

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Detects Oracle sequences associated with autoincrement columns by inspecting
BEFORE INSERT triggers in ALL_TRIGGERS.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
