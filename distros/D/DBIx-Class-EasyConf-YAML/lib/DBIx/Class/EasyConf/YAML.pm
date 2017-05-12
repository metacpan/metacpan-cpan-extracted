package DBIx::Class::EasyConf::YAML;

use 5.008008;
use strict;

use YAML;
our $VERSION = '0.11';
our $VERBOSE = undef;

sub configure {
  my ($package, $fh) = @_;

  my %args = map { lc $_ => 1 } @ARGV;
  $VERBOSE    = $args{verbose} ? 1 : undef;
  my $config  = $args{configuration} ? 1 : undef;

  {
    no strict 'refs';
    $fh ||=  *{"${package}::DATA"};
  }

  my $yaml = do { local $/; <$fh> };
  my $data = YAML::Load($yaml);

  _set_table         ($package, $data);
  _set_columns       ($package, $data);
  _set_pk            ($package, $data);
  _set_unique        ($package, $data);
  _set_relationships ($package, $data);

  print_configuration($package) if $config;
}


sub _set_table {
  my ($package, $data) = @_;
  my $table = $data->{table}
    or die "Cannot configure $package: table not specified.\n";
  $package->table($table);
}

sub _set_pk {
  my ($package, $data) = @_;
  my $pk = $data->{primary_key}
    or die "Cannot configure $package: primary key not specified.\n";
  $package->set_primary_key(ref $pk eq 'ARRAY' ? @$pk : $pk);
}

sub _set_columns {
  my ($package, $data) = @_;
  die "Cannot configure $package: columns not properly specified.\n"
    unless ref $data->{columns} eq 'HASH';
  my $columns = $data->{columns};
  $package->add_columns(%{ $columns });
}

sub _set_unique {
  my ($package, $data) = @_;
  return unless ref $data->{unique} eq 'HASH';
  for my $name (keys %{ $data->{unique} }) {
    my $spec = $data->{unique}->{$name};
    my $cols = ref $spec eq 'ARRAY' ? $spec : [ $spec ];
    $package->add_unique_constraint($name => $cols);
  }
}

sub _set_relationships {
  my ($package, $data) = @_;
  return unless ref $data->{relationships} eq 'ARRAY';
  for my $relation (@{ $data->{relationships} }) {
    my ($relation, $value) = each %{ $relation };
    my ($type, $class, $condition, $attrs) = @{ $value };
    $class = resolve_relative_class($class, $package) 
      unless $type eq 'many_to_many';
    $package->$type($relation, $class, $condition, $attrs);

    if ($VERBOSE) {
      my %relationships = map { $_ => 1 } $package->relationships;
      my $ok = exists $relationships{$relation} ? 1 : undef;
      my $space_one = " " x (50 - length $package);
      my $space_two = " " x (20 - length $relation);
      print STDERR 
	($ok ? "RELATION OK:" : "RELATION FAIL: "),
	  "$package $space_one $relation $space_two $type\n",
	    "\t$package->$type($relation, $class, $condition)\n\n";
    }
  }
}
  
sub resolve_relative_class {
  my ($class, $package) = @_;
  return $class if $class =~ /::/; # fully qualified already.
  (my $new_package = $package) =~ s/::[^:]+$/::$class/;
  return $new_package;
}

sub print_configuration {
  my $package = shift;
  local $\ = "\n";
  print "Table: ", $package->table;
  print "Primary Key: ", join ", " => $package->primary_columns;
  
  print "Columns: ";
  for my $col ($package->columns) {
    my %info = %{ $package->column_info($col) };
    print "\t$col:";
    print "\t\t$_ => $info{$_}" for sort keys %info;
  }
  
  print "Relationships:";
  for my $rel ($package->relationships) {
    my %info = %{ $package->relationship_info($rel) };
    print "\t$rel:";
    for my $key (sort keys %info) {
      if (ref $info{$key}) {
	print "\t\t$key:";
	print "\t\t\t$_ => $info{$key}->{$_}" for sort keys %{ $info{$key} };
      }
      else {
	print "\t\t$key => $info{$key}";
      }
    }
  }

  print "Constraints: ";
  my %uniq = $package->unique_constraints;
  map { print "\t$_ => ", join ", " => @{ $uniq{$_} } } keys %uniq;
}


1;
__END__

=head1 NAME

DBIx::Class::EasyConf::YAML - DBIx::Class Component for text based
schema configuration

=head1 SYNOPSIS

  package MyApp::Schema::Result::SomeTable;
  use parent qw[ DBIx::Class::Core ];
  __PACKAGE__->load_components(qw[ EasyConf::YAML ]);
  our $DDL ||= __PACKAGE__->configure();

  1;

  __DATA__
  --->
  =head1 NAME
  
  MyAPP::Schema::Result::SomeTable - Random Schema File
  
  =head1 DESCRIPTION
  ---
    table: some_table
    primary_key: id
    columns:
      id:
        type: int
        nullable: 0
        is_auto_increment: 1
      name:
        type: VARCHAR
        size: 16
        is_nullable: 0
      description:
        type: VARCHAR
        size: 128
        is_nullable: 1
    relationships:
      - other_relation:
          - belongs_to
          - MyApp::Schema::Result::SomeOtherTable
          - id
    unique:
      name_uniq: id
      desc_uniq: 
        - name
        - description
  # EndOfYAML


=head1 DESCRIPTION

Generates a DBIx::Class::ResultSource from a YAML description.  If the
YAML is presented as shown in the SYNOPSIS the ResultSource class will
be self POD documenting.  If the class is executed with
'configuration' in @ARGV, a summary of the ResultSource is printed to
standard out.

=head1 GOTCHA

Note that relationships sometimes need to be created in a particular
order (such is the case when defining many_to_many relationships).
Given that, the relationships key takes an array of hashes; watch the
indentation carefully (it's correct above).  It'd be possible to
optionally allow a hash here, but I think that might lead to hard to
find errors.  Drop me a line if you have a strong opinion.

=head1 RATIONALE

The "self-documenting" bit mentioned above.  Also, there's a boatload
of punctuation and quoting that is required to do this the usual way;
it's less error prone, in my opinion, to use YAML as good text editors
will do the right thing by it.

=head1 AUTHOR

kevin montuori <montuori@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kevin Montuori & mconsultancy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
