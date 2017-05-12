use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::Skeleton;
use base 'Class::Accessor';
use Template;
use Apache::SWIT::Maker::Manifest;
use Apache::SWIT::Maker::Config;

sub get_template_vars {
	my $self = shift;
	my %res;
	my $ts = $self->template;
	while ($ts =~ /(\w+_v)\b/g) {
		$res{$1} = $self->$1;
	}
	return \%res;
}

sub template_options { return {}; }

sub get_output {
	my $self = shift;
	my $tstr = $self->template;
	my $out;
	my $t = Template->new($self->template_options) or die "No template";
	my $vars = $self->get_template_vars;
	$t->process(\$tstr, $vars, \$out) or die "Process error " . $t->error;
	return $out;
}

sub is_in_manifest { return 1; }

sub write_output {
	my $self = shift;
	my @a = ($self->output_file, $self->get_output);
	$self->is_in_manifest ? swmani_write_file(@a) : mkpath_write_file(@a);
}

sub root_class_v { Apache::SWIT::Maker::Config->instance->root_class; }

1;
