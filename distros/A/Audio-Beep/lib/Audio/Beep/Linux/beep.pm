package Audio::Beep::Linux::beep;

$Audio::Beep::Linux::beep::VERSION = 0.11;

use strict;

sub new {
    my $class = shift;
    my %hash = @_;
    $hash{path} ||= _search_path();
    return unless $hash{path};
    return bless \%hash, $class;
}

sub play {
    my $self = shift;
    my ($pitch, $duration) = @_;
    return `\Q$self->{path}\E -l $duration -f $pitch`;
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

Audio::Beep::Linux::beep - Audio::Beep player module using the B<beep> program

=head1 SYNOPIS

    my $player = Audio::Beep::Linux::beep->new([%options]);

=head1 USAGE

The C<new> class method can receive as option in hash fashion the following
directives

=over 4

=item path => '/full/path/to/beep'

With the path option you can set the full path to the B<beep> program in
the object. If you don't use this option the new method will look anyway
in some likely places where B<beep> should be before returning undef.

=back

=head1 NOTES

The B<beep> program is a Linux program wrote by Johnathan Nightingale.
You should find C sources in the tarball where you found this file.
The B<beep> program needs to be (usually) executed as root to actually work.
Please check C<beep(1)> for more info.

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright 2003-2004 Giulio Motta L<giulienk@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;
