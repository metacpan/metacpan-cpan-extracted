package App::Presto::Stash;
our $AUTHORITY = 'cpan:MPERRY';
$App::Presto::Stash::VERSION = '0.010';
# ABSTRACT: Presto stash

use Moo;

{
	my $stash = {};
	sub get {
		my $self = shift;
		my $key  = shift;
		return exists $stash->{$key} ? $stash->{$key} : undef;
	}
	sub set {
		my $self = shift;
		my($k,$v) = @_;
		return $stash->{$k} = $v;
	}
	sub unset {
		my $self = shift;
		my $k = shift;
		return delete $stash->{$k};
	}

	sub stash {
		my $self = shift;
		if(@_ == 2){
			return $self->set(@_);
		} elsif(@_ == 1){
			return $self->get(@_);
		} else {
			return $stash;
		}
	}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Presto::Stash - Presto stash

=head1 VERSION

version 0.010

=head1 AUTHORS

=over 4

=item *

Brian Phillips <bphillips@cpan.org>

=item *

Matt Perry <matt@mattperry.com> (current maintainer)

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Brian Phillips and Shutterstock Images (http://shutterstock.com).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
