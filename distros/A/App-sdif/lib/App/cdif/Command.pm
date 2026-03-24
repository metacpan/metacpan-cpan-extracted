package App::cdif::Command;

use v5.14;
use warnings;
use utf8;

use parent 'Command::Run';

# Compatibility: expand array reference in command
sub command {
    my $obj = shift;
    if (@_) {
	my @cmd = map { ref eq 'ARRAY' ? @$_ : $_ } @_;
	return $obj->SUPER::command(@cmd);
    }
    $obj->SUPER::command;
}

# Compatibility wrapper for read_error option
sub option {
    my $obj = shift;
    if (@_ == 1) {
	my $key = shift;
	if ($key eq 'read_error') {
	    my $stderr = $obj->SUPER::option('stderr') // '';
	    return $stderr eq 'redirect' ? 1 : 0;
	}
	return $obj->SUPER::option($key);
    } else {
	while (my($k, $v) = splice @_, 0, 2) {
	    if ($k eq 'read_error') {
		$obj->SUPER::option(stderr => $v ? 'redirect' : undef);
	    } else {
		$obj->SUPER::option($k => $v);
	    }
	}
	return $obj;
    }
}

# Compatibility: return INPUT filehandle
sub stdin {
    my $obj = shift;
    $obj->{INPUT};
}

# Compatibility: setstdin method
sub setstdin {
    my $obj = shift;
    $obj->with(stdin => shift);
}

1;

__END__

=encoding utf-8

=head1 NAME

App::cdif::Command - Compatibility wrapper for Command::Run

=head1 SYNOPSIS

    use App::cdif::Command;

    my $obj = App::cdif::Command->new('ls', '-l');
    $obj->update;
    print $obj->data;

=head1 DESCRIPTION

This module is a thin wrapper around L<Command::Run> for backward
compatibility.  New code should use L<Command::Run> directly.

=head1 COMPATIBILITY

The following compatibility features are provided:

=over 4

=item * B<command> method accepts array references and expands them

=item * B<read_error> option is mapped to C<stderr =E<gt> 'redirect'>

=item * B<stdin> method returns the internal INPUT filehandle

=item * B<setstdin> method is mapped to C<with(stdin =E<gt> ...)>

=back

=head1 SEE ALSO

L<Command::Run>

=cut
