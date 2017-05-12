package Class::DBI::SQL::Transformer::Quotify;

use warnings;
use strict;

use base qw/Class::DBI::SQL::Transformer/;
our $VERSION = '0.02';

sub _expand_table {
	my $self = shift;
	my $s = shift;
	my ($class, $alias) = split /=/, defined($s)?$s:'', 2;
	my $caller = $self->{_caller};
	my $table = $class ? $class->table : $caller->table;
	$self->{cmap}{ $alias || $table } = $class || ref $caller || $caller;
	($alias ||= "") &&= " ".$caller->db_Main->quote_identifier($alias);
	return $caller->db_Main->quote_identifier($table) . $alias;
}

sub _expand_join {
	my $self  = shift;
	my $joins = shift;
	my @table = split /\s+/, $joins;

	my $caller = $self->{_caller};
	my %tojoin = map { $table[$_] => $table[ $_ + 1 ] } 0 .. $#table - 1;
	my @sql;
	while (my ($t1, $t2) = each %tojoin) {
		my ($c1, $c2) = map $self->{cmap}{$_}
			|| $caller->_croak("Don't understand table '$_' in JOIN"), ($t1, $t2);

		my $join_col = sub {
			my ($c1, $c2) = @_;
			my $meta = $c1->meta_info('has_a');
			my ($col) = grep $meta->{$_}->foreign_class eq $c2, keys %$meta;
			$col;
		};

		my $col = $join_col->($c1 => $c2) || do {
			($c1, $c2) = ($c2, $c1);
			($t1, $t2) = ($t2, $t1);
			$join_col->($c1 => $c2);
		};

		$caller->_croak("Don't know how to join $c1 to $c2") unless $col;
		push @sql, sprintf " %s = %s ",
			$caller->db_Main->quote_identifier($t1, $col),
			$caller->db_Main->quote_identifier($t2, $c2->primary_column);
	}
	return join " AND ", @sql;
}

sub _backtickify_arg {
    my $self = shift;
    my $caller = $self->{_caller};
    my $char = $caller->db_Main->get_info(29) || q{"}; # SQL_IDENTIFIER_QUOTE_CHAR
    return $_[0] if $_[0] =~ /^$char[^$char]*$char$/; # return if already quoted
    my @cols = $_[1]
        ? @{$_[1]} # use what's given us (in the recursion cases)
        # or (the initial case) use all cols, sorted longest to shortest
        # This is necessary so that 'foo bar' gets processed before 'foo',
        #  so that if you have "foo bar" it doesn't become "`foo` bar"
        : sort { length $b <=> length $a } map { "$_" } $caller->all_columns
    ;
    return $_[0] unless @cols;
    my $c = shift @cols; # process first col
    my $quoted = $caller->db_Main->quote_identifier($c);
    $_[0] =~ s/\b(?<!$char)$c(?!$char)\b/$quoted/g; # quote it where it's currently unquoted
    # Recurse on all the pieces w/the remaining columns to process.
    # Note the the quoted ones will just return right way.
    my @s = map { $self->_backtickify_arg($_,\@cols) } split /($quoted)/, $_[0];
    $_[0] = join '', @s;
    return $_[0];
}

sub _do_transformation {
	my $me     = shift;
	my $sql    = $me->{_sql};
	my @args   = @{ $me->{_args} };
	my $caller = $me->{_caller};

	# Each entry in @args is a SQL fragment. This will bugger with fragments that
	# contain strings that match column names but are not supposed to be column names.
	$me->_backtickify_arg($_) for @args;

	$sql =~ s/__TABLE(?:\((.+?)\))?__/$me->_expand_table($1)/eg;
	$sql =~ s/__JOIN\((.+?)\)__/$me->_expand_join($1)/eg;
	$sql =~ s/__ESSENTIAL__/join ", ", map { $caller->db_Main->quote_identifier($_) } $caller->_essential/eg;
	$sql =~
		s/__ESSENTIAL\((.+?)\)__/join ", ", map $caller->db_Main->quote_identifier($1,$_), $caller->_essential/eg;
	if ($sql =~ /__IDENTIFIER__/) {
		my $key_sql = join " AND ", map $caller->db_Main->quote_identifier($_).'=?', $caller->primary_columns;
		$sql =~ s/__IDENTIFIER__/$key_sql/g;
	}

	$me->{_transformed_sql}  = $sql;
	$me->{_transformed_args} = [@args];
	$me->{_transformed}      = 1;
	return 1;
}

1;

=pod

=head1 NAME

Class::DBI::SQL::Transformer::Quotify - Quote column and table names in Class::DBI-generated SQL

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

  package Foo;
  use base qw/Class::DBI/;
  __PACKAGE__->connection('DBI:Mock:', '', '');
  __PACKAGE__->sql_transformer_class('Class::DBI::SQL::Transformer::Quotify');
  __PACKAGE__->table('table name');
  __PACKAGE__->columns( Essential => 'my id', 'my name' );
  package main;
  my $row = Foo->retrieve( 3 );

=head1 DESCRIPTION

This is an attempt to solve the problem of spaces and/or reserved words in table and/or column names.  Normally, Class::DBI does not quote these, so it results in sql such as the following (which clearly will error out):

  SELECT my id, my name
  FROM table name
  WHERE my id = ?

This is implemented by subclassing L<Class::DBI::SQL::Transformer> and notifying L<Class::DBI> via its C<sql_transformer_class()> attribute.  Note that some of the methods are completely replaced.

=head1 BACKGROUND/EVOLUTION

I first came upon L<Class::DBI::Plugin::Backtickify>, which worked great, except the naming of the schema was so bad I hit an edge case that needed fixing first, which got me looking under the hood: L<http://rt.cpan.org/Public/Bug/Display.html?id=32133>

Since that version of Class::DBI::Plugin::Backtickify, Class::DBI (as of v3.0.8) had refactored the Class::DBI::SQL::Transformer class and introduced the Class::DBIsql_transformer_class() method. Which is why this module has the namespace it does instead of Class::DBI::Plugin:: and why I didn't just submit a patch for Backtickify.

Drawing heavily from Backtickify, i generalized it to this module by using L<DBI>::quote_identifier() instead of a hardcoded backtick.

This potentially is (at least a partial) solution (or workaround) for Class::DBI RT ticket 7715 I<Class::DBI does not correctly quote column names (Pg, maybe others)>: L<http://rt.cpan.org/Ticket/Display.html?id=7715>

In the course of investigation, also reported this Class::DBI issue, which this module also resolves: L<http://rt.cpan.org/Ticket/Display.html?id=32115>

=head1 AUTHOR

David Westbrook (CPAN: davidrw), C<< <dwestbrook at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-class-dbi-sql-transformer-quotify at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-DBI-SQL-Transformer-Quotify>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Class::DBI::SQL::Transformer::Quotify

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Class-DBI-SQL-Transformer-Quotify>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Class-DBI-SQL-Transformer-Quotify>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Class-DBI-SQL-Transformer-Quotify>

=item * Search CPAN

L<http://search.cpan.org/dist/Class-DBI-SQL-Transformer-Quotify>

=back

=head1 SEE ALSO

L<Class::DBI>, L<Class::DBI::SQL::Transformer>, L<DBI>, L<Class::DBI::Plugin::Backtickify>

=head1 ACKNOWLEDGEMENTS

David Baird for the groundwork of Class::DBI::Plugin::Backtickify

=head1 COPYRIGHT & LICENSE

Copyright 2008 David Westbrook, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

