use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Template;
use base 'Template';

sub new {
	my ($self, $args) = @_;
	$args ||= { ABSOLUTE => 1, INCLUDE_PATH => ($INC[0] . "/..") };
	return $self->SUPER::new($args) or die "Unable to create template";
}

sub preload_all {
	my @tts = map { chomp; $_; } `find $INC[0]/../templates/ -name "*.tt"`;
	@tts = map { s#^.*\.\./(templates.*)#$1#; $_ } @tts;
	chdir('/');
	$Apache::SWIT::TEMPLATE->context->template($_) for @tts;
	chdir($INC[0] . "/../../");
}

1;
