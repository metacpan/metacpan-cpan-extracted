package Aion::Emitter::ListenersRun;
# Список слушателей

use common::sense;
use List::Util qw/pairmap max/;
use Aion::Format qw/printcolor/;

use Aion;

with qw/Aion::Run/;

# Маска для фильтра по командам
has mask => (is => 'ro', isa => Maybe[Str], arg => 1);

# Эмиттер
has emitter => (is => 'ro', isa => 'Aion::Emitter', eon => 1);

#@run emit:listeners „List of listeners”
sub list {
	my ($self) = @_;
	
	my @listeners = sort { $a->{evt} eq $b->{evt}? $a->{nice} <=> $b->{nice}: $a->{evt} cmp $b->{evt} }
		pairmap { my $evt = $a; map { +{ %$_, evt => $evt, act => "$_->{pkg}#$_->{sub}", nice => 0+$_->{nice} } } @$b }
		%{$self->emitter->event};
	
	@listeners = grep { /$self->{mask}/ } @listeners if $self->mask ne "";
	my $evtlen = max map length $_->{evt}, @listeners;
	my $actlen = max map length $_->{act}, @listeners;
	my $nicelen = max map length $_->{nice}, @listeners;
	for my $listener_bag (@listeners) {
		printcolor "#{blue}%+${nicelen}s#r #green%-${evtlen}s #{red}%-${actlen}s #{bold black}%s#r\n", @$listener_bag{qw/nice evt act remark/};
	}
}

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Emitter::ListenersRun - команда отображающая список слушателей

=head1 SYNOPSIS

Файл etc/annotation/eon.ann:

	Aion::Emitter#new,1=Aion::Emitter

Файл etc/annotation/listen.ann:

	Listener::RadiusListener#listen,6=Event::BallEvent
	Listener::WeightListener#listen,6=Event::BallEvent
	Listener::WeightListener#minimize,6=Event::BallEvent#mini „Minimize version”

Код:

	use Aion::Format qw/trappout/;
	use Aion::Emitter::ListenersRun;
	
	my $listenersRun = Aion::Emitter::ListenersRun->new;
	
	my $output = trappout {
		$listenersRun->list;
	};
	
	$output # ~> „Minimize version”

=head1 DESCRIPTION

Команда отображающая список слушателей.

=head1 FEATURES

=head2 mask

Маска для фильтра по командам.

=head2 emitter

Эмиттер.

=head1 SUBROUTINES

=head2 list ()

Точка входа в команду.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<Perl5>

=head1 COPYRIGHT

The Aion::Emitter::ListenersRun module is copyright © 2026 Yaroslav O. Kosmina. Rusland. All rights reserved.
