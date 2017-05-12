package CatalystX::Features::Lib;
$CatalystX::Features::Lib::VERSION = '0.26';
use Moose;

sub setup {
	my $c = shift;

    $c->next::method(@_);

    my $appname = ref $c || $c;

    foreach my $feature ( $c->features->list ) {
        # change INC
        unshift @INC, $feature->lib;
	}

}

=head1 NAME

CatalystX::Features::Lib - Unshift your /lib into @INC

=head1 VERSION

version 0.26

=head1 SYNOPSIS

	use Catalyst qw/
			CatalystX::Features
			CatalystX::Features::Lib
		/;

=head1 METHODS

=head2 setup

Unshifts your feature C</lib> in @INC.

=head1 TODO

=over 

=item Warn when there are duplicate lib files.

=back

=head1 AUTHORS

	Rodrigo de Oliveira (rodrigolive), C<rodrigolive@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
