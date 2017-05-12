package Data::FormValidator::ErrMsgs::JavaScript;
use base 'Exporter';
use Carp;
use strict;
use vars (qw/@EXPORT_OK/);

@EXPORT_OK = (qw/&dfv_js_error_msgs/);

use warnings;
use strict;

=head1 NAME

Data::FormValidator::ErrMsgs::JavaScript - Let JavaScript handle DFV error presentation.

=cut

our $VERSION = '1.00';

=head1 SYNOPSIS

 use Data::FormValidator::ErrMsgs::JavaScript (qw/&dfv_js_error_msgs/);

 # In a DFV profile:
 msgs => \&dfv_js_error_msgs,

Now your error messages will come out like this:

 <script type="text/javascript">dfv_error_msg('field_name');</script>

=head1 FUNCTIONS

=head2 dfv_js_error_msgs

See L<SYNOPSIS> above for syntax. 

It's up to you define the C<dfv_error_msg> function in JavaScript to do
something interesting. 

This function respects the following C<msgs> configuration directives,
which are documented more in L<Data::FormValidator>:

 prefix
 any_errors

Of course, these can't be set directly in the profile anymore because 
the callback is there. They can still be set through the defaults system  
documented in L<Data::FormValidator>.

=head1 LIMITATIONS

More detail could be passed through to the JavaScript function about the failure.
This may change in the future, perhaps in an incompatible way.

It is not currently possible to use a format string other than the one
provided.

Workarounds included sending a patch or using this routine as the basis for your own. 

That workaround might look like this: 

 msgs => dfv_js_error_msgs({
    format => 'foo: %';
 });

A closure could then be created which passing in the arguments
you want. 

=cut

sub dfv_js_error_msgs {
	my $self = shift;
	my $controls = shift || {};
	if (defined $controls and ref $controls ne 'HASH') {
		die "$0: parameter passed to msgs must be a hash ref";
	}


	# Allow msgs to be called more than one to accumulate error messages
	$self->{msgs} ||= {};
	$self->{msgs} = { %{ $self->{msgs} }, %$controls };

	my %profile = (
		prefix	=> '',
		%{ $self->{msgs} },
        # XXX Should maybe have some javascript quoting on the field name
		format  => qq{<script type="text/javascript">dfv_error_msg('%s');</script>},
	);


	my %msgs = ();

	# Add invalid messages to hash
		#  look at all the constraints, look up their messages (or provide a default)
		#  add field + formatted constraint message to hash
	if ($self->has_invalid) {
		my $invalid = $self->invalid;
		for my $i ( keys %$invalid ) {
			$msgs{$i} = sprintf $profile{format},$i;
		}
	}

	# Add missing messages, if any
	if ($self->has_missing) {
		my $missing = $self->missing;
		for my $m (@$missing) {
			$msgs{$m} = sprintf $profile{format},$m;
		}
	}

	my $msgs_ref = Data::FormValidator::Results::prefix_hash($profile{prefix},\%msgs);

    if (! $self->success) {
    	$msgs_ref->{ $profile{any_errors} } = 1 if defined $profile{any_errors};
    }

	return $msgs_ref;

}

=head1 FUTURE

If you like this extension to Data::FormValidator, give me some feedback
on the Data::FormValidator list and we'll work out a stable interface.

L<http://lists.sourceforge.net/lists/listinfo/cascade-dataform>

=head1 AUTHOR

Mark Stosberg, C<< <mark at summersault.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-formvalidator-errmsgs-javascript at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-FormValidator-ErrMsgs-JavaScript>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO


L<Data::FormValidator>
L<http://search.cpan.org/dist/Data-FormValidator-ErrMsgs-JavaScript>

=head1 COPYRIGHT & LICENSE

Copyright 2005 Mark Stosberg, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Data::FormValidator::ErrMsgs::JavaScript
