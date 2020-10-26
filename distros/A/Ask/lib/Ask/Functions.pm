use 5.008008;
use strict;
use warnings;

{
	package Ask::Functions;
	
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.012';
	
	use Exporter::Shiny qw(
		info warning error entry question file_selection
		single_choice multiple_choice
	);
	
	sub _exporter_validate_opts {
		my ( $class, $opts ) = @_;
		
		$opts->{'backend'} ||= do { require Ask; 'Ask'->detect };
		$opts->{'backend'}->is_usable or die;
	}
	
	for my $f ( our @EXPORT_OK ) {
		no strict 'refs';
		*{"_generate_$f"} = sub {
			my ( $class, $name, $args, $opts ) = @_;
			my $backend = $opts->{'backend'};
			return sub { $backend->$f( @_ % 2 ? ( text => @_ ) : @_ ) };
		};
	}
}

1;

__END__

=head1 NAME

Ask::Functions - guts behind Ask's exported functions

=head1 SYNOPSIS

	use Ask 'question';

=head1 DESCRIPTION

This module implements the exported functions for Ask. It is kept separate
to avoid the functions polluting the namespace of the C<Ask> package.

You can force the use of a particular backend.

	use Ask::Tk;
	use Ask { backend => Ask::Tk->new }, qw( question info );

This module uses L<Exporter::Tiny>.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Ask>.

=head1 SEE ALSO

L<Ask>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013, 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

