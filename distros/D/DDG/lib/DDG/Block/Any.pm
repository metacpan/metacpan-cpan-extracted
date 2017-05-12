package DDG::Block::Any;
our $AUTHORITY = 'cpan:DDG';
# ABSTRACT: EXPERIMENTAL
$DDG::Block::Any::VERSION = '1016';
use Moo;
use Carp;
with qw( DDG::Block );

#  _______  ______  _____ ____  ___ __  __ _____ _   _ _____  _    _
# | ____\ \/ /  _ \| ____|  _ \|_ _|  \/  | ____| \ | |_   _|/ \  | |
# |  _|  \  /| |_) |  _| | |_) || || |\/| |  _| |  \| | | | / _ \ | |
# | |___ /  \|  __/| |___|  _ < | || |  | | |___| |\  | | |/ ___ \| |___
# |_____/_/\_\_|   |_____|_| \_\___|_|  |_|_____|_| \_| |_/_/   \_\_____|
#
# API MIGHT CHANGE
#

sub request {
	my ( $self, $request ) = @_;
	my @results;
	for (@{$self->plugin_objs}) {
		my $trigger = $_->[0];
		my $plugin = $_->[1];
		push @results, $self->handle_request_matches($plugin,$request,0);
		return @results if $self->return_one && @results;
	}
	return @results;
}

sub get_triggers_of_plugin { return; }

1;

__END__

=pod

=head1 NAME

DDG::Block::Any - EXPERIMENTAL

=head1 VERSION

version 1016

=head1 AUTHOR

DuckDuckGo <open@duckduckgo.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by DuckDuckGo, Inc. L<https://duckduckgo.com/>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
