package Audio::Beep::BSD::beep;

$Audio::Beep::BSD::beep::VERSION = 0.11;

use strict;

sub new {
    my $class = shift;
    my %hash = @_;
    $hash{path} ||= _search_path();
    $hash{device} ||= '/dev/speaker';
    return unless $hash{path} and $hash{device};
    return bless \%hash, $class;
}

sub play {
    my $self = shift;
    my ($pitch, $duration) = @_;
    $duration = sprintf('%.0f', $duration / 10);
    return `\Q$self->{path}\E -d \Q$self->{device}\E -p $pitch $duration`;
}

sub rest {
    my $self = shift;
    my ($duration) = @_;
    select undef, undef, undef, $duration/1000;
    return 1;
}

sub _search_path {
    my @prob_paths = qw(
        /usr/bin/beep
        /usr/local/bin/beep
        /bin/beep
    );
    do { return $_ if -e and -x _ } for @prob_paths;
    return;
}

=head1 NAME

Audio::Beep::BSD::beep - Audio::Beep player module using the B<beep> program

=head1 IMPORTANT!

This player module IS NOT TESTED! I found docs about the BSD B<beep> program
but I never had a chance to use it or test it.
So use it AT YOUR OWN RISK and report me bugs if possible.

=head1 SYNOPIS

    my $player = Audio::Beep::BSD::beep->new([%options]);

=head1 USAGE

The C<new> class method can receive as option in hash fashion the following
directives

=over 4

=item path => '/full/path/to/beep'

With the path option you can set the full path to the B<beep> program in
the object. If you don't use this option the new method will look anyway
in some likely places where B<beep> should be before returning undef.

=item device => '/dev/myspeaker'

Use the device option if your speaker device is different from 
"/dev/speaker". AFAIK this device exists only on i386 architecture.
That also means that this module won't probably
work for different architectures.

=back

=head1 NOTES

The B<beep> program is a BSD program wrote by Andrew Stevenson.
I found it at L<http://www.freshports.org/audio/beep/> , but you can find it 
also here L<http://www.freebsd.org/ports/audio.html>

=head1 BUGS

None known, but all possible, cause this IS NOT TESTED.

=head1 COPYRIGHT

Copyright 2004 Giulio Motta L<giulienk@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
