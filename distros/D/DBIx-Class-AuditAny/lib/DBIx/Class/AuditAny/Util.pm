package DBIx::Class::AuditAny::Util;

# ABSTRACT: Util functions for DBIx::Class::AuditAny

=head1 NAME

DBIx::Class::AuditAny::Util - Util functions for DBIx::Class::AuditAny

=head1 DESCRIPTION

This package contains misc util funcs used in the L<DBIx::Class::AuditAny> codebase

=head1 FUNCTIONS

=cut

#*CORE::GLOBAL::die = sub { require Carp; Carp::confess };

require Exporter;
use Term::ANSIColor qw(:constants);
use Data::Dumper;
require Module::Runtime;
use Try::Tiny;

our @ISA = qw(Exporter);
our @EXPORT = qw(
 resolve_localclass package_exists try catch uniq
 get_raw_source_rows
 get_raw_source_related_rows
);

# debug util funcs
push @EXPORT, qw(scream scream_color);

=head2 scream

Prints the supplied object/structure using Dumper

=cut
sub scream {
	local $_ = caller_data(3);
	scream_color(YELLOW . BOLD,@_);
}

=head2 scream_color

Prints the supplied object/structure using Dumper. The first arg can be a color code.

=cut
sub scream_color {
	#return unless ($ENV{DEBUG}); ##<---- new: disabled without 'DEBUG'
	my $color = shift;
	local $_ = caller_data(3) unless (
		$_ eq 'no_caller_data' or (
			ref($_) eq 'ARRAY' and
			scalar(@$_) == 3 and
			ref($_->[0]) eq 'HASH' and 
			defined $_->[0]->{package}
		)
	);
	
	my $data = $_[0];
	$data = \@_ if (scalar(@_) > 1);
	$data = Dumper($data) if (ref $data);
	$data = '  ' . UNDERLINE . 'undef' unless (defined $data);

	my $pre = '';
	$pre = BOLD . ($_->[2]->{subroutine} ? $_->[2]->{subroutine} . '  ' : '') .
		'[line ' . $_->[1]->{line} . ']: ' . CLEAR . "\n" unless ($_ eq 'no_caller_data');
	
	print STDERR $pre . $color . $data . CLEAR . "\n";
}

=head2 caller_data

Returns an arrayref of hashes containing standard 'caller' function data
with named properties

=cut
sub caller_data {
	my $depth = shift || 1;
	
	my @list = ();
	for(my $i = 0; $i < $depth; $i++) {
		my $h = {};
		($h->{package}, $h->{filename}, $h->{line}, $h->{subroutine}, $h->{hasargs},
			$h->{wantarray}, $h->{evaltext}, $h->{is_require}, $h->{hints}, $h->{bitmask}) = caller($i);
		push @list,$h if($h->{package});
	}
	
	return \@list;
}

=head2 package_exists

Check if the package exists

=cut
#unmht://www.develop-help.com.unmht/http.5/perl/examples/havepack.mhtml/
sub package_exists(@) {
	my ($pack) = @_;
	my $base ||= \%::;
	while ($pack =~ /(.*?)::(.*)/m	&& exists($base->{$1."::"})) {
		$base = *{$base->{$1."::"}}{HASH};
		$pack = $2;
	}
	return exists $base->{$pack."::"};
}

=head2 resolve_localclass

Loads the class name, relative to DBIx::Class::AuditAny:: or absolute when
prefixed with '+'

=cut
sub resolve_localclass($) { 
	my $class = shift;
	$class = $class =~ /^\+(.*)$/ ? $1 : "DBIx::Class::AuditAny::$class";
	Module::Runtime::require_module($class);
	return $class;
}


=head2 uniq

Returns a list with duplicates removed. If passed a single arrayref, duplicates are
removed from the arrayref in place, and the new list (contents) are returned.

=cut
sub uniq {
	my %seen = ();
	return grep { !$seen{$_}++ } @_ unless (@_ == 1 and ref($_[0]) eq 'ARRAY');
	return () unless (@{$_[0]} > 0);
	# we add the first element to the end of the arg list to prevetn deep recursion in the
	# case of nested single element arrayrefs
	@{$_[0]} = uniq(@{$_[0]},$_[0]->[0]);
	return @{$_[0]};
}


=head2 get_raw_source_rows

logic adapted from L<DBIx::Class::Storage#insert>

=cut
sub get_raw_source_rows {
	my $Source = shift;
	my $cond = shift;

	my @rows = ();
	my @cols = $Source->columns;
	
	my $cur = DBIx::Class::ResultSet->new($Source, {
		where => $cond,
		select => \@cols,
	})->cursor;
	
	while(my @data = $cur->next) {
		my %returned_cols = ();
		@returned_cols{@cols} = @data;
		push @rows, \%returned_cols;
	}

	return \@rows;
}


=head2 get_raw_source_related_rows

=cut
sub get_raw_source_related_rows {
	my $Source = shift;
	my $rel = shift;
	my $cond = shift;
	
	my $RelSource = $Source->related_source($rel) 
		or die "Bad relationship name '$rel'";
	
	my $Rs = DBIx::Class::ResultSet->new($Source, {
		where => $cond
	})->as_subselect_rs; #<-- need to wrap in subselect to prevent possible ambiguous col errs
	
	my @rows = ();
	my @cols = $RelSource->columns;
	
	my $cur = $Rs->search_related_rs($rel,undef,{
		select => \@cols,
	})->cursor;
	
	while(my @data = $cur->next) {
		my %returned_cols = ();
		@returned_cols{@cols} = @data;
		push @rows, \%returned_cols;
	}

	return \@rows;
}


1;

__END__

=head1 SEE ALSO

=over

=item *

L<DBIx::Class::AuditAny>

=item *

L<DBIx::Class>

=back

=head1 SUPPORT
 
IRC:
 
    Join #rapidapp on irc.perl.org.

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012-2015 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
