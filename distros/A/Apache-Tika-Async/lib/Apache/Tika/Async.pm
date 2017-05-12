package Apache::Tika::Async;
use strict;
use Moo;
use JSON::XS qw(decode_json);

use vars '$VERSION';
$VERSION = '0.06';

=head1 NAME

Apache::Tika::Async - connect to Apache Tika

=head1 SYNOPSIS

    use Apache::Tika::Async;

    my $tika= Apache::Tika::Server->new;

    my $fn= shift;

    use Data::Dumper;
    print Dumper $tika->get_meta($fn);
    print Dumper $tika->get_text($fn);

=cut

has java => (
    is => 'rw',
    #isa => 'Str',
    default => 'java',
);

has 'jarfile' => (
    is => 'rw',
    #isa => 'Str',
    #default => 'jar/tika-server-1.5-20130816.014724-18.jar',
    default => sub {
        # Do a natural sort on the dot-version
        (sort { my $ad; $a =~ /server-1.(\d+)/ and $ad=$1;
                my $bd; $b =~ /server-1.(\d+)/ and $bd=$1;
                $bd <=> $ad
              } glob 'jar/tika-server-*.jar')[0]
    },
);

has java_args => (
    is => 'rw',
    #isa => 'Array',
    builder => sub { [] },
);

has tika_args => (
    is => 'rw',
    #isa => 'Array',
    default => sub { [ ] },
);

sub cmdline {
    my( $self )= @_;
    $self->java,
    @{$self->java_args},
    '-jar',
    $self->jarfile,
    @{$self->tika_args},
};

sub fetch {
    my( $self, %options )= @_;
    my @cmd= $self->cmdline;
    push @cmd, $options{ type };
    push @cmd, $options{ filename };
    @cmd= map { qq{"$_"} } @cmd;
    die "Fetching from local process is currently disabled";
    #warn "[@cmd]";
    ''.`@cmd`
}

sub decode_csv {
    my( $self, $line )= @_;
    $line =~ m!"([^"]+)"!g;
}

sub get_meta {
    my( $self, $file )= @_;
    #return decode_json($self->fetch( filename => $file, type => 'meta' ));
    # Hacky CSV-to-hash decode :-/
    return $self->fetch( filename => $file, type => 'meta' )->meta;
};

sub get_text {
    my( $self, $file )= @_;
    return $self->fetch( filename => $file, type => 'text' );
};

sub get_test {
    my( $self, $file )= @_;
    return $self->fetch( filename => $file, type => 'test' );
};

sub get_all {
    my( $self, $file )= @_;
    return $self->fetch( filename => $file, type => 'all' );
};

sub get_language {
    my( $self, $file )= @_;
    return $self->fetch( filename => $file, type => 'language' );
};

__PACKAGE__->meta->make_immutable;

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/apache-tika>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Apache-Tika-Async>
or via mail to L<apache-tika-async-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2014-2016 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
