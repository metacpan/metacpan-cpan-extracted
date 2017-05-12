package Catalyst::Plugin::ChainedURI;
BEGIN {
  $Catalyst::Plugin::ChainedURI::AUTHORITY = 'cpan:GETTY';
}
{
  $Catalyst::Plugin::ChainedURI::VERSION = '0.007';
}
# ABSTRACT: Simple way to get an URL to an action from chained catalyst controller
use strict;
use warnings;
use Carp qw( croak );

sub chained_uri {
	my ( $c, $controller, $action_for, @extra ) = @_;
	my $control = $c->controller($controller);

	croak "Catalyst::Plugin::ChainedURI can't get controller ".$controller if !$control;
	
	my $action = $control->action_for($action_for);

	croak "Catalyst::Plugin::ChainedURI can't get action ".$action_for." on controller ".$controller if !$action;
	croak "Catalyst::Plugin::ChainedURI needs Chained action as target (given: ".$controller."->".$action_for.")" if !$action->attributes->{Chained};
	croak "Catalyst::Plugin::ChainedURI needs the end of the chain as target (given: ".$controller."->".$action_for.")" if $action->attributes->{CaptureArgs};

	my @ca;
	my %params;
	for my $arg (@extra) {
		if (ref $arg eq 'HASH') {
			$params{$_} = $arg->{$_} for keys %{$arg};
		} else {
			push @ca, $arg;
		}
	}

	$c->log->debug(
		'ChainedURI '.$controller.'->'.$action_for.' '.
		join(',',map { defined $_ ? $_ : "" } @ca).
		( %params
			? ' { '.join(' ',map { $_.'='.$params{$_} } keys %params).' }'
			: '' )
	) if $c->debug and $c->log->is_debug;

	my @captures;
	my $curr = $action;
	my $i = 0;
	while ($curr) {
		$i++;
		if (my $cap = $curr->attributes->{CaptureArgs}) {
			my $cc = $cap->[0];
			for (@{$curr->attributes->{StashArg}}) {
				if ($_) {
					$cc--;
					croak "Catalyst::Plugin::ChainedURI: too many StashArg attributes on given action '".$action."'" if $cc < 0;
					push @captures, $c->stash->{$_};
				}
			}
			croak "Catalyst::Plugin::ChainedURI: the given action '".$action."' needs more captures" if @ca < $cc; # not enough captures
			if ($cc) {
				my @splice = splice(@ca, 0, $cc);
				unshift(@captures, @splice);
			}
		}
		my $parent_path = $curr->attributes->{Chained}->[0];
		$curr = $parent_path eq '/' ? undef : $c->dispatcher->get_action_by_path($parent_path);
		$curr = undef if $i > 10;
	}
	
	@captures = reverse @captures;
	
	return $c->uri_for_action($action,\@captures,@ca,%params ? ({ %params }) : ());
}

sub current_chained_uri {
	my ( $c, @extra_args ) = @_;
	my $base = (ref $c);
	my $cbase = $base.'::Controller::';
	my $class = $c->action->class;
	$class =~ s/$cbase//g;
	my $name = $c->action->name;
	my @captures = @{$c->req->captures};
	my @arguments = @{$c->req->arguments};
	my %params = %{$c->req->query_parameters};
	for my $arg (@extra_args) {
		if (ref $arg eq 'HASH') {
			$params{$_} = $arg->{$_} for keys %{$arg};
		} else {
			push @arguments, $arg;
		}
	}
	return $class, $name, @captures, @arguments, %params ? ({ %params }) : ();
}


1;

__END__

=pod

=head1 NAME

Catalyst::Plugin::ChainedURI - Simple way to get an URL to an action from chained catalyst controller

=head1 VERSION

version 0.007

=head1 SYNOPSIS

	# In the Root controller, for example:

	sub base :Chained('/') :PathPart('') :CaptureArgs(1) :StashArg('language') {
		my ( $c, $language ) = @_;
		...
		$c->stash->{language} = $language;
		...
	}
	
	sub othercapture :Chained('base') :PathPart('') :CaptureArgs(1) { ... }
	sub final :Chained('othercapture') :PathPart('') :Args(1) { ... }
	
	# Somewhere

	my $uri = $c->chained_uri('Root','final',$othercapture_capturearg,$final_arg);
	my @current_chained_uri = $c->current_chained_uri; # current list
	my $new_url = $c->chained_uri($c->current_chained_uri,{ more => 'params' });

	# Usage hints
	
	$c->stash->{u} = sub { $c->chained_uri(@_) }; # for getting [% u(...) %]

=head1 DESCRIPTION

B<TODO>

B<Warning> The function I<current_chained_uri> doesn't work before you reach
your target action.

=head1 SUPPORT

IRC

	Join #catalyst on irc.perl.org and ask for Getty.

Repository

	http://github.com/Getty/p5-catalyst-plugin-chaineduri
	Pull request and additional contributors are welcome

Issue Tracker

	http://github.com/Getty/p5-catalyst-plugin-chaineduri/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us> L<http://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Raudssus Social Software.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
