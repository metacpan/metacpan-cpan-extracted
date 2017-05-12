package App::Slackeria::Plugin;

use strict;
use warnings;
use 5.010;

our $VERSION = '0.12';

sub new {
	my ( $obj, %conf ) = @_;
	my $ref = {};
	$ref->{default} = \%conf;
	return bless( $ref, $obj );
}

sub run {
	my ( $self, $check_conf ) = @_;
	my %conf = %{ $self->{default} };
	my $ret;

	for my $key ( keys %{$check_conf} ) {
		$conf{$key} = $check_conf->{$key};
	}

	if ( ( defined $conf{enable} and $conf{enable} == 0 )
		or $conf{disable} )
	{
		return {
			data => q{},
			skip => 1,
		};
	}

	$self->{conf} = \%conf;

	$ret = eval { $self->check() };

	if ( $@ or not defined $ret ) {
		return {
			ok   => 0,
			data => $@,
		};
	}

	if ( defined $conf{href} and not defined $ret->{href} ) {
		$ret->{href} = sprintf( $conf{href}, $conf{name} );
	}
	$ret->{ok} = 1;
	return $ret;
}

1;

__END__

=head1 NAME

App::Slackeria::Plugin - parent class for all slackeria plugins

=head1 SYNOPSIS

    use parent 'App::Slackeria::Plugin';

    sub check {
        my ($self) = @_;

        if (everything_ok()) {
            return {
                data => show_things(),
            };
        }
        else {
            die("not found\n");
        }
    }

=head1 VERSION

version 0.12

=head1 DESCRIPTION

B<App::Slackeria::Plugin> is not a plugin itself; it is meant to serve as
a parent class for all other plugins.

=head1 METHODS

=over

=item $plugin = App::Slackeria::Plugin::Something->new(I<%conf>);

Returns a new object. A reference to I<%conf> is stored in $self->{default}.

=item $plugin->run(I<$conf>)

Merges $self->{default} and I<$conf> and saves the result in $self->{conf}.
I<$conf> takes precedence; $self->{default} and I<$conf> are not touched in
the process.

If $conf{enable} is set to 0, immediately returns { skip => 1 }.

It then calls the check function of App::Slackeria::Plugin::Something. If it
fails (dies or returns undef), { ok => 0, data => $@} is returned.

The hashref returned by the B<check> call is returned, with the additional key
B<ok> set to 1. Also, if $conf{href} is set, but B<check> did not set a
B<href> key, B<href> is set to $conf{href} with %s replaced by $conf{name}.

=back

=head1 DEPENDENCIES

None.

=head1 SEE ALSO

slackeria(1), App::Slackeria::PluginLoader(3pm).

=head1 AUTHOR

Copyright (C) 2011 by Daniel Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

  0. You just DO WHAT THE FUCK YOU WANT TO.
