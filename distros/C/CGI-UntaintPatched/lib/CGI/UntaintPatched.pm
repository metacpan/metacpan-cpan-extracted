package CGI::UntaintPatched;

use strict;
use warnings;
our $VERSION = '0.01';
use base 'CGI::Untaint';
use Carp;

=head1 NAME 

CGI::UntaintPatched - CGI::Untaint but it returns a "No input for '$field'\n" error for fields left blank on a  web form. 

=head1 SYNOPSIS

  if ($h->error =~ /No input for/) {
    # caught empty input now handle it
  }

  See  CGI::Untaint. 

=head1 DESCRIPTION

Instead of passing the empty string to the untaint handlers, which 
do not like it or updating them all, it seemed better
to have CGI::Untaint catch the field left blank exception. So it does.  
This should be ok I see no point untainting an empty string. But i am open to suggestions and other patches. 

=cut


# offending method ripped from base and patched
sub _do_extract {
	my $self = shift;

	my %param = @_;

	#----------------------------------------------------------------------
	# Make sure we have a valid data handler
	#----------------------------------------------------------------------
	my @as = grep /^-as_/, keys %param;
	croak "No data handler type specified"        unless @as;
	croak "Multiple data handler types specified" unless @as == 1;

	my $field      = delete $param{ $as[0] };
	my $skip_valid = $as[0] =~ s/^(-as_)like_/$1/;
	my $module     = $self->_load_module($as[0]);

	#----------------------------------------------------------------------
	# Do we have a sensible value? Check the default untaint for this
	# type of variable, unless one is passed.
	#----------------------------------------------------------------------

	################# PETER'S PATCH #####################
	my $raw = $self->{__data}->{$field} ;
	die "No parameter for '$field'\n" if !defined($raw);
	die "No input for '$field'\n" if $raw eq '';
    #####################################################


	# 'False' values get returned as themselves with no warnings.
	# return $self->{__lastval} unless $self->{__lastval};

	my $handler = $module->_new($self, $raw);

	my $clean = eval { $handler->_untaint };
	if ($@) {    # Give sensible death message
		die "$field ($raw) does not untaint with default pattern\n"
			if $@ =~ /^Died at/;
		die $@;
	}

	#----------------------------------------------------------------------
	# Are we doing a validation check?
	#----------------------------------------------------------------------
	unless ($skip_valid) {
		if (my $ref = $handler->can('is_valid')) {
			die "$field ($raw) does not pass the is_valid() check\n"
				unless $handler->$ref();
		}
	}

	return $handler->untainted;
}

=head1 BUGS

None known yet.

=head1 SEE ALSO

L<CGI>. L<perlsec>. L<CGI::Untaint>.

=head1 AUTHOR

Peter Speltz but most code was ripped from CGI::Untaint.

=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  peterspeltz@cafes.net or bug-CGI-UntaintPatched@rt.cpan.org

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 Peter Speltz.  All rights reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
