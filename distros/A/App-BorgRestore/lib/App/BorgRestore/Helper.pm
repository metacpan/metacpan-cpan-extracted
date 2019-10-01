package App::BorgRestore::Helper;
use v5.14;
use strictures 2;

use autodie;
use Exporter 'import';
use Function::Parameters;
use POSIX ();

our @EXPORT_OK = qw(untaint);

=encoding utf-8

=head1 NAME

App::BorgRestore::Helper - Helper functions

=head1 DESCRIPTION

App::BorgRestore::Helper provides some general helper functions used in various packages in the L<App::BorgRestore> namespace.

=cut

fun untaint($data, $regex) {
	$data =~ m/^($regex)$/ or die "Failed to untaint: $data";
	return $1;
}

fun format_timestamp($timestamp) {
	return POSIX::strftime "%a. %F %H:%M:%S %z", localtime $timestamp;
}

# XXX: this also exists in BorgRestore::_handle_added_archives()
fun parse_borg_time($string) {
	if ($string =~ m/^.{4} (?<year>....)-(?<month>..)-(?<day>..) (?<hour>..):(?<minute>..):(?<second>..)$/) {
		my $time = POSIX::mktime($+{second},$+{minute},$+{hour},$+{day},$+{month}-1,$+{year}-1900);
		return $time;
	}
	return;
}

1;

__END__
