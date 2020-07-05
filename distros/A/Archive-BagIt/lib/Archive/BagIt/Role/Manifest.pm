use strict;
use warnings;
package Archive::BagIt::Role::Manifest;

use Moo::Role;
with 'Archive::BagIt::Role::Plugin';

use namespace::autoclean;

has 'algorithm' => (
    is => 'rw',
    #isa=>'HashRef',
);

sub BUILD {}

after BUILD => sub {
    my $self = shift;
    my $algorithm = $self->algorithm->name;
    $self->{bagit}->{manifests}->{$algorithm} = $self;
};

sub verify_file {
}

sub verify {
}

sub manifest {
}

sub create_manifest {
    my ($self) = @_;
    my $algo = $self->algorithm->name;
    my $manifest_file = $self->bagit->metadata_path."/manifest-${algo}.txt";
    # Generate digests for all of the files under ./data
    open(my $fh, ">",$manifest_file) or die("Cannot create manifest-${algo}.txt: $!\n");
    foreach my $rel_payload_file (@{$self->bagit->payload_files}) {
        #print "rel_payload_file: ".$rel_payload_file;
        my $payload_file = File::Spec->catdir($self->bagit->bag_path, $rel_payload_file);
        my $digest = $self->algorithm->verify_file( $payload_file );
        print($fh "$digest  $rel_payload_file\n");
        #print "lineout: $digest $filename\n";
    }
    close($fh);
    return 1;

}

sub create_tagmanifest {
    my ($self) = @_;
    my $algo = $self->algorithm->name;
    my $tagmanifest_file = $self->bagit->metadata_path . "/tagmanifest-${algo}.txt";
    open(my $fh, ">", $tagmanifest_file) or die("Cannot create tagmanifest-${algo}.txt: $! \n");
    foreach my $rel_nonpayload_file (@{$self->bagit->non_payload_files}) {
        my $nonpayload_file = File::Spec->catdir($self->bagit->bag_path, $rel_nonpayload_file);
        if ($rel_nonpayload_file =~ m/tagmanifest-.*\.txt$/) {
            # Ignore, we can't take digest from ourselves
        }
        elsif (-f $nonpayload_file) {
            # non-payload is all which is not payload, this allows user to define and handle own subdirs
            my $digest = $self->algorithm->verify_file($nonpayload_file);
            print($fh "$digest  $rel_nonpayload_file\n");
        }
        else {
            die("A file or directory that doesn't match: $rel_nonpayload_file");
        }
    }
    close($fh);
    return 1;
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::Role::Manifest

=head1 VERSION

version 0.058

=head1 NAME

Archive::BagIt::Role::Manifest

=head1 VERSION

version 0.058

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Archive::BagIt/>.

=head1 SOURCE

The development version is on github at L<https://github.com/Archive-BagIt>
and may be cloned from L<git://github.com/Archive-BagIt.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Rob Schmidt <rjeschmi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Rob Schmidt and William Wueppelmann.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Rob Schmidt <rjeschmi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Rob Schmidt and William Wueppelmann.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
