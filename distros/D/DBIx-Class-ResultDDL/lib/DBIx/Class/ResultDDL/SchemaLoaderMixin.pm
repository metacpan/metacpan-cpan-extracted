package DBIx::Class::ResultDDL::SchemaLoaderMixin;
use strict;
use warnings;
use List::Util 'max', 'all';
use DBIx::Class::ResultDDL;
use Carp;
sub deparse; #local utilities to be cleaned from the namespace
sub deparse_hashkey;
use namespace::clean;

# ABSTRACT: Modify Schema Loader to generate ResultDDL notation
our $VERSION = '2.04'; # VERSION


#sub _write_classfile {
#   my ($self, $class, $text, $is_schema)= @_;
#   main::explain($class);
#   main::explain($text);
#   main::explain($self->{_dump_storage}{$class});
#   $self->next::method($class, $text, $is_schema);
#}

sub generate_resultddl_import_line {
	qq|use DBIx::Class::ResultDDL qw/ -V2 /;\n|
}


sub generate_column_info_sugar {
	my ($self, $class, $col_name, $orig_col_info)= @_;

	my $checkpkg= $self->_get_class_check_namespace($class);
	my $class_settings= DBIx::Class::ResultDDL::_settings_for_package($checkpkg);

	my %col_info= %$orig_col_info;
	my $stmt= _get_data_type_sugar(\%col_info, $class_settings);
	$stmt .= ' null'
		if delete $col_info{is_nullable};
	$stmt .= ' default('.deparse(delete $col_info{default_value}).'),'
		if exists $col_info{default_value};
	# add sugar for inflate_json if the serializer class is JSON, but not if the package feature inflate_json
	# was enabled and the column type is flagged as json.
	$stmt .= ' inflate_json' if 'JSON' eq ($col_info{serializer_class}||'');
	$stmt .= ' fk' if delete $col_info{is_foreign_key};
	
	# Test the syntax for equality to the original
	my $out;
	eval "package $checkpkg; \$out= DBIx::Class::ResultDDL::expand_col_options(\$checkpkg, $stmt);";
	defined $out or croak "Error verifying generated ResultDDL for $class $col_name: $@";
	
	if ($out->{'extra.unsigned'}) {
		$out->{extra}{unsigned}= delete $out->{'extra.unsigned'};
	}

	# Ignore the problem where 'integer' generates a default size for mysql that wasn't
	# in the Schema Loader spec.  TODO: add an option to skip generating this.
	delete $out->{size} if $out->{size} && !$orig_col_info->{size};

	# Data::Dumper gets confused and thinks sizes need quoted
	if (defined $orig_col_info->{size} && $orig_col_info->{size} =~ /^[0-9]+$/) {
		$orig_col_info->{size}= 0 + $orig_col_info->{size};
	}

	if (deparse({ %col_info, %$out }) eq deparse({ %$orig_col_info })) {
		# Any field in %$out removes the need to have it in $col_info.
		# This happens with implied options like serializer_class => 'JSON'
		for (keys %col_info) {
			delete $col_info{$_} if exists $out->{$_};
		}
		# remove trailing comma
		$stmt =~ s/,\s*$//;
		# dump the rest, and done.
		$stmt .= ', '.&_deparse_hashkey.' => '.deparse($col_info{$_})
			for sort keys %col_info;
	}
	else {
		warn "Unable to use ResultDDL sugar '$stmt'\n  "
			.deparse({ %col_info, %$out })." ne ".deparse($orig_col_info)."\n";
		$stmt= join(', ',
			map &_deparse_hashkey.' => '.deparse($orig_col_info->{$_}),
			sort keys %$orig_col_info
		);
	}
	return $stmt;
}


sub generate_relationship_sugar {
	my ($self, $class, $method, $relname, $foreignclass, $colmap, $options)= @_;
	#use DDP; &p(['before', @_[1..$#_]]);
	my $expr= '';
	# The $foreignclass $colmap arguments can be combined into a simpler
	#  hashref of { local_col => 'ForeignClass.colname' } as long as some expectations hold:
	my ($parent_ns)= ($class =~ /^(.*?::)([^:]+)$/);
	if (defined $parent_ns and !ref $foreignclass and (!ref $colmap || ref $colmap eq 'HASH')) {
		# Can we use a shortened class name for the foreign table?
		if ($foreignclass =~ /^(.*?::)([^:]+)$/ and $1 eq $parent_ns) {
			$foreignclass= $2;
		}
		my %newmap= ref $colmap eq 'HASH'? (%$colmap) : ($colmap => $colmap);
		# Just in case SchemaLoader prefixed them with 'self.' or 'foreign.'...
		s/^self[.]// for values %newmap;
		%newmap= reverse %newmap;
		s/^foreign[.]// for values %newmap;
		# Apply the foreign class name to the first column in the map
		my ($first_key)= sort keys %newmap;
		$newmap{$first_key}= $foreignclass . '.' . $newmap{$first_key};
		$expr .= deparse(\%newmap);
	} else {
		$expr .= deparse($foreignclass, $colmap);
	}
	if ($options && keys %$options) {
		$expr .= ', ' . $self->generate_relationship_attr_sugar($options);
	}

	# Test the syntax for equality to the original
	my $checkpkg= $self->_get_class_check_namespace($class);
	my @out;
	eval "package $checkpkg; \@out= DBIx::Class::ResultDDL::expand_relationship_params(\$class, \$method, \$relname, $expr);";
	@out or croak "Error verifying generated ResultDDL for $class $method $relname: $@";

	#use DDP; &p(['after', @out, $expr]);

	return $method . ' ' . deparse_hashkey($relname) . ' => ' . $expr . ';';
}


sub generate_relationship_attr_sugar {
	my ($self, $orig_options)= @_;
	my %options= %$orig_options;
	my @expr;
	if (defined $options{on_update} && defined $options{on_delete}
		&& $options{on_update} eq $options{on_delete}
	) {
		my $val= delete $options{on_update};
		delete $options{on_delete};
		push @expr, $val eq 'CASCADE'? 'ddl_cascade'
			: $val eq 'RESTRICT'? 'ddl_cascade(0)'
			: 'ddl_cascade('.deparse($val).')'
	}
	if (defined $options{cascade_copy} && defined $options{cascade_delete}
		&& $options{cascade_copy} eq $options{cascade_delete}
	) {
		my $val= delete $options{cascade_copy};
		delete $options{cascade_delete};
		push @expr, $val eq '1'? 'dbic_cascade'
			: 'dbic_cascade('.deparse($val).')'
	}
	push @expr, substr(deparse(\%options),2,-2) if keys %options;
	return join ', ', @expr
}

my %rel_methods= map +($_ => 1), qw( belongs_to might_have has_one has_many );
sub _dbic_stmt {
	my ($self, $class, $method)= splice(@_, 0, 3);
	# The first time we generate anything for each class, inject the 'use' line.
	$self->_raw_stmt($class, $self->generate_resultddl_import_line($class))
		unless $self->{_ResultDDL_SchemaLoader}{$class}{use_line}++;
	if ($method eq 'table') {
		$self->_raw_stmt($class, q|table |.deparse(@_).';');
	}
	elsif ($method eq 'add_columns') {
		my @col_defs;
		while (@_) {
			my ($col_name, $col_info)= splice(@_, 0, 2);
			push @col_defs, [
				deparse_hashkey($col_name),
				$self->generate_column_info_sugar($class, $col_name, $col_info)
			];
		}
		# align the definitions, but round up to help avoid unnecessary diffs
		# when new columns get added.
		my $widest= max map length($_->[0]), @col_defs;
		$widest= ($widest + 3) & ~3;
		$self->_raw_stmt($class, sprintf("col %-*s => %s;", $widest, @$_))
			for @col_defs;
	}
	elsif ($method eq 'set_primary_key') {
		$self->_raw_stmt($class, q|primary_key |.deparse(@_).";");
	}
	elsif ($rel_methods{$method} && @_ == 4) {
		# Add a linebreak before the relationships, for readability.
		$self->_raw_stmt($class, "\n")
			unless $self->{_ResultDDL_SchemaLoader}{$class}{relation_linebreak}++;
		$self->_raw_stmt($class, $self->generate_relationship_sugar($class, $method, @_));
	}
	else {
		$self->next::method($class, $method, @_);
	}
	return;
}

my %data_type_sugar= (
	(map {
		my $type= $_;
		$type => sub { my ($col_info)= @_;
			if ($col_info->{size} && $col_info->{size} =~ /^[0-9]+$/) {
				return "$type(".delete($col_info->{size})."),";
			} elsif ($col_info->{size} && ref $col_info->{size} eq 'ARRAY'
				&& ($#{$col_info->{size}} == 0 || $#{$col_info->{size}} == 1)
				&& (all { /^[0-9]+$/ } @{$col_info->{size}})
			) {
				return "$type(".join(',', @{delete($col_info->{size})})."),";
			} else {
				return $type;
			}
		}
	} qw( integer float real numeric decimal varchar nvarchar char nchar binary varbinary )),
	(map {
		my $type= $_;
		$type => sub { my ($col_info, $class_settings)= @_;
			# include timezone in type sugar, if known.
			if ($col_info->{timezone} && !ref $col_info->{timezone}) {
				return "$type(".deparse(delete $col_info->{timezone})."),";
			} else {
				return $type;
			}
		}
	} qw( datetime timestamp )),
	(map {
		my $type= $_;
		$type => sub { my ($col_info, $class_settings)= @_;
			# Remove serializer_class => 'JSON' if inflate_json is enabled package-wide
			delete $col_info->{serializer_class}
				if $class_settings->{inflate_json} && ($col_info->{serializer_class}||'') eq 'JSON';
			return $type;
		}
	} qw( json jsonb )),
);

sub _get_data_type_sugar {
	my ($col_info, $class_settings)= @_;

	my $t= delete $col_info->{data_type}
		or return ();

	my $pl= ($data_type_sugar{$t} //= do {
		my $sugar= DBIx::Class::ResultDDL->can($t);
		my @out= $sugar? $sugar->() : ();
		@out >= 2 && $out[0] eq 'data_type' && $out[1] eq $t? sub { $t }
		: sub { 'data_type => '.deparse($t).',' }
	})->($col_info, $class_settings);

	if ($col_info->{extra} && $col_info->{extra}{unsigned}) {
		$pl =~ s/,?$/,/ unless $pl =~ /\w$/;
		$pl .= ' unsigned';
		if (1 == keys %{ $col_info->{extra} }) {
			delete $col_info->{extra};
		} else {
			$col_info->{extra}= { %{ $col_info->{extra} } };
			delete $col_info->{extra}{unsigned};
		}
	}
	return $pl;
}

sub _deparse_scalar {
	return 'undef' unless defined;
	return $_ if /^(0|[1-9][0-9]*)$/;
	my $x= $_;
	$x =~ s/\\/\\\\/g;
	$x =~ s/'/\\'/g;
	return "'$x'";
}
sub _deparse_scalarref {
	"\\" . (map &_deparse_scalar, $$_)[0]
}
sub deparse_hashkey { local $_= $_[0]; &_deparse_hashkey }
sub _deparse_hashkey {
	# TODO: complete support for perl's left-hand of => operator parsing rule
	/^[A-Za-z_][A-Za-z0-9_]*$/? $_ : &_deparse_scalar;
}
sub _deparse_hashref {
	my $h= $_;
	return '{ '.join(', ', map +(&_deparse_hashkey.' => '.deparse($h->{$_})), sort keys %$h).' }'
}
sub _deparse_arrayref {
	return '[ '.join(', ', map &_deparse, @$_).' ]'
}
sub _deparse {
	!ref()? &_deparse_scalar
	: ref() eq 'SCALAR'? &_deparse_scalarref
	: ref() eq 'ARRAY'? &_deparse_arrayref
	: ref() eq 'HASH'? &_deparse_hashref
	: do {
		require Data::Dumper;
		Data::Dumper->new([$_])->Terse(1)->Quotekeys(0)->Sortkeys(1)->Indent(0)->Dump;
	}
}
sub deparse {
	join(', ', map &_deparse, @_);
}

our %per_class_check_namespace;
sub _get_class_check_namespace {
	my ($self, $class)= @_;
	return ($per_class_check_namespace{$class} ||= do {
		my $use_line= $self->generate_resultddl_import_line($class);
		local $DBIx::Class::ResultDDL::DISABLE_AUTOCLEAN= 1;
		my $pkg= 'DBIx::Class::ResultDDL_check' . scalar keys %per_class_check_namespace;
		my $perl= "package $pkg; $use_line 1";
		eval $perl or croak "Error setting up package to verify generated ResultDDL: $@\nFor code:\n$perl";
		$pkg;
	});
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::ResultDDL::SchemaLoaderMixin - Modify Schema Loader to generate ResultDDL notation

=head1 SYNOPSIS

  package MyLoader;
  use parent
    'DBIx::Class::ResultDDL::SchemaLoaderMixin', # mixin first
    'DBIx::Class::Schema::Loader::DBI::mysql';
  
  1;

You can then use it with the loader_class option:

  use DBIx::Class::Schema::Loader qw/ make_schema_at /;
  my %options= ...;
  my @conn_info= (
    'dbi:mysql:my_database',
    $user, $pass,
    { loader_class => 'MyLoader' }
  );
  make_schema_at($package, \%options, \@conn_info);

You can also use this custom loader class to inject some DBIC settings
that SchemaLoader doesn't know about:

  package MyLoader;
  use parent
    'DBIx::Class::ResultDDL::SchemaLoaderMixin', # mixin first
    'DBIx::Class::Schema::Loader::DBI::mysql';
  
  sub generate_resultddl_import_line {
    return "use DBIx::Class::ResultDDL qw/ -V2 -inflate_datetime -inflate_json /;\n"
  }
  
  sub generate_column_info_sugar {
    my ($self, $class, $colname, $colinfo)= @_;
    if ($colname eq 'jsoncol' || $colname eq 'textcol') {
      $colinfo->{serializer_class}= 'JSON'
    }
    $self->next::method($class, $colname, $colinfo);
  }
  
  1;

=head1 DESCRIPTION

This module overrides behavior of L<DBIx::Class::Schema::Loader::Base> to
generate Result files that use L<DBIx::Class::ResultDDL> notation.
C<< ::Schema::Loader::Base >> is the base class for all of the actual loader
classes, which are invoked by C<< ::Schema::Loader >> (but do not share a
class hierarchy with ::Schema::Loader itself).

This is essentially a Role, but Schema Loader isn't based on Moo(se) and this
ResultDDL distribution does not yet depend on Moo(se), so it just uses plain
perl multiple inheritance.  Inherit from the mixin first so that its methods
take priority.  (it does override private methods of schema loader, so without
the Role mechanism to verify it, there is a chance parts just stop working if
Schema Loader changes its internals.  But it's a development-time tool, and
you'll see the output change, and the output will still be valid)

=head1 METHODS

The following methods are public so that you can override them:

=head2 generate_resultddl_import_line

  $perl_stmt= $loader->generate_resultddl_import_line($class);

This should return a string like C<< "use DBIx::Class::ResultDDL qw/ -V2 /;\n" >>.
Don't forget the trailing semicolon.

=head2 generate_column_info_sugar

  $perl_stmt= $loader->generate_column_info_sugar($class, $col_name, $col_info);

This runs for each column being generated on the result class.
It takes the name of the result class, the name of the column, and the hashref
of DBIC %col_info that ::Schema::Loader created.  It then returns the string of
C<$generated_perl> to appear in C<< "col $col_name => $generated_perl;\n" >>.

If you override this, you can use the class and column name to decide if you
want to alter the C<$col_info> before SchemaLoaderMixin works its magic.
For instance, you might supply datetimes or serializer classes that
::Schema::Loader wouldn't know you wanted.

You could also munge the returned string, or just create a string if your own.

=head2 generate_relationship_sugar

  $perl_stmt= $loader->generate_relationship_sugar(
    $class, $rel_type, %rel_name, $foreign_class, $col_map, $attrs
  );

This method takes the typical arguments of one of the relationship-defining
methods of DBIC and returns the equivalent sugar-ized form.  (namely, it
attempts to convert the $foreign_class and $col_map into the simplified
version used by ResultDDL, and replace $attrs with sugar functions where
available.)

=head2 generate_relationship_attr_sugar

  $perl_expr= $loader->generate_relationship_attr_sugar(\%attrs);

This is a piece of L</generate_relationship_sugar> that deals only with the
replacement of relationship attributes with equivalent sugar functions.

=head1 THANKS

Thanks to L<Clippard Instrument Laboratory Inc.|http://www.clippard.com/>
for supporting open source, including portions of this module.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 VERSION

version 2.04

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad, IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
