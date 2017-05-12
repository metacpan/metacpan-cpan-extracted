use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Maker::Conversions;
use base 'Exporter';
use File::Slurp;
use Carp;

our @EXPORT = qw(conv_table_to_class conv_make_full_class
		conv_next_dual_test conv_class_to_app_name
		conv_forced_write_file conv_eval_use conv_file_to_class
		conv_module_contents conv_class_to_file
		conv_class_to_entry_point conv_silent_system);

sub conv_class_to_file {
	my $c = shift;
	$c =~ s/::/\//g;
	return $c . ".pm";
}

sub conv_module_contents {
	my ($module_class, $str) = @_;
	return <<ENDM;
use strict;
use warnings FATAL => 'all';

package $module_class;
$str

1;
ENDM
}

sub conv_silent_system {
	my $res = `$_[0] 2>&1`;
	$? and die "Unable to do $_[0]:\n$res";
}

sub _capitalize {
	my ($l, $rest) = ($_[0] =~ /(\w)(\w*)/);
	return uc($l) . $rest;
}

sub conv_table_to_class {
	my $t = shift or confess "No table was given";
	return join('', map { _capitalize($_) } split('_', $t));
}

sub conv_make_full_class {
	my ($root, $prefix, $class) = @_;
	my $res;
	if ($class =~ s/^$root\:://) {
		$res = $root . "::$class";
	} else {
		$res = $root . "::$prefix\::$class";
	}
	return $res;
}

sub conv_next_dual_test {
	my $max = 0;
	foreach (split("\n", $_[0])) {
		/\/dual\/(\d\d\d).*\.t\b/ or next;
		next if $max > $1;
		$max = $1;
	}
	return sprintf("%03d", $max + 10);
}

sub conv_class_to_app_name {
	my $class = lc(shift);
	$class =~ s/::/_/g;
	return $class;
}

sub conv_forced_write_file {
	my ($to_conf, $str) = @_;

	# ExtUtils::Install changes permissions to readonly
	my $readonly = ! -w $to_conf;
	chmod 0644, $to_conf if $readonly;
	write_file($to_conf, $str);
	chmod 0444, $to_conf if $readonly;
}

sub conv_eval_use {
	my $c = shift;
	eval "use $c";
	confess "Cannot use $c: $@" if $@;
	return $c;
}

sub conv_file_to_class {
	my $file = shift;
	$file =~ s#^lib/##;
	$file =~ s#/#::#g;
	$file =~ s#\..+##;
	return $file;
}

sub conv_class_to_entry_point {
	my ($c, $rc) = @_;
	$rc ||= ".+::UI";
	$c =~ s/^$rc\:://;
	$c =~ s#::#/#g;
	return lc($c);
}

1;
